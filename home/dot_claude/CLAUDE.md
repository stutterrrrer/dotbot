# Ian — preferences for Claude Code (all projects, all Macs)

Managed by chezmoi (`~/.chezmoi/home/dot_claude/CLAUDE.md`). Edit the source,
then `chezmoi apply`. Claude.ai account memory is separate and is not visible
to Claude Code sessions.

## Communication

- Call me Ian. Answer in English unless I ask otherwise. English is my second
  language: when useful, briefly correct important grammar, suggest clearer
  phrasing, and say what you think I meant.
- Keep simple answers concise; give organized, actionable detail for
  substantial work.
- For programming/AI topics, point out nonstandard wording and give the
  standard industry term. When showing code or commands, explain the
  important lines, flags, and symbols.
- Dictation: "intelligence" in an IDE context means IntelliJ. "SS" means
  screenshot.
- A new message while a task is unfinished is a follow-up or addition —
  finish the earlier task too, unless I clearly replace it.

## How to work

- When I ask for implementation, inspect the real state and actually do it;
  don't stop at generic instructions. Show what changed (content, path link,
  or screenshot) and verify the result.
- A request to compare configurations is read-only: give exact paths,
  overlaps, contradictions, and diffs; don't edit until asked.
- Preserve unrelated changes in any working tree.
- On macOS, prefer APIs, app databases, CLIs, JXA/AppleScript before
  screenshots/UI automation. Don't steal focus during background work.
- When comparing apps, weigh adoption, maintenance/release activity, open
  issues, platform compatibility, and security/notarization.
- I'm in Shanghai (Asia/Shanghai) and often on a VPN: for network/access
  problems consider China routing, DNS, proxies, and VPN clients (e.g. 0dcloud).
- Give links as markdown links with a short label, e.g.
  `[Notion: "Inside tmux" section](https://…)`, not bare URLs. Claude Code
  emits them as real terminal hyperlinks (OSC 8), which tmux passes through
  (`terminal-features … hyperlinks` in `~/.tmux.conf`), so they stay clickable
  even when wrapped. A long bare URL that wraps breaks: IntelliJ's own URL
  detection grabs the cut-off first line and opens the truncated link. Use
  HTTPS URLs, not `notion://`. Finicky (the default browser, `~/.finicky.js`)
  sends Notion links straight to the Notion app.
- Before sending any external message, find the exact message/recipient and
  get my confirmation right before sending.

## Notion notes

- Never just append to a page. Fetch it first, read the nearby text, and
  merge the new material into the relevant existing headings: add to or
  replace what's there, remove duplicates (point to the other section
  instead), and keep one coherent structure.
- Match the page's existing formatting (gray callouts, numbered steps,
  tables, Sources lists) and keep my own highlights and edits.
- After editing, give the clickable HTTPS link and summarize what moved,
  merged, or was replaced.

## Claude desktop app

- Remote Control is on, so I may be on my phone: send screenshots, reports,
  and built files with SendUserFile instead of only giving local paths.
- After editing files, open the diff pane instead of pasting long diffs.
- For tasks longer than ~5 minutes, send a push notification when done or
  blocked.
- Use the built-in browser by default; use Chrome only for sites where I need
  my logged-in session — including shopping sites like Taobao. Claude in
  Chrome asks per action unless I picked "Always allow actions on this site"
  at its prompt (Notion is already allowed). Purchases, deletes, permission
  changes, and account creation always ask, so remind me up front on
  shopping sites.
- Answer in chat; publish an Artifact page only when I ask or when the result
  is meant to be shared.
- No standing per-reply chapter/retitle/cache-badge checklist (didn't hold up
  in tool-heavy sessions). Use `mark_chapter`/`cache-status.sh` occasionally,
  not every reply.

## Dotfiles (chezmoi)

- Repo: `~/.chezmoi` (source under `home/`), remote
  `https://github.com/stutterrrrer/chezmoi.git`.
- Change managed files only in the chezmoi source, then `chezmoi apply`.
- Ask before changing `home/dot_vimrc`, `home/dot_ideavimrc`, or
  `home/dot_zshrc`. Keep vimrc and ideavimrc as separate files.
- `docs/migration-reference/` is reference only — never deploy it or
  wholesale-import old-Mac plists.

## IntelliJ + Claude workflow

- Use the official **Claude Code [Beta]** JetBrains plugin
  (`com.anthropic.code.plugin`), not JetBrains AI Assistant/AI Chat, for live
  selection/active-file context and IDE diffs. Use `/ide` if it isn't
  connected; treat my current selection/open file as default context for
  "this".
- In the terminal, keep tables to ≤4 narrow columns; otherwise use lists.
- Reference code as `path:line` so IntelliJ makes it clickable.
- Status line, notification hook, session-title hook, and Vim Esc behavior
  are all pinned in `home/dot_claude/modify_settings.json` — read it if the
  details matter rather than asking me to restate them.

## Code style

- Use verbose, descriptive variable names rather than cryptic abbreviations.
- Leave clear, concise comments where they explain intent, non-obvious
  logic, or important tradeoffs.

## macOS troubleshooting

- Keyboard shortcut / input problems: check the exact key event with KeyCastr
  first, before diagnosing or changing Vim, iTerm, BetterTouchTool, or other
  mappings.
- macOS Keyboard Shortcuts: a mapping in `com.apple.symbolichotkeys` is not
  the same as the shortcut being enabled in System Settings. Verify the UI
  checkbox (especially Mission Control Control+number) before concluding a
  shortcut is configured.
- Space/Desktop indicator: use WhichSpace; don't suggest or install Spaceman.
- Stop and ask me when a password or macOS privacy prompt needs my input.
- Mac migration: use the existing chezmoi workflow; don't run Dotbot or
  migrate Karabiner.
- Verify machine-specific facts locally before documenting them, and scope
  facts that differ between Macs to the right host.

## Machine facts (re-verify before relying on them)

- IntelliJ's Conda field needs the executable `/opt/homebrew/bin/conda`
  (Miniforge base `/opt/homebrew/Caskroom/miniforge/base`), not the base dir.
- Missing colors in a CLI inside IntelliJ: check for an inherited `NO_COLOR`
  first, not the theme.
