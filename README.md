# codex-lark-starter

<div align="center">

**The fastest way to put an AI assistant in your Feishu or Lark workspace.**

Connect **Feishu / Lark** → **lark-channel-bridge** → **Codex CLI** → **OpenAI**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![ShellCheck](https://img.shields.io/badge/shellcheck-passing-brightgreen)](.github/workflows/shellcheck.yml)

<!-- Screenshot placeholder: assets/screenshot-channel.png -->

</div>

---

## What is this?

A **GitHub Starter Kit** that gives you everything you need to run an
AI-powered assistant inside a Feishu or Lark channel — documentation,
install scripts, example configs, shell tooling, and step-by-step guides.

**This is NOT an npm package.**  There is no build step, no TypeScript
compilation, and no `node_modules` to manage.  You clone it, read the
docs, run the install scripts, configure your credentials, and you are
done.

---

## Who is this for?

| Role | What you get |
|------|-------------|
| **Developer** setting up a team AI bot | Working shell scripts, architecture docs, config templates |
| **Engineering manager** exploring AI integration | Architecture overview, roadmap, design rationale |
| **DevOps / Platform engineer** | WSL / Linux / macOS install scripts, troubleshooting guide |
| **Open-source contributor** | CONTRIBUTING.md, handoff template, code of conduct |

---

## Architecture

```
┌──────────────┐     ┌─────────────────────┐     ┌───────────┐     ┌──────────┐
│  Feishu/Lark │────▶│ lark-channel-bridge │────▶│ Codex CLI │────▶│  OpenAI  │
│   (channel)  │◀────│     (WebSocket)      │◀────│  (agent)  │◀────│   (API)  │
└──────────────┘     └─────────────────────┘     └───────────┘     └──────────┘
```

Detailed architecture diagrams are in
[assets/architecture.svg](assets/architecture.svg) and
[docs/architecture.md](docs/architecture.md).

---

## Features

- **Plug-and-play shell scripts** — Start, stop, restart, and monitor the
  bridge with a single command.
- **Platform-agnostic installers** — WSL 2, bare-metal Linux, and macOS
  are all supported.
- **Production-ready configuration** — Rate limiting, concurrency,
  timeouts, and retry logic are built into the config schema.
- **Security-first defaults** — Bridge binds to loopback, credentials are
  never written to un-gitignored files, HMAC verification is enforced.
- **Comprehensive documentation** — Architecture, quick-start,
  troubleshooting, FAQ, design principles, and development roadmap.
- **CI-verified shell scripts** — Every `.sh` file passes `shellcheck`
  automatically via GitHub Actions.

---

## Quick Start

```bash
# 1. Clone this kit
git clone https://github.com/<your-org>/codex-lark-starter.git
cd codex-lark-starter

# 2. Run the platform installer
./install/install-system.sh

# 3. Install Node.js and Codex CLI
./install/install-node.sh
./install/install-codex.sh

# 4. Configure your credentials
cp examples/config.example.json config.json
# Edit config.json with your Feishu App ID, App Secret, and OpenAI API key

# 5. Start the bridge
./scripts/codex-bridge.sh start

# 6. Send a message to your bot in Feishu/Lark
```

For a detailed walkthrough, see [docs/quick-start.md](docs/quick-start.md).

---

## Repository Structure

```
.
├── README.md                       ← You are here
├── LICENSE                         ← MIT
├── CHANGELOG.md                    ← Release history
├── SECURITY.md                     ← Vulnerability reporting
├── CONTRIBUTING.md                 ← How to contribute
├── CODE_OF_CONDUCT.md              ← Community standards
│
├── docs/
│   ├── architecture.md             ← System design and data flow
│   ├── installation.md             ← Per-platform install guide
│   ├── quick-start.md              ← 15-minute walkthrough
│   ├── troubleshooting.md          ← Common issues and fixes
│   ├── faq.md                      ← Frequently asked questions
│   ├── design-principles.md        ← Why decisions were made
│   ├── development-roadmap.md      ← What we plan to build
│   ├── release-process.md          ← How releases are tagged
│   └── handoff-template.md         ← Contributor handoff checklist
│
├── scripts/
│   ├── codex-bridge.sh             ← Lifecycle manager (start/stop/restart/status/logs)
│   └── detect-host-ip.sh           ← WSL ↔ Windows host IP detection
│
├── install/
│   ├── install-system.sh           ← Base system packages
│   ├── install-node.sh             ← Node.js 20 LTS via nvm
│   ├── install-codex.sh            ← Codex CLI binary
│   └── install-bridge.sh           ← Bridge symlink + validation
│
├── examples/
│   ├── config.example.json         ← Feishu + OpenAI config template
│   ├── workspace.example.json      ← Codex workspace template
│   └── profile.example.json        ← Codex user profile template
│
├── assets/
│   ├── README-assets.md            ← Asset inventory and guidelines
│   └── architecture.svg            ← Full architecture diagram
│
└── .github/
    └── workflows/
        ├── markdown.yml            ← Lint all .md files
        └── shellcheck.yml          ← Lint all .sh files
```

---

## Prerequisites

| Component | Minimum Version | Purpose |
|-----------|----------------|---------|
| Node.js   | 20 LTS         | Bridge runtime |
| Codex CLI | latest         | AI agent CLI |
| Feishu / Lark Bot | —        | Channel integration |
| OpenAI API key | —          | Model inference |

### Supported Environments

| Platform | Status |
|----------|--------|
| Linux (x86_64, aarch64) | Primary target, fully tested |
| WSL 2 (Windows) | Fully supported |
| macOS (Apple Silicon / Intel) | Tested |

---

## Installation

| Platform | Guide |
|----------|-------|
| WSL 2    | [install-system.sh](install/install-system.sh) + [installation.md](docs/installation.md) |
| Linux    | [docs/installation.md](docs/installation.md) |
| macOS    | [docs/installation.md](docs/installation.md) |

---

## Configuration

Copy the example and fill in your credentials:

```bash
cp examples/config.example.json config.json
```

Required fields:

```json
{
  "lark": {
    "appId": "<your-app-id>",
    "appSecret": "<your-app-secret>"
  },
  "openai": {
    "apiKey": "<your-api-key>"
  }
}
```

Full schema and defaults: [examples/config.example.json](examples/config.example.json).

---

## Documentation

| Document | Audience |
|----------|----------|
| [Quick Start](docs/quick-start.md) | Everyone |
| [Installation](docs/installation.md) | Developers, DevOps |
| [Architecture](docs/architecture.md) | Developers, architects |
| [Troubleshooting](docs/troubleshooting.md) | Everyone |
| [FAQ](docs/faq.md) | Everyone |
| [Design Principles](docs/design-principles.md) | Contributors |
| [Development Roadmap](docs/development-roadmap.md) | Contributors, managers |
| [Release Process](docs/release-process.md) | Maintainers |
| [Handoff Template](docs/handoff-template.md) | Contributors |

---

## Roadmap

See [docs/development-roadmap.md](docs/development-roadmap.md) for the
full plan.  Highlights:

- [x] Shell-script lifecycle manager (`codex-bridge.sh`)
- [x] Cross-platform install scripts
- [x] Complete documentation set
- [ ] `Dockerfile` and `docker-compose.yml`
- [ ] systemd service unit
- [ ] Health-check endpoint in bridge
- [ ] Telemetry / observability guide
- [ ] Multi-language docs (zh-CN)

---

## Contributing

This project follows a fork-and-PR workflow.  Start here:

1. Read [CONTRIBUTING.md](CONTRIBUTING.md)
2. Read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
3. Read [docs/design-principles.md](docs/design-principles.md)
4. Use [docs/handoff-template.md](docs/handoff-template.md) when
   transferring work

---

## Security

See [SECURITY.md](SECURITY.md) for our vulnerability reporting process and
supported versions.

---

## License

MIT — see [LICENSE](LICENSE).
