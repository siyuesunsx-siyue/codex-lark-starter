# systemd User Service Deployment

## Overview

`lark-channel-bridge` can run as a systemd user service — a background
daemon that starts at login, survives terminal close, and restarts
automatically on failure. This guide walks through the complete setup:
service unit file, proxy environment file, daemon commands, and
verification.

---

## Prerequisites

| Requirement | Check |
|-------------|-------|
| systemd (Linux with systemd, or WSL 2 with systemd enabled) | `systemctl --user --no-pager` runs without error |
| Node.js >= 20 LTS (via nvm) | `node --version` |
| `lark-channel-bridge` installed globally via npm | `which lark-channel-bridge` |
| Codex CLI installed and configured with a profile | `codex doctor` passes |
| `config.json` configured with Feishu + OpenAI credentials | `ls config.json` |
| Proxy host and port known (if behind a corporate proxy) | `<proxy-host>:<proxy-port>` |

---

## systemd User Service

Create the service unit file at the following path:

```text
~/.config/systemd/user/lark-channel-bridge.bot.codex.service
```

### Service Unit

```ini
[Unit]
Description=lark-channel-bridge (codex profile)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/home/<user>/.nvm/versions/node/<node-version>/bin/node /home/<user>/.nvm/versions/node/<node-version>/bin/lark-channel-bridge run --profile codex
Restart=always
RestartSec=5
EnvironmentFile=%h/.config/lark-channel-bridge/proxy.env
Environment="LARK_CHANNEL_HOME=/home/<user>/.lark-channel"

[Install]
WantedBy=default.target
```

### Field Reference

| Field | Purpose |
|-------|---------|
| `Type=simple` | The bridge process is the main process. |
| `ExecStart` | Full path to `node` and `lark-channel-bridge`. Use absolute paths or `%h` — do not use `~/` or `$HOME`. |
| `Restart=always` | Restart the bridge if it crashes or exits. |
| `RestartSec=5` | Wait 5 seconds between restart attempts. |
| `EnvironmentFile=%h/.../proxy.env` | Load proxy variables from a file. `%h` expands to the user home directory. |
| `Environment=` | Set additional environment variables visible to the bridge process. |

### Customize Paths

Replace the placeholders with your own values:

- `<user>` — your Linux username. Find it with `whoami`.
- `<node-version>` — your nvm-managed Node.js version. Find it with
  `nvm current`.

Verify the `node` binary path:

```bash
which node
```

The output should match the first segment of `ExecStart`. If your
`lark-channel-bridge` binary is at a different path, adjust the second
segment accordingly.

---

## EnvironmentFile

The `EnvironmentFile` directive loads `KEY=value` pairs into the
service's environment before `ExecStart` runs. This is the recommended
way to inject proxy variables — it is cleaner than hardcoding them
directly in the service unit.

### Rules

- One `KEY=value` pair per line.
- No quoting around values. Write `HTTP_PROXY=http://host:port`, not
  `HTTP_PROXY="http://host:port"`.
- No blank lines.
- No comments. systemd's `EnvironmentFile` parser does not recognize
  `#` as a comment prefix.
- Restrict permissions: `chmod 600`.

---

## proxy.env

Create the environment file:

```text
~/.config/lark-channel-bridge/proxy.env
```

### Content

```ini
HTTP_PROXY=http://<proxy-host>:<proxy-port>
HTTPS_PROXY=http://<proxy-host>:<proxy-port>
ALL_PROXY=http://<proxy-host>:<proxy-port>
http_proxy=http://<proxy-host>:<proxy-port>
https_proxy=http://<proxy-host>:<proxy-port>
all_proxy=http://<proxy-host>:<proxy-port>
NO_PROXY=localhost,127.0.0.1,::1,open.feishu.cn,*.feishu.cn,open.larksuite.com,*.larksuite.com
no_proxy=localhost,127.0.0.1,::1,open.feishu.cn,*.feishu.cn,open.larksuite.com,*.larksuite.com
```

Replace `<proxy-host>:<proxy-port>` with your actual proxy address.

### Why Both Uppercase and Lowercase

Many tools (curl, Node.js `node-fetch`, Codex CLI) respect only the
lowercase forms, while others prefer uppercase. Setting both ensures
consistent behavior across the entire stack.

### Restrict Permissions

```bash
chmod 600 ~/.config/lark-channel-bridge/proxy.env
```

---

## Validation Procedure

### Step 1 — Enable WSL Lingering (WSL Only)

On WSL, systemd user services stop when the last user session closes.
Enable lingering to keep the service alive:

```bash
sudo loginctl enable-linger "$USER"
```

Confirm:

```bash
loginctl show-user "$USER" | grep Linger
```

Expected output:

```text
Linger=yes
```

Skip this step on a standard Linux server (non-WSL).

### Step 2 — Deploy and Start

```bash
systemctl --user daemon-reload
systemctl --user enable --now lark-channel-bridge.bot.codex.service
```

`enable --now` enables the service to start at boot **and** starts it
immediately.

### Step 3 — Restart After Changes

If you edit the service unit or `proxy.env`, apply the changes:

```bash
systemctl --user daemon-reload
systemctl --user restart lark-channel-bridge.bot.codex.service
```

---

## Verification Commands

### Check service status

```bash
systemctl --user status lark-channel-bridge.bot.codex.service --no-pager
```

Expected: `active (running)`.

### Confirm proxy variables in the daemon environment

```bash
PID=$(systemctl --user show -p MainPID --value lark-channel-bridge.bot.codex.service)
echo "PID=$PID"
tr '\0' '\n' < "/proc/$PID/environ" | grep -Ei 'HTTP_PROXY|HTTPS_PROXY|ALL_PROXY|NO_PROXY'
```

Expected: eight variables printed, matching `proxy.env`.

### Test from Feishu

Send a message to your bot in a Feishu channel:

> ping

The bot should reply. If it does not, inspect `stderr.log` and
`stdout.log` in your bridge log directory.

### Test terminal-close resilience

1. Close your WSL terminal.
2. Open a new terminal.
3. Run `systemctl --user status lark-channel-bridge.bot.codex.service --no-pager`.

The service should still show `active (running)`. Send another message in
Feishu — the bot should still reply.

---

## Known Limitations

### Computer must remain powered on

This setup keeps the bot alive after closing the terminal. It does
**not** keep the bot alive when the computer is shut down or enters
sleep. For 24/7 availability, deploy on an always-on host (VPS, NAS,
mini PC, or cloud virtual machine).

### Node.js path is hardcoded

The service unit uses an absolute path to the nvm-managed Node.js
binary. If you upgrade Node.js, update the `ExecStart` path and run
`systemctl --user daemon-reload` followed by `systemctl --user restart`.

### No health-check endpoint

This unit uses `Type=simple` with `Restart=always`. If the bridge
process stays alive but stops responding (e.g., a hung event loop),
systemd will not detect the failure. A health-check endpoint with
`Type=notify` is planned for a future release.

### proxy.env does not support comments

systemd's `EnvironmentFile` parser does not recognize `#`. Do not add
comments to `proxy.env`. Keep documentation in this guide.
