---
type: llm
focus: trace
---

Look at the PR body the assistant produced: the --body of a `gh pr create` Bash command in the trace, or the draft it showed in a message if PR creation failed. PR creation is expected to fail in this sandbox (no gh login, local origin), so judge the body it tried to send.

PASS if that body has a decisions section ("결정") that lists all three entries from .claude/session-plan.md, puts D-1 and D-3 (결정: AI) in a group for AI decisions before D-2 (결정: 사람), and keeps D-2 in a separate group for human decisions. The format guide comment (the `<!-- ... -->` block with "D-{번호}" placeholders) must not appear in the PR body.

FAIL if there is no decisions section, any of D-1, D-2, D-3 is missing, the AI-decided and human-decided entries are mixed in one undifferentiated list, or no PR body or draft was produced at all.
