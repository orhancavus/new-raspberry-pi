# Raspberry Pi Setup & Automated Installation Plan

## 1. Analysis of `rp_tenkanhm.txt`

Analysis of the 266 command entries reveals a complete setup of a Raspberry Pi 5 development workstation customized for AI inference (Hailo NPU + Ollama), vision processing, modern web development, and remote access.

### Discovered Software & Tools
| Category | Software / Tool | Purpose & Usage in History |
| :--- | :--- | :--- |
| **Shell & CLI** | `zsh`, `oh-my-zsh` plugins | `zsh-autosuggestions`, `zsh-syntax-highlighting`, custom PATH |
| **Modern CLI Utilities** | `eza`, `silversearcher-ag`, `tmux`, `gpg`, `zip` | Modern `ls` alternative (`eza`), code search (`ag`), terminal multiplexer |
| **Python Tooling** | `uv` (Astral) | Fast Python package manager, venvs with `--system-site-packages` |
| **Node.js Environment** | `nvm`, Node.js 20, npm, npx | Next.js frontend projects (`nx_web_app`, `rpi_stat`), shadcn-ui |
| **AI / NPU Hardware** | Hailo AI Kit (`hailo-all`, `python3-hailort`) | Raspberry Pi AI HAT / Hailo-8L / Hailo-10 PCIe NPU inference |
| **Local LLM Engine** | `ollama` | Local LLMs (`qwen2.5:1.5b`, `moondream` vision model) |
| **Camera & Vision** | `rpicam-apps` / `libcamera` | Tested `rpicam-hello`, `rpicam-still`, `rpicam-vid` |
| **Networking & Tunnels**| `cloudflared` | Exposing local web apps & ports to the internet via Cloudflare Tunnel |
| **Developer Git / SSH** | `gh` (GitHub CLI), `git`, `ssh-keygen` | Ed25519 key, Git identity (`orhancavus`), repo clones |
| **Workspace Organization**| `~/pydev/` hierarchy | Organized folders: `01_agents`, `02_apps`, `03_ai_experiments`, etc. |
| **AI Agent Skills** | Antigravity CLI (`agy`) dirs | `~/.agents/skills`, `~/.gemini/antigravity-cli/skills` |

---

## 2. Key Architecture & Installation Insights

1. **Hailo NPU & Python Site-Packages**:
   - The Raspberry Pi AI kit requires Debian system packages (`hailo-all`, `python3-hailort`).
   - Python virtual environments managed by `uv` must be initialized with `--system-site-packages` so Python scripts can import `hailo_platform`.
   - The PCIe port on Raspberry Pi 5 needs Gen 3 activation in `/boot/firmware/config.txt` for optimal Hailo throughput.
2. **Hailo Gen AI Zoo vs Standard Ollama**:
   - The history shows an attempt to install `hailo-gen-ai-model-zoo` and `hailo-ollama` deb packages, which were subsequently uninstalled/purged in favor of standard official `ollama`.
   - The script will configure official `ollama` directly, with Hailo acceleration reserved for Hailo RT Python workflows (e.g., `rpi-person-tracker`).
3. **Idempotency & Non-Interactive Safety**:
   - The script will check if packages/keys/directories exist before creating or appending.
   - It will avoid duplicate exports in `~/.zshrc` or `~/.bashrc`.
   - GPG keyring additions (`eza`, `cloudflared`) will use modern `/etc/apt/keyrings/` without deprecated `apt-key`.

---

## 3. Proposed Script Architecture

We propose creating a modular installation directory:
```
setup-scripts/
├── install.sh                  # Main entry point (supports interactive menu or non-interactive full run)
├── config.env                  # Customizable variables (Git name/email, Node version, Ollama models)
└── scripts/
    ├── 01_system_base.sh       # Apt update, essential tools (ag, tmux, gpg, eza, zip)
    ├── 02_shell_zsh.sh         # Zsh, Oh-My-Zsh plugins, ~/.zshrc configuration
    ├── 03_python_uv.sh         # Astral uv installation, PATH configuration
    ├── 04_nodejs.sh            # NVM, Node.js 20, core npm packages
    ├── 05_hailo_ai.sh          # Raspberry Pi AI Kit (hailo-all, python3-hailort, PCIe check)
    ├── 06_ollama.sh            # Ollama runtime & model pulling (qwen2.5, moondream)
    ├── 07_cloudflared.sh       # Cloudflare Tunnel package & helper launcher script
    ├── 08_workspace_dirs.sh    # Directory structure (pydev, agent skills)
    └── 09_git_ssh.sh           # Git identity, SSH keygen, GitHub CLI
```

Additionally, a single standalone unified script `setup_all.sh` can be provided for one-line execution:
`curl -sSL ... | bash` or `./setup_all.sh`.

---

## 4. Step-by-Step Installation Phases

