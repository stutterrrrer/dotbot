#!/bin/bash
set -euo pipefail

# Oh My Zsh is installed once because its directory is managed by Oh My Zsh,
# not by chezmoi. Existing installations must be left untouched.
oh_my_zsh_installation_directory="$HOME/.oh-my-zsh"
oh_my_zsh_repository_url="https://github.com/ohmyzsh/ohmyzsh.git"

if [[ -d "$oh_my_zsh_installation_directory" ]]; then
  exit 0
fi

echo "Installing Oh My Zsh."
git clone --depth=1 \
  "$oh_my_zsh_repository_url" \
  "$oh_my_zsh_installation_directory"
