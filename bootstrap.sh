#!/usr/bin/env bash

# bootstrap.sh - Install or update dotfiles from GitHub and symlink them
# Usage: curl -s https://raw.githubusercontent.com/ted209er/home-bootstrap/main/bootstrap.sh | bash

set -e

REPO="https://github.com/ted209er/home-bootstrap.git"
DOTFILES="$HOME/.dotfiles"

# Check if Git is installed
if ! command -v git &> /dev/null; then
  echo "Git is not installed. Please install Git first."
  exit 1
fi

# Clone the repo as a bare repo
# A bare repo has no working directory (no actual files checked out),
# Only contains the .git dir (version control metadate)
# Used as a remote repo for dotfile management
if [ ! -d "$DOTFILES" ]; then
  echo "Cloning dotfiles into bare repository..."
  git clone --bare "$REPO" "$DOTFILES"
fi

# Define alias for working with the bare repo
# Had to take this out as alias is getting set and called only within the scope of this script, so the alias hasn't been loaded and cannot be called.
#alias dotfiles="git --git-dir=$DOTFILES --work-tree=$HOME"

# Updating to create a variable to hold the git command

GIT_CMD="git --git-dir=$DOTFILES --work-tree=$HOME"
# Tells git that the working tree is actually $HOME, not where the repo lives ($HOME/.dotfiles)
# This way I don't have a ~/.bashrc and a ~/dotfiles/.bashrc in the repo. the ~/.dotfiles version
# controls the files in ~./bashrc.

# Prevent untracked files from showing
mkdir -p .config-backup

echo "Checking out dotfiles..."
GIT_CMD checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | while read -r file; do
  mkdir -p "$(dirname ".config-backup/$file")"
  mv "$HOME/$file" ".config-backup/$file"
done

GIT_CMD checkout

GIT_CMD config --local status.showUntrackedFiles no

echo "✅ Dotfiles installed! Backup of previous files in ~/.config-backup"

# Optional: install packages or tools here
# sudo apt update && sudo apt install -y vim curl git tmux

# Optional: run host-specific setup
# [[ "$HOSTNAME" == "rpi-monitor" ]] && ./scripts/rpi-setup.sh
