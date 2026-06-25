# Troubleshooting

Common issues and how to resolve them.

---

## Bridge fails to start

### Symptom

```text
[bridge] ERROR: cannot bind to 127.0.0.1:8765 — address already in use
```

### Cause

Another process (possibly a previous bridge instance) is holding the port.

### Fix

```bash
# Find the process
lsof -i :8765

# Kill it
kill -9 <PID>

# Retry
./scripts/codex-bridge.sh start
```

---

## "Invalid App ID or App Secret"

### Symptom

The bridge logs:

```text
[ingestion] ERROR: Lark API returned 400 — invalid app_id
```

### Fix

1. Go to the [Feishu Developer Console](https://open.feishu.cn/app).
2. Open your app → **Credentials**.
3. Copy the **App ID** and **App Secret** exactly — no extra spaces.
4. Paste them into `config.json`.

---

## OpenAI returns 401 / 429

### Symptom

```text
[agent] ERROR: OpenAI API returned 401 — invalid API key
```
or
```text
[agent] ERROR: OpenAI API returned 429 — rate limit exceeded
```

### Fix

- **401**: Verify the API key in `config.json`. Generate a new one at
  [platform.openai.com/api-keys](https://platform.openai.com/api-keys).
- **429**: You have exceeded your rate limit. Wait a few minutes, or
  upgrade your OpenAI plan. You can also increase `retryDelay` in
  `config.json`.

---

## Bot does not reply in Feishu

### Symptom

The bridge is running (no errors in logs) but messages go unanswered.

### Fix

1. **Check event subscription URL** — In the Feishu Developer Console,
   verify the "Event Subscription" URL points to your bridge's public
   endpoint.
2. **Verify the bot is in the channel** — The bot must be explicitly added
   to the group chat or channel.
3. **Check permissions** — The app needs the `im:message` and
   `im:message:send_as_bot` scopes.
4. **Look for silent failures** — Check `logs/bridge.log` for any
   ingestion errors.

---

## "Node.js version mismatch"

### Symptom

```text
[install] ERROR: Node.js >= 20.0.0 required, found v18.x.x
```

### Fix

```bash
# Using nvm
nvm install 20
nvm use 20

# Or re-run the installer
./install/install-node.sh
```

---

## WSL: bridge cannot reach Lark API

### Symptom

DNS resolution or HTTP requests to `open.feishu.cn` fail.

### Fix

```bash
# Verify DNS
nslookup open.feishu.cn

# If it fails, reset WSL DNS
sudo rm /etc/resolv.conf
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'

# Test
curl -I https://open.feishu.cn
```

---

## Logs

All logs are written to `logs/`:

| File | Content |
|------|---------|
| `logs/bridge.log` | Bridge lifecycle and errors |
| `logs/agent.log`  | Codex CLI stdout/stderr |
| `logs/access.log` | Request/response metadata (user content redacted) |

Increase log verbosity by setting `"logLevel": "debug"` in `config.json`.
