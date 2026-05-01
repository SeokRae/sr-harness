# sr-harness

> A custom Claude Code harness for designing how your AI assistant works — not the other way around.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)](https://claude.ai/code)
[![Status](https://img.shields.io/badge/Status-Early%20Stage-orange)](.)

> English | [한국어](./README.ko.md)

---

## Why

When working with Claude Code day-to-day, the same patterns keep breaking down:

- Principles exist as background rules — they load into context but don't get enforced when it matters
- Issue-Driven Development lives in a CLAUDE.md file, disconnected from the actual workflow
- Brainstorming, planning, and implementation feel like separate sessions, not one continuous flow

sr-harness structures these into a single workflow where each stage enforces the right behavior automatically.

---

## How it works

Instead of relying on rules loaded somewhere in context, each skill applies checkpoints at stage entry.

```
harness-execute: before touching code
  [ ] Is the request clear? If not → ask first
  [ ] Is there a simpler path? If yes → propose it
  [ ] Is there a success criterion? If not → define it

harness-execute: when editing existing code
  [ ] Read the file before writing
  [ ] Only touch lines directly related to the request
  [ ] Leave surrounding code, comments, and formatting as-is
```

From idea to PR, each skill hands off naturally to the next.

---

## Installation

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
#     Version: 0.1.0
#     Scope: user
#     Status: ✔ enabled
```

---

## Workflow

```
harness-start
      │  Identify task type, load session plan, route to the right skill
      │
      ├─ harness-brainstorm
      │    Not: dump all ideas at once
      │    But: one round = one concrete output + one clarifying question
      │    Exit: idea is small enough to fit in a single GitHub Issue
      │
      ├─ harness-plan
      │    Every step must have a verify condition
      │    Format: "do X → verify: [done criteria]"
      │    No verify = step doesn't go in the plan
      │
      ├─ harness-issue
      │    Create GitHub Issue → branch from origin/main
      │    Rule: 1 Issue = 1 Branch = 1 PR
      │    No chain branches. No multi-issue branches.
      │
      ├─ harness-execute ←─────────────────────────┐
      │    Karpathy checkpoints at stage entry       │
      │    step → verify → commit → next step       │
      │                                              │
      ├─ harness-debug  ──────────────────────────  ┘
      │    Diagnose before touching code
      │    Never retry the same failing approach twice
      │
      └─ harness-finish
           push → PR with "Closes #N" in body
           No alternatives. Always a PR.
```

---

## Skills

| Skill | Role |
|-------|------|
| `harness-start` | Session entry point · routing |
| `harness-brainstorm` | Iterative feedback loop to concretize ideas |
| `harness-plan` | Planning with step → verify format |
| `harness-issue` | GitHub Issue + branch creation |
| `harness-execute` | Implementation with Karpathy checkpoints |
| `harness-finish` | push + PR (Closes #N) |
| `harness-debug` | Diagnose-first debugging |

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
cd ~/IdeaProjects/sr-harness
# Edit skills/{skill-name}/SKILL.md

git add . && git commit -m "fix: update skill" && git push
claude plugins marketplace update sr-harness
```

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
