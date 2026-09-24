# Ian's macOS dotfiles

This repository is managed by [chezmoi](https://www.chezmoi.io/). The desired
home-directory state lives under `home/`.

## Which files matter

The active setup is:

- `.chezmoiroot` — tells chezmoi to use `home/` as its source directory.
- `home/` — the only directory chezmoi applies to your home directory.
- `home/.chezmoidata/codex.toml` and `home/dot_codex/` — the reviewed portable
  Codex preferences merged into `~/.codex/`; machine-local Codex runtime state
  is intentionally excluded.
- `home/dot_claude/modify_settings.json` — pins Claude Code's Vim prompt mode
  and native `jk`/`kj` → Escape in `~/.claude/settings.json`; all other keys
  Claude Code writes there are left untouched.
- `home/dot_claude/CLAUDE.md` — Ian's global Claude Code preferences and
  IntelliJ workflow, loaded by every Claude Code session on every Mac.
- `Brewfile` — formulas and casks installed by the chezmoi hook.
- `README.md` and `APPLICATION-MIGRATION-CHECKLIST.md` — setup and migration
  instructions.
- `docs/CHEZMOI-WALKTHROUGH.md` — how the source layout, templates, and hooks
  work.
- `docs/MAC-MIGRATION-RUNBOOK.md` — the ordered new-Mac and maintenance
  procedure.
- `docs/MAC-SYSTEM-SETTINGS-MIGRATION.md` — the audited native macOS settings,
  the BTT-versus-native ownership split, and the read-only audit script.
- `docs/migration-reference/` — reviewed exports that ChatGPT or another AI
  tool may read as migration source material. These files are tracked in the
  repository but are outside `home/`, so chezmoi never applies them directly.

The migration is now chezmoi-only. The former Dotbot files and submodule have
been removed from the repository. Keep `~/.dotbot-symlink-backup-20260922`
locally only if you still want a short-term rollback copy.

## New Mac setup

For the complete ordered procedure, use
[`docs/MAC-MIGRATION-RUNBOOK.md`](docs/MAC-MIGRATION-RUNBOOK.md).

Install and apply everything with:

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply \
  --source "$HOME/.chezmoi" \
  https://github.com/stutterrrrer/chezmoi.git
```

The command installs chezmoi, clones this repository into `~/.chezmoi`,
installs Homebrew if necessary, installs the packages in `Brewfile`, installs
Oh My Zsh, and applies the managed files. If the repository has been cloned
already, run:

```sh
chezmoi --source "$HOME/.chezmoi" init --apply
```

The repository and local checkout are named `chezmoi` to match the active
migration tool.

## Everyday commands

```sh
chezmoi --source "$HOME/.chezmoi" diff
chezmoi --source "$HOME/.chezmoi" apply
chezmoi --source "$HOME/.chezmoi" update
chezmoi --source "$HOME/.chezmoi" doctor
```

Edit managed files in `home/` or use `chezmoi edit`. Run `chezmoi diff` before
applying changes to a machine.

## Machine-specific settings

The local chezmoi config is not committed. To enable the local proxy on a
machine, add this to `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
enable_proxy = true
```

Conda is initialized only when a standard Anaconda or Miniconda installation
is found. Homebrew is detected in both `/opt/homebrew` and `/usr/local`.

## Secrets

Do not commit credentials, SSH private keys, tokens, or application secrets.
Use chezmoi encryption with `age` or a password manager before adding those
files. The current repository does not contain encrypted secrets.
