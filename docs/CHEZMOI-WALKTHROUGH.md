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
old symlinks. The former Dotbot files were removed after the migration was
validated.

## Active repository layout

```text
.
├── .chezmoiroot                         # source-state root selector
├── Brewfile                             # Homebrew formulas and casks
├── home/                                # active chezmoi source state
│   ├── .chezmoi.toml.tmpl               # per-machine config template
│   ├── .chezmoiignore                   # conditional target exclusions
│   ├── .chezmoidata/codex.toml          # portable Codex preferences
│   ├── dot_gitconfig                    # -> ~/.gitconfig
│   ├── dot_zshrc                        # -> ~/.zshrc
│   ├── dot_codex/                       # -> ~/.codex/ (portable Codex preferences)
│   ├── dot_config/ian/private_proxy...  # -> ~/.config/ian/proxy.zsh
│   ├── dot_local/bin/...                # -> ~/.local/bin/...
│   └── run_*                            # setup hooks, never target files
├── APPLICATION-MIGRATION-CHECKLIST.md   # app-by-app post-install checks
└── docs/                                # these persistent guides
```

## How chezmoi maps names

Chezmoi encodes the target path and file behavior in the source filename:

| Source name | Target or behavior |
| --- | --- |
| `home/dot_zshrc` | `~/.zshrc` |
| `home/dot_codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| `home/dot_codex/keybindings.json` | `~/.codex/keybindings.json` |
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
chezmoi --source "$HOME/.chezmoi" apply
```

Do not put credentials, tokens, private keys, or other machine-specific
secrets in this repository. Use chezmoi encryption or a password manager for
those values.

## Codex preferences: portable versus machine-specific

The active Codex preference files are deliberately split from the rest of the
Codex data:

- `home/dot_codex/AGENTS.md` manages `~/.codex/AGENTS.md`, the portable
  natural-language user and agent preferences that Codex loads as instruction
  context.
- `home/dot_codex/keybindings.json` manages the portable Codex desktop
  keybinding preference.
- `home/.chezmoidata/codex.toml` is the source of portable Codex choices.
- `home/dot_codex/modify_private_config.toml` partially manages
  `~/.codex/config.toml`: it updates only the reviewed portable choices while
  preserving machine-specific absolute paths, local MCP commands, project trust
  entries, plugin marketplace paths, and application state already on the Mac.

The following are intentionally excluded from chezmoi: `auth.json`,
conversation/history/session files, SQLite databases, caches, lock files,
browser state, plugin/runtime directories, and any exported application state
that contains credentials or machine-local paths. Do not add the whole
`~/.codex` directory with `chezmoi add`; add only a reviewed portable file or
preference value.

To update the portable Codex preferences, edit the source files and review the
rendered result before applying:

```sh
vim "$HOME/.chezmoi/home/dot_codex/AGENTS.md"
vim "$HOME/.chezmoi/home/dot_codex/keybindings.json"
chezmoi --source "$HOME/.chezmoi" diff -- ~/.codex/AGENTS.md ~/.codex/keybindings.json
chezmoi --source "$HOME/.chezmoi" apply
```

If you intentionally edited one of the live files under `~/.codex/`, capture
only that reviewed file back into the source state instead of importing the
whole directory:

```sh
chezmoi --source "$HOME/.chezmoi" re-add ~/.codex/AGENTS.md
chezmoi --source "$HOME/.chezmoi" re-add ~/.codex/keybindings.json
git diff -- home/dot_codex
```

On a new Mac, `chezmoi apply` recreates `~/.codex/`, applies the portable
values to `config.toml`, and installs these two standalone preference files
after Codex has been installed. The existing machine-local configuration is
preserved rather than copied from this Mac.

The Codex desktop app may rewrite TOML table indentation or ordering after it
starts. If `chezmoi diff --exclude=scripts` shows only formatting around
machine-local marketplace tables, use `chezmoi verify --exclude=scripts` and
check the semantic values; do not use `chezmoi re-add` on the whole file.
Portable values are still controlled by `home/.chezmoidata/codex.toml`, while
the machine-local paths remain in the live target.

## Useful inspection commands

```sh
# Show the source path for a target.
chezmoi --source "$HOME/.chezmoi" source-path ~/.zshrc

# Show the rendered target content without changing anything.
chezmoi --source "$HOME/.chezmoi" cat ~/.zshrc

# Preview all differences.
chezmoi --source "$HOME/.chezmoi" diff

# Check whether the target state is already applied.
chezmoi --source "$HOME/.chezmoi" verify

# Show machine data used by templates.
chezmoi --source "$HOME/.chezmoi" data
```

Official references: [source-directory customization](https://www.chezmoi.io/user-guide/advanced/customize-your-source-directory/), [setup and config templates](https://www.chezmoi.io/user-guide/setup/), and [script behavior](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/).
