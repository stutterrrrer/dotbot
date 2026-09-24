#!/usr/bin/env python3
"""Claude Code UserPromptSubmit hook: give CLI sessions natural, rolling
titles like the desktop app ("Claude Code: status line + session titles").

How it works (a rolling summary, like an EWMA: the current title IS the state):
1. On each new question the hook immediately applies the title stored in this
   session's state file, so the prompt is never delayed.
2. Every QUESTIONS_PER_UPDATE questions it starts a detached background job
   that asks Haiku, via `claude -p`, to blend those questions into the current
   title: keep themes that recur, add new ones, drop tangents once the topic
   has moved on. The result is saved and shown from the next question (a
   `claude -p` call takes ~5-10 s, far too slow to wait for).
3. The very first question has no Haiku title yet, so it gets a quick local
   title from the question itself.

Cost: one Haiku call (thinking off) is ~2.6k input + ~10 output tokens,
about $0.0026 at API prices, so every 3 questions keeps it small.

Past messages are never re-read. Short follow-ups ("yes", "continue") and
slash commands change nothing. The desktop app titles sessions itself, so
stay silent there.
Docs: https://code.claude.com/docs/en/hooks (UserPromptSubmit -> sessionTitle)
"""
import fcntl
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

MIN_WORDS_FOR_NEW_TOPIC = 4
QUESTIONS_PER_UPDATE = 3          # one Haiku call per this many new questions
MAX_QUESTION_CHARS = 600          # what Haiku sees of each question
MAX_TITLE_LENGTH = 60
STATE_DIRECTORY = Path.home() / ".cache" / "claude-session-titles"
STATE_MAX_AGE_SECONDS = 30 * 24 * 3600
HAIKU_TIMEOUT_SECONDS = 60
# Set on the background `claude -p` call so this hook never triggers itself.
CHILD_MARKER_VARIABLE = "CLAUDE_SESSION_TITLE_CHILD"

TITLE_SYSTEM_PROMPT = """You keep a short title for a chat session, like a browser tab title.
You get the current title (may be empty) and the user's newest question(s).
Reply with ONLY the updated title.

Rules:
- 3 to 7 words, a natural readable phrase (you may use ":" "+" "&"), not a keyword list.
- Treat the current title as a running summary. If the new question continues
  the topic, keep the title's main subject and blend in the new theme.
  Replace parts only when the conversation has clearly moved on.
- Keep product names and acronyms as written (CLI, IntelliJ, Claude Code).
- No quotes, no trailing period.

Examples:
current: (empty) | new: how do I set up remote connection from my phone to this mac's claude code
-> Remote Control from phone
current: Remote Control from phone | new: check that remote control is on for all future sessions
-> Remote Control for all sessions
current: Claude Code: status line + quota | new: make CLI session titles read more naturally
-> Claude Code: status line + session titles
current: Claude Code: status line + session titles | new: check the IntelliJ settings export zip
-> IntelliJ settings backup"""

LEADING_FILLER_PATTERN = re.compile(
    r"^(?:(?:ok(?:ay)?|so|hey|hi|also|and|now|then|please|pls)[,\s]+"
    r"|(?:can|could|would|will) you (?:also |please )?"
    r"|i (?:want|would like|need) (?:you )?to )+",
    re.IGNORECASE,
)


def quick_local_title(question: str) -> str:
    """First-question fallback: the question itself, trimmed to a title."""
    first_line = question.strip().splitlines()[0]
    title = LEADING_FILLER_PATTERN.sub("", " ".join(first_line.split())).strip()
    if len(title) > MAX_TITLE_LENGTH:
        title = title[:MAX_TITLE_LENGTH].rsplit(" ", 1)[0]
    title = title.rstrip(" ?.!,;:")
    return title[:1].upper() + title[1:]


def load_state(state_file: Path) -> dict:
    try:
        return json.loads(state_file.read_text())
    except (OSError, json.JSONDecodeError):
        return {}


def save_state(state_file: Path, state: dict) -> None:
    temporary_file = state_file.with_suffix(".tmp")
    temporary_file.write_text(json.dumps(state))
    temporary_file.replace(state_file)  # atomic, so readers never see half a file


def locked(state_file: Path):
    """Exclusive lock shared by the hook and the background job."""
    lock_handle = open(state_file.with_suffix(".lock"), "w")
    fcntl.flock(lock_handle, fcntl.LOCK_EX)
    return lock_handle


