#!/bin/bash


set -e

# Variables
REPO_URL="git@github.com:ted209er/dotfiles_bootstrap.git"
DOTFILES="$HOME/.dotfiles"
BOOTSTRAP_DIR="$HOME/Repos/dotfiles_bootstrap"
ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"

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

# Installing oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing oh-my-zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install plugins if they don't already exist
[ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"

[ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"

# Install powerlevel10k theme
[ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}/themes/powerlevel10k"


# Set zsh as default shell
if ["$SHELL" != "$(which zsh)" ]; then
  echo "💡 Setting Zsh as the default shell..."
  chsh -s "$(which zsh)"
fi

# Display system info
echo "🖥️ Running Neofetch:"
neofetch || echo "⚠️ Neofetch not found."

echo "✅ Bootstrap complete. Please restart your terminal or run 'exec zsh' to start using Zsh."


