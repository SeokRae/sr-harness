# Contributing to sr-harness

## What's welcome

- Workflow pattern improvements
- Karpathy checkpoint refinements
- Issue-Driven Development rule updates
- Bug reports from real usage

## How to contribute

1. Open an Issue first — describe what you want to change and why
2. Fork the repo and create a branch: `feature/{issue-number}-{description}`
3. Edit the relevant `skills/{skill-name}/SKILL.md`
4. Open a PR with `Closes #N` in the body

## Editing skills

Each skill lives in `skills/{skill-name}/SKILL.md`. The frontmatter `description` field controls when Claude triggers the skill — changes here have the biggest impact on behavior.

When proposing a change, include:
- What problem you ran into with the current version
- What you changed and why
- How you verified the new behavior works

## Reporting issues

Open a GitHub Issue with:
- Which skill was involved
- What you expected to happen
- What actually happened

## Versioning

This project uses [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`).

| Change type | Version segment | Example |
|-------------|----------------|---------|
| New skill added | `MINOR` | 0.3.0 → 0.4.0 |
| Existing skill behavior extended | `MINOR` | 0.3.0 → 0.4.0 |
| Bug fix, wording, doc only | `PATCH` | 0.3.0 → 0.3.1 |
| Skill removed or interface broken | `MAJOR` | 0.x.x → 1.0.0 |

**Rule**: version bump must be included in the **same PR** as the change — never as a separate follow-up PR.

Files to update together:

```
.claude-plugin/plugin.json      → "version"
.claude-plugin/marketplace.json → "metadata.version" + "plugins[0].version"
```

## Release workflow

After a PR is merged:

```bash
# 1. Pull latest main
git checkout main && git pull origin main

# 2. Create annotated tag
git tag -a v{version} -m "v{version}: {one-line summary}"

# 3. Push tag
git push origin v{version}

# 4. Create GitHub Release
gh release create v{version} --title "v{version}" --generate-notes
```
