#!/usr/bin/env bash
# This script sets up the devcontainer environment for the project.
set -e

echo "Running devcontainer setup..."
# Setup virtualenv or pip packages if needed
# python3 -m venv .venv
# source .venv/bin/activate
# pip install -r requirements.txt

if ! command -v gh >/dev/null 2>&1; then
    echo "gh CLI not found, installing..."
    sudo apt-get update
    sudo apt-get install -y curl gnupg lsb-release gpg

    keyring_path="/usr/share/keyrings/githubcli-archive-keyring.gpg"
    source_path="/etc/apt/sources.list.d/github-cli.list"
    source_line="deb [arch=$(dpkg --print-architecture) signed-by=${keyring_path}] https://cli.github.com/packages stable main"

    if [ ! -f "$keyring_path" ]; then
        echo "Installing GitHub CLI apt keyring..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
            sudo dd of="$keyring_path"
        sudo chmod go+r "$keyring_path"
    else
        echo "GitHub CLI apt keyring already exists: $keyring_path"
    fi

    if [ ! -f "$source_path" ] || [ "$(cat "$source_path")" != "$source_line" ]; then
        echo "Installing GitHub CLI apt source: $source_path"
        printf '%s\n' "$source_line" | sudo tee "$source_path" > /dev/null
    else
        echo "GitHub CLI apt source already current: $source_path"
    fi

    sudo apt-get update
    sudo apt-get install -y gh
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "GitHub CLI is not authenticated."
    echo "To use gh inside the container, authenticate on the host before rebuild or run: gh auth login"
fi

echo "Devcontainer setup complete."

if command -v neofetch >/dev/null 2>&1; then
    neofetch
fi
