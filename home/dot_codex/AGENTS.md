# Preference persistence

- Save future user preferences and durable instructions in this file rather
  than standalone note files, unless I explicitly request a different
  location.

## Preference and instruction ownership

- Account-wide ChatGPT Memory owns durable personal preferences that should
  follow the user across devices. Do not duplicate personal shopping/style
  preferences or personal background in this file.
- This file owns machine-specific and agent-specific working instructions.
- Manage this file through the existing chezmoi configuration so it
  participates in Mac configuration and migration. The active source is
  `/Users/ian/.chezmoi/home/dot_codex/AGENTS.md`; inspect the active chezmoi
  source before changing paths or tracked files.
- Verify machine-specific facts locally before documenting them. Scope facts
  that differ between Macs to the correct host using the existing
  configuration conventions.
- If account-wide Memory is unavailable in an agent session, say so when a
  missing preference matters; do not assume this file grants access to it.

## Current Mac migration constraints

- Use the existing chezmoi migration workflow. Do not run Dotbot or migrate
  Karabiner as part of this migration.
- Stop for user interaction when a password or macOS privacy prompt requires
  it.
- Inspect the current configuration before editing, preserve unrelated
  instructions and user changes, and verify the resulting targeted diff.
- Treat reviewed files under `docs/migration-reference/` as AI-readable
  reference material only; do not deploy them as active chezmoi targets.

# Named task commands

- `old_mac_task`: When I use this name with a task description, locate the
  currently connected old-Mac local Codex Work task, regardless of its exact
  title, and perform the requested task there. Use the connected old Mac and
  its workspace rather than this Mac unless I explicitly say otherwise. If no
  connected old-Mac task is available, report that limitation instead of
  silently using another task or machine.

When writing or modifying code:

- Use verbose, descriptive variable names rather than cryptic abbreviations.
- Leave clear, concise comments where they explain intent, non-obvious logic, or important tradeoffs.

Communication preferences:

- Respond in English by default unless I ask for another language.
- When a task takes meaningful time or involves substantial work, provide a sufficiently detailed, well-organized explanation rather than an overly terse answer.
- Because English is my second language, begin responses with a brief language note when useful: point out important grammatical errors, suggest clearer phrasing, and identify likely intended meaning. Keep this section short and secondary to the main answer.
- For programming and AI topics, point out discrepancies between my wording and standard industry terminology, and suggest the standard English terms.

Personal preferences:

- When a new user message arrives while an earlier request is unfinished, continue and complete the earlier request first unless the new message clearly replaces it. Treat follow-up questions as additions when possible, and answer both in a coherent order.
- After modifying files, directly open the changed file or files in Codex's side-by-side panel when practical.
- When explaining code or commands, explain what each line, flag, symbol, and important term does instead of providing unexplained snippets.
- When the user says "intelligence" in a software-development or IDE context, infer that they mean IntelliJ, because they commonly use dictation.
- For macOS Space/Desktop indicators, use WhichSpace; do not suggest or install Spaceman.

- When comparing applications, always consider objective adoption and
  maintenance signals, including download counts, latest release or update
  date, release cadence, current maintenance activity, open issues, platform
  compatibility, and relevant security or distribution details such as
  notarization.
- For keyboard shortcut and input problems, use the user's KeyCastr setup
  first to verify the exact key event before diagnosing or changing Vim,
  iTerm, BetterTouchTool, or other mappings.
- During background diagnostics or configuration work, avoid activating apps,
  opening windows, stealing keyboard focus, or sending foreground keystrokes
  whenever possible. Prefer passive checks and background APIs; ask before
  foreground interaction is necessary.
- Prefer programmatic access to application data and controls, such as APIs,
  local databases, AppleScript, and command-line interfaces, before using
  screenshots or other visual inspection. Use screenshots when no reliable
  structured interface is available.
- When troubleshooting macOS Keyboard Shortcuts, distinguish between a
  shortcut mapping defined in `com.apple.symbolichotkeys` and the
  corresponding shortcut enabled in System Settings. Verify the UI checkbox,
  especially for Mission Control Control+number shortcuts, before concluding
  that the shortcut is configured.
- When I ask you to add a tech tip to the Notion page titled `chat-gpt related`
  in the Tech Tips Master List database, add it to that page unless I specify a
  different destination.
