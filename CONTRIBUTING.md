# Contributing to codex-lark-starter

Thank you for your interest in contributing.  This document tells you how.

---

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).
Please read it before participating.

---

## What Can I Contribute?

| Area | Examples |
|------|----------|
| **Documentation** | Fix typos, improve clarity, add missing information, translate |
| **Shell scripts** | Improve portability, add features, fix bugs, write tests |
| **Config examples** | Add use-case templates, improve defaults |
| **Install scripts** | Add support for new platforms or package managers |
| **GitHub workflows** | Add linting, testing, or automation |
| **Architecture** | Propose improvements or alternatives |

---

## Getting Started

### 1. Fork and Clone

```bash
git clone https://github.com/<your-username>/codex-lark-starter.git
cd codex-lark-starter
```

### 2. Create a Branch

Use a descriptive branch name:

- `docs/fix-typo-in-quick-start`
- `feat/add-fedora-install`
- `fix/shellcheck-warning-in-bridge-script`

### 3. Make Your Changes

Follow these guidelines:

- **Shell scripts**: Must pass `shellcheck`.  Use `set -euo pipefail`.
  Prefer portable constructs over GNU-isms.
- **Markdown**: Wrap prose at 80 characters.  Use reference-style links
  for repeated URLs.
- **JSON**: Indent with 2 spaces.  Use `_comment` keys for inline
  documentation (this project uses them intentionally).
- **Commit messages**: Use imperative mood.  Keep the first line under 72
  characters.  Example: `docs: add Fedora install instructions`

### 4. Run the Linters

Before opening a PR, run the linters locally:

```bash
# Shell scripts
shellcheck scripts/*.sh install/*.sh

# Markdown (requires markdownlint-cli)
markdownlint '**/*.md'
```

These same checks run in CI and must pass.

### 5. Open a Pull Request

- Fill in the PR template (once it exists).
- Link any related issues.
- Assign a reviewer if you know who should look at it.
- Be patient — maintainers are volunteers.

---

## Pull Request Checklist

Before submitting, confirm:

- [ ] Shell scripts pass `shellcheck` with zero errors and zero warnings.
- [ ] Markdown passes `markdownlint`.
- [ ] No secrets or credentials are committed.
- [ ] No machine-specific paths are hardcoded.
- [ ] Documentation matches implementation.
- [ ] `CHANGELOG.md` is updated under `## [Unreleased]`.
- [ ] Commit history is clean (squash WIP commits).

---

## Review Process

1. A maintainer will triage your PR within one week.
2. Feedback may request changes.  This is normal.
3. Once approved, a maintainer will merge.
4. Your contribution will be acknowledged in the release notes.

---

## Development Environment

You do not need a special development environment to contribute to this
project.  A text editor and a shell are sufficient.

Optional tools that help:

| Tool | Purpose | Install |
|------|---------|---------|
| `shellcheck` | Lint shell scripts | `apt install shellcheck` / `brew install shellcheck` |
| `markdownlint` | Lint markdown | `npm install -g markdownlint-cli` |
| `shfmt` | Format shell scripts | `apt install shfmt` / `brew install shfmt` |

---

## Design Principles

Before proposing a significant change, read
[docs/design-principles.md](docs/design-principles.md) to understand the
project's philosophy and constraints.
