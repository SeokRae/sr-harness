# sr-harness

> A custom coding-agent harness for designing how your AI assistant works — not the other way around.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)](https://claude.ai/code)
[![Codex](https://img.shields.io/badge/Codex-Plugin-2563eb)](.codex-plugin/plugin.json)
[![Status](https://img.shields.io/badge/Status-Early%20Stage-orange)](.)
[![Workflow Cycle](https://img.shields.io/badge/Workflow-Interactive%20Diagram-68b6ff)](https://seokrae.github.io/sr-harness/)

> English | [한국어](./README.ko.md) | [Interactive Workflow →](https://seokrae.github.io/sr-harness/)

---

## Why

When working with coding agents day-to-day, the same patterns keep breaking down:

- Principles exist as background rules — they load into context but don't get enforced when it matters
- Issue-Driven Development lives in a project memory file, disconnected from the actual workflow
- Brainstorming, planning, and implementation feel like separate sessions, not one continuous flow

sr-harness structures these into a single workflow where each stage enforces the right behavior automatically.

---

## How it works

Instead of relying on rules loaded somewhere in context, each skill applies checkpoints at stage entry.

```
execute: before touching code
  [ ] Is the request clear? If not → ask first
  [ ] Is there a simpler path? If yes → propose it
  [ ] Is there a success criterion? If not → define it

execute: when editing existing code
  [ ] Read the file before writing
  [ ] Only touch lines directly related to the request
  [ ] Leave surrounding code, comments, and formatting as-is
```

From idea to PR, each skill hands off naturally to the next.

---

## Installation

sr-harness ships manifests for both Claude Code and Codex:

- Claude Code: `.claude-plugin/plugin.json`
- Codex: `.codex-plugin/plugin.json`

### Claude Code

```bash
# Add marketplace
claude plugins marketplace add https://github.com/SeokRae/sr-harness.git

# Install
claude plugins install sr-harness@sr-harness
```

Verify:
```bash
claude plugins list
#   ❯ sr-harness@sr-harness
#     Version: 0.18.0
#     Scope: user
#     Status: ✔ enabled
```

### Codex

Codex support is manifest-ready through `.codex-plugin/plugin.json`. Install it through your Codex plugin marketplace or local plugin source configuration. Once installed, the shared `skills/*/SKILL.md` files are available to Codex.

Runtime-specific behavior is documented in [`docs/RUNTIME-COMPATIBILITY.md`](./docs/RUNTIME-COMPATIBILITY.md).

---

## Lifecycle

The full lifecycle — state transitions, the skill map, resolved gaps, and the remaining roadmap — is documented in [`docs/LIFECYCLE.md`](./docs/LIFECYCLE.md).

## Workflow

```
start
      │  Identify task type, load session plan, route to the right skill
      │
      ├─ brainstorm
      │    Not: dump all ideas at once
      │    But: one round = one concrete output + one clarifying question
      │    Exit: idea is small enough to fit in a single GitHub Issue
      │
      ├─ plan
      │    Every step must have a verify condition
      │    Format: "do X → verify: [done criteria]"
      │    No verify = step doesn't go in the plan
      │
      ├─ issue
      │    Create GitHub Issue → branch from origin/main
      │    Rule: 1 Issue = 1 Branch = 1 PR
      │    No chain branches. No multi-issue branches.
      │
      ├─ execute ←─────────────────────────┐
      │    Karpathy checkpoints at stage entry       │
      │    step → verify → commit → next step       │
      │                                              │
      ├─ debug  ──────────────────────────  ┘
      │    Diagnose before touching code
      │    Never retry the same failing approach twice
      │
      ├─ analyze
      │    Intent check: Issue requirements ↔ git diff
      │    coverage gap · scope creep · contradiction
      │
      ├─ verify
      │    Integration check before submitting
      │    git status · changed files · test suite
      │
      ├─ submit
      │    push → PR with "Closes #N" in body
      │    Stops here. User reviews the PR.
      │
      ├─ review
      │    Receive review feedback → back to execute
      │
      └─ finish
           Merge + delete branch + pull main
           The work is truly done.
```

---

## Skills

| Skill | Role |
|-------|------|
| `start` | Session entry point · routing |
| `brainstorm` | Iterative feedback loop to concretize ideas |
| `plan` | Planning with step → verify format |
| `issue` | GitHub Issue + branch creation |
| `execute` | Implementation with Karpathy checkpoints |
| `debug` | Diagnose-first debugging |
| `analyze` | Intent-consistency gate (Issue ↔ diff) before verify |
| `verify` | Integration check before PR |
| `submit` | push + PR (Closes #N) · stops for user review |
| `review` | Receive review feedback → back to execute |
| `finish` | Merge + delete branch + pull main |
| `ralph` | Automated execute→verify loop until pass (bypass mode) |
| `goal` | Goal-driven autonomous execution via Stop hook in Claude Code; workflow guidance in Codex until a Codex-native loop is added |
| `release` | Create a GitHub Release (version + auto-generated notes) |
| `abort` | Cancel work · clean up branch |
| `pause` | Suspend session · hand off to next session |
| `dev-coding-principles` | Coding quality checklist — Naming, Exception Handling, Test |
| `dev-architecture` | Architecture checklist — Hexagonal, Layer Separation, Package Structure |
| `dev-documentation-principles` | Documentation checklist — Decision Recording, Drift Handling, Existing Convention First |
| `dev-stack-java` | Java/Spring Boot idioms — Spring, JPA, Exception & Response (auto-detected) |
| `dev-monitoring-design` | Anomaly/spike monitoring dashboard & report info-design checklist — Measure, Diagnose, Detect, Present |
| `ownership-principles` | Agent-era ownership checklist — Inner/outer loop, verdict, cognitive debt/surrender, orchestration tax |
| `meta` | Meta-Harness evolution loop — analyze a target skill and propose 3 improved candidates |

### Stack auto-detection

`execute` automatically detects the project stack and loads the matching skill:

| Indicator file | Skill loaded |
|----------------|-------------|
| `build.gradle` or `pom.xml` | `dev-stack-java` |

---

## Core Principles

### Karpathy's Four Rules

Each rule is a checkpoint at a specific stage — not a suggestion loaded into context.

| Rule | Enforced in | What it prevents |
|------|-------------|-----------------|
| **§1 Think Before Coding** | start · brainstorm · debug | Silently picking an interpretation and running with it |
| **§2 Simplicity First** | execute | Writing 200 lines when 50 would do |
| **§3 Surgical Changes** | execute | Touching code that wasn't part of the request |
| **§4 Goal-Driven Execution** | plan · execute | Moving to the next step before verifying the current one |

### Issue-Driven Development

```
Issue → Branch (from origin/main) → Implement → Commit (#N) → PR (Closes #N) → Merge
```

One rule: `Closes #N` in the **PR body** closes the Issue. `(#N)` in commit messages does not.

---

## How to Know It's Working

- Every brainstorm ends with one concrete, Issue-sized plan
- Every step in the plan has an explicit done-condition
- Diffs contain only lines directly related to the request
- Every PR has `Closes #N` in the body

---

## Updating Skills

```bash
cd sr-harness
# Edit skills/{skill-name}/SKILL.md

git add . && git commit -m "fix: update skill" && git push
claude plugins marketplace update sr-harness
```

When changing the skill list or version, update both `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json`.

---

## Contributing

Workflow patterns, Karpathy checkpoint improvements, and issue-driven rule refinements are welcome.

- 🐛 [Bug report](https://github.com/SeokRae/sr-harness/issues/new)
- ✨ [Feature request](https://github.com/SeokRae/sr-harness/issues/new)

---

## References

- [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) — Original Karpathy guidelines plugin

---

MIT License
