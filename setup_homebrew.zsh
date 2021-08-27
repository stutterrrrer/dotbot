#!/usr/bin/env zsh

echo "\n<<< Starting ian's Homebrew Setup >>>\n"

# install homebrew if it's not installed yet.
# https://yadm.io/docs/bootstrap#
echo "installing Homebrew ( unless it's already installed )"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# install from the hopefully up-to-date Brewfile (generated from brew bundle dump) a list of all historical installations from homebrew.
brew bundle --verbose
