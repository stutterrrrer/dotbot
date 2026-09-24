#!/usr/bin/env python3
"""Claude Code UserPromptSubmit hook: keep the CLI session title in line with
the session's rolling topic, like the desktop app does.

Instead of titling from only the newest question, each session keeps a small
table of keyword weights that works like an exponentially weighted moving
average (EWMA): on every new question, old weights decay by (1 - ALPHA) and the
question's keywords are added with weight ALPHA. Topics that keep coming up
stay in the title; one-off tangents fade after a few questions. Past messages
are never re-read; the table is the whole memory.

Local only (no model call), so it adds no latency or usage. Short follow-ups
("yes", "continue") and slash commands leave the title and weights unchanged.
The desktop app titles sessions itself, so stay silent there.
Docs: https://code.claude.com/docs/en/hooks (UserPromptSubmit -> sessionTitle)
"""
import json
import os
import re
import sys
import time
from pathlib import Path

ALPHA = 0.4                  # weight of the newest question (higher = reacts faster)
PHRASE_BONUS = 1.5           # prefer "status line" over "status" + "line"
MIN_KEPT_WEIGHT = 0.03       # forget terms that decayed below this
MIN_WORDS_FOR_NEW_TOPIC = 4
MAX_TITLE_PHRASES = 3
MAX_TITLE_LENGTH = 50
STATE_DIRECTORY = Path.home() / ".cache" / "claude-session-titles"
STATE_MAX_AGE_SECONDS = 30 * 24 * 3600

STOPWORDS = set("""
a an the and or but if then so also as at by for from in into of on onto to
with without within about over under up down out off than too very just only
i me my mine we our you your yours it its this that these those there here
is am are was were be been being do does did done doing have has had having
can could would should will shall may might must need needs want wants
what whats which who whom whose when where why how whether
make makes made show shows get gets got set use using used let lets like
please pls ok okay hey hi yes no not dont doesnt isnt cant im ive
all any some each every both either more most other another same such
one two now again still already even well way thing things something
tell know think see look check try go going give take put keep
current currently new way ways instead rather
turn turned change changes changed try tried ask asked say says find found
add added remove run runs start stop open close work works working happen
happens end ends everything anything nothing someone type text line-of
even better best good great whole completely rough going ongoing on-going
sure able really actually maybe via per etc also both future past
doesnt doenst didnt wont dont thats theres lets hows
""".split())

CHUNK_BREAK_PATTERN = re.compile(r"[,;:?!()\[\]\n]|\.(?:\s|$)")
TOKEN_PATTERN = re.compile(r"[A-Za-z][A-Za-z0-9+#.\-]*[A-Za-z0-9+#]|[A-Za-z]")


def normalize(word: str) -> str:
    """Lowercase and strip a simple plural so 'sessions' and 'session' merge."""
    lowered = word.lower()
    if len(lowered) > 4 and lowered.endswith("s") and not lowered.endswith(("ss", "us", "is")):
        return lowered[:-1]
    return lowered


def extract_terms(prompt_text: str) -> tuple[dict[str, float], dict[str, str]]:
    """Return {term_key: score} for keywords and adjacent-keyword phrases,
    plus {term_key: display_form} keeping the user's casing (IDE, CLI)."""
    term_scores: dict[str, float] = {}
    display_forms: dict[str, str] = {}
    # Phrases never span punctuation ("greps? turn" is not a phrase).
    for text_chunk in CHUNK_BREAK_PATTERN.split(prompt_text):
        previous_keyword = None  # (key, surface) of the previous token if it was a keyword
        for surface_word in TOKEN_PATTERN.findall(text_chunk):
            key = normalize(surface_word)
            if key in STOPWORDS or len(key) < 2:
                previous_keyword = None
                continue
            term_scores[key] = term_scores.get(key, 0.0) + 1.0
            display_forms[key] = surface_word
            if previous_keyword:
                phrase_key = f"{previous_keyword[0]} {key}"
                term_scores[phrase_key] = term_scores.get(phrase_key, 0.0) + PHRASE_BONUS
                display_forms[phrase_key] = f"{previous_keyword[1]} {surface_word}"
            previous_keyword = (key, surface_word)
    # L2-normalize: a long question can't swamp the history, and a keyword-rich
    # question isn't spread thinner than a three-word one (as a plain sum would).
    vector_length = sum(score * score for score in term_scores.values()) ** 0.5 or 1.0
    return {key: score / vector_length for key, score in term_scores.items()}, display_forms


def update_weights(state: dict, prompt_text: str) -> None:
    new_scores, new_display_forms = extract_terms(prompt_text)
    term_weights = {
        key: weight * (1 - ALPHA)
        for key, weight in state.get("term_weights", {}).items()
        if weight * (1 - ALPHA) >= MIN_KEPT_WEIGHT
    }
    for key, score in new_scores.items():
        term_weights[key] = term_weights.get(key, 0.0) + ALPHA * score
    display_forms = {key: form for key, form in state.get("display_forms", {}).items() if key in term_weights}
    for key, new_form in new_display_forms.items():
        # Keep the most capitalized spelling seen, so "CLI" beats a later "cli".
        old_form = display_forms.get(key, "")
        if sum(map(str.isupper, new_form)) >= sum(map(str.isupper, old_form)):
            display_forms[key] = new_form
    state["term_weights"] = term_weights
    state["display_forms"] = display_forms


def build_title(state: dict) -> str | None:
    ranked_terms = sorted(state["term_weights"].items(), key=lambda item: item[1], reverse=True)
    chosen_keys: list[str] = []
    covered_words: set[str] = set()
    for key, _weight in ranked_terms:
        key_words = set(key.split())
        if key_words & covered_words:
            continue  # skip "status" once "status line" is in, and near-duplicates
        chosen_keys.append(key)
        covered_words |= key_words
        if len(chosen_keys) == MAX_TITLE_PHRASES:
            break
    if not chosen_keys:
        return None
    title = ", ".join(state["display_forms"].get(key, key) for key in chosen_keys)
    if len(title) > MAX_TITLE_LENGTH:
        title = title[:MAX_TITLE_LENGTH].rsplit(",", 1)[0]
    return title[:1].upper() + title[1:]


def prune_old_state_files() -> None:
    cutoff_time = time.time() - STATE_MAX_AGE_SECONDS
    for state_file in STATE_DIRECTORY.glob("*.json"):
        try:
            if state_file.stat().st_mtime < cutoff_time:
                state_file.unlink()
        except OSError:
            pass


def main() -> None:
    if os.environ.get("CLAUDE_CODE_ENTRYPOINT") == "claude-desktop":
        return
    try:
        hook_input = json.load(sys.stdin)
    except json.JSONDecodeError:
        return

    prompt_text = hook_input.get("prompt", "").strip()
    if not prompt_text or prompt_text.startswith("/"):
        return
    if len(prompt_text.split()) < MIN_WORDS_FOR_NEW_TOPIC:
        return

    session_id = re.sub(r"[^A-Za-z0-9_-]", "", hook_input.get("session_id", "")) or "unknown"
    STATE_DIRECTORY.mkdir(parents=True, exist_ok=True)
    state_file = STATE_DIRECTORY / f"{session_id}.json"
    try:
        state = json.loads(state_file.read_text())
    except (OSError, json.JSONDecodeError):
        state = {}
        prune_old_state_files()  # cheap housekeeping, once per new session

    update_weights(state, prompt_text)
    state_file.write_text(json.dumps(state))

    title = build_title(state)
    if title:
        print(json.dumps({
            "hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "sessionTitle": title}
        }))


if __name__ == "__main__":
    main()
