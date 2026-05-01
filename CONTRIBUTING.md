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
