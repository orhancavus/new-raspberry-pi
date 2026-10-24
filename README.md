# Raspberry Pi 5 AI & Developer Workstation Setup

This setup suite automates the complete configuration of a new Raspberry Pi 5 installation, reconstructed and optimized from my previous work on a similar device

https://github.com/orhancavus/new-raspberry-pi

It equips the Raspberry Pi for:
- **Local AI & NPU Acceleration**: Raspberry Pi AI Kit (Hailo-8 / Hailo-8L / Hailo-10) with PCIe Gen 3 throughput and `python3-hailort`.
- **Local LLM & Vision Inference**: Ollama engine with automated pulling of `qwen2.5:1.5b` and `moondream` (vision model).
- **Modern Python Tooling**: Astral `uv` package manager with support for system site-packages.
- **Node.js Ecosystem**: NVM and Node.js LTS (v20) for web development (Next.js, shadcn-ui, Tailwind).
- **Modern Terminal Experience**: `zsh`, Oh-My-Zsh, `zsh-autosuggestions`, `zsh-syntax-highlighting`, and `eza` (modern `ls`).
- **Remote Access & Tunnels**: Cloudflare Tunnel (`cloudflared`) and a launcher helper script (`start_cloudflared.sh`).
- **Containerization & Dev Tools**: Docker CE Engine, GitHub CLI (`gh`), Git, and ED25519 SSH keys.

---

## 📁 Repository Structure

```
.
├── config.env                 # Central configuration (Git info, Node version, model lists)
├── install.sh                 # Interactive & modular runner script
├── setup_all.sh               # Standalone all-in-one script (single file deployment)
├── README.md                  # Documentation and runbook
├── rp_tenkanhm.txt            # Original command history analyzed
└── scripts/
    ├── 01_system_base.sh      # Base system packages, silversearcher-ag, tmux, eza, zip
    ├── 02_shell_zsh.sh        # Zsh, Oh-My-Zsh, plugins, aliases, and PATH
    ├── 03_python_uv.sh        # Astral uv installation & PATH setup
    ├── 04_nodejs.sh           # NVM, Node.js 20, npm/npx
    ├── 05_hailo_ai.sh         # Hailo AI Kit (hailo-all, python3-hailort, PCIe Gen 3)
    ├── 06_ollama.sh           # Ollama installation & model pulls (qwen2.5:1.5b, moondream)
    ├── 07_cloudflared.sh      # Cloudflare Tunnel & ~/start_cloudflared.sh helper
    ├── 08_workspace_dirs.sh   # ~/pydev folder hierarchy & agent skills directories
    ├── 09_git_ssh.sh          # Git identity, SSH keygen (ed25519), GitHub CLI (gh)
    └── 10_docker.sh           # Docker CE Engine & user group configuration
```

---

## 🚀 Quick Start

### Option 1: Standalone Single-File Setup (Quickest)
If you want to transfer just a single file to your new Raspberry Pi:

1. Copy [`setup_all.sh`](./setup_all.sh) to your Raspberry Pi:
   ```bash
   scp setup_all.sh pi@<raspberry-pi-ip>:~/
   ```
2. SSH into your Raspberry Pi and execute:
   ```bash
   chmod +x setup_all.sh
   ./setup_all.sh
   ```

---

### Option 2: Modular & Interactive Setup (Recommended)
If you copy the entire folder:

1. Copy the directory to your Raspberry Pi:
   ```bash
   scp -r . pi@<raspberry-pi-ip>:~/pi-setup/
   ```
2. Inspect or customize [`config.env`](./config.env) if you wish to adjust your Git email, model selections, or Node version.
3. Make the runner executable and run it:
   ```bash
   chmod +x install.sh scripts/*.sh
   ./install.sh
   ```
   - Running `./install.sh` without arguments launches a menu allowing you to run all phases or choose individual steps.
   - Run unattended with:
     ```bash
     ./install.sh --all
     ```
   - Run a single phase with:
     ```bash
     ./install.sh --step 5   # Runs Phase 5 (Hailo AI Kit)
     ```

---

## ⚙️ Configuration (`config.env`)

You can customize options before running:

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `GIT_USER_NAME` | `"your_username"` | Global Git author name |
| `GIT_USER_EMAIL` | `"your_email@example.com"` | Global Git author email |
| `NODE_VERSION` | `"20"` | Node.js version installed via NVM |
| `PULL_OLLAMA_MODELS`| `true` | Automatically pull local AI models |
| `OLLAMA_MODELS` | `("qwen2.5:1.5b" "moondream")` | List of models to pull |
| `ENABLE_PCIE_GEN3` | `true` | Adds PCIe Gen 3 entries to `/boot/firmware/config.txt` |
| `INSTALL_DOCKER` | `true` | Installs Docker CE from `get.docker.com` |

---

## 🔍 Post-Installation Steps & Verification

### 1. Reboot for PCIe Gen 3 & Hailo NPU
The PCIe Gen 3 config and Hailo DKMS kernel modules require a system reboot:
```bash
sudo reboot
```

### 2. Verify Hailo NPU Identification
After rebooting, check that the Hailo AI chip is communicating over PCIe:
```bash
hailortcli fw-control identify
```
*Expected output: Firmware version, device architecture (e.g. Hailo-8 / Hailo-8L), and PCIe link status.*

### 3. Hailo with Python (`uv`)
When creating virtual environments with `uv` for Hailo applications (like `rpi-person-tracker`), **always include system site-packages** so the Python bindings can access `python3-hailort`:
```bash
uv venv --system-site-packages
source .venv/bin/activate
uv run python -c "import hailo_platform; print('Hailo OK')"
```

### 4. Switch Default Shell to Zsh
```bash
chsh -s $(which zsh)
```
Log out and log back in to enter your new Zsh environment with autosuggestions and `eza` aliases.

### 5. Authenticate GitHub CLI
```bash
gh auth login
gh auth setup-git
```

### 6. Expose Web Applications with Cloudflare Tunnel
A helper script was created at `~/start_cloudflared.sh`. To quickly expose a local server (e.g. Next.js on port 3000 or FastAPI on port 8000):
```bash
./start_cloudflared.sh 3000
```
This generates a secure public HTTPS URL through Cloudflare.

---

## 🔄 Migrating Files from Previous Raspberry Pi to macOS

To copy projects and folders from your previous Raspberry Pi to your Mac while intelligently skipping heavy or transient directories (like `node_modules`, `.venv`, `.next`, cache files, and anything matched by `.gitignore`), use [`sync_from_pi.sh`](./sync_from_pi.sh):

```bash
# 1. Preview files without copying (Dry Run simulation)
./sync_from_pi.sh --host 192.168.1.101 --user tenkanhm --remote ~/pydev/ --dry-run

# 2. Run the live transfer
./sync_from_pi.sh --host 192.168.1.101 --user tenkanhm --remote ~/pydev/ --dest ~/Downloads/rpi-backup

# Or run interactively (prompts for host, user, paths, and confirmation):
./sync_from_pi.sh
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.