def ask_haiku_for_title(current_title: str, questions: list[str]) -> str | None:
    newest_questions = " / ".join(question[:MAX_QUESTION_CHARS] for question in questions)
    request = f"current: {current_title or '(empty)'} | new: {newest_questions}\n->"
    try:
        completed = subprocess.run(
            [
                "claude", "-p", "--model", "haiku",
                "--setting-sources", "project",     # no user hooks, status line, Remote Control
                "--strict-mcp-config",              # no MCP servers to start
                "--tools", "",                      # plain text answer only
                "--no-session-persistence",         # keep it out of /resume
                "--system-prompt", TITLE_SYSTEM_PROMPT,
                request,
            ],
            capture_output=True, text=True, timeout=HAIKU_TIMEOUT_SECONDS,
            cwd=STATE_DIRECTORY,                    # no project CLAUDE.md to load
            # Thinking off: a 5-word title doesn't need it, and it was ~98% of
            # the output tokens (748 -> 12), cutting the call cost by ~60%.
            env={**os.environ, CHILD_MARKER_VARIABLE: "1", "MAX_THINKING_TOKENS": "0"},
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    lines = [line.strip() for line in completed.stdout.splitlines() if line.strip()]
    if completed.returncode != 0 or not lines:
        return None
    title = lines[-1].strip("\"'` ").removeprefix("->").strip().rstrip(".")
    return title[:MAX_TITLE_LENGTH] or None


def refine_title_in_background(state_file: Path) -> None:
    """Background job: fold every queued question into the title, then exit."""
    while True:
        with locked(state_file):
            state = load_state(state_file)
            queued_questions = state.get("queued_questions", [])
            if not queued_questions:
                state.pop("refining_since", None)
                save_state(state_file, state)
                return
            state["queued_questions"] = []
            save_state(state_file, state)
            current_title = state.get("title", "")

        new_title = ask_haiku_for_title(current_title, queued_questions)

        with locked(state_file):
            state = load_state(state_file)
            if new_title:
                state["title"] = new_title
            save_state(state_file, state)


def prune_old_state_files() -> None:
    cutoff_time = time.time() - STATE_MAX_AGE_SECONDS
    for state_file in STATE_DIRECTORY.glob("*"):
        try:
            if state_file.stat().st_mtime < cutoff_time:
                state_file.unlink()
        except OSError:
            pass


def main() -> None:
    if len(sys.argv) == 3 and sys.argv[1] == "--refine":
        refine_title_in_background(Path(sys.argv[2]))
        return
    if os.environ.get(CHILD_MARKER_VARIABLE):
        return
    if os.environ.get("CLAUDE_CODE_ENTRYPOINT") == "claude-desktop":
        return
    try:
        hook_input = json.load(sys.stdin)
    except json.JSONDecodeError:
        return

    question = hook_input.get("prompt", "").strip()
    if not question or question.startswith("/") or len(question.split()) < MIN_WORDS_FOR_NEW_TOPIC:
        return

    session_id = re.sub(r"[^A-Za-z0-9_-]", "", hook_input.get("session_id", "")) or "unknown"
    STATE_DIRECTORY.mkdir(parents=True, exist_ok=True)
    state_file = STATE_DIRECTORY / f"{session_id}.json"

    with locked(state_file):
        state = load_state(state_file)
        if not state:
            prune_old_state_files()  # cheap housekeeping, once per new session
        title_to_show = state.get("title") or quick_local_title(question)
        state.setdefault("title", title_to_show)
        state.setdefault("queued_questions", []).append(question)
        start_background_job = (
            len(state["queued_questions"]) >= QUESTIONS_PER_UPDATE
            and (
                "refining_since" not in state
                or time.time() - state["refining_since"] > HAIKU_TIMEOUT_SECONDS * 3  # stale job
            )
        )
        if start_background_job:
            state["refining_since"] = time.time()
        save_state(state_file, state)

    if start_background_job:
        subprocess.Popen(
            [sys.executable, __file__, "--refine", str(state_file)],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            start_new_session=True,  # detached: survives the hook exiting
        )

    print(json.dumps({
        "hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "sessionTitle": title_to_show}
    }))


if __name__ == "__main__":
    main()
