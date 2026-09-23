# macOS application migration checklist

Use this list after `chezmoi apply` and `brew bundle` on the new Mac. Check an
item only after its settings, licenses, and sign-in state have been verified.

## Homebrew casks

- [ ] Dropzone — install and sign in/configure actions.
- [ ] KeyCastr — enable the preferred keystroke display options.
- [ ] BetterTouchTool — restore triggers, gestures, keyboard shortcuts, and
  accessibility permission.
- [ ] Moom — restore window-layout shortcuts and accessibility permission.

## Terminal and shell

- [ ] iTerm2 — import `com.googlecode.iterm2.plist` if iTerm2 is the terminal
  of choice; verify profiles, key mappings, and shell integration.
- [ ] Terminal — import `com.apple.Terminal.plist` only if Apple Terminal is
  still used.
- [ ] Oh My Zsh — confirm the managed `.zshrc` loads without errors.
- [ ] Powerlevel10k — verify the prompt and `.p10k.zsh` appearance.
- [ ] Homebrew CLI tools — verify `brew doctor`, `brew bundle check`, tmux,
  MacVim, fzf, ranger, nnn, rbenv, git-lfs, and shell plugins.

## Development tools

- [ ] IntelliJ IDEA — install/sign in, verify the `idea` launcher, and restore
  IDE settings/plugins separately from this repository.
- [ ] IntelliJ scratch files — restore the contents of
  `legacy-dotbot/intellij_scratch_files_symlinks/` to the new IntelliJ scratch
  directory if needed.
- [ ] Git — verify user identity, osxkeychain, Git LFS, and SSH/GPG access.
- [ ] Python/Conda — verify the intended interpreter and environment; Conda
  initialization is automatic only for standard Anaconda/Miniconda paths.

## macOS permissions and final checks

- [ ] Grant Accessibility/Input Monitoring permissions to BetterTouchTool and
  Moom when macOS requests them.
- [ ] Re-enable any app-specific login items, menu-bar helpers, and cloud sync.
- [ ] Run `chezmoi diff`, `chezmoi doctor`, and `brew bundle check`.
- [ ] Keep `~/.dotbot-symlink-backup-20260922` until the new setup has been
  used successfully; remove it only after rollback is no longer needed.
