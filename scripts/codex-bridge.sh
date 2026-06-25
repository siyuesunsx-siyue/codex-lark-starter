#!/usr/bin/env bash
#
# codex-bridge.sh — lifecycle manager for the lark-channel-bridge process.
#
# This script provides start / stop / restart / status / logs commands
# for managing the bridge process.  It uses a PID file for tracking and
# supports graceful shutdown with a SIGKILL fallback after a configurable
# timeout.
#
# Usage:
#   codex-bridge.sh {start|stop|restart|status|logs}
#
# Environment variables (all optional):
#   BRIDGE_HOST       TCP bind address           (default: 127.0.0.1)
#   BRIDGE_PORT       TCP port                   (default: 8765)
#   BRIDGE_CONFIG     Path to config.json         (default: ./config.json)
#   BRIDGE_STOP_WAIT  Seconds to wait for SIGTERM (default: 10)
#
# Dependencies:
#   - node (Node.js >= 20)
#   - A bridge entrypoint script.  Auto-detected from:
#       ./bridge/index.js  (recommended convention)
#       ./index.js         (single-file fallback)
#     Or set BRIDGE_ENTRYPOINT to a custom absolute path.
#
# Exit codes:
#   0   Success
#   1   Configuration error (missing config, missing node, etc.)
#   2   Process error (failed to start, failed to stop)

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — override via environment variables
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

BRIDGE_HOST="${BRIDGE_HOST:-127.0.0.1}"
BRIDGE_PORT="${BRIDGE_PORT:-8765}"
BRIDGE_CONFIG="${BRIDGE_CONFIG:-${PROJECT_DIR}/config.json}"
BRIDGE_STOP_WAIT="${BRIDGE_STOP_WAIT:-10}"

# The entrypoint for the bridge process.
# Set BRIDGE_ENTRYPOINT to override (e.g. if your bridge is at a custom path).
BRIDGE_ENTRYPOINT="${BRIDGE_ENTRYPOINT:-}"

PID_FILE="${PROJECT_DIR}/.bridge.pid"
LOG_DIR="${PROJECT_DIR}/logs"
BRIDGE_LOG="${LOG_DIR}/bridge.log"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

#
# Initialize the log directory and files.  Creates the directory if it does
# not exist and touches the log file so tail -f will not fail on first run.
#
_init_logs() {
  if [[ ! -d "$LOG_DIR" ]]; then
    mkdir -p "$LOG_DIR" || {
      echo "[bridge] ERROR: Cannot create log directory: ${LOG_DIR}" >&2
      exit 2
    }
  fi
  if [[ ! -f "$BRIDGE_LOG" ]]; then
    touch "$BRIDGE_LOG"
  fi
}

#
# Check whether a bridge process is currently running by reading the PID
# file and verifying the process exists.
#
# Returns 0 if running, 1 otherwise.
#
_is_running() {
  if [[ ! -f "$PID_FILE" ]]; then
    return 1
  fi

  local pid
  pid="$(cat "$PID_FILE" 2>/dev/null)" || return 1

  # Validate PID is a positive integer
  if [[ ! "$pid" =~ ^[0-9]+$ ]]; then
    echo "[bridge] WARNING: PID file contains invalid data. Removing." >&2
    rm -f "$PID_FILE"
    return 1
  fi

  # Check if the process exists (POSIX-compatible kill -0)
  if kill -0 "$pid" 2>/dev/null; then
    return 0
  fi

  # Process is gone — clean up stale PID file
  rm -f "$PID_FILE"
  return 1
}

#
# Verify that config.json exists at the expected path.
# Exits with code 1 and a helpful message if it does not.
#
_require_config() {
  if [[ ! -f "$BRIDGE_CONFIG" ]]; then
    echo "[bridge] ERROR: Configuration file not found." >&2
    echo "[bridge] Expected: ${BRIDGE_CONFIG}" >&2
    echo "[bridge] Create it with:" >&2
    echo "[bridge]   cp examples/config.example.json config.json" >&2
    echo "[bridge] Then edit config.json with your credentials." >&2
    exit 1
  fi
}

