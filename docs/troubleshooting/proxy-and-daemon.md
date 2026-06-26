# Proxy Environment Variables for lark-channel-bridge + Codex in WSL

If you work behind an HTTP proxy (corporate network, VPN, or WSL behind a
Windows proxy), the bridge and Codex CLI have conflicting proxy needs.
This document explains the symptoms, the diagnosis process, and a working
recovery path.

---

## Symptoms

When proxy variables are configured incorrectly, you will typically see one
or more of the following:

### 1. "Thinking" indicator with no response

Feishu shows the typing / "Codex is thinking" indicator, but no reply ever
arrives. The bridge has accepted the message and forwarded it to Codex, but
Codex cannot reach the OpenAI API through the proxy.

### 2. "stream disconnected before completion"

The bridge log shows:

```text
stream disconnected before completion
```

The connection between the bridge and Codex was established but dropped
before Codex finished generating. This usually means Codex attempted an
API call that failed mid-stream because it could not route through the
proxy.

### 3. "could not resolve bot identity"

The bridge log shows:

```text
could not resolve bot identity via /open-apis/bot/v3/info
```

The bridge called the Feishu/Lark OpenAPI to verify the bot's identity,
but the request was routed through the proxy — which either blocked it,
timed out, or returned an unexpected response. Feishu's API domains should
**not** go through the proxy.

### 4. `codex doctor` works in terminal, but bridge daemon fails

Running `codex doctor` in your interactive shell passes all checks. But
after starting `lark-channel-bridge` as a daemon, Feishu messages go
unanswered. The daemon process is not inheriting your shell's proxy
environment variables.

---

## Root Cause

| Component | Proxy Requirement | Reason |
|-----------|------------------|--------|
| Codex CLI → OpenAI | **Must** use proxy | OpenAI API (`api.openai.com`) may be unreachable directly from corporate/WSL networks. |
| Bridge → Feishu/Lark API | **Usually bypass proxy in this WSL setup** | In the verified WSL environment, routing Feishu OpenAPI (`open.feishu.cn`, `open.larksuite.com`) through the general-purpose HTTP proxy caused bot identity resolution failures. Your network may differ; verify with logs and connectivity tests. |

The verified recovery path is to set proxy variables with a carefully
scoped `NO_PROXY` exclusion list that keeps Feishu/Lark traffic bypassing
the proxy in this WSL setup, while other traffic such as Codex's OpenAI
calls routes through the proxy.

---

## Working Proxy Configuration

```bash
export HTTP_PROXY="http://your-proxy-host:port"
export HTTPS_PROXY="http://your-proxy-host:port"
export ALL_PROXY="http://your-proxy-host:port"
export http_proxy="$HTTP_PROXY"
export https_proxy="$HTTPS_PROXY"
export all_proxy="$ALL_PROXY"

export NO_PROXY="localhost,127.0.0.1,::1,open.feishu.cn,*.feishu.cn,open.larksuite.com,*.larksuite.com"
export no_proxy="$NO_PROXY"
```

**Explanation:**

- `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY` — Route all traffic through
  the proxy by default. This allows Codex to reach the OpenAI API.
- `NO_PROXY` — Exclude Feishu/Lark API domains, plus localhost, for the
  verified WSL setup. The wildcards `*.feishu.cn` and `*.larksuite.com`
  cover subdomains such as `internal-api.feishu.cn` and `app.larksuite.com`.
  If your network requires Feishu/Lark to use a proxy, do not copy this
  value blindly; verify against your own logs.
- Lowercase variants (`http_proxy`, `https_proxy`, `all_proxy`,
  `no_proxy`) — Many tools (curl, Node.js `node-fetch`) respect the
  lowercase forms. Set both to be safe.

---

## Diagnosis Commands

Run these in order to confirm the issue:

### Check Codex standalone connectivity

```bash
codex doctor
```

If this passes in your interactive shell but symptoms persist with the
bridge daemon, the daemon is missing proxy variables.

