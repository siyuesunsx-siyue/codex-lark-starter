# Architecture

## High-Level Overview

```text
┌──────────────────────────────────────────────────────────────────────┐
│                           Feishu / Lark                              │
│                                                                      │
│  ┌──────────┐     ┌──────────────┐     ┌──────────────────────────┐ │
│  │  Channel │────▶│  Event       │────▶│  Outgoing Webhook /      │ │
│  │  Message │     │  Subscription│     │  Bot WebSocket           │ │
│  └──────────┘     └──────────────┘     └───────────┬──────────────┘ │
└────────────────────────────────────────────────────┼────────────────┘
                                                     │
                                                     ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      lark-channel-bridge                             │
│                                                                      │
│  ┌────────────┐     ┌────────────┐     ┌──────────────────────────┐ │
│  │  Ingestion │────▶│  Queue     │────▶│  Dispatch Engine         │ │
│  │  Handler   │     │  (in-mem)  │     │  (round-robin to agents) │ │
│  └────────────┘     └────────────┘     └───────────┬──────────────┘ │
│                                                    │                 │
│  ┌────────────┐     ┌────────────┐     ┌───────────┴──────────────┐ │
│  │  Response  │◀────│  Formatter │◀────│  Agent Process Manager   │ │
│  │  Publisher │     │  (Markdown │     │  (spawn / kill / health) │ │
│  │            │     │   → Feishu)│     └──────────────────────────┘ │
│  └────────────┘     └────────────┘                                   │
└──────────────────────────────────────────────────────────────────────┘
                                                     │
                                                     ▼
┌──────────────────────────────────────────────────────────────────────┐
│                          Codex CLI                                   │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  JSON-lines protocol over stdin / stdout                       │ │
│  │                                                                │ │
│  │  → {"role":"user","content":"..."}                              │ │
│  │  ← {"role":"assistant","content":"...","tool_calls":[...]}     │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                     │               │
│                                                     ▼               │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  OpenAI API (model routing, token accounting, retry)           │ │
│  └────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Feishu / Lark Feeds

Messages arrive via one of two channels:

| Channel | Protocol | Use Case |
|---------|----------|----------|
| Outgoing Webhook | HTTPS POST | Quick setup, single-bot |
| Bot WebSocket | WSS (persistent) | Production, multi-bot, low-latency |

In both cases the bridge receives a JSON payload containing:

- `message_id` — unique per message
- `chat_id` — conversation identifier
- `sender_id` / `sender_name` — who sent it
- `text` — the raw message body
- `timestamp` — server-time of receipt

### 2. lark-channel-bridge

The bridge is a single Node.js process responsible for:

- **Authentication** — refreshes Feishu tenant access tokens periodically
  using the app credentials.
- **Ingestion** — normalizes webhook and WebSocket events into a uniform
  internal message envelope.
- **Queue** — holds incoming messages in an in-memory FIFO, ensuring one
  agent handles one message at a time (configurable concurrency).
- **Dispatch** — routes messages to Codex CLI worker processes.
- **Response** — takes the Codex output, splits long replies into Feishu
  card messages (respecting the 30 KB API limit), and posts them back.

**Lifecycle states:**

```text
[stopped] ──start──▶ [starting] ──ready──▶ [running]
    ▲                    │                     │
    │                    ▼                     ▼
    └──stop── [stopping] ◀──crash── [error] ◀─┤
```

Managed by `codex-bridge.sh`.

### 3. Codex CLI

Codex CLI runs as a long-lived subprocess. Communication happens over
stdin/stdout using newline-delimited JSON (JSON-lines). Each line is one
complete message.

**Protocol — request (bridge → Codex)**

```json
{
  "id": "req-001",
  "role": "user",
  "content": "Summarize this bug report: ...",
  "context": {
    "chat_id": "oc_xxxx",
    "sender": "user@example.com"
  }
}
```

**Protocol — response (Codex → bridge)**

```json
{
  "id": "req-001",
  "role": "assistant",
  "content": "Here is a summary: ..."
}
```

Tool-call streaming is supported via partial chunks:

```json
{
  "id": "req-001",
  "role": "assistant",
  "partial": true,
  "chunk": "Here is "
}
```

The bridge reassembles partial chunks before delivering the final response
to the user.

### 4. OpenAI

Codex CLI handles all OpenAI API interactions. The bridge is agnostic to
the model being used. Supported configuration values control:

- `model` — e.g. `gpt-4o`, `gpt-4o-mini`
- `max_tokens` — output token cap
- `temperature` — creativity parameter

---

## Data Flow (End-to-End)

```text
   User              Lark Server          Bridge              Codex             OpenAI
    │                    │                   │                   │                  │
    │  "hello world"     │                   │                   │                  │
    │───────────────────▶│                   │                   │                  │
    │                    │  POST /webhook    │                   │                  │
    │                    │──────────────────▶│                   │                  │
    │                    │                   │  JSON-lines msg   │                  │
    │                    │                   │──────────────────▶│                  │
    │                    │                   │                   │  POST /chat      │
    │                    │                   │                   │─────────────────▶│
    │                    │                   │                   │◀─────────────────│
    │                    │                   │◀──────────────────│                  │
    │                    │◀──────────────────│                   │                  │
    │◀───────────────────│                   │                   │                  │
    │  "Hello! How can   │                   │                   │                  │
    │   I help?"         │                   │                   │                  │
```

---

## Security Model

| Concern | Mitigation |
|---------|------------|
| App Secret exposure | Never written to disk; sourced from env vars or secrets manager |
| Message integrity | Feishu's HMAC-SHA256 signature verification is enforced |
| Network isolation | Bridge binds to `127.0.0.1` by default |
| Token rotation | Tenant access tokens auto-refreshed before expiry |
| Audit log | Every request/response pair is logged with timestamp and message ID (user content is redacted by default) |

---

## Scaling

A single bridge process can handle approximately **10–50 concurrent
conversations** depending on model latency. For higher throughput:

1. Increase `concurrency` in `config.json`.
2. Run multiple bridge instances behind a message-queue (Redis / RabbitMQ).
3. Shard by `chat_id` to maintain conversation context affinity.
