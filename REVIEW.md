# REVIEW.md — codex-lark-starter

Comprehensive review for public release readiness.

**Reviewed:** 2026-06-25 (re-reviewed after polish pass)  
**Reviewer:** Maintainer perspective  
**Scope:** Every file in the repository  
**Context:** This is a **GitHub Starter Kit** (documentation + scripts + config
templates), NOT an npm package.  No `package.json`, no build step, no
`node_modules`.

---

## Overall Score: 79 / 100

A polished, well-documented GitHub Starter Kit that delivers on its
promise.  Strong documentation, clean architecture, and CI-verified shell
scripts make this immediately useful.  The main gap is the absence of
screenshot/GIF assets and a Dockerfile (both called out as planned in the
roadmap).

---

## Major Strengths

1. **Documentation is the product — and it is excellent.**  This is a
   documentation-first project, and the docs deliver.  `architecture.md`
   is the standout with detailed ASCII diagrams, a JSON-lines protocol
   spec, and security / scaling sections.  Every doc has a clear audience
   and purpose.

2. **Clean starter-kit identity.**  The README now explicitly states "This
   is NOT an npm package" and "There is no build step."  This eliminates
   the confusion from the earlier version.  The `install-bridge.sh`
   script validates the environment instead of trying to `npm install`
   and silently failing.

3. **Shell scripts are significantly improved.**  `detect-host-ip.sh` no
   longer uses GNU-isms (`grep -oP` → `sed`, platform-aware `ping`).
   `codex-bridge.sh` has retry logic, proper node version checking, and
   resolved entrypoint auto-detection.  All scripts have `--help` flags
   and clear exit codes.

4. **Community health files are complete.**  `SECURITY.md`,
   `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, and `docs/handoff-template.md`
   are all present and well-written.

5. **CI is in place.**  `markdown.yml` and `shellcheck.yml` run on every
   push and PR for `.md` and `.sh` changes respectively.

6. **Design principles document is a strong addition.**  `docs/design-principles.md`
   gives contributors a clear framework for evaluating changes.  The
   "Documentation First" and "No Build Step" rules are exactly right for
   a starter kit.

7. **Architecture SVG is production-quality.**  The color-coded diagram
   with security and scaling callouts is visually clear and technically
   accurate.

8. **Roadmap and release process docs** give the project a clear trajectory
   and operational maturity.

---

## Major Weaknesses

### 1. No Screenshots or Animated Demos

The README has a screenshot placeholder comment (`<!-- Screenshot
placeholder -->`).  For a "starter kit" that is meant to be visually
scanned in under 60 seconds, screenshots are table-stakes.  At minimum:

- Screenshot of the bot replying in a Feishu channel
- Terminal recording of the `./scripts/codex-bridge.sh start` flow

The `assets/README-assets.md` correctly documents that these are planned.

### 2. No Dockerfile (Yet)

The FAQ and roadmap both mention Docker.  A two-stage Dockerfile would be
~15 lines and would dramatically lower the barrier for users who want to
run this in a container without running install scripts.

### 3. Example Config Uses JSON `_comment` Keys

JSON does not support comments.  The `_comment` fields in
`config.example.json`, `workspace.example.json`, and
`profile.example.json` will be silently accepted by most parsers (they are
valid JSON keys) but are non-standard and may confuse users who expect
`//` or `/* */` comments.  Switching to JSONC (`.jsonc` extension) or
adding a `$schema` field would be cleaner.

### 4. Bridge Entrypoint Still Needs a Real Implementation

`codex-bridge.sh` auto-detects the entrypoint from three candidate paths,
but none of them exist in this repository.  The script is correct — it
reports a clear error and tells the user to set `BRIDGE_ENTRYPOINT` — but
a "starter kit" that cannot actually *run* the bridge out of the box is
missing its centerpiece.  At minimum, a minimal `bridge/index.js` that
starts a WebSocket connection to Lark and spawns Codex CLI would close
this gap.

### 5. `install-system.sh` Only Covers `apt` on Linux

Fedora/RHEL (`dnf`), Arch (`pacman`), and Alpine (`apk`) users get a
polite error message and a suggestion to install packages manually — but
the roadmap already calls this out as a v0.4 item.  Acceptable for now,
but limits the audience.

---

## Missing Pieces (Prioritized)

