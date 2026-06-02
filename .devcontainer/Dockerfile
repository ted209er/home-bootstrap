FROM ubuntu:22.04

# Install core dev packages
RUN apt-get update && apt-get install -y \
    sudo \
    build-essential \
    git \
    curl \
    wget \
    zsh \
    shellcheck \
    neofetch \
    tmux \
    vim \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    unzip \
    fonts-firacode \
    && apt-get clean

# Create the default devcontainer user.
RUN useradd -ms /bin/zsh ted209er

# Set up passwordless sudo for the user
RUN echo "ted209er ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/ted209er \
    && chmod 0440 /etc/sudoers.d/ted209er

USER ted209er
WORKDIR /home/ted209er
