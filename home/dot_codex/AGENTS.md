# **Machine-Specific Codex Instructions — Not Account-Wide Preferences**

> This field shows the contents of this Mac's `AGENTS.md`. It contains
> machine-specific and local-agent workflow rules; it is not the account-wide
> ChatGPT preference field. For account-wide preferences, open **Custom
> For account-wide preferences, in ChatGPT on iPhone or in ChatGPT Web,  open **Custom instructions**  under
> **Settings → Personalization → Custom instructions**.
> Account-wide preferences are not accessible from ChatGPT Mac app.

# Machine-specific and local-agent workflow

## Account-preference bridge for Codex tasks

- The account-level source of truth is ChatGPT's Custom instructions field.
- Before responding to each user message, read `/Users/ian/.codex/account-preferences.md` and apply its account-level response preferences when relevant.
- This file is a local mirror, not a replacement for account Custom instructions; system, developer, and current user instructions take precedence.
- When a preference is saved or amended, refresh the mirror from the verified ChatGPT Custom instructions field before claiming that Codex is synchronized.
- Task continuity safeguard: if a new user message arrives while an earlier task is unfinished, treat the new message as a follow-up or addition and resume the earlier task first. Do not replace the unfinished task unless the user clearly says to switch tasks.
- Keep only this bridge rule in `AGENTS.md`; do not paste the full account preference text here.

- Keep account-level ChatGPT response preferences in Custom instructions;
  this file contains only machine-specific and local-agent workflow rules.
- Manage this file through the existing chezmoi configuration so it
  participates in Mac configuration and migration. The active source is
  `/Users/ian/.chezmoi/home/dot_codex/AGENTS.md`; inspect the active chezmoi
  source before changing paths or tracked files.
- Verify machine-specific facts locally before documenting them. Scope facts
  that differ between Macs to the correct host using the existing
  configuration conventions.

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

## Agent and machine-specific workflow

- After modifying files, directly open the changed file or files in Codex's side-by-side panel when practical.
- For macOS Space/Desktop indicators, use WhichSpace; do not suggest or install Spaceman.
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
