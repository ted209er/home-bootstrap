#!/bin/bash

set -e

# Variables
REPO_URL="git@github.com:ted209er/dotfiles_bootstrap.git"
BOOTSTRAP_DIR="$HOME/Repos/dotfiles_bootstrap"
ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"

# Install core packages
echo "🔧 Installing required packages..."
sudo apt update
sudo apt install -y zsh git curl tmux vim neofetch unzip python3 python3-pip python3-venv

# Clone dotfiles repo if needed
if [ ! -d "$BOOTSTRAP_DIR" ]; then
  echo "📥 Cloning dotfiles repo..."
  git clone "$REPO_URL" "$BOOTSTRAP_DIR"
else
  echo "📂 Dotfiles repo already exists. Pulling latest changes..."
  cd "$BOOTSTRAP_DIR"
  git pull origin main
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

# === Install Docker if not installed ===
if ! command -v docker &> /dev/null; then
  echo "🔄 Docker not found. Installing Docker..."
  # Detect architecture
  ARCH=$(uname -m)
  echo "Detected architecture: $ARCH"

  # Use Docker's convenience script for installation
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  rm get-docker.sh
  echo "Docker installed successfully."

  # Add user to docker group
  sudo usermod -aG docker "$USER"
  echo "User $USER added to the docker group. You may need to log out and log back in for this to take effect."
  echo "To verify Docker installation, run: docker --version"
  echo "To start using Docker, run: sudo systemctl start docker"
  echo "To enable Docker to start on boot, run: sudo systemctl enable docker"

  # Enable and start Docker service
  sudo systemctl enable docker
  sudo systemctl start docker
  echo "Docker service started and enabled to run on boot."

  # Verify Docker installation
  if ! command -v docker &> /dev/null; then
    echo "❌ Docker installation failed. Please check the logs for errors."
    exit 1
  else
    echo "✅ Docker installed successfully."
  fi
else
  echo "Docker is already installed."
fi

ZSH_PATH="$(command -v zsh)"

# Set zsh as default shell
if [ "$SHELL" != "$ZSH_PATH" ]; then
  echo "💡 Setting Zsh as the default shell..."
  chsh -s "$ZSH_PATH"
fi

# Display system info
echo "🖥️ Running Neofetch:"
neofetch || echo "⚠️ Neofetch not found."

echo "✅ Dev Bootstrap complete. Please restart your terminal or run 'exec zsh' to start using Zsh."
echo "🚨 You may need to log out/in or reboot to activate Docker group permissions."
