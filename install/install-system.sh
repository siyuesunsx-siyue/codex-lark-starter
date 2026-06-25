#!/usr/bin/env bash
#
# install-system.sh — install base system packages for codex-lark-starter.
#
# This script detects the platform (WSL 2 or bare-metal Linux), installs
# required system packages via the available package manager, and
# configures WSL-specific networking helpers.
#
# Supported package managers:
#   - apt (Debian, Ubuntu, WSL)
#   - brew (macOS — limited; prefers native tools)
#   - dnf (Fedora, RHEL) — future
#
# This script is idempotent — running it multiple times is safe.
#
# Usage:
#   ./install-system.sh
#
# Exit codes:
#   0   Success
#   1   Unsupported platform or package manager not found
#   2   A package installation command failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Color helpers (auto-disabled if stdout is not a terminal)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' NC=''
fi

log()  { echo -e "${GREEN}[install-system]${NC} $*"; }
warn() { echo -e "${YELLOW}[install-system]${NC} WARNING: $*" >&2; }
err()  { echo -e "${RED}[install-system]${NC} ERROR: $*" >&2; }

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------

IS_WSL=false
# /proc/sys/kernel/osrelease contains "microsoft" or "WSL" on WSL 2
if [[ -f /proc/sys/kernel/osrelease ]]; then
  if grep -qiE 'microsoft|WSL' /proc/sys/kernel/osrelease 2>/dev/null; then
    IS_WSL=true
  fi
fi

OS_NAME="$(uname -s)"

log "Detected OS: ${OS_NAME}"
if $IS_WSL; then
  log "Detected WSL 2 environment."
fi

# ---------------------------------------------------------------------------
# Install via apt (Debian / Ubuntu / WSL)
# ---------------------------------------------------------------------------

_install_apt() {
  log "Updating package index ..."
  sudo apt update -qq || {
    err "apt update failed.  Check your internet connection and try again."
    exit 2
  }

  log "Installing base packages (curl, git, build-essential, ca-certificates, unzip, jq) ..."
  sudo apt install -y -qq \
    build-essential \
    curl \
    git \
    ca-certificates \
    unzip \
    jq || {
    err "apt install failed.  Try running 'sudo apt update' manually and re-run."
    exit 2
  }

  log "apt packages installed."
}

# ---------------------------------------------------------------------------
# Install via brew (macOS)
# ---------------------------------------------------------------------------

_install_brew() {
  if ! command -v brew &>/dev/null; then
    err "Homebrew is not installed."
    err "Install it from: https://brew.sh"
    err "Or run: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
  fi

  log "Installing base packages via Homebrew ..."
  brew install curl git jq unzip 2>/dev/null || {
    warn "Some brew packages may already be installed.  Continuing."
  }

  log "brew packages installed."
}

# ---------------------------------------------------------------------------
# WSL-specific setup
# ---------------------------------------------------------------------------

_configure_wsl() {
  if ! $IS_WSL; then
    return
  fi

  # Symlink detect-host-ip.sh so it is available on PATH
  local detect_script="${PROJECT_DIR}/scripts/detect-host-ip.sh"
  if [[ -f "$detect_script" ]]; then
    chmod +x "$detect_script"
    sudo ln -sf "$detect_script" /usr/local/bin/detect-host-ip
    log "Symlinked detect-host-ip → /usr/local/bin/detect-host-ip"
  else
    warn "detect-host-ip.sh not found at ${detect_script}"
  fi

  # Configure systemd in /etc/wsl.conf if not already set.
  # We append to the file instead of overwriting to preserve existing config.
  if [[ ! -f /etc/wsl.conf ]] || ! grep -q '^\[boot\]' /etc/wsl.conf 2>/dev/null; then
    log "Configuring WSL for systemd support ..."
    {
      echo ""
      echo "# Added by codex-lark-starter install-system.sh"
      echo "[boot]"
      echo "systemd=true"
      echo ""
      echo "[network]"
      echo "generateResolvConf=true"
    } | sudo tee -a /etc/wsl.conf > /dev/null

    warn "WSL configuration updated.  You must restart WSL for changes to take effect:"
    warn "  (PowerShell) wsl --shutdown"
    warn "  Then re-open your WSL terminal."
  else
    log "WSL /etc/wsl.conf already has [boot] section — skipping."
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

log "=== codex-lark-starter — System Installer ==="
log ""

case "$OS_NAME" in
  Linux)
    if command -v apt &>/dev/null; then
      _install_apt
    else
      err "Unsupported Linux distribution."
      err "This script currently supports Debian / Ubuntu (apt)."
      err "For Fedora, run: sudo dnf install curl git jq unzip"
      err "For Arch, run:  sudo pacman -S curl git jq unzip"
      err "Contributions for other package managers are welcome!"
      exit 1
    fi
    _configure_wsl
    ;;

  Darwin)
    _install_brew
    log "macOS does not need WSL-specific configuration — skipping."
    ;;

  *)
    err "Unsupported operating system: ${OS_NAME}"
    err "Supported: Linux (apt), macOS (brew), WSL 2"
    exit 1
    ;;
esac

log ""
log "System packages installed successfully."
log ""
log "Next steps:"
log "  1. ./install/install-node.sh       – Install Node.js 20 LTS"
log "  2. ./install/install-codex.sh      – Install Codex CLI"
log "  3. ./install/install-bridge.sh     – Validate and symlink the bridge"

if $IS_WSL; then
  log ""
  warn "IMPORTANT: If /etc/wsl.conf was modified, restart WSL now:"
  warn "  (PowerShell) wsl --shutdown"
fi
