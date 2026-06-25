# FAQ

---

## What is the difference between Feishu and Lark?

Feishu (飞书) is the domestic Chinese version. Lark is the international
version. They share the same API surface, so `codex-lark-starter` works
with both. Set `"platform": "feishu"` or `"platform": "lark"` in
`config.json` to switch API base URLs.

---

## Does this require an internet-accessible server?

Yes. Feishu / Lark servers need to reach your bridge via an HTTPS endpoint
(for webhook mode) or the bridge must initiate a WebSocket connection to
Feishu's servers (bot WebSocket mode — recommended for production).

For local development, use a tunneling service such as **ngrok**,
**Cloudflare Tunnel**, or **frp**.

---

## Can I use models other than OpenAI?

The bridge is model-agnostic. Codex CLI handles the model routing. As
long as Codex CLI supports the provider, it will work. Check the Codex
CLI documentation for provider configuration.

---

## How do I add custom tool calls?

Codex CLI supports MCP (Model Context Protocol) servers and custom tools.
Define them in `workspace.example.json` (or your own `workspace.json`).
The bridge passes the workspace configuration to Codex CLI at startup.

See [examples/workspace.example.json](../examples/workspace.example.json).

---

## How many concurrent conversations can one bridge handle?

Approximately 10–50, depending on:
- OpenAI model latency
- Complexity of prompts
- Available CPU / memory on the host

For higher concurrency, run multiple bridge instances behind a message
queue. See [architecture.md](architecture.md#scaling).

---

## Is message content encrypted at rest?

By default, no. The bridge does not persist message content to disk. Only
request metadata (message ID, timestamp, chat ID) is logged. User message
text is redacted from logs.

If you need audit logging with content, set `"logContent": true` in
`config.json` — but be aware this will write plaintext messages to disk.

---

## How do I update the bridge?

```bash
git pull origin main
./scripts/codex-bridge.sh restart
```

---

## Can I run this in Docker?

A `Dockerfile` is planned for a future release. For now, run the install
scripts inside your container:

```dockerfile
FROM node:20-slim
COPY . /app
WORKDIR /app
RUN ./install/install-bridge.sh
CMD ["./scripts/codex-bridge.sh", "start"]
```

---

## What permissions does the Lark bot need?

| Scope | Purpose |
|-------|---------|
| `im:message` | Read messages from channels |
| `im:message:send_as_bot` | Post replies |
| `im:chat` | Read chat metadata |
| `im:chat:readonly` | List group members (optional) |

---

## How do I contribute?

See [handoff-template.md](handoff-template.md) for the contributor
checklist and workflow.
