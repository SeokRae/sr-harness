# Runtime Compatibility

sr-harness is a dual-runtime plugin. Claude Code and Codex share the same skill source files under `skills/`, while each runtime owns its own plugin manifest and runtime-specific behavior.

## Manifest Layout

| Runtime | Manifest | Purpose |
| --- | --- | --- |
| Claude Code | `.claude-plugin/plugin.json` | Claude plugin metadata and skill registration |
| Claude Code | `.claude-plugin/marketplace.json` | Claude marketplace metadata |
| Codex | `.codex-plugin/plugin.json` | Codex plugin metadata and skill registration |

Version bumps must keep both manifests in sync.

## Shared Contract

The reusable workflow contract lives in `skills/*/SKILL.md`.

Shared skills should prefer runtime-neutral wording:

- Use `agent` when the behavior applies to both Claude Code and Codex.
- Use `Claude Code` or `Codex` only for runtime-specific commands, hooks, or UI behavior.
- Keep checklist, planning, debugging, and verification rules in the shared skill file when they do not require a runtime-specific tool.

## Runtime-Specific Behavior

Claude-specific behavior currently includes:

- `.claude/session-plan.md`
- `.claude/goal-state.json`
- `.claude/ralph-loop.local.md`
- `.claude/settings.local.json`
- `CLAUDE_PLUGIN_ROOT`
- `CLAUDE_CODE_SESSION_ID`
- Stop hooks used by `goal` and `ralph`

Codex can load the shared skills through `.codex-plugin/plugin.json`, but Codex does not automatically install the Claude Stop-hook loop. In Codex, `goal` and `ralph` should be treated as workflow guidance until a Codex-native loop implementation is added.

## State Path Policy

New runtime-neutral state should live under `.sr-harness/`.

Use `.claude/` only for Claude Code hook configuration or backward compatibility. If a skill needs persistent state in both runtimes, document both paths explicitly or migrate to `.sr-harness/` with a fallback for legacy `.claude/` files.

## Change Checklist

When adding or changing a skill:

1. Keep the shared behavior in `skills/<name>/SKILL.md`.
2. Put Claude-only behavior in a clearly labeled `Claude Code` subsection.
3. Put Codex-only behavior in a clearly labeled `Codex` subsection.
4. Update `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` together when the skill list or version changes.
5. Validate the Codex manifest with the Codex plugin validator before release.