#
# Verify that the node binary is available on PATH.
# Exits with a helpful message if it is not.
#
_require_node() {
  if ! command -v node &>/dev/null; then
    echo "[bridge] ERROR: Node.js is not installed or not on PATH." >&2
    echo "[bridge] Install it with:" >&2
    echo "[bridge]   ./install/install-node.sh" >&2
    exit 1
  fi

  local version
  version="$(node --version 2>/dev/null | sed 's/^v//' | cut -d. -f1)" || version="0"
  if [[ "$version" -lt 20 ]]; then
    echo "[bridge] ERROR: Node.js >= 20 is required. Found: $(node --version)" >&2
    echo "[bridge] Upgrade with:" >&2
    echo "[bridge]   ./install/install-node.sh" >&2
    exit 1
  fi
}

#
# Resolve the bridge entrypoint.  Uses BRIDGE_ENTRYPOINT if set,
# otherwise looks for common locations in the project directory.
#
# This project is a starter kit — it does not assume a build pipeline
# or a monorepo layout.  Auto-detection searches for plain source files
# only (no dist/ or build/ directories).
#
# Priority:
#   1. BRIDGE_ENTRYPOINT environment variable (manual override)
#   2. ./bridge/index.js (the recommended convention)
#   3. ./index.js (single-file bridge at project root)
#
_resolve_entrypoint() {
  if [[ -n "$BRIDGE_ENTRYPOINT" ]]; then
    echo "$BRIDGE_ENTRYPOINT"
    return
  fi

  local candidates=(
    "${PROJECT_DIR}/bridge/index.js"
    "${PROJECT_DIR}/index.js"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -f "$candidate" ]]; then
      echo "$candidate"
      return
    fi
  done

  echo ""
}

