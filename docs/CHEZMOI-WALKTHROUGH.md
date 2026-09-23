# Chezmoi walkthrough

This document explains the migration from Dotbot to chezmoi and the layout that
is now active. The short version is: edit `home/`, preview with `chezmoi diff`,
and apply with `chezmoi apply`.

## What changed

The old setup used Dotbot to create home-directory symlinks from flat files at
the repository root. During the migration, the six home symlinks were backed
up in `~/.dotbot-symlink-backup-20260922`.

The new setup uses chezmoi to render and copy managed files into the home
directory. It intentionally manages regular files rather than recreating the
old symlinks. The old Dotbot files remain together under `legacy-dotbot/` only
for rollback and reference.

## Active repository layout

```text
.
├── .chezmoiroot                         # source-state root selector
├── Brewfile                             # Homebrew formulas and casks
├── home/                                # active chezmoi source state
│   ├── .chezmoi.toml.tmpl               # per-machine config template
│   ├── .chezmoiignore                   # conditional target exclusions
│   ├── dot_gitconfig                    # -> ~/.gitconfig
│   ├── dot_zshrc                        # -> ~/.zshrc
│   ├── dot_config/ian/private_proxy...  # -> ~/.config/ian/proxy.zsh
│   ├── dot_local/bin/...                # -> ~/.local/bin/...
│   └── run_*                            # setup hooks, never target files
├── APPLICATION-MIGRATION-CHECKLIST.md   # app-by-app post-install checks
├── docs/                                # these persistent guides
└── legacy-dotbot/                       # disposable old setup
```

`legacy-dotbot/` contains the old installer, Dotbot submodule, flat dotfiles,
plist exports, and IntelliJ scratch-file links. Do not edit those files for
normal maintenance. Once the new Mac is working, delete that directory and
the root `.gitmodules` file together. Keep the home backup until rollback is
no longer needed.

## How chezmoi maps names

Chezmoi encodes the target path and file behavior in the source filename:

| Source name | Target or behavior |
| --- | --- |
| `home/dot_zshrc` | `~/.zshrc` |
| `home/dot_config/ian/...` | `~/.config/ian/...` |
| `dot_` prefix | Adds a leading dot to that path component |
| `private_` prefix | Makes the generated file private; it is not part of the target filename |
| `executable_` prefix | Makes the generated file executable |
| `.tmpl` suffix | Renders the file as a Go template before applying it |
| `run_once_...` | Runs once for each unique rendered script body |
| `run_onchange_...` | Runs again when the rendered script body changes |
| `before_` / `after_` in a script name | Controls whether the hook runs before or after file updates |

`.chezmoiroot` contains `home`, so chezmoi treats `home/` as the source-state
root. Repository files such as `README.md`, `Brewfile`, and these guides are
therefore not copied into `$HOME`.

## What happens during `chezmoi init --apply`

1. Chezmoi clones or opens the repository in the configured source directory.
2. `home/.chezmoi.toml.tmpl` creates the machine-local config at
   `~/.config/chezmoi/chezmoi.toml`. It asks whether the local HTTP proxy
   should be enabled and stores the answer as `data.enable_proxy`.
3. The Homebrew pre-hook installs Homebrew on macOS when `brew` is missing.
4. Chezmoi renders the managed files and compares them with `$HOME`.
5. The Homebrew post-hook runs `brew bundle` using the repository `Brewfile`.
   A checksum comment makes the hook run again when `Brewfile` changes.
6. The Oh My Zsh once-hook clones Oh My Zsh if `~/.oh-my-zsh` does not exist.
7. The final target files are available in `$HOME`.

The hooks are deliberately idempotent: rerunning the apply should not reinstall
Homebrew or Oh My Zsh when they already exist. Chezmoi records successful
`run_once_` and `run_onchange_` executions in its local state database.

## Machine-local proxy setting

The committed template contains only the loopback proxy values and is included
when `data.enable_proxy` is true. The generated file is private and lives at
`~/.config/ian/proxy.zsh`. To change the choice on a machine, edit the local
chezmoi config:

```toml
[data]
enable_proxy = true
```

Then run:

```sh
chezmoi --source "$HOME/.dotfiles" apply
```

Do not put credentials, tokens, private keys, or other machine-specific
secrets in this repository. Use chezmoi encryption or a password manager for
those values.

## Useful inspection commands

```sh
# Show the source path for a target.
chezmoi --source "$HOME/.dotfiles" source-path ~/.zshrc

# Show the rendered target content without changing anything.
chezmoi --source "$HOME/.dotfiles" cat ~/.zshrc

# Preview all differences.
chezmoi --source "$HOME/.dotfiles" diff

# Check whether the target state is already applied.
chezmoi --source "$HOME/.dotfiles" verify

# Show machine data used by templates.
chezmoi --source "$HOME/.dotfiles" data
```

Official references: [source-directory customization](https://www.chezmoi.io/user-guide/advanced/customize-your-source-directory/), [setup and config templates](https://www.chezmoi.io/user-guide/setup/), and [script behavior](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/).
