# macOS application migration checklist

Use this list after `chezmoi apply` and `brew bundle` on the new Mac. Check an
item only after its settings, licenses, and sign-in state have been verified.

## Migration boundaries

The labels below are intentional:

- **CHEZMOI** — copied or rendered automatically by this repository.
- **BREW ONLY** — the application is installed by Homebrew, but its settings
  are not copied.
- **EXPORT/IMPORT** — use the application-supported transfer format; do not
  copy its live database or preference directory into this repository.
- **MANUAL** — macOS permission, license, account, or hardware state must be
  recreated on the new Mac.

## What chezmoi migrates

After `chezmoi apply`, these user-level files and settings are restored:

- **CHEZMOI** `~/.zshrc`, including Homebrew detection, Oh My Zsh loading,
  Powerlevel10k loading, shell history behavior, aliases, and the opt-in proxy
  source.
- **CHEZMOI** `~/.p10k.zsh`, the Powerlevel10k prompt configuration.
- **CHEZMOI** `~/.gitconfig`, including Git aliases, defaults, and credential
  helper configuration. Credentials and private keys are not included.
- **CHEZMOI** `~/.vimrc` and `~/.ideavimrc`, including Vim and IdeaVim settings
  and key mappings.
- **CHEZMOI** `~/.tmux.conf`.
- **CHEZMOI** `~/.local/bin/idea` and
  `~/.local/bin/codex_thread_lock_status`.
- **CHEZMOI** `~/.config/ian/proxy.zsh` only when the machine-local chezmoi
  setting enables the proxy.
- **CHEZMOI** the portable Codex preferences: `~/.codex/AGENTS.md`,
  `~/.codex/keybindings.json`, and the reviewed general values merged into
  `~/.codex/config.toml`.
- **CHEZMOI** the machine-local chezmoi configuration itself, generated from
  `home/.chezmoi.toml.tmpl`; it asks the new Mac whether the proxy should be
  enabled.

The setup hooks also install Homebrew when needed, install the packages in
`Brewfile`, and install Oh My Zsh. They do not migrate application databases,
macOS privacy permissions, licenses, accounts, or window/display state.

## Homebrew casks

- [ ] **BREW ONLY — Dropzone** — install and sign in/configure actions.
- [ ] **BREW ONLY — KeyCastr** — enable the preferred keystroke display
  options.
- [ ] **EXPORT/IMPORT + MANUAL — BetterTouchTool** — export the Master Preset
  as a JSON preset on the old Mac, transfer it privately, import it on the new
  Mac, and grant Accessibility permission. See the detailed procedure below.
- [ ] **EXPORT/IMPORT + MANUAL — Moom** — perform the one-time plist export
  and import, then grant Accessibility permission. Moom does not provide
  automatic cross-Mac settings sync.

### BetterTouchTool transfer

BetterTouchTool's supported portable unit is a preset, not the entire live
settings directory. The Master Preset contains the global and app-specific
trigger configuration. Export it from BetterTouchTool's Presets interface as a
JSON preset, transfer it through a private channel, and import it on the new
Mac. Review the preset before importing because BTT presets can contain scripts
or other actions.

The current machine also has these live BTT state locations, but they are not
managed by chezmoi and should not be committed to this repository:

```text
~/Library/Application Support/BetterTouchTool/
~/Library/Preferences/com.hegenberg.BetterTouchTool.plist
```

Optional: BetterTouchTool now offers experimental iCloud preset sync. It can
reduce future manual transfers, but keep a reviewed JSON export as the
rollback source because the vendor still describes the sync as experimental.

### Moom transfer

Moom has no automatic cross-Mac sync and its vendor explicitly advises against
keeping its settings file synchronized through a symlink. For this one-time
migration, quit Moom on both Macs and run:

On the old Mac:

```sh
defaults export com.manytricks.Moom "$HOME/Desktop/Moom.plist"
```

Transfer `Moom.plist` privately to the new Mac. After installing Moom, quit it
and run on the new Mac:

```sh
defaults import com.manytricks.Moom "$HOME/Desktop/Moom.plist"
```

Then launch Moom and verify the custom actions, keyboard shortcuts, grid
dimensions, saved layouts, and display-specific behavior. Because layouts can
depend on the new Mac's displays and resolutions, expect to adjust those
parts manually even after import. Do not put the plist in chezmoi.

## Terminal and shell

- [ ] **EXPORT/IMPORT — iTerm2** — import `com.googlecode.iterm2.plist` if
  iTerm2 is the terminal of choice; verify profiles, key mappings, and shell
  integration. The plist is not currently managed by chezmoi.
- [ ] **EXPORT/IMPORT — Apple Terminal** — import `com.apple.Terminal.plist`
  only if Apple Terminal is still used. The plist is not currently managed by
  chezmoi.
- [ ] **CHEZMOI — Oh My Zsh** — confirm the managed `.zshrc` loads without
  errors.
- [ ] **CHEZMOI — Powerlevel10k** — verify the prompt and `.p10k.zsh`
  appearance.
- [ ] **CHEZMOI/BREW — Homebrew CLI tools** — verify `brew doctor`,
  `brew bundle check`, tmux, MacVim, fzf, ranger, nnn, rbenv, git-lfs, and
  shell plugins.

