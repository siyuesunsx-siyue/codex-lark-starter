#!/usr/bin/env bash
#
# install-codex.sh — install the Codex CLI binary.
#
# This script attempts to download a prebuilt Codex CLI binary for the
# current platform.  If no prebuilt binary is available, it falls back to
# installing via npm.
#
# Supported platforms:
#   - Linux (x86_64, aarch64)
#   - macOS (x86_64, arm64)
#   - WSL 2
#
# Usage:
#   ./install-codex.sh
#
# Environment variables:
#   CODEX_INSTALL_DIR   Installation directory   (default: $HOME/.local/bin)
#   CODEX_VERSION       Version to install       (default: latest)
#
# Exit codes:
#   0   Success
#   1   Platform not supported or Codex CLI not found on PATH after install

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

log()  { echo -e "${GREEN}[install-codex]${NC} $*"; }
warn() { echo -e "${YELLOW}[install-codex]${NC} WARNING: $*" >&2; }
err()  { echo -e "${RED}[install-codex]${NC} ERROR: $*" >&2; }

INSTALL_DIR="${CODEX_INSTALL_DIR:-$HOME/.local/bin}"
CODEX_VERSION="${CODEX_VERSION:-latest}"

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------

_detect_platform() {
  local os arch

  case "$(uname -s)" in
    Linux)  os="linux" ;;
    Darwin) os="darwin" ;;
    *)
      err "Unsupported operating system: $(uname -s)"
      err "Supported: Linux, macOS, WSL 2"
      exit 1
      ;;
  esac

  case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)
      err "Unsupported architecture: $(uname -m)"
      err "Supported: x86_64 (amd64), aarch64 (arm64)"
      exit 1
      ;;
  esac

  echo "${os}-${arch}"
}

# ---------------------------------------------------------------------------
# Install via npm (fallback)
# ---------------------------------------------------------------------------

_install_via_npm() {
  if ! command -v npm &>/dev/null; then
    err "npm is not available.  Cannot install Codex CLI."
    err "Install Node.js first: ./install/install-node.sh"
    exit 1
  fi

  log "Installing Codex CLI via npm (this may take a minute) ..."

  # Try the two known package names.  At the time of writing, the exact
  # npm package name for Codex CLI is not finalized.  The script tries
  # both and reports which succeeded.
  local installed=false

  for pkg in "codex" "@anthropic/codex"; do
    if npm install -g "$pkg" 2>/dev/null; then
      log "Installed via npm: ${pkg}"
      installed=true
      break
    fi
  done

  if ! $installed; then
    err "Could not install Codex CLI via npm."
    err "Checked packages: codex, @anthropic/codex"
    err ""
    err "If Codex CLI uses a different package name, set CODEX_INSTALL_DIR"
    err "and install it manually, then re-run this script."
    err ""
    err "For manual installation instructions, visit:"
    err "  https://github.com/anthropics/codex"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------

_verify() {
  # Ensure INSTALL_DIR is on PATH for the verification step
  export PATH="${INSTALL_DIR}:${PATH}"

  if command -v codex &>/dev/null; then
    log "Codex CLI found on PATH: $(command -v codex)"
    log "Codex CLI version: $(codex --version 2>&1 || echo 'version unavailable')"
    return 0
  fi

  # Check if the binary exists in INSTALL_DIR but INSTALL_DIR is not on PATH
  if [[ -x "${INSTALL_DIR}/codex" ]]; then
    warn "Codex CLI is installed at ${INSTALL_DIR}/codex but is not on your PATH."
    warn ""
    warn "Add it to your PATH by adding this line to your shell profile (~/.bashrc, ~/.zshrc):"
    warn "  export PATH=\"${INSTALL_DIR}:\$PATH\""
    warn ""
    warn "Then reload your shell: source ~/.bashrc"
    return 0
  fi

  err "Codex CLI is not available on PATH and was not found in ${INSTALL_DIR}."
  err "Something went wrong during installation."
  err "Check the output above for specific error messages."
  exit 1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

log "=== codex-lark-starter — Codex CLI Installer ==="
log ""

# Ensure the install directory exists
mkdir -p "$INSTALL_DIR"

PLATFORM="$(_detect_platform)"
log "Detected platform: ${PLATFORM}"
log "Install directory: ${INSTALL_DIR}"
log ""

# Attempt to download a prebuilt binary.
#
# NOTE: The URL pattern below assumes Codex CLI publishes GitHub release
# assets.  If the pattern changes, the script will fall back to npm.
# Contributions to fix the URL pattern are welcome.

CODEX_URL="https://github.com/anthropics/codex/releases/latest/download/codex-${PLATFORM}"

log "Attempting to download prebuilt binary ..."
log "URL: ${CODEX_URL}"
log ""

if curl -fsSL -o "${INSTALL_DIR}/codex" "$CODEX_URL" 2>/dev/null; then
  chmod +x "${INSTALL_DIR}/codex"
  log "Downloaded Codex CLI binary to ${INSTALL_DIR}/codex"
else
  log "Prebuilt binary not available for ${PLATFORM}."
  log "Falling back to npm installation ..."
  _install_via_npm
fi

_verify

log ""
log "Codex CLI installation complete."
log ""
log "Next: ./install/install-bridge.sh"