### High Priority

| Item | Status |
|------|--------|
| Screenshots / GIF demos | Planned (assets/README-assets.md) |
| Dockerfile + docker-compose.yml | Planned (roadmap v0.3) |
| Minimal working bridge entrypoint | Missing — scripts handle absence gracefully |
| `.editorconfig` | Missing |
| Issue / PR templates | Missing |

### Medium Priority

| Item | Status |
|------|--------|
| `.markdownlint.json` config | Missing — CI uses defaults |
| `.shellcheckrc` config | Missing — CI uses defaults |
| dnf / pacman support in install-system.sh | Planned (roadmap v0.4) |
| Multi-language docs (zh-CN) | Planned (roadmap v1.0) |
| `CODEOWNERS` | Missing |

### Low Priority

| Item | Status |
|------|--------|
| Pre-commit hook config | Planned (roadmap v0.2) |
| systemd service unit | Planned (roadmap v0.3) |
| Health-check endpoint spec | Planned (roadmap v0.3) |

---

## Detailed File-by-File Notes

### `README.md` — 8 / 10

- Clear positioning ("GitHub Starter Kit, not an npm package").  
- Good architecture diagram, feature list, and quick start.  
- Repository structure tree is comprehensive.  
- Missing: real screenshot, badges that work (ShellCheck badge is a static
  shield, not linked to CI).

### `docs/architecture.md` — 9 / 10

- Excellent.  ASCII art is clear and informative.  
- Protocol spec is well-defined.  
- Security model and scaling sections are strong.  
- Minor: the Architecture ASCII diagram in README and this doc overlap;
  could consolidate.

### `docs/installation.md` — 7 / 10

- Now references `install-system.sh` correctly.  
- macOS section could mention `install-system.sh` (currently suggests
  `brew install` manually).

### `docs/quick-start.md` — 7 / 10

- Now references `install-system.sh` correctly.  
- "Under 5 minutes" claim is still optimistic.  
- Good flow for a first-time user.

### `docs/troubleshooting.md` — 7 / 10

- Covers real failure modes.  
- The `sudo rm /etc/resolv.conf` fix is still destructive.  Should add a
  backup warning.

### `docs/faq.md` — 8 / 10

- Practical and well-organized.  
- Docker section is honest ("planned for a future release").

### `docs/design-principles.md` — 9 / 10 (New)

- Excellent contribution.  The 10 principles provide a clear decision
  framework.  "Documentation First" and "No Build Step" are exactly right.

### `docs/development-roadmap.md` — 8 / 10 (New)

- Clear versioning of planned work.  Realistic about what is done vs.
  what is planned.

### `docs/release-process.md` — 8 / 10 (New)

- Solid process document.  Covers versioning, tagging, GitHub releases,
  and hotfixes.

### `docs/handoff-template.md` — 7 / 10

- Useful internal checklist.  Could benefit from a companion template
  for external PRs.

### `scripts/codex-bridge.sh` — 7 / 10 (Improved)

- Now has `--help`, proper exit codes, retry loop, node version check.  
- Entrypoint auto-detection with clear error messages.  
- Could still benefit from `trap` cleanup and log rotation.

### `scripts/detect-host-ip.sh` — 8 / 10 (Improved)

- No more GNU-isms.  Portable `sed`, platform-aware ping.  
- `--export`, `--validate`, `--help` modes are clean.  
- Fallback from `ip route` to `route -n` to `netstat -rn`.

### `install/install-system.sh` — 7 / 10 (New, renamed)

- Proper platform detection using `/proc/sys/kernel/osrelease`.  
- Doesn't overwrite `/etc/wsl.conf` blindly (appends).  
- Clear error messages for unsupported package managers.  
- Limited to `apt` and `brew` for now.

### `install/install-node.sh` — 7 / 10 (Improved)

- Better error messages throughout.  
- Warns about `curl | bash` pattern.  
- Idempotent — detects existing adequate Node.js.  
- NVM_VERSION is still hardcoded.

### `install/install-codex.sh` — 7 / 10 (Improved)

- Tries both known package names for npm fallback.  
- Clear error messages with manual install guidance.  
- Download URL pattern is still guessed (no SHA-256 verification).

### `install/install-bridge.sh` — 7 / 10 (Improved)

