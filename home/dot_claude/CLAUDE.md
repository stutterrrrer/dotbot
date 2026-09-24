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
- Use clickable HTTPS links (including Notion HTTPS, not `notion://`). When
  asked to open a Notion page, prefer the native Notion app.
- Before sending any external message, find the exact message/recipient and
  get my confirmation right before sending.

## Dotfiles (chezmoi)

- Repo: `~/.chezmoi` (source under `home/`), remote
  `https://github.com/stutterrrrer/chezmoi.git`.
- Change managed files only in the chezmoi source, then `chezmoi apply`.
- Ask before changing `home/dot_vimrc`, `home/dot_ideavimrc`, or
  `home/dot_zshrc`. Keep vimrc and ideavimrc as separate files.
- `docs/migration-reference/` is reference only — never deploy it or
  wholesale-import old-Mac plists.

## IntelliJ + Claude workflow

- Run the `claude` CLI inside IntelliJ's built-in terminal so Claude Code's
  Vim prompt mode works (`editorMode: vim`, `jk`/`kj` → Esc, pinned by
  `home/dot_claude/modify_settings.json`).
- Use the official **Claude Code [Beta]** JetBrains plugin
  (`com.anthropic.code.plugin`) for live selection / active-file context and
  IDE diffs. Use `/ide` if it isn't connected.
- Don't use JetBrains AI Assistant / AI Chat for this.
- For Vim-mode Esc, IntelliJ's Settings → Tools → Terminal → "Move focus to the
  editor with Escape" must be off.

## Machine facts (re-verify before relying on them)

- IntelliJ's Conda field needs the executable `/opt/homebrew/bin/conda`
  (Miniforge base `/opt/homebrew/Caskroom/miniforge/base`), not the base dir.
- Missing colors in a CLI inside IntelliJ: check for an inherited `NO_COLOR`
  first, not the theme.
- Codex conversation stuck "open in another app": delete it from IntelliJ's
  AI Chat tool window, then Retry in the ChatGPT/Codex app.
