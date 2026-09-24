# New Mac migration runbook

Use this document for a fresh Mac or a later replacement Mac. Run the commands
in order and stop to review any `chezmoi diff` output before accepting changes.

## Before the old Mac is retired

1. Finish and test changes in `home/`.
2. Check the repository status and commit/push the migration changes:

   ```sh
   cd "$HOME/.chezmoi"
   git status
   git diff --check
   # Stage tracked edits/deletions, then explicitly stage migration files.
   # This avoids accidentally committing local IDE metadata or app exports.
   git add -u
   git add .chezmoiroot Brewfile README.md \
     APPLICATION-MIGRATION-CHECKLIST.md docs home scripts
   git commit -m "complete chezmoi migration"
   git push
   ```

3. Confirm the repository is reachable from the new Mac at
   `https://github.com/stutterrrrer/chezmoi.git`.
4. Keep `~/.dotbot-symlink-backup-20260922` until the new machine has passed
   the final checks.

## First boot on the new Mac

Open Terminal and install the Apple command-line tools if macOS requests them:

```sh
xcode-select --install
```

Install, clone, and apply chezmoi in one command:

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply --verbose \
  --source "$HOME/.chezmoi" \
  https://github.com/stutterrrrer/chezmoi.git
```

When prompted, answer the local HTTP proxy question according to the network
you are using. If the repository is already cloned, use:

```sh
chezmoi --source "$HOME/.chezmoi" init --apply --verbose
```

If you want to inspect before applying, split the operation into:

```sh
chezmoi --source "$HOME/.chezmoi" diff
chezmoi --source "$HOME/.chezmoi" apply --verbose
```

## If Homebrew does not finish

The `Brewfile` contains tools such as Python and MacVim. Intel Homebrew may
need to build dependencies from source, and individual casks can fail because
of a vendor download. A failed package hook does not mean the dotfiles should
be restored from the old symlinks.

On the source Intel Mac, the 2026-09-23 attempt installed many dependencies
but did not complete the Brewfile. The remaining failures were MacVim,
ShellCheck, tmux, git-lfs, the Powerlevel10k tap formula, cask registration
for existing applications, and Moom's vendor download. Homebrew also reported
that the installed Command Line Tools are older than the current release and
that Intel macOS is now a Tier 3 configuration. The new Apple-Silicon Mac is
expected to avoid much of the source-build pressure, but still follow the
checks below if a package hook fails.

First check the compiler toolchain in an interactive Terminal:

```sh
xcode-select --print-path
clang++ --version
brew doctor
```

If macOS offers a Command Line Tools update, install it from Software Update
or run `xcode-select --install`, then retry the formula step. Do not delete
`/Library/Developer/CommandLineTools` as a first-line migration action.

First retry the package step directly:

```sh
brew bundle install --no-upgrade --file="$HOME/.chezmoi/Brewfile"
```

The cask adoption step needs an interactive Terminal because Homebrew may ask
for the administrator password to adjust ownership or permissions on an
existing `/Applications` app. Run this outside a non-interactive agent hook if
the app is already present:

```sh
brew install --cask --adopt dropzone bettertouchtool keycastr
```

Trust only the explicitly selected Powerlevel10k formula if Homebrew's tap
trust policy blocks it:

```sh
brew trust --formula romkatv/powerlevel10k/powerlevel10k
```

Then reapply the files after the package step succeeds:

```sh
chezmoi --source "$HOME/.chezmoi" apply --verbose
```

Install an individual cask separately when necessary:

```sh
brew install --cask bettertouchtool
brew install --cask moom
```

If a cask download fails, record it in the application checklist and retry
when the vendor site is reachable. Do not run `brew bundle cleanup` during
migration; cleanup can remove software that is not yet represented in the
Brewfile.

For the current Moom download failure, retry from an interactive Terminal when
the vendor site is reachable:

```sh
brew fetch --cask moom --retry
brew install --cask moom
```

The existing `/Applications/Moom Classic.app`, BetterTouchTool, Dropzone, and
KeyCastr application bundles are not proof that Homebrew has registered the
casks. Confirm registration with `brew list --cask` and confirm the application
itself launches before checking off the Brewfile item.

## Verify the new machine

Run the following checks:

```sh
chezmoi --source "$HOME/.chezmoi" verify
chezmoi --source "$HOME/.chezmoi" doctor
brew bundle check --file="$HOME/.chezmoi/Brewfile" --verbose
zsh -n "$HOME/.zshrc"
test -x "$HOME/.local/bin/idea"
```

Then complete [APPLICATION-MIGRATION-CHECKLIST.md](../APPLICATION-MIGRATION-CHECKLIST.md), including app sign-in, terminal profile import, IntelliJ setup, and Accessibility permissions for BetterTouchTool and Moom. For the native keyboard, input, Dock, hot-corner, accessibility, and display settings that are intentionally outside chezmoi, use [the system-settings inventory](MAC-SYSTEM-SETTINGS-MIGRATION.md).

## Future maintenance

### Change a managed file

Edit the corresponding file in `home/`, not the generated file in `$HOME`:

```sh
vim home/dot_zshrc
chezmoi --source "$HOME/.chezmoi" diff
chezmoi --source "$HOME/.chezmoi" apply
```

If you edit a generated file directly, capture it back into the source state
with `chezmoi re-add` only after reviewing the result. Prefer editing `home/`
so the intended state is obvious in Git.

### Add or remove a package

Edit `Brewfile`, use a descriptive comment, and let the checksum-triggered hook
install the change:

```sh
vim Brewfile
brew bundle check --file="$HOME/.chezmoi/Brewfile" --verbose
chezmoi --source "$HOME/.chezmoi" apply
```

`Brewfile` is an explicit, version-controlled package manifest. Homebrew does
not add packages to it automatically when you run `brew install` or
`brew install --cask`; installing WhichSpace separately therefore requires an
entry to make it part of future migrations. `brew bundle dump` can create an
installed-state snapshot, but it may include packages that are not intentional
and can overwrite the curated migration manifest, so use it only as a reviewed
source of additions rather than as an automatic recorder.

Do not use `brew bundle cleanup` unless you intentionally want to uninstall
every dependency missing from the Brewfile.

### Change a setup hook

The active hooks are in `home/` and are rendered/executed by chezmoi; they do
not create files in `$HOME` themselves. Keep hooks idempotent, use descriptive
variable names, quote paths, fail clearly with `set -euo pipefail`, and explain
why each external command is needed. Test the rendered script before applying
when changing a template.

Chezmoi normally remembers successful `run_once_` and `run_onchange_` hooks.
If you deliberately need to rerun one after correcting an external condition,
inspect the change first and clear only the relevant state bucket:

```sh
# Allows run_onchange_ hooks to run again.
chezmoi --source "$HOME/.chezmoi" state delete-bucket --bucket=entryState

# Allows run_once_ hooks to run again. Use this cautiously.
chezmoi --source "$HOME/.chezmoi" state delete-bucket --bucket=scriptState
```

Usually it is safer to rerun the specific underlying command directly—for
example, `brew bundle install --no-upgrade ...`—than to clear all once-script
state.

### Publish a migration update

```sh
   cd "$HOME/.chezmoi"
git diff --check
chezmoi --source "$HOME/.chezmoi" diff
git status
git add home Brewfile README.md docs scripts APPLICATION-MIGRATION-CHECKLIST.md
git commit -m "update macOS dotfiles"
git push
```

On another Mac, `chezmoi update` pulls and applies the source repository. Review
the diff before using `chezmoi apply` if the change is important or contains a
template update.

## Final cleanup after the migration

The legacy Dotbot directory and its submodule declaration have been removed.
Do not remove the local `~/.dotbot-symlink-backup-20260922` rollback copy until
you have confirmed that the new regular files, shell behavior, applications,
and credentials all work.