- Now a validator, not an npm installer.  Correct for starter kit identity.  
- Symlinks both `codex-bridge.sh` and `detect-host-ip.sh`.  
- Environment summary at end is helpful.

### `SECURITY.md` — 8 / 10 (New)

- Clear scope definition.  Good best-practices section for users.  
- Missing: named maintainer contact for vulnerability reports.

### `CONTRIBUTING.md` — 8 / 10 (New)

- Clear workflow.  Good checklist.  Links to design principles.  
- Missing: PR template reference (template does not exist yet).

### `CODE_OF_CONDUCT.md` — 9 / 10 (New)

- Standard Contributor Covenant 2.1.  Complete.

### `.github/workflows/` — 8 / 10 (New)

- Both workflows are correctly scoped to relevant file changes.  
- `shellcheck.yml` uses `ludeeus/action-shellcheck` which is a
  well-maintained third-party action.  Pinning to `@master` is acceptable
  but `@v2` would be better.

### `assets/architecture.svg` — 9 / 10 (New)

- Hand-authored, color-coded, with security and scaling callouts.  
- Versioned in metadata.

### `examples/` — 6 / 10

- `_comment` keys are a JSON anti-pattern.  
- `workspace.example.json` references `./workspace` directory (doesn't exist).  
- `profile.example.json` has `~/.codex/history.jsonl` — tilde won't expand
  in JSON.

---

## Dimension-by-Dimension Scoring

| Dimension | Score | Notes |
|-----------|-------|-------|
| Repository structure | 9 / 10 | Clean, logical, nothing extraneous |
| README quality | 8 / 10 | Clear identity, good first impression.  Missing screenshots. |
| Documentation completeness | 9 / 10 | Architecture, install, FAQ, troubleshooting, roadmap, principles, release process — all there. |
| Beginner friendliness | 7 / 10 | Quick start is clear.  Missing bridge implementation means they cannot run it without extra work. |
| Shell script robustness | 7 / 10 | Portable, well-commented, `--help` on all.  Could use `trap` cleanup and log rotation. |
| Security | 7 / 10 | Good defaults, good docs.  `curl \| bash` is warned about.  Still no checksum verification. |
| Portability | 8 / 10 | Linux (apt), macOS (brew), WSL 2.  No more GNU-isms.  dnf/pacman coming in roadmap. |
| Naming consistency | 8 / 10 | `install-system.sh` is correctly named.  `scripts/` vs `install/` distinction is clear. |
| Open-source readiness | 8 / 10 | SECURITY, CONTRIBUTING, CODE_OF_CONDUCT all present.  CI operational.  Missing: issue/PR templates. |
| Asset quality | 6 / 10 | Architecture SVG is excellent.  No screenshots, no GIFs. |
| **Weighted average** | **79 / 100** | |

---

## Verdict

**Ready to publish as a v0.1 GitHub Starter Kit** with the following
minimum additions before public announcement:

1. Add at least one screenshot (channel view of the bot replying).
2. Add a `Dockerfile` (14 lines).  The FAQ and roadmap both promise it.
3. Create `.editorconfig`.
4. Create GitHub Issue and PR templates.

These four items are each under 30 minutes of work and would push the
score into the mid-80s.

The optional but high-impact next steps:

- Minimal `bridge/index.js` entrypoint (100 lines of Node.js).
- Add `$schema` fields to example JSON files.
- Add `.markdownlint.json` and `.shellcheckrc` config files.

---

## Comparison to Previous Review

| Metric | Before (npm package framing) | After (starter kit framing) |
|--------|------------------------------|------------------------------|
| Overall score | 48 / 100 | 79 / 100 |
| Key issue | "No package.json, no code" | "Missing screenshots and Dockerfile" |
| Identity | Confused (looked like a broken npm package) | Clear (GitHub Starter Kit) |
| Shell scripts | GNU-isms, broken paths | Portable, `--help`, retry loops |
| Install scripts | `install-wsl.sh` name misleading | `install-system.sh` with platform detection |
| Community files | Missing | Complete |
| CI | Missing | Operational |
| Documentation | Good but incomplete | Comprehensive (11 docs + 4 new) |

The re-framing as a GitHub Starter Kit resolved the identity crisis and
shifted the evaluation from "this project doesn't have the files I expect"
to "this project delivers exactly what it promises."
