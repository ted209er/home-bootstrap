#!/usr/bin/env bash
# This script sets up the devcontainer environment for the project.
set -euo pipefail

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

info "Running devcontainer setup."
# Setup virtualenv or pip packages if needed
# python3 -m venv .venv
# source .venv/bin/activate
# pip install -r requirements.txt

if ! command -v gh >/dev/null 2>&1; then
    info "gh CLI not found, installing."
    sudo apt-get update
    sudo apt-get install -y curl gnupg lsb-release gpg

    keyring_path="/usr/share/keyrings/githubcli-archive-keyring.gpg"
    source_path="/etc/apt/sources.list.d/github-cli.list"
    source_line="deb [arch=$(dpkg --print-architecture) signed-by=${keyring_path}] https://cli.github.com/packages stable main"

    if [ ! -f "$keyring_path" ]; then
        info "Installing GitHub CLI apt keyring."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
            sudo dd of="$keyring_path"
        sudo chmod go+r "$keyring_path"
    else
        info "GitHub CLI apt keyring already exists: $keyring_path"
    fi

    if [ ! -f "$source_path" ] || [ "$(cat "$source_path")" != "$source_line" ]; then
        info "Installing GitHub CLI apt source: $source_path"
        printf '%s\n' "$source_line" | sudo tee "$source_path" > /dev/null
    else
        info "GitHub CLI apt source already current: $source_path"
    fi

    sudo apt-get update
    sudo apt-get install -y gh
fi

if ! gh auth status >/dev/null 2>&1; then
    warn "GitHub CLI is not authenticated."
    warn "To use gh inside the container, authenticate on the host before rebuild or run: gh auth login"
fi

info "Devcontainer setup complete."

if command -v neofetch >/dev/null 2>&1; then
    neofetch
fi
