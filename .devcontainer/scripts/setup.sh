#!/usr/bin/env bash
# This script sets up the devcontainer environment for the project.
set -e

echo "Running devcontainer setup..."
# Setup virtualenv or pip packages if needed
# python3 -m venv .venv
# source .venv/bin/activate
# pip install -r requirements.txt

if ! command -v gh &> /dev/null; then
    echo "gh CLI not found, installing..."
    sudo apt-get update
    sudo apt-get install -y curl gnupg lsb-release gpg

    if [ -f /etc/apt/sources.list.d/github-cli.list ]; then
        echo "Removing existing github-cli.list"
        sudo rm /etc/apt/sources.list.d/github-cli.list
    fi

    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
        sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
        sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y gh
fi

if ! gh auth status &> /dev/null; then
    echo "GitHub CLI is not authenticated."
    echo "To use gh inside the container, authenticate on the host before rebuild or run: gh auth login"
fi

echo "Devcontainer setup complete."

if command -v neofetch &> /dev/null; then
    neofetch
fi