### Phase 1: Base System & Essential CLI Tools
- Update package index: `sudo apt update && sudo apt upgrade -y`
- Install standard utilities: `build-essential`, `curl`, `wget`, `gpg`, `tmux`, `silversearcher-ag`, `zip`, `unzip`, `git`
- Configure `eza` repository (modern `ls`):
  - Add `/etc/apt/keyrings/gierens.gpg`
  - Add `/etc/apt/sources.list.d/gierens.list`
  - Install `eza`

### Phase 2: Shell & Terminal Customization
- Ensure `zsh` is installed
- If Oh-My-Zsh is present (or installed):
  - Clone `zsh-autosuggestions` to `${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/`
  - Clone `zsh-syntax-highlighting` to `${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/`
- Configure `~/.zshrc`:
  - Ensure `$HOME/.local/bin` is in `$PATH`
  - Add plugins `(git zsh-autosuggestions zsh-syntax-highlighting)`
  - Add aliases: `alias ls="eza"`, `alias ll="eza -la"`

### Phase 3: Python Environment (`uv`)
- Install `uv` via official installer: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Export `PATH="$HOME/.local/bin:$PATH"`
- Validate `uv --version`

### Phase 4: Node.js & Tooling
- Install `nvm` (Node Version Manager): `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash`
- Load `nvm` into current session
- Install and set default Node.js version 20: `nvm install 20 && nvm use 20`
- Validate `node -v` and `npm -v`

### Phase 5: Raspberry Pi AI Kit & Hailo NPU
- Install Raspberry Pi AI Kit packages:
  `sudo apt install -y hailo-all python3-hailort rpicam-apps`
- Check / advise on PCIe Gen 3 in `/boot/firmware/config.txt`:
  - `dtparam=pciex1`
  - `dtparam=pciex1_gen=3`
- Hardware validation test: `hailortcli fw-control identify`

### Phase 6: Local AI Engine (Ollama)
- Install Ollama: `curl -fsSL https://ollama.com/install.sh | sh`
- Start Ollama service: `sudo systemctl enable --now ollama`
- Pull models used in history:
  - `ollama pull qwen2.5:1.5b`
  - `ollama pull moondream` (compact multimodal vision model)

### Phase 7: Cloudflare Tunnel (`cloudflared`)
- Add Cloudflare GPG keyring: `/usr/share/keyrings/cloudflare-main.gpg`
- Add repository: `/etc/apt/sources.list.d/cloudflared.list`
- Install `cloudflared` via apt
- Generate a starter helper script: `~/start_cloudflared.sh` to quickly launch ad-hoc quick tunnels (`cloudflared tunnel --url http://localhost:3000`)

### Phase 8: Project Directory Structure
- Create user directory tree:
  ```bash
  mkdir -p ~/pydev/{01_agents,02_apps,03_ai_experiments,04_tools_cli,05_rasbpi}
  mkdir -p ~/.agents/skills
  mkdir -p ~/.gemini/antigravity-cli/skills/public-repo-readiness
  ```

### Phase 9: Git, SSH & GitHub CLI
- Set global Git identity:
  - `git config --global user.name "orhancavus"`
  - `git config --global user.email "orhancv@gmail.com"`
- Generate SSH Key if not existing: `ssh-keygen -t ed25519 -C "raspberrypi" -f ~/.ssh/id_ed25519 -N ""`
- Install GitHub CLI: `sudo apt install -y gh`
- Provide next step instructions for `gh auth login` and `gh auth setup-git`

### Optional Add-ons (Found in history exploration)
- Docker Engine installation via `https://get.docker.com` (can be toggled in `config.env`).

---

## 5. Implementation Status

All scripts and documentation have been created, verified for syntax validity (`bash -n`), and granted executable permissions:

- **Runner Script**: [`install.sh`](./install.sh) (Interactive & modular)
- **Standalone All-in-One**: [`setup_all.sh`](./setup_all.sh) (Single-file runner)
- **Configuration**: [`config.env`](./config.env) (Central variables)
- **Documentation**: [`README.md`](./README.md) (Runbook and verification guide)
- **Phase Scripts**:
  1. [`01_system_base.sh`](./scripts/01_system_base.sh)
  2. [`02_shell_zsh.sh`](./scripts/02_shell_zsh.sh)
  3. [`03_python_uv.sh`](./scripts/03_python_uv.sh)
  4. [`04_nodejs.sh`](./scripts/04_nodejs.sh)
  5. [`05_hailo_ai.sh`](./scripts/05_hailo_ai.sh)
  6. [`06_ollama.sh`](./scripts/06_ollama.sh)
  7. [`07_cloudflared.sh`](./scripts/07_cloudflared.sh)
  8. [`08_workspace_dirs.sh`](./scripts/08_workspace_dirs.sh)
  9. [`09_git_ssh.sh`](./scripts/09_git_ssh.sh)
  10. [`10_docker.sh`](./scripts/10_docker.sh)

