#!/usr/bin/env bash
# ==============================================================================
# Phase 9: Git Configuration, SSH Key & GitHub CLI ('gh')
# ==============================================================================
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.env"
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

GIT_USER_NAME="${GIT_USER_NAME:-your_username}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-your_email@example.com}"

echo -e "${BLUE}[9/10] Starting Git, SSH & GitHub CLI Setup...${NC}"

# Detect existing git identity or prompt if default placeholder is detected
if [ "$GIT_USER_NAME" = "your_username" ] || [ -z "$GIT_USER_NAME" ]; then
    EXISTING_NAME=$(git config --global user.name 2>/dev/null || true)
    if [ -n "$EXISTING_NAME" ]; then
        GIT_USER_NAME="$EXISTING_NAME"
    elif [ -t 0 ]; then
        read -r -p "Enter your Git user name: " input_name
        GIT_USER_NAME="${input_name:-$GIT_USER_NAME}"
    fi
fi

if [ "$GIT_USER_EMAIL" = "your_email@example.com" ] || [ -z "$GIT_USER_EMAIL" ]; then
    EXISTING_EMAIL=$(git config --global user.email 2>/dev/null || true)
    if [ -n "$EXISTING_EMAIL" ]; then
        GIT_USER_EMAIL="$EXISTING_EMAIL"
    elif [ -t 0 ]; then
        read -r -p "Enter your Git email: " input_email
        GIT_USER_EMAIL="${input_email:-$GIT_USER_EMAIL}"
    fi
fi

# Configure Git Identity
echo -e "${BLUE}--> Configuring Git user identity...${NC}"
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global init.defaultBranch main

echo "  Git User:  $(git config --global user.name)"
echo "  Git Email: $(git config --global user.email)"

# Generate SSH Key (ed25519) if not present
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
    echo -e "${BLUE}--> Generating new ED25519 SSH key for raspberrypi...${NC}"
    ssh-keygen -t ed25519 -C "raspberrypi" -f "$SSH_KEY" -N ""
    echo -e "${GREEN}✔ SSH key generated at $SSH_KEY${NC}"
    echo -e "${YELLOW}Public key:${NC}"
    cat "${SSH_KEY}.pub"
else
    echo -e "${YELLOW}--> SSH key already exists at $SSH_KEY.${NC}"
fi

# Install GitHub CLI (gh)
if ! command -v gh &> /dev/null; then
    echo -e "${BLUE}--> Installing GitHub CLI (gh)...${NC}"
    sudo apt update -y
    sudo apt install -y gh
fi

echo -e "${GREEN}✔ GitHub CLI installed: $(gh --version | head -n 1)${NC}"
echo -e "${YELLOW}Tip: To log into your GitHub account, run: 'gh auth login'${NC}"