#
# Write a timestamped log message to both stdout and the bridge log file.
#
_log() {
  local timestamp
  timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%SZ')"
  echo "[bridge] ${timestamp} $*"
  echo "[bridge] ${timestamp} $*" >> "$BRIDGE_LOG"
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

#
# Start the bridge process in the background.
#
cmd_start() {
  if _is_running; then
    local pid
    pid="$(cat "$PID_FILE")"
    _log "Bridge is already running (PID: ${pid})."
    return 0
  fi

  _require_config
  _require_node
  _init_logs

  local entrypoint
  entrypoint="$(_resolve_entrypoint)"

  if [[ -z "$entrypoint" ]]; then
    echo "[bridge] ERROR: Cannot find bridge entrypoint." >&2
    echo "" >&2
    echo "[bridge] This script auto-detects the bridge from these paths:" >&2
    echo "[bridge]   ${PROJECT_DIR}/bridge/index.js" >&2
    echo "[bridge]   ${PROJECT_DIR}/index.js" >&2
    echo "[bridge] None were found." >&2
    echo "" >&2
    echo "[bridge] To fix this, set BRIDGE_ENTRYPOINT to the absolute path of" >&2
    echo "[bridge] your bridge's main JavaScript file.  For example:" >&2
    echo "" >&2
    echo "[bridge]   export BRIDGE_ENTRYPOINT=${PROJECT_DIR}/bridge/index.js" >&2
    echo "[bridge]   ./scripts/codex-bridge.sh start" >&2
    echo "" >&2
    echo "[bridge] Or write a minimal bridge at bridge/index.js and try again:" >&2
    echo "[bridge]   mkdir -p ${PROJECT_DIR}/bridge" >&2
    echo "[bridge]   # Create your bridge entrypoint, then:" >&2
    echo "[bridge]   ./scripts/codex-bridge.sh start" >&2
    exit 2
  fi

  if [[ ! -f "$entrypoint" ]]; then
    echo "[bridge] ERROR: Bridge entrypoint not found: ${entrypoint}" >&2
    exit 2
  fi

  _log "Starting bridge on ${BRIDGE_HOST}:${BRIDGE_PORT} ..."
  _log "Entrypoint: ${entrypoint}"

  node "$entrypoint" \
    --config "$BRIDGE_CONFIG" \
    --host "$BRIDGE_HOST" \
    --port "$BRIDGE_PORT" \
    >> "$BRIDGE_LOG" 2>&1 &

  local pid=$!
  echo "$pid" > "$PID_FILE"

  # Wait briefly and verify the process did not crash immediately.
  # We retry a few times in case the process takes longer to initialize.
  local retries=3
  local alive=false
  for ((i = 0; i < retries; i++)); do
    sleep 1
    if kill -0 "$pid" 2>/dev/null; then
      alive=true
      break
    fi
  done

  if $alive; then
    _log "Started successfully (PID: ${pid})."
    _log "Listening on ${BRIDGE_HOST}:${BRIDGE_PORT}"
  else
    _log "ERROR: Bridge process exited immediately after start."
    _log "Check the log for details: ${BRIDGE_LOG}"
    rm -f "$PID_FILE"
    exit 2
  fi
}

#
# Stop the running bridge process.
# Sends SIGTERM first, waits BRIDGE_STOP_WAIT seconds, then sends SIGKILL
# if the process is still alive.
#
cmd_stop() {
  if ! _is_running; then
    echo "[bridge] Bridge is not running."
    return 0
  fi

  local pid
  pid="$(cat "$PID_FILE")"
  _log "Stopping bridge (PID: ${pid}) ..."

  # Send SIGTERM for graceful shutdown
  if ! kill "$pid" 2>/dev/null; then
    _log "Process already gone. Cleaning up PID file."
    rm -f "$PID_FILE"
    return 0
  fi

  # Wait for the process to exit, up to BRIDGE_STOP_WAIT seconds
  local waited=0
  while kill -0 "$pid" 2>/dev/null && [[ $waited -lt $BRIDGE_STOP_WAIT ]]; do
    sleep 1
    waited=$((waited + 1))
  done

  # Force kill if still alive
  if kill -0 "$pid" 2>/dev/null; then
    _log "Bridge did not stop after ${BRIDGE_STOP_WAIT}s. Sending SIGKILL."
    kill -9 "$pid" 2>/dev/null || true
    sleep 1
  fi

  # Final check
  if kill -0 "$pid" 2>/dev/null; then
    _log "WARNING: Failed to kill process ${pid}."
    return 2
  fi

  rm -f "$PID_FILE"
  _log "Stopped."
}

#
# Restart the bridge by stopping the current instance and starting a new
# one.
#
cmd_restart() {
  cmd_stop
  sleep 1
  cmd_start
}

#
# Print the current status of the bridge process.
#
cmd_status() {
  if _is_running; then
    local pid
    pid="$(cat "$PID_FILE")"
    echo "[bridge] RUNNING — PID: ${pid}, Address: ${BRIDGE_HOST}:${BRIDGE_PORT}"
  else
    echo "[bridge] STOPPED"
  fi
}

#
# Tail the bridge log file in follow mode.
#
cmd_logs() {
  _init_logs
  echo "[bridge] Following ${BRIDGE_LOG} (Ctrl+C to exit) ..."
  tail -f "$BRIDGE_LOG"
}

# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------

_print_usage() {
  echo "Usage: $0 {start|stop|restart|status|logs}"
  echo ""
  echo "Commands:"
  echo "  start     Start the bridge daemon"
  echo "  stop      Stop the bridge daemon"
  echo "  restart   Stop then start"
  echo "  status    Print running status"
  echo "  logs      Tail live logs"
  echo ""
  echo "Environment:"
  echo "  BRIDGE_HOST        TCP bind address    (default: 127.0.0.1)"
  echo "  BRIDGE_PORT        TCP port            (default: 8765)"
  echo "  BRIDGE_CONFIG      Path to config.json (default: ./config.json)"
  echo "  BRIDGE_ENTRYPOINT  Path to bridge main (auto-detected)"
  echo "  BRIDGE_STOP_WAIT   Graceful stop wait  (default: 10 seconds)"
}

case "${1:-}" in
  start)    cmd_start ;;
  stop)     cmd_stop ;;
  restart)  cmd_restart ;;
  status)   cmd_status ;;
  logs)     cmd_logs ;;
  -h|--help|help) _print_usage ;;
  *)
    _print_usage >&2
    exit 1
    ;;
esac