### Check bridge daemon status

```bash
lark-channel-bridge ps
lark-channel-bridge status --profile codex
```

Look for the process state and any error flags.

### Inspect daemon logs

```bash
tail -n 200 /path/to/daemon/stdout.log
tail -n 200 /path/to/daemon/stderr.log
```

Replace `/path/to/daemon/` with the actual log directory for your bridge
installation. Look for the error strings listed under
[Symptoms](#symptoms) above.

### Check the running daemon's environment

```bash
# Find the daemon PID first
lark-channel-bridge ps --profile codex

# Then inspect its environment
tr '\0' '\n' < /proc/<PID>/environ | grep -Ei 'HTTP_PROXY|HTTPS_PROXY|ALL_PROXY|NO_PROXY'
```

Replace `<PID>` with the actual process ID. If this command produces no
output, the daemon was started without proxy variables — confirming the
root cause.

---

## Recovery Path: Foreground Mode (Diagnostic Workaround)

If you confirmed the daemon is missing proxy variables, use foreground
mode as a temporary workaround:

### Step 1 — Stop the daemon

```bash
lark-channel-bridge stop --profile codex
```

### Step 2 — Set proxy variables in your current shell

```bash
export HTTP_PROXY="http://your-proxy-host:port"
export HTTPS_PROXY="http://your-proxy-host:port"
export ALL_PROXY="http://your-proxy-host:port"
export http_proxy="$HTTP_PROXY"
export https_proxy="$HTTPS_PROXY"
export all_proxy="$ALL_PROXY"

export NO_PROXY="localhost,127.0.0.1,::1,open.feishu.cn,*.feishu.cn,open.larksuite.com,*.larksuite.com"
export no_proxy="$NO_PROXY"
```

Replace `your-proxy-host:port` with your actual proxy address.

### Step 3 — Start the bridge in foreground mode

```bash
lark-channel-bridge run --profile codex
```

This starts the bridge in the foreground and inherits your shell's
environment, including the proxy variables you just exported.

### Step 4 — Test from Feishu

Send a message to your bot:

> ping

If everything is working, the bot will reply. The bridge log should show
no errors.

---

## Important: Foreground Mode Limitations

Foreground mode is **not** a permanent solution. As soon as you close the
terminal, the bridge process terminates and your bot goes offline.

Use foreground mode only for:

- **Diagnosis** — Confirming that proxy variables fix the issue.
- **Short-term use** — Keeping the bridge alive in a `tmux` or `screen`
  session while you work on the permanent fix.

---

## Where to Log This Issue

When you hit this problem, note the following in your issue report or
troubleshooting log:

| Item | Value |
|------|-------|
| Environment | WSL 2 (or your OS) |
| Proxy type | HTTP / SOCKS5 / corporate PAC |
| Proxy host:port | (redact credentials) |
| `codex doctor` result | Pass / Fail |
| Daemon environment has proxy vars? | Yes / No (from `tr '\0' '\n' < /proc/<PID>/environ`) |
| Error message in daemon logs | (copy the exact error) |
| Foreground mode works? | Yes / No |

---

## Next Step: Persistent Daemon Environment

The permanent fix is to make the OS-managed daemon inherit the proxy and
`NO_PROXY` variables at start time. This is typically done through one of
the following mechanisms:

- **systemd** — Add `Environment=` or `EnvironmentFile=` directives to the
  service unit.
- **launchd** (macOS) — Add `EnvironmentVariables` to the plist.
- **Docker** — Pass `--env` flags or use an `env_file` in
  `docker-compose.yml`.
- **WSL init scripts** — Export the variables in `~/.bashrc` and ensure
  the daemon manager reads the user environment before spawning the
  bridge process.

This document does not provide the implementation for these yet. It will
be addressed in a future release. For now, use the foreground-mode
diagnostic path described above to confirm the proxy configuration is
correct.
