# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

- Initial project scaffold.
- `codex-bridge.sh` — bridge lifecycle manager (start / stop / restart / status / logs).
- `detect-host-ip.sh` — WSL ↔ Windows host IP detection with macOS support.
- Platform install scripts: `install-system.sh`, `install-node.sh`, `install-codex.sh`, `install-bridge.sh`.
- Example configuration files (`config`, `workspace`, `profile`).
- Full documentation set: architecture, installation, quick-start, troubleshooting, FAQ, design principles, development roadmap, release process, contributor handoff template.
- GitHub community files: `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`.
- CI workflows: `markdown.yml` (markdownlint), `shellcheck.yml` (shellcheck).
- `assets/` directory with `architecture.svg` system diagram.
- `REVIEW.md` — comprehensive code review document.

### Changed

- Renamed `install-wsl.sh` → `install-system.sh` with broader platform support (apt + brew).
- Improved shell script portability — removed GNU-isms from `detect-host-ip.sh`, added macOS fallbacks.
- Improved shell script help output — all scripts now support `-h` / `--help`.
- Improved `install-bridge.sh` — now a validator (no npm install), consistent with starter-kit identity.

### Fixed

- Replaced `grep -oP` (GNU-only) with portable `sed` in `detect-host-ip.sh`.
- Added platform-aware ping timeout flag in `detect-host-ip.sh`.
- Added retry loop in `codex-bridge.sh` start command instead of single `sleep 1`.
- Added `_require_node` check to `codex-bridge.sh`.

---

## [0.1.0] — Initial Scaffold

### Added

- Initial project scaffold.
- `codex-bridge.sh` — main bridge lifecycle manager.
- `detect-host-ip.sh` — host IP detection for WSL ↔ Windows networking.
- Platform install scripts (`install-wsl.sh`, `install-node.sh`, `install-codex.sh`, `install-bridge.sh`).
- Example configuration files (`config`, `workspace`, `profile`).
- Full documentation set: architecture, installation, quick-start, troubleshooting, FAQ, and contributor handoff template.
