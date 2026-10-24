#!/usr/bin/env bash
# ==============================================================================
# Phase 2: Zsh, Oh-My-Zsh & Productivity Plugins
# ==============================================================================
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[2/10] Starting Zsh & Shell Environment Configuration...${NC}"

# Ensure zsh is installed
if ! command -v zsh &> /dev/null; then
    echo -e "${BLUE}--> Installing zsh...${NC}"
    sudo apt install -y zsh
fi

# Install Oh-My-Zsh if not already present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${BLUE}--> Installing Oh-My-Zsh (unattended)...${NC}"
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins"

# 1. zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo -e "${BLUE}--> Cloning zsh-autosuggestions plugin...${NC}"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    echo -e "${YELLOW}--> zsh-autosuggestions already exists, updating...${NC}"
    git -C "$ZSH_CUSTOM/plugins/zsh-autosuggestions" pull || true
fi

# 2. zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo -e "${BLUE}--> Cloning zsh-syntax-highlighting plugin...${NC}"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
    echo -e "${YELLOW}--> zsh-syntax-highlighting already exists, updating...${NC}"
    git -C "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" pull || true
fi

# Configure ~/.zshrc if it exists
ZSHRC="$HOME/.zshrc"
if [ ! -f "$ZSHRC" ]; then
    touch "$ZSHRC"
fi

# Add PATH export if not present
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$ZSHRC"; then
    echo -e "${BLUE}--> Adding ~/.local/bin to PATH in ~/.zshrc...${NC}"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
fi

# Ensure plugins are enabled in .zshrc
if grep -q "^plugins=" "$ZSHRC"; then
    # If plugins= is present, ensure our plugins are included if not already
    if ! grep -q "zsh-autosuggestions" "$ZSHRC"; then
        sed -i 's/^plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
    fi
else
    echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' >> "$ZSHRC"
fi

# Add eza aliases if not present
if ! grep -q "alias ls='eza'" "$ZSHRC"; then
    echo -e "${BLUE}--> Adding modern aliases (eza) to ~/.zshrc...${NC}"
    cat << 'EOF' >> "$ZSHRC"

# Modern CLI aliases
if command -v eza >/dev/null 2>&1; then
    alias ls='eza'
    alias ll='eza -la --icons --git'
    alias la='eza -a --icons'
    alias lt='eza --tree --level=2'
fi
EOF
fi

# Add tmux helper alias
if ! grep -q "my-dev" "$ZSHRC"; then
    echo "alias tmux-dev='tmux attach -t my-dev || tmux new -t my-dev'" >> "$ZSHRC"
fi

echo -e "${GREEN}✔ Zsh and Oh-My-Zsh configured successfully.${NC}"
