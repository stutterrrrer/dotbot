# Ian's macOS dotfiles

This repository is managed by [chezmoi](https://www.chezmoi.io/). The desired
home-directory state lives under `home/`. The old Dotbot setup is isolated in
`legacy-dotbot/` so it can be removed cleanly after migration.

## Which files matter

The active setup is:

- `.chezmoiroot` — tells chezmoi to use `home/` as its source directory.
- `home/` — the only directory chezmoi applies to your home directory.
- `home/.chezmoidata/codex.toml` and `home/dot_codex/` — the reviewed portable
  Codex preferences merged into `~/.codex/`; machine-local Codex runtime state
  is intentionally excluded.
- `Brewfile` — formulas and casks installed by the chezmoi hook.
- `README.md` and `APPLICATION-MIGRATION-CHECKLIST.md` — setup and migration
  instructions.
- `docs/CHEZMOI-WALKTHROUGH.md` — how the source layout, templates, and hooks
  work.
- `docs/MAC-MIGRATION-RUNBOOK.md` — the ordered new-Mac and maintenance
  procedure.
- `docs/MAC-SYSTEM-SETTINGS-MIGRATION.md` — the audited native macOS settings,
  the BTT-versus-native ownership split, and the read-only audit script.

The disposable rollback setup is all under `legacy-dotbot/`. It contains the
old Dotbot submodule, installer/configuration, flat dotfiles, plist exports,
and IntelliJ scratch-file links. Do not use it for the new Mac. After the new
machine has been tested successfully, remove `legacy-dotbot/` and the root
`.gitmodules` file together. Keep `~/.dotbot-symlink-backup-20260922` until
you are certain rollback is no longer needed.

## New Mac setup

For the complete ordered procedure, use
[`docs/MAC-MIGRATION-RUNBOOK.md`](docs/MAC-MIGRATION-RUNBOOK.md).

Install and apply everything with:

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply \
  --source "$HOME/.dotfiles" \
  https://github.com/stutterrrrer/dotbot.git
```

The command installs chezmoi, clones this repository into `~/.dotfiles`,
installs Homebrew if necessary, installs the packages in `Brewfile`, installs
Oh My Zsh, and applies the managed files. If the repository has been cloned
already, run:

```sh
chezmoi --source "$HOME/.dotfiles" init --apply
```

The repository name still says `dotbot` on GitHub; it can be renamed there
later without changing the local layout.

## Everyday commands

```sh
chezmoi --source "$HOME/.dotfiles" diff
chezmoi --source "$HOME/.dotfiles" apply
chezmoi --source "$HOME/.dotfiles" update
chezmoi --source "$HOME/.dotfiles" doctor
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
