#!/usr/bin/env bash
#
# detect-host-ip.sh — resolve the Windows host IP from within WSL 2.
#
# In WSL 2, the Windows host IP is typically available as the nameserver
# in /etc/resolv.conf.  This script detects that IP and also offers a
# validation mode to test reachability.
#
# Usage:
#   detect-host-ip.sh                  Print the Windows host IP
#   detect-host-ip.sh --export         Emit "export WSL_HOST_IP=..." for eval
#   detect-host-ip.sh --validate <ip>  Test whether an IP is reachable
#
# Detection methods (tried in order):
#   1. $WSL_HOST_IP environment variable (manual override)
#   2. /etc/resolv.conf nameserver entry (WSL default)
#   3. Default route via 'ip route' or 'route -n' (fallback)
#
# Portability notes:
#   - Uses 'sed' instead of 'grep -oP' to support macOS / BSD grep.
#   - Uses 'awk' for default route detection (works on Linux and macOS).
#   - Uses 'ping -c 1' with a platform-appropriate timeout flag.
#
# Exit codes:
#   0   Success
#   1   Could not detect IP or invalid usage

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

#
# Extract the first nameserver IP from /etc/resolv.conf using sed.
# sed is portable across Linux (GNU) and macOS (BSD).
#
_detect_from_resolv() {
  if [[ -f /etc/resolv.conf ]]; then
    sed -n 's/^nameserver[[:space:]]\{1,\}\([0-9.]\{1,\}\).*/\1/p' /etc/resolv.conf 2>/dev/null | head -1 || true
  fi
}

#
# Extract the default gateway from the routing table.
# Tries 'ip route' (Linux) first, falls back to 'route -n' (macOS / BSD).
#
_detect_from_route() {
  if command -v ip &>/dev/null; then
    ip route show default 2>/dev/null | awk '{print $3; exit}' || true
  elif command -v route &>/dev/null; then
    # macOS / BSD: 'route -n get default' or parse 'netstat -rn'
    if route -n get default 2>/dev/null | awk '/gateway:/ {print $2; exit}' 2>/dev/null; then
      true
    else
      netstat -rn 2>/dev/null | awk '/^default|^0\.0\.0\.0/ {print $2; exit}' || true
    fi
  fi
}

#
# Main detection routine.  Returns the best-guess IP for the Windows host.
#
_detect_ip() {
  # Allow manual override via environment variable
  if [[ -n "${WSL_HOST_IP:-}" ]]; then
    echo "$WSL_HOST_IP"
    return
  fi

  local ip

  # Method 1: /etc/resolv.conf nameserver
  ip="$(_detect_from_resolv)"

  # Method 2: default route gateway
  if [[ -z "$ip" ]]; then
    ip="$(_detect_from_route)"
  fi

  if [[ -z "$ip" ]]; then
    echo "[detect-host-ip] ERROR: Could not detect host IP address." >&2
    echo "[detect-host-ip] This usually means you are not running inside WSL 2," >&2
    echo "[detect-host-ip] or the network configuration is non-standard." >&2
    echo "[detect-host-ip] Set WSL_HOST_IP manually:" >&2
    echo "[detect-host-ip]   export WSL_HOST_IP=192.168.1.100" >&2
    echo "[detect-host-ip] Then re-run this script." >&2
    exit 1
  fi

  echo "$ip"
}

#
# Validate that a string looks like an IPv4 address.
#
_is_valid_ip() {
  local ip="$1"
  [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
}

#
# Determine the ping timeout flag for the current platform.
# Linux uses -W (seconds), macOS uses -t (seconds).
#
_ping_timeout_flag() {
  case "$(uname -s)" in
    Darwin) echo "-t" ;;
    *)      echo "-W" ;;
  esac
}

#
# Test whether an IP is reachable via ICMP ping.
# Prints a warning if ping fails (firewalls often block ICMP) but does
# not exit with an error — the IP may still be correct for TCP.
#
_validate() {
  local ip="$1"

  if ! _is_valid_ip "$ip"; then
    echo "[detect-host-ip] ERROR: Invalid IPv4 address: ${ip}" >&2
    echo "[detect-host-ip] Expected format: 192.168.1.100" >&2
    exit 1
  fi

  local timeout_flag
  timeout_flag="$(_ping_timeout_flag)"

  echo "[detect-host-ip] Pinging ${ip} ..."

  if ping -c 1 "${timeout_flag}" 1 "$ip" >/dev/null 2>&1; then
    echo "[detect-host-ip] ${ip} is reachable."
  else
    echo "[detect-host-ip] WARNING: ${ip} did not respond to ping." >&2
    echo "[detect-host-ip] This is common — Windows Firewall blocks ICMP by default." >&2
    echo "[detect-host-ip] The IP may still be correct for TCP connections on ports you have opened." >&2
  fi
}

# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------

_print_usage() {
  echo "Usage: $0 [--export|--validate <ip>|-h|--help]"
  echo ""
  echo "Options:"
  echo "  (none)              Print the detected host IP"
  echo "  --export            Emit 'export WSL_HOST_IP=...' for shell eval"
  echo "  --validate <ip>     Test reachability of an IP via ping"
  echo "  -h, --help          Show this help message"
  echo ""
  echo "Examples:"
  echo "  detect-host-ip.sh"
  echo "  eval \$(detect-host-ip.sh --export)"
  echo "  detect-host-ip.sh --validate 172.24.0.1"
}

case "${1:-}" in
  --export)
    local_ip="$(_detect_ip)"
    echo "export WSL_HOST_IP=${local_ip}"
    ;;
  --validate)
    if [[ -z "${2:-}" ]]; then
      echo "[detect-host-ip] ERROR: --validate requires an IP argument." >&2
      echo "Usage: $0 --validate <ip>" >&2
      exit 1
    fi
    _validate "$2"
    ;;
  -h|--help)
    _print_usage
    ;;
  "")
    _detect_ip
    ;;
  *)
    echo "[detect-host-ip] ERROR: Unknown option: $1" >&2
    _print_usage >&2
    exit 1
    ;;
esac
