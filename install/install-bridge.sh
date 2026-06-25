#!/usr/bin/env bash
#
# install-bridge.sh — validate environment and prepare the bridge for use.
#
# This script checks that all prerequisites are met (Node.js, Codex CLI),
# symlinks convenience scripts to /usr/local/bin, and verifies that the
# configuration example file is present.
#
# This script does NOT install npm dependencies or build anything,
# because this is a starter kit (documentation + scripts), not an
# npm package.
#
# Usage:
#   ./install-bridge.sh
#
# Prerequisites:
#   - ./install/install-system.sh  (or equivalent manual setup)
#   - ./install/install-node.sh
#   - ./install/install-codex.sh
#
# Exit codes:
#   0   Success
#   1   Prerequisite missing
#   2   Symlink or permission error

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

log()  { echo -e "${GREEN}[install-bridge]${NC} $*"; }
warn() { echo -e "${YELLOW}[install-bridge]${NC} WARNING: $*" >&2; }
err()  { echo -e "${RED}[install-bridge]${NC} ERROR: $*" >&2; }

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------

_check_node() {
  if ! command -v node &>/dev/null; then
    err "Node.js is not installed."
    err "Run: ./install/install-node.sh"
    exit 1
  fi

  local version major
  version="$(node --version 2>/dev/null | sed 's/^v//')" || version="0.0.0"
  major="$(echo "$version" | cut -d. -f1)"

  if [[ "$major" -lt 20 ]]; then
    err "Node.js >= 20 is required.  Found: v${version}"
    err "Run: ./install/install-node.sh"
    exit 1
  fi

  log "Node.js $(node --version) — OK"
}

_check_codex() {
  if ! command -v codex &>/dev/null; then
    warn "Codex CLI is not found on PATH."
    warn "The bridge needs Codex CLI to function."
    warn "Run: ./install/install-codex.sh"
    warn ""
    warn "Continuing anyway — you can install Codex CLI later."
    return
  fi

  log "Codex CLI found: $(command -v codex) — OK"
}

_check_config_example() {
  local config_example="${PROJECT_DIR}/examples/config.example.json"

  if [[ ! -f "$config_example" ]]; then
    err "Configuration example not found: ${config_example}"
    err "The repository may be corrupted.  Try re-cloning."
    exit 1
  fi

  log "Configuration example found — OK"
}

# ---------------------------------------------------------------------------
# Symlink helper scripts to /usr/local/bin
# ---------------------------------------------------------------------------

_symlink_scripts() {
  local scripts=(
    "${PROJECT_DIR}/scripts/codex-bridge.sh"
    "${PROJECT_DIR}/scripts/detect-host-ip.sh"
  )

  # Ensure /usr/local/bin exists
  if [[ ! -d /usr/local/bin ]]; then
    warn "/usr/local/bin does not exist.  Skipping symlinks."
    warn "You can run scripts directly from ${PROJECT_DIR}/scripts/"
    return
  fi

  for script in "${scripts[@]}"; do
    if [[ ! -f "$script" ]]; then
      warn "Script not found, skipping: ${script}"
      continue
    fi

    local basename
    basename="$(basename "$script" .sh)"

    chmod +x "$script"

    if sudo ln -sf "$script" "/usr/local/bin/${basename}" 2>/dev/null; then
      log "Symlinked: ${basename} → /usr/local/bin/${basename}"
    else
      warn "Could not symlink ${basename} to /usr/local/bin/"
      warn "You may need to run this script with appropriate permissions."
      warn "You can also run scripts directly from: ${PROJECT_DIR}/scripts/"
    fi
  done
}

# ---------------------------------------------------------------------------
# Configuration guidance
# ---------------------------------------------------------------------------

_guide_config() {
  if [[ -f "${PROJECT_DIR}/config.json" ]]; then
    log "config.json found — configuration is already set up."
    return
  fi

  log ""
  log "Configuration file not found.  Create it now:"
  log ""
  log "  cp examples/config.example.json config.json"
  log ""
  log "Then edit config.json and fill in:"
  log "  - Feishu / Lark App ID and App Secret"
  log "  - OpenAI API Key"
  log ""
  log "See examples/config.example.json for all available options."
}

# ---------------------------------------------------------------------------
# Environment summary
# ---------------------------------------------------------------------------

_print_summary() {
  echo ""
  echo "=== Environment Summary ==="
  echo "  OS       : $(uname -s) $(uname -m)"
  echo "  Node.js  : $(node --version 2>/dev/null || echo 'NOT INSTALLED')"
  echo "  npm      : $(npm --version 2>/dev/null || echo 'NOT INSTALLED')"
  echo "  Codex CLI: $(codex --version 2>&1 || echo 'NOT INSTALLED')"
  echo "  Bridge   : ${PROJECT_DIR}/scripts/codex-bridge.sh"
  echo ""
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

log "=== codex-lark-starter — Bridge Validator ==="
log ""

_check_node
_check_codex
_check_config_example
_symlink_scripts
_guide_config
_print_summary

log "Validation complete."
log ""
log "When your config.json is ready, start the bridge:"
log "  ./scripts/codex-bridge.sh start"
log ""
log "For detailed instructions, read: docs/quick-start.md"
