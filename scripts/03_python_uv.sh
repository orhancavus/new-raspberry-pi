#!/usr/bin/env bash
# ==============================================================================
# Phase 3: Python Environment & Astral 'uv'
# ==============================================================================
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[3/10] Starting Python Environment & Astral 'uv' Setup...${NC}"

# Ensure python3, pip, and venv tools exist
echo -e "${BLUE}--> Ensuring python3 and development headers are installed...${NC}"
sudo apt install -y python3 python3-pip python3-venv python3-dev

# Install Astral uv (modern high-performance Python package & project manager)
echo -e "${BLUE}--> Installing Astral uv...${NC}"
curl -LsSf https://astral.sh/uv/install.sh | sh

# Export path for current session
export PATH="$HOME/.local/bin:$PATH"

# Ensure PATH is in ~/.bashrc and ~/.zshrc
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ] && ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$rc"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
    fi
done

if command -v uv &> /dev/null; then
    UV_VER=$(uv --version)
    echo -e "${GREEN}✔ Astral uv installed successfully: ${UV_VER}${NC}"
else
    echo -e "${YELLOW}Warning: uv binary installed to ~/.local/bin. Ensure PATH is reloaded.${NC}"
fi
