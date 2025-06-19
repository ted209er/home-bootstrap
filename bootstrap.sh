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
if [ ! -d "$DOTFILES" ]; then
  echo "Cloning dotfiles into bare repository..."
  git clone --bare "$REPO" "$DOTFILES"
fi

# Define alias for working with the bare repo
alias dotfiles="git --git-dir=$DOTFILES --work-tree=$HOME"

# Prevent untracked files from showing
mkdir -p .config-backup

echo "Checking out dotfiles..."
dotfiles checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | while read -r file; do
  mkdir -p "$(dirname ".config-backup/$file")"
  mv "$HOME/$file" ".config-backup/$file"
done

dotfiles checkout

dotfiles config --local status.showUntrackedFiles no

echo "✅ Dotfiles installed! Backup of previous files in ~/.config-backup"

# Optional: install packages or tools here
# sudo apt update && sudo apt install -y vim curl git tmux

# Optional: run host-specific setup
# [[ "$HOSTNAME" == "rpi-monitor" ]] && ./scripts/rpi-setup.sh
