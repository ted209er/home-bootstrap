#!/bin/bash

set -e

# Variables
REPO_URL="git@github.com:ted209er/dotfiles_bootstrap.git"
BOOTSTRAP_DIR="$HOME/Repos/dotfiles_bootstrap"
ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"
DRY_RUN=false
PACKAGES=(zsh git curl tmux vim neofetch)

usage() {
  cat <<EOF
Usage: $0 [--dry-run] [--help]

Bootstrap a baseline workstation with core packages, dotfiles, oh-my-zsh,
zsh plugins, powerlevel10k, and zsh as the login shell.

Options:
  --dry-run  Print privileged, networked, and file-mutating actions without
             running them.
  --help     Show this help message.
EOF
}

run_cmd() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'

  if [ "$DRY_RUN" = false ]; then
    "$@"
  fi
}

ensure_symlink() {
  local source=$1
  local target=$2
  local current_target

  if [ -L "$target" ]; then
    current_target="$(readlink "$target")"
    if [ "$current_target" = "$source" ]; then
      echo "Symlink already correct: $target -> $source"
      return
    fi

    echo "Will replace symlink: $target currently points to $current_target"
  elif [ -e "$target" ]; then
    echo "Will replace existing path with symlink: $target"
  else
    echo "Will create symlink: $target -> $source"
  fi

  run_cmd ln -sfn "$source" "$target"
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        printf 'Error: unknown option: %s\n\n' "$1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
}

install_oh_my_zsh() {
  echo "Installing oh-my-zsh from https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
  if [ "$DRY_RUN" = true ]; then
    echo "+ RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
  else
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
}

parse_args "$@"

# Install core packages
echo "Will install core packages: ${PACKAGES[*]}"
run_cmd sudo apt update
run_cmd sudo apt install -y "${PACKAGES[@]}"

# Clone dotfiles repo if needed
if [ ! -d "$BOOTSTRAP_DIR" ]; then
  echo "Will clone dotfiles repo: $REPO_URL -> $BOOTSTRAP_DIR"
  run_cmd git clone "$REPO_URL" "$BOOTSTRAP_DIR"
else
  echo "Dotfiles repo already exists: $BOOTSTRAP_DIR"
fi

# Symlink dotfiles
echo "Checking dotfile symlinks..."
ensure_symlink "$BOOTSTRAP_DIR/.zshrc" "$HOME/.zshrc"
ensure_symlink "$BOOTSTRAP_DIR/.p10k.zsh" "$HOME/.p10k.zsh"

# Installing oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  install_oh_my_zsh
else
  echo "oh-my-zsh already exists: $HOME/.oh-my-zsh"
fi

# Install plugins if they don't already exist
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
  echo "Will clone zsh-autosuggestions plugin."
  run_cmd git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
else
  echo "zsh-autosuggestions already exists."
fi

if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
  echo "Will clone zsh-syntax-highlighting plugin."
  run_cmd git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
else
  echo "zsh-syntax-highlighting already exists."
fi

# Install powerlevel10k theme
if [ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]; then
  echo "Will clone powerlevel10k theme."
  run_cmd git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}/themes/powerlevel10k"
else
  echo "powerlevel10k already exists."
fi


ZSH_PATH="$(command -v zsh || true)"

# Set zsh as default shell
if [ -n "$ZSH_PATH" ] && [ "$SHELL" != "$ZSH_PATH" ]; then
  echo "💡 Setting Zsh as the default shell..."
  run_cmd chsh -s "$ZSH_PATH"
elif [ -z "$ZSH_PATH" ]; then
  echo "zsh is not currently on PATH; package installation should provide it."
else
  echo "zsh is already the current shell."
fi

# Display system info
echo "🖥️ Running Neofetch:"
if [ "$DRY_RUN" = true ]; then
  echo "+ neofetch"
else
  neofetch || echo "⚠️ Neofetch not found."
fi

if [ "$DRY_RUN" = true ]; then
  echo "✅ Dry run complete. No changes were made."
else
  echo "✅ Bootstrap complete. Please restart your terminal or run 'exec zsh' to start using Zsh."
fi
