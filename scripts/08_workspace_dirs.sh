#!/usr/bin/env bash
# ==============================================================================
# Phase 8: Developer Workspace & Directory Structure
# ==============================================================================
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[8/10] Creating Developer Directory Structure & AI Agent Skills Folders...${NC}"

# Development project hierarchy
PROJECT_DIRS=(
    "$HOME/pydev/01_agents"
    "$HOME/pydev/02_apps"
    "$HOME/pydev/03_ai_experiments"
    "$HOME/pydev/04_tools_cli"
    "$HOME/pydev/05_rasbpi"
    "$HOME/.agents/skills"
)

for dir in "${PROJECT_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "  Created: $dir"
    fi
done

# If start_cloudflared.sh exists, also provide a copy or symlink in ~/pydev/05_rasbpi
if [ -f "$HOME/start_cloudflared.sh" ] && [ -d "$HOME/pydev/05_rasbpi" ]; then
    cp "$HOME/start_cloudflared.sh" "$HOME/pydev/05_rasbpi/start_cloudflared.sh"
    chmod +x "$HOME/pydev/05_rasbpi/start_cloudflared.sh"
fi

echo -e "${GREEN}✔ Workspace directories created successfully.${NC}"
