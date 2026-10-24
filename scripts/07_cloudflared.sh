#!/usr/bin/env bash
# ==============================================================================
# Phase 7: Cloudflare Tunnel ('cloudflared') & Helper Launcher
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

GENERATE_CLOUDFLARE_HELPER="${GENERATE_CLOUDFLARE_HELPER:-true}"

echo -e "${BLUE}[7/10] Starting Cloudflare Tunnel (cloudflared) Setup...${NC}"

# Add Cloudflare GPG key
sudo mkdir -p --mode=0755 /usr/share/keyrings
if [ ! -f /usr/share/keyrings/cloudflare-main.gpg ]; then
    echo -e "${BLUE}--> Fetching Cloudflare GPG key...${NC}"
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg > /dev/null
fi

# Add cloudflared repository
echo -e "${BLUE}--> Configuring Cloudflare apt repository...${NC}"
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list > /dev/null

# Install cloudflared
sudo apt update -y
sudo apt install -y cloudflared

CF_VER=$(cloudflared --version)
echo -e "${GREEN}✔ cloudflared installed successfully: ${CF_VER}${NC}"

# Generate helper script
if [ "$GENERATE_CLOUDFLARE_HELPER" = "true" ]; then
    HELPER_PATH="$HOME/start_cloudflared.sh"
    echo -e "${BLUE}--> Creating helper tunnel script at $HELPER_PATH...${NC}"
    cat << 'EOF' > "$HELPER_PATH"
#!/usr/bin/env bash
# Quick Cloudflare tunnel launcher for local web apps (Next.js / FastAPI)
PORT="${1:-3000}"
HOST="${2:-localhost}"

echo "=========================================================="
echo " Starting Cloudflare Quick Tunnel for http://${HOST}:${PORT}"
echo "=========================================================="
cloudflared tunnel --url "http://${HOST}:${PORT}"
EOF
    chmod +x "$HELPER_PATH"
    echo -e "${GREEN}✔ Created executable $HELPER_PATH (Run: ./start_cloudflared.sh [port])${NC}"
fi
