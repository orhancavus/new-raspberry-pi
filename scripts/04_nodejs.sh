#!/usr/bin/env bash
# ==============================================================================
# Phase 4: Node.js & NVM (Node Version Manager)
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

NODE_VERSION="${NODE_VERSION:-20}"

echo -e "${BLUE}[4/10] Starting Node.js & NVM Setup (Target Node v${NODE_VERSION})...${NC}"

export NVM_DIR="$HOME/.nvm"

# Install NVM if not installed
if [ ! -d "$NVM_DIR" ]; then
    echo -e "${BLUE}--> Installing NVM (v0.40.1)...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
else
    echo -e "${YELLOW}--> NVM already exists at $NVM_DIR.${NC}"
fi

# Load NVM for this shell session
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Ensure NVM initialization is in ~/.zshrc
ZSHRC="$HOME/.zshrc"
if [ -f "$ZSHRC" ] && ! grep -q 'NVM_DIR' "$ZSHRC"; then
    echo -e "${BLUE}--> Adding NVM loader to ~/.zshrc...${NC}"
    cat << 'EOF' >> "$ZSHRC"

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
fi

echo -e "${BLUE}--> Installing Node.js version ${NODE_VERSION}...${NC}"
nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"
nvm use default

NODE_VER=$(node -v)
NPM_VER=$(npm -v)
echo -e "${GREEN}✔ Node.js installed successfully: ${NODE_VER} (npm: ${NPM_VER})${NC}"
