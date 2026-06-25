# Quick Start

Get the bridge running in under 5 minutes.

---

## 1. Gather Credentials

You need three things:

| Credential | Where to Get It |
|-----------|-----------------|
| Feishu App ID | [Feishu Developer Console](https://open.feishu.cn/app) → App Settings |
| Feishu App Secret | Same page, under "Credentials" |
| OpenAI API Key | [OpenAI Platform](https://platform.openai.com/api-keys) |

---

## 2. Clone and Install

```bash
git clone <repo-url> codex-lark-starter
cd codex-lark-starter

# Run all installers (Linux / WSL)
for script in install/install-*.sh; do
  chmod +x "$script" && "$script"
done
```

---

## 3. Configure

```bash
cp examples/config.example.json config.json
```

Edit `config.json` and fill in the three credentials:

```json
{
  "lark": {
    "appId": "cli_xxxxxxxxxxxx",
    "appSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxx"
  },
  "openai": {
    "apiKey": "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  }
}
```

The other fields have sensible defaults and can be left as-is.

---

## 4. Start the Bridge

```bash
./scripts/codex-bridge.sh start
```

Expected output:

```text
[bridge] Starting ...
[bridge] PID: 12345
[bridge] Listening on 127.0.0.1:8765
[bridge] Ready.
```

---

## 5. Test in Feishu

Go to your Feishu workspace, find the bot (by the name you set in the
Developer Console), and send a message:

> Hello, what can you do?

You should receive a reply within a few seconds.

---

## 6. Stop the Bridge

```bash
./scripts/codex-bridge.sh stop
```

---

## Next Steps

- Read [architecture.md](architecture.md) to understand how the pieces fit
  together.
- Read [troubleshooting.md](troubleshooting.md) if something goes wrong.
- Read [faq.md](faq.md) for common questions.
