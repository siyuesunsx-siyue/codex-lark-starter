# Development Roadmap

This document tracks planned work.  Items are not commitments — they
reflect the maintainers' current priorities.  Contributions are welcome
for any item.

---

## v0.1 — Foundation (current)

- [x] Repository scaffold
- [x] `codex-bridge.sh` lifecycle manager
- [x] `detect-host-ip.sh` WSL IP detection
- [x] Platform install scripts (system, Node.js, Codex CLI, bridge)
- [x] Example config files (config, workspace, profile)
- [x] Complete documentation set
- [x] GitHub community files (SECURITY, CONTRIBUTING, CODE_OF_CONDUCT)
- [x] CI workflows (markdownlint, shellcheck)
- [x] Design principles document

---

## v0.2 — Developer Experience

- [ ] `.editorconfig` for consistent formatting
- [ ] Issue templates (bug report, feature request)
- [ ] PR template
- [ ] `CODEOWNERS` file
- [ ] `markdownlint` configuration file (`.markdownlint.json`)
- [ ] `shellcheck` configuration file (`.shellcheckrc`)
- [ ] Pre-commit hook for linting
- [ ] Badge updates for CI status

---

## v0.3 — Production Readiness

- [ ] `Dockerfile` and `docker-compose.yml`
- [ ] systemd service unit (`install/codex-bridge.service`)
- [ ] Health-check endpoint specification
- [ ] Log rotation configuration
- [ ] Monitoring and observability guide
- [ ] Benchmark document (messages/sec, latency percentiles)

---

## v0.4 — Platform Expansion

- [ ] Fedora / RHEL install script variant
- [ ] Arch Linux install script variant
- [ ] Alpine Linux / BusyBox considerations
- [ ] macOS Homebrew formula
- [ ] Windows (native PowerShell) notes

---

## v0.5 — Ecosystem

- [ ] Example MCP server configuration
- [ ] Custom tool-call walkthrough
- [ ] Multi-bot configuration guide
- [ ] Channel routing rules documentation

---

## v1.0 — Stable

- [ ] Semantic versioning policy in CHANGELOG.md
- [ ] Release automation (GitHub Actions release workflow)
- [ ] Multi-language documentation (zh-CN)
- [ ] Community showcase (real-world deployments)

---

## Backlog

Items under consideration but not yet prioritized:

- Terraform module for Lark app provisioning
- Helm chart for Kubernetes deployment
- Prometheus metrics endpoint in bridge
- Rate-limit dashboard (Grafana)
- Web UI for configuration management
- Native Lark Bot SDK wrapper (thin TypeScript library)
- `npx create-codex-lark-starter` scaffolding command
