#!/usr/bin/env bash
# ==============================================================================
# Phase 6: Ollama Local LLM Engine & Vision Models
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

PULL_OLLAMA_MODELS="${PULL_OLLAMA_MODELS:-true}"

echo -e "${BLUE}[6/10] Starting Ollama Local AI Setup...${NC}"

if ! command -v ollama &> /dev/null; then
    echo -e "${BLUE}--> Installing Ollama via official installer...${NC}"
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo -e "${YELLOW}--> Ollama is already installed at $(command -v ollama).${NC}"
fi

# Ensure systemd service is started
echo -e "${BLUE}--> Enabling and starting Ollama service...${NC}"
sudo systemctl enable --now ollama || true

# Wait for Ollama service to become responsive (up to 30 seconds)
echo -e "${BLUE}--> Waiting for Ollama daemon to respond...${NC}"
RETRIES=15
until curl -s http://localhost:11434/api/tags > /dev/null || [ $RETRIES -eq 0 ]; do
    sleep 2
    RETRIES=$((RETRIES - 1))
done

if [ $RETRIES -eq 0 ]; then
    echo -e "${YELLOW}Warning: Ollama daemon did not respond within 30s. Models can be pulled manually later.${NC}"
else
    echo -e "${GREEN}✔ Ollama daemon is ready.${NC}"
    
    if [ "$PULL_OLLAMA_MODELS" = "true" ]; then
        for model in "${OLLAMA_MODELS[@]}"; do
            echo -e "${BLUE}--> Pulling Ollama model: ${model}...${NC}"
            ollama pull "$model" || echo -e "${YELLOW}Failed to pull ${model}, you can retry later with 'ollama pull ${model}'${NC}"
        done
        echo -e "${GREEN}✔ Model download complete.${NC}"
    fi
fi

echo -e "${GREEN}✔ Ollama setup finished.${NC}"