The repository currently contains historical/working terminal plist exports,
but they live outside the active `home/` source tree. Keep only the plist for
the terminal you actually use and transfer it privately.

## Development tools

- [ ] **BREW/INSTALL + ACCOUNT SYNC — IntelliJ IDEA** — install/sign in, verify
  the `idea` launcher, and enable JetBrains Backup and Sync for IDE themes,
  keymaps, editor settings, plugins, live templates, and other supported
  categories. Use a JetBrains settings ZIP export if account sync is not
  available.
- [ ] **CHEZMOI — IdeaVim** — verify `~/.ideavimrc`; this repository carries
  the Vim-style IntelliJ key mappings separately from IntelliJ's native
  keymap.
- [ ] **MANUAL — IntelliJ scratch files** — restore the contents of
  `legacy-dotbot/intellij_scratch_files_symlinks/` to the new IntelliJ scratch
  directory if needed.
- [ ] **CHEZMOI/MANUAL — Git** — verify user identity, osxkeychain, Git LFS, and
  SSH/GPG access. Identity configuration is managed; credentials and keys are
  intentionally not.
- [ ] **BREW/MANUAL — Python/Conda** — verify the intended interpreter and
  environment; Conda initialization is automatic only for standard
  Anaconda/Miniconda paths.

## Keyboard and window-management utilities not currently managed
- [ ] **MANUAL — macOS keyboard shortcuts and permissions** — System Settings
  keyboard shortcuts, Accessibility, Input Monitoring, Screen Recording, and
  Full Disk Access are not portable chezmoi files and must be reapproved. See
  [`docs/MAC-SYSTEM-SETTINGS-MIGRATION.md`](docs/MAC-SYSTEM-SETTINGS-MIGRATION.md)
  for the source-Mac audit, BTT ownership recommendations, and the read-only
  audit script.

## macOS system settings and BTT ownership

The current Mac's audited non-default-looking settings include Dark mode,
24-hour time, English/Chinese input sources, key-repeat values, function-key
mode, pointer/trackpad speeds, explicit trackpad gestures, Dock auto-hide and
right-side placement, four configured hot corners, increased contrast/reduced
transparency, and a multi-display Spaces layout. These are **MANUAL / NATIVE
MACOS** settings by default. Recreate them in System Settings after the new
Mac's hardware and displays are connected.

- [ ] **MANUAL — Keyboard > Keyboard Shortcuts** — review and recreate
  Mission Control, Spotlight, Screenshots, Services, Input Sources, Function
  Keys, Modifier Keys, and App Shortcuts. The raw `com.apple.symbolichotkeys`
  records are implementation details, not a safe bulk-import format.
- [ ] **MANUAL — Keyboard and Trackpad** — recreate key-repeat delay/rate,
  press-and-hold behavior, function-key mode, pointer/trackpad speed, Force
  Click, scrolling, and native three/four-finger gestures.
- [ ] **MANUAL — Language & Region / Control Center** — recreate English and
  Chinese input sources, locale/units, Celsius, 24-hour time, date, and
  weekday display.
- [ ] **MANUAL — Desktop & Dock / Displays** — recreate Dock auto-hide,
  right-side placement, size, hot corners, appearance, display arrangement,
  Mission Control, and Spaces after the new hardware is connected.
- [ ] **MANUAL — Accessibility** — recreate increased contrast and reduced
  transparency, then separately reapprove Accessibility, Input Monitoring,
  Screen Recording, and Full Disk Access for the relevant apps.
- [ ] **EXPORT/IMPORT — BTT** — import the reviewed Master Preset only for
  custom gestures, app shortcuts, window actions, text expansion, or hot
  corners that BTT is intentionally chosen to own.

BTT can reliably own custom gestures, app-specific shortcuts, window actions,
and hot-corner actions when they are configured in BTT and exported as a
reviewed Master Preset. Choose one owner for each shortcut: do not leave a
native macOS shortcut and a BTT shortcut active for the same trigger unless
double execution is intentional. Do not use BTT as the owner for key repeat,
function-key mode, input-source installation, modifier remapping, display/
Spaces topology, accessibility options, or privacy permissions.

For the exact observed values and the safer native-versus-BTT split, see
[`docs/MAC-SYSTEM-SETTINGS-MIGRATION.md`](docs/MAC-SYSTEM-SETTINGS-MIGRATION.md).

## macOS permissions and final checks

- [ ] **MANUAL — permissions** — grant Accessibility/Input Monitoring
  permissions to BetterTouchTool and Moom when macOS requests them.
- [ ] Re-enable any app-specific login items, menu-bar helpers, and cloud sync.
- [ ] Run `chezmoi diff`, `chezmoi doctor`, and `brew bundle check`.
- [ ] Keep `~/.dotbot-symlink-backup-20260922` until the new setup has been
  used successfully; remove it only after rollback is no longer needed.

## Vendor references

- [Moom settings transfer FAQ](https://manytricks.com/osticket/kb/faq.php?id=53)
- [BetterTouchTool presets](https://docs.folivora.ai/docs/configuration/presets/)
- [BetterTouchTool automatic backups](https://docs.folivora.ai/docs/configuration/restoring-backups/)
- [JetBrains IDE settings backup and sync](https://www.jetbrains.com/help/idea/sharing-your-ide-settings.html)
