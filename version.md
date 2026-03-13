# Versioning Guide

A complete reference for understanding software versioning — including semantic versioning rules, when to bump each number, and how to handle versioning when you build on top of someone else's code.

---

## 1. What Is a Version Number?

A version number communicates **what changed** between releases. The most widely used standard is **Semantic Versioning (SemVer)**:

```
MAJOR.MINOR.PATCH
  │      │     └── e.g. 1.4.2
  │      └──────── e.g. 1.4.0
  └─────────────── e.g. 2.0.0
```

Each of the three numbers has a specific meaning and rule for when it must change.

---

## 2. The Three Numbers — When to Change Each

### PATCH — `1.0.X`
Increment when you make **backwards-compatible bug fixes** only. Nothing new. Nothing broken.

| Change type | Example |
|-------------|---------|
| Fix a crash | Script exited with wrong error code → fixed |
| Fix wrong output | Status was showing `approved` instead of `uploaded` → fixed |
| Fix a typo in a message | "Uploded" → "Uploaded" |
| Security patch with no API change | Sanitize an input that wasn't being checked |

```
1.0.0 → 1.0.1   (bug fix)
1.0.1 → 1.0.2   (another bug fix)
```

---

### MINOR — `1.X.0`
Increment when you **add new functionality** in a backwards-compatible way. Old workflows still work without any changes.

When you bump MINOR, reset PATCH to 0.

| Change type | Example |
|-------------|---------|
| New optional input | Add `caption` input to action (optional, has a default) |
| New output variable | Action now also outputs `file_size` |
| New behaviour users can opt into | Add `dry_run: true` option |
| Performance improvement visible to users | Polling is now faster |

```
1.0.3 → 1.1.0   (new feature added, patch reset)
1.1.0 → 1.2.0   (another new feature)
```

---

### MAJOR — `X.0.0`
Increment when you make **breaking changes** — anything that would cause existing workflows to fail or behave differently without modification.

When you bump MAJOR, reset both MINOR and PATCH to 0.

| Change type | Example |
|-------------|---------|
| Rename an input | `file_path` renamed to `artifact_path` |
| Remove an input or output | `message_id` output removed |
| Change default behaviour | `fail_on_no` default changed from `false` to `true` |
| Change output values | `status` now returns `approved` instead of `uploaded` |
| Require a new mandatory input | New required `thread_id` input added |

```
1.4.2 → 2.0.0   (breaking change, everything reset)
```

---

## 3. The Full Flow — A Real Example

Starting at `1.0.0`:

```
1.0.0   Initial release
1.0.1   Fix: timeout was off by 1 second
1.0.2   Fix: file upload failed for filenames with spaces
1.1.0   Feature: add optional `caption` input for the uploaded file
1.1.1   Fix: caption was being trimmed incorrectly
1.2.0   Feature: add `message_id` to outputs
2.0.0   Breaking: renamed input `file_path` → `artifact_path`
2.0.1   Fix: crash when artifact_path had trailing slash
2.1.0   Feature: add `thread_id` optional input for forum topics
```

---

## 4. Pre-release and Build Suffixes (Optional)

These are used before a stable release is published:

| Suffix | Meaning | Example |
|--------|---------|---------|
| `-alpha` | Early, unstable preview | `2.0.0-alpha` |
| `-beta` | Feature-complete but not fully tested | `2.0.0-beta` |
| `-rc.1` | Release candidate, nearly final | `2.0.0-rc.1` |

These are **never used in production** by people who depend on your action. They signal: "use at your own risk."

---

## 5. Versioning When You Build on Someone Else's Code

This is a common situation — you fork a project, customize it, and publish it under your own name (e.g. forking an action and publishing as `yourname/repo@v1`).

### 5a. You fork and publish as your own

When the original project is at `v2.3.1` and you fork it:

**Do not copy their version number.** Start fresh from `v1.0.0`. Your versioning is now independent.

```
Original repo:  xz-dev/SomeAction@v2.3.1
Your fork:      safwanehfaz/telec@v1.0.0   ← start from v1, independent
```

Your `v1` has no relationship to their `v2`. You own the version history from now on.

### 5b. You sync updates from the original upstream

If the original project releases a new version and you pull those changes into your fork:

- If the upstream change is just a **bug fix** → bump your PATCH
- If the upstream change **adds features** → bump your MINOR
- If the upstream change is **breaking** → bump your MAJOR

```
You are at:     safwanehfaz/telec@v1.2.0
Upstream fixes a bug → you merge it → release safwanehfaz/telec@v1.2.1
Upstream adds a feature → you merge it → release safwanehfaz/telec@v1.3.0
Upstream makes breaking change → you merge it → release safwanehfaz/telec@v2.0.0
```

### 5c. You only make your own changes (no upstream sync)

Version it purely based on **what you changed**, same rules as any project.

---

## 6. GitHub Actions Versioning Specifically

GitHub Actions supports two referencing styles:

```yaml
uses: safwanehfaz/telec@v1        # floating tag — always latest v1.x.x
uses: safwanehfaz/telec@v1.2.3    # pinned — exact version, never changes
```

### Floating Major Tags (Recommended Practice)

The standard convention for GitHub Actions is to maintain a floating `v1` tag that always points to the latest `v1.x.x` release. This means users who write `@v1` get your latest stable v1 release automatically.

**How to maintain floating tags:**

After publishing `v1.2.3`, move the `v1` tag to point to the same commit:

```bash
git tag -fa v1 -m "Update v1 tag to v1.2.3"
git push origin v1 --force
```

Do the same for `v2` when you publish `v2.x.x` releases.

### Pin vs Float — When to use which

| Style | Who should use it | Why |
|-------|------------------|-----|
| `@v1` | Most users | Get bug fixes automatically |
| `@v1.2.3` | Production-critical workflows | Guarantee nothing changes unexpectedly |
| `@main` | Development/testing only | Unstable, avoid in production |

---

## 7. How to Create a Release on GitHub

1. Push all your changes to `main`
2. Go to your repository → **Releases** → **Draft a new release**
3. Set **Tag**: `v1.0.0` (or `v2`, `v1.2.3`, etc.)
4. Set **Title**: `v1.0.0`
5. Write release notes describing what changed
6. Click **Publish release**

No files need to be attached — GitHub automatically packages the entire repository at that tag commit.

---

## 8. Quick Decision Chart

```
Did anything break for existing users?
    YES → bump MAJOR, reset minor and patch to 0
    NO  → Did you add new features?
              YES → bump MINOR, reset patch to 0
              NO  → Did you fix a bug?
                        YES → bump PATCH
                        NO  → no release needed
```

---

## 9. Summary Table

| What changed | Version bump | Example |
|--------------|-------------|---------|
| Bug fix only | PATCH | `1.2.3` → `1.2.4` |
| New optional feature | MINOR | `1.2.4` → `1.3.0` |
| Breaking change | MAJOR | `1.3.0` → `2.0.0` |
| Forked from someone else | Start at `v1.0.0` | Independent versioning |
| Merged upstream bug fix | PATCH | Same as bug fix rule |
| Merged upstream new feature | MINOR | Same as new feature rule |
| Merged upstream breaking change | MAJOR | Same as breaking change rule |
