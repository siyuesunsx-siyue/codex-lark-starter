# Release Process

This document describes how releases are created, tagged, and published
for `codex-lark-starter`.

---

## Versioning

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

- **MAJOR** — Breaking changes to the config schema, script interfaces,
  or documented architecture.
- **MINOR** — New features, new scripts, new documentation sections.
- **PATCH** — Bug fixes, typo corrections, CI improvements.

---

## Release Checklist

### 1. Prepare the Release

- [ ] All CI checks pass on the default branch.
- [ ] `CHANGELOG.md` has an entry for the new version under a
  `## [vX.Y.Z]` header (moved from `[Unreleased]`).
- [ ] All documentation is up to date.
- [ ] `shellcheck` passes on all `.sh` files.
- [ ] `markdownlint` passes on all `.md` files.
- [ ] No placeholder URLs (`<repo-url>`, `<raw-install-url>`) remain.

### 2. Tag the Release

```bash
git checkout main
git pull origin main
git tag -a vX.Y.Z -m "vX.Y.Z"
git push origin vX.Y.Z
```

### 3. Create GitHub Release

1. Go to the [Releases page](../../releases).
2. Click "Draft a new release."
3. Select the `vX.Y.Z` tag.
4. Title: `vX.Y.Z`
5. Description: Copy the relevant section from `CHANGELOG.md`.
6. Publish.

### 4. Post-Release

- [ ] Announce in project channels (Feishu group, etc.).
- [ ] Close the milestone in GitHub Issues (if applicable).
- [ ] Start a new `[Unreleased]` section in `CHANGELOG.md`.

---

## Pre-Releases

For early testing, tag with a pre-release suffix:

```bash
git tag -a v0.2.0-beta.1 -m "v0.2.0-beta.1"
```

Mark the release as "pre-release" in GitHub.  Pre-releases are not
considered stable and may be removed.

---

## Hotfixes

For urgent fixes to a released version:

1. Branch from the release tag: `git checkout -b hotfix/vX.Y.Z vX.Y.Z`
2. Apply the fix.
3. Bump the PATCH version.
4. Tag: `git tag -a vX.Y.(Z+1) -m "vX.Y.(Z+1) - hotfix"`
5. Merge back to `main`.

---

## Roles

| Role | Responsibility |
|------|---------------|
| **Release manager** | Runs the checklist, creates the tag, publishes the release. |
| **Reviewer** | Approves the CHANGELOG entry and version bump PR. |
| **Contributor** | Ensures their changes are listed in `CHANGELOG.md` under `[Unreleased]`. |
