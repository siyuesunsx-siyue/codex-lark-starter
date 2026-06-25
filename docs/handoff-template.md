# Handoff Template

Use this checklist when transferring work between contributors.

---

## Before Handoff

- [ ] All changes are on a feature branch (`feat/`, `fix/`, `docs/`).
- [ ] `CHANGELOG.md` is updated under `## [Unreleased]`.
- [ ] Shell scripts pass `shellcheck` (or manually reviewed).
- [ ] Documentation reflects the current state of the code.
- [ ] No secrets or credentials in any committed file.
- [ ] Git history is clean (squash WIP commits if needed).

---

## Handoff Notes

| Field | Value |
|-------|-------|
| **Branch** | |
| **PR / Issue** | |
| **What changed** | |
| **Breaking changes** | Yes / No |
| **New dependencies** | |
| **Config changes needed** | |
| **Rollback steps** | |
| **Assigned to** | @username |

---

## Reviewer Checklist

- [ ] Code compiles / passes lint.
- [ ] Tests pass (if applicable).
- [ ] Documentation matches implementation.
- [ ] No hardcoded paths, secrets, or machine-specific values.
- [ ] Error handling covers all edge cases.
- [ ] Logging is appropriate (no PII in logs).

---

## After Merge

- [ ] Tag a release (if applicable).
- [ ] Deploy to staging and run the smoke test.
- [ ] Notify the team in the relevant Feishu / Lark channel.
