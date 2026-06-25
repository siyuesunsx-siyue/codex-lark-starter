#!/usr/bin/env bash
#
# install-node.sh — install Node.js 20 LTS using nvm.
#
# This script installs nvm (Node Version Manager) if not already present,
# then installs and activates Node.js 20 LTS.  It is idempotent — running
# it multiple times is safe.
#
# Supported platforms:
#   - Linux (all distributions with bash and curl)
#   - macOS
#   - WSL 2
#
# Usage:
#   ./install-node.sh
#
# Environment variables:
#   NVM_VERSION   nvm version to install   (default: v0.40.1)
#   NODE_VERSION   Node.js major version   (default: 20)
#   NVM_DIR        nvm installation path   (default: $HOME/.nvm)
#
# Exit codes:
#   0   Success
#   1   nvm or Node.js installation failed
#   2   Node.js version is too old

set -euo pipefail

# Color helpers (auto-disabled if stdout is not a terminal)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' NC=''
fi

log()  { echo -e "${GREEN}[install-node]${NC} $*"; }
warn() { echo -e "${YELLOW}[install-node]${NC} WARNING: $*" >&2; }
err()  { echo -e "${RED}[install-node]${NC} ERROR: $*" >&2; }

NVM_VERSION="${NVM_VERSION:-v0.40.1}"
NODE_VERSION="${NODE_VERSION:-20}"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# ---------------------------------------------------------------------------
# Load nvm into the current shell session
# ---------------------------------------------------------------------------

_load_nvm() {
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck disable=SC1090,SC1091
    . "$NVM_DIR/nvm.sh"
  fi
}

# ---------------------------------------------------------------------------
# Check for existing Node.js installations
# ---------------------------------------------------------------------------

_detect_existing_node() {
  local node_path
  node_path="$(command -v node 2>/dev/null || true)"

  if [[ -z "$node_path" ]]; then
    return 1
  fi

  local version
  version="$(node --version 2>/dev/null || echo 'v0.0.0')"
  local major
  major="$(echo "$version" | sed 's/^v//' | cut -d. -f1)"

  log "Found existing Node.js: ${version} at ${node_path}"

  if [[ "$major" -ge "$NODE_VERSION" ]]; then
    log "Node.js ${version} meets the minimum requirement (>= ${NODE_VERSION})."
    return 0
  fi

  warn "Node.js ${version} is older than ${NODE_VERSION}.  Will upgrade via nvm."
  return 1
}

# ---------------------------------------------------------------------------
# Install nvm
# ---------------------------------------------------------------------------

_install_nvm() {
  # Check if nvm is already loaded in this shell
  if command -v nvm &>/dev/null; then
    log "nvm is already loaded: $(nvm --version 2>/dev/null || echo 'version unknown')"
    return
  fi

  # Check if nvm is installed but not loaded
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    log "nvm is installed but not loaded.  Loading now ..."
    _load_nvm
    if command -v nvm &>/dev/null; then
      return
    fi
    err "nvm.sh exists but could not be loaded."
    err "Try opening a new terminal or running: source ~/.bashrc"
    exit 1
  fi

  log "Installing nvm ${NVM_VERSION} ..."
  log "Downloading from: https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh"
  log ""
  warn "Note: This script downloads and executes nvm's install.sh via curl."
  warn "nvm is a widely-trusted project: https://github.com/nvm-sh/nvm"
  warn "You can also install nvm manually: https://github.com/nvm-sh/nvm#installing-and-updating"
  log ""

  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash || {
    err "nvm installation failed."
    err "Check your internet connection or try installing nvm manually."
    exit 1
  }

  # Load nvm immediately for this session
  export NVM_DIR="$HOME/.nvm"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck disable=SC1090,SC1091
    . "$NVM_DIR/nvm.sh"
  fi

  if ! command -v nvm &>/dev/null; then
    err "nvm was installed but the 'nvm' command is not available."
    err "This is expected if you are running this script for the first time."
    err "Please open a NEW terminal and re-run this script, or run:"
    err "  source ~/.bashrc"
    err "  ./install/install-node.sh"
    exit 1
  fi

  log "nvm installed successfully: $(nvm --version 2>/dev/null || echo 'ok')"
}

# ---------------------------------------------------------------------------
# Install Node.js via nvm
# ---------------------------------------------------------------------------

_install_node() {
  _load_nvm

  if ! command -v nvm &>/dev/null; then
    err "nvm is not available.  Cannot install Node.js."
    err "Make sure nvm is installed and loaded in your shell."
    err "Try: source ~/.bashrc && ./install/install-node.sh"
    exit 1
  fi

  # Check if the desired version is already active
  local current
  current="$(node --version 2>/dev/null || echo 'none')"

  if [[ "$current" == "v${NODE_VERSION}."* ]]; then
    log "Node.js ${current} is already active.  Nothing to do."
    return
  fi

  log "Installing Node.js ${NODE_VERSION} LTS via nvm ..."
  log "This may take a few minutes while nvm downloads and compiles Node.js."
  log ""

  nvm install "$NODE_VERSION" || {
    err "Node.js ${NODE_VERSION} installation failed."
    err "Check your internet connection and try again."
    exit 1
  }

  nvm use "$NODE_VERSION" || {
    err "Could not activate Node.js ${NODE_VERSION}."
    exit 1
  }

  nvm alias default "$NODE_VERSION" || {
    warn "Could not set ${NODE_VERSION} as the default Node.js version."
    warn "You can set it manually: nvm alias default ${NODE_VERSION}"
  }

  log "Node.js $(node --version) installed and activated."
}

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------

_verify() {
  log "Verifying Node.js installation ..."
  echo "  node    : $(node --version 2>/dev/null || echo 'NOT FOUND')"
  echo "  npm     : $(npm --version 2>/dev/null || echo 'NOT FOUND')"
  echo "  nvm     : $(nvm --version 2>/dev/null || echo 'NOT FOUND')"

  local required_major="$NODE_VERSION"
  local installed_major
  installed_major="$(node --version 2>/dev/null | sed 's/^v//' | cut -d. -f1)" || installed_major=0

  if [[ "$installed_major" -lt "$required_major" ]]; then
    err "Node.js ${required_major}+ is required.  Found: v${installed_major}."
    err "Re-run this script or install Node.js ${required_major} manually."
    exit 2
  fi

  log "Verification passed."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

log "=== codex-lark-starter — Node.js Installer ==="
log ""

_install_nvm

# After nvm is loaded, check if an adequate Node.js is already available
_load_nvm
if _detect_existing_node; then
  _verify
  log ""
  log "Node.js is ready.  Next: ./install/install-codex.sh"
  exit 0
fi

_install_node
_verify

log ""
log "Node.js installation complete."
log ""
log "Next: ./install/install-codex.sh"
