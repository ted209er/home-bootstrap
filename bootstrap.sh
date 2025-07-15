#!/bin/bash


set -e

# Variables
REPO_URL="git@github.com:ted209er/dotfiles_bootstrap.git"
DOTFILES="$HOME/.dotfiles"
BOOTSTRAP_DIR="$HOME/Repos/dotfiles_bootstrap"

# Install core packages
echo "🔧 Installing required packages..."
sudo apt update
sudo apt install -y zsh git curl tmux vim neofetch

# Clone dotfiles repo if needed
if [ ! -d "$BOOTSTRAP_DIR" ]; then
  echo "📥 Cloning dotfiles repo..."
  git clone "$REPO_URL" "$BOOTSTRAP_DIR"
fi

# Symlink dotfiles
echo "🔗 Setting up dotfile symlinks..."
ln -sf "$BOOTSTRAP_DIR/.zshrc" "$HOME/.zshrc"
ln -sf "$BOOTSTRAP_DIR/.p10k.zsh" "$HOME/.p10k.zsh"

# Set zsh as default shell
if ["$SHELL" != "$(which zsh)" ]; then
  echo "💡 Setting Zsh as the default shell..."
  chsh -s "$(which zsh)"
fi

# Display system info
echo "🖥️ Running Neofetch:"
neofetch || echo "⚠️ Neofetch not found."

echo "✅ Bootstrap complete. Please restart your terminal or run 'exec zsh' to start using Zsh."


