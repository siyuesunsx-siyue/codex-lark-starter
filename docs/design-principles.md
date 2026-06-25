# Design Principles

This document explains the philosophy and constraints behind
`codex-lark-starter`.  Contributors should read this before proposing
significant changes.

---

## 1. Documentation First

This is a **documentation-first** project.  The primary deliverable is the
set of guides, references, and runbooks.  Code (shell scripts, config
examples) exists to support the documentation, not the other way around.

**Rule:** Every new feature or change must include documentation.
Undocumented features are bugs.

---

## 2. No Build Step

Users should be able to clone this repository and use it immediately.
There is no `package.json`, no TypeScript compilation, no `node_modules`,
and no build pipeline.

**Why:** A starter kit that requires a build step to read is a failure.  A
user who cannot `cat README.md` without installing dependencies has
already been let down.

**Rule:** All files in this repository are plaintext and
human-readable without tooling.

---

## 3. Shell Scripts Must Be Portable

Scripts must work on:

- Ubuntu / Debian (apt)
- macOS (brew, BSD userland)
- WSL 2

**Rule:** Avoid GNU-isms when a POSIX or BSD-compatible alternative
exists.  When a GNU feature is unavoidable, gate it behind a platform
check and provide a fallback.

| Avoid | Prefer |
|-------|--------|
| `grep -oP` | `sed` or `awk` |
| `ping -W` | `ping -c` with platform check |
| `ip route` | detect and fall back to `route -n` |
| `/proc/version` | `uname -r` |

---

## 4. Security by Default

- Bridge binds to `127.0.0.1`, not `0.0.0.0`.
- Credentials are never committed or hardcoded in scripts.
- All shell scripts use `set -euo pipefail`.
- `config.json` is in `.gitignore`.

**Rule:** A fresh clone, with `config.json` configured, must not expose
any credentials or open any public-facing ports.

---

## 5. Gradual Complexity

The README is a 5-paragraph summary.  The Quick Start is a 6-step
checklist.  The installation guide is per-platform.  The architecture doc
is a full technical specification.

**Rule:** Every document must be self-contained for its audience.  A
beginner should not need to read the architecture doc to run the bridge.
An architect should not need to read the troubleshooting guide to
understand the data flow.

---

## 6. No Vendor Lock-In

This project uses Codex CLI and OpenAI, but the architecture diagrams and
config schemas are provider-agnostic.  The bridge is designed to work with
any LLM backend that Codex CLI supports.

**Rule:** Do not bake OpenAI-specific assumptions into the architecture
docs or shell scripts.  Config examples may show OpenAI as the default
(that is what most users need), but the schema must support alternative
providers.

---

## 7. Beginner-Friendly Error Messages

Every shell script must:

- Print a human-readable error message when it fails.
- Suggest the next action ("Run: ./install/install-node.sh").
- Not crash silently.

**Rule:** A first-time user who runs a script and sees an error must know
what went wrong and what to do about it within 10 seconds of reading the
output.

---

## 8. Config Over Code

Configuration is done via JSON files, not environment variables, not
command-line flags, and not hardcoded defaults in scripts.

**Why:** JSON is visible, diffable, and documentable.  Environment
variables are invisible until they fail.  Command-line flags are
ephemeral.

**Rule:** All tunable behavior must flow through `config.json` (or
`workspace.json` / `profile.json` for Codex-specific settings).

---

## 9. One Script, One Responsibility

- `install-system.sh` → system packages only.
- `install-node.sh` → Node.js only.
- `install-codex.sh` → Codex CLI only.
- `install-bridge.sh` → bridge validation and symlinks only.

**Rule:** A script must have a single, clearly stated purpose.  If a
script does two things, split it.

---

## 10. CI-Verified Quality

Every `.sh` file must pass `shellcheck`.  Every `.md` file must pass
`markdownlint`.  These checks run in GitHub Actions on every push and PR.

**Rule:** A PR that fails CI will not be merged.  Run the linters locally
before pushing.
