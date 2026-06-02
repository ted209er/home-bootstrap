#!/bin/bash

set -euo pipefail

# Variables
REPO_URL="git@github.com:ted209er/dotfiles_bootstrap.git"
BOOTSTRAP_DIR="$HOME/Repos/dotfiles_bootstrap"
ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"
DRY_RUN=false
PACKAGES=(zsh git curl tmux vim neofetch unzip python3 python3-pip python3-venv)

info() {
  printf 'INFO: %s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: $0 [--dry-run] [--help]

Bootstrap a development workstation with core packages, dotfiles, oh-my-zsh,
zsh plugins, powerlevel10k, Python tooling, Docker, and zsh as the login shell.

Options:
  --dry-run  Print privileged, networked, service, and file-mutating actions
             without running them.
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
      info "Symlink already correct: $target -> $source"
      return
    fi

    info "Will replace symlink: $target currently points to $current_target"
  elif [ -e "$target" ]; then
    info "Will replace existing path with symlink: $target"
  else
    info "Will create symlink: $target -> $source"
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
        printf '\n' >&2
        usage >&2
        die "Unknown option: $1"
        ;;
    esac
    shift
  done
}

install_oh_my_zsh() {
  info "Installing oh-my-zsh from https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
  if [ "$DRY_RUN" = true ]; then
    info "+ RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
  else
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
}

parse_args "$@"

# Install core packages
info "Will install core packages: ${PACKAGES[*]}"
run_cmd sudo apt update
run_cmd sudo apt install -y "${PACKAGES[@]}"

# Clone dotfiles repo if needed
if [ ! -d "$BOOTSTRAP_DIR" ]; then
  info "Will clone dotfiles repo: $REPO_URL -> $BOOTSTRAP_DIR"
  run_cmd git clone "$REPO_URL" "$BOOTSTRAP_DIR"
else
  info "Dotfiles repo already exists. Will pull latest changes from origin main."
  run_cmd git -C "$BOOTSTRAP_DIR" pull origin main
fi

# Symlink dotfiles
info "Checking dotfile symlinks..."
ensure_symlink "$BOOTSTRAP_DIR/.zshrc" "$HOME/.zshrc"
ensure_symlink "$BOOTSTRAP_DIR/.p10k.zsh" "$HOME/.p10k.zsh"

# Installing oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  install_oh_my_zsh
else
  info "oh-my-zsh already exists: $HOME/.oh-my-zsh"
fi

# Install plugins if they don't already exist
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
  info "Will clone zsh-autosuggestions plugin."
  run_cmd git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
else
  info "zsh-autosuggestions already exists."
fi

if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
  info "Will clone zsh-syntax-highlighting plugin."
  run_cmd git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
else
  info "zsh-syntax-highlighting already exists."
fi

# Install powerlevel10k theme
if [ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]; then
  info "Will clone powerlevel10k theme."
  run_cmd git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}/themes/powerlevel10k"
else
  info "powerlevel10k already exists."
fi

# === Install Docker if not installed ===
if ! command -v docker >/dev/null 2>&1; then
  info "Docker not found. Installing Docker."
  # Detect architecture
  ARCH=$(uname -m)
  info "Detected architecture: $ARCH"

  # Use Docker's convenience script for installation
  info "Will download Docker install script from https://get.docker.com"
  if [ "$DRY_RUN" = true ]; then
    info "+ docker_script=\$(mktemp)"
    info "+ curl -fsSL https://get.docker.com -o \"\$docker_script\""
  else
    docker_script="$(mktemp)"
    trap 'rm -f "$docker_script"' EXIT
    run_cmd curl -fsSL https://get.docker.com -o "$docker_script"
  fi
  info "Will run Docker install script with sudo."
  if [ "$DRY_RUN" = true ]; then
    info "+ sudo sh \"\$docker_script\""
    info "+ rm -f \"\$docker_script\""
  else
    run_cmd sudo sh "$docker_script"
    run_cmd rm -f "$docker_script"
    trap - EXIT
  fi
  if [ "$DRY_RUN" = false ]; then
    info "Docker installed successfully."
  fi

  # Add user to docker group
  current_user="${USER:-$(id -un)}"
  info "Will add user to docker group: $current_user"
  run_cmd sudo usermod -aG docker "$current_user"
  if [ "$DRY_RUN" = false ]; then
    info "User $current_user added to the docker group. You may need to log out and log back in for this to take effect."
  fi
  info "To verify Docker installation, run: docker --version"
  info "To start using Docker, run: sudo systemctl start docker"
  info "To enable Docker to start on boot, run: sudo systemctl enable docker"

  # Enable and start Docker service
  info "Will enable and start Docker service."
  run_cmd sudo systemctl enable docker
  run_cmd sudo systemctl start docker
  if [ "$DRY_RUN" = false ]; then
    info "Docker service started and enabled to run on boot."
  fi

  # Verify Docker installation
  if [ "$DRY_RUN" = false ] && ! command -v docker >/dev/null 2>&1; then
    die "Docker installation failed. Please check the logs for errors."
  elif [ "$DRY_RUN" = false ]; then
    info "Docker installed successfully."
  fi
else
  info "Docker is already installed."
fi

ZSH_PATH="$(command -v zsh || true)"
CURRENT_SHELL="${SHELL:-}"

# Set zsh as default shell
if [ -n "$ZSH_PATH" ] && [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
  info "Setting zsh as the default shell."
  run_cmd chsh -s "$ZSH_PATH"
elif [ -z "$ZSH_PATH" ]; then
  warn "zsh is not currently on PATH; package installation should provide it."
else
  info "zsh is already the current shell."
fi

# Display system info
info "Running neofetch."
if [ "$DRY_RUN" = true ]; then
  info "+ neofetch"
else
  neofetch || warn "neofetch not found."
fi

if [ "$DRY_RUN" = true ]; then
  info "Dry run complete. No changes were made."
else
  info "Dev bootstrap complete. Please restart your terminal or run 'exec zsh' to start using zsh."
  warn "You may need to log out/in or reboot to activate Docker group permissions."
fi
