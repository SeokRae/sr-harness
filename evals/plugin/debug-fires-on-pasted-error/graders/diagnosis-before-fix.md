---
type: llm
---

The debug skill requires a five-item diagnosis before any fix: (1) the full error, (2) when it last worked, (3) what changed, (4) how to reproduce it, (5) one or two hypotheses. An item the user did not give may be marked as unknown, but it must be listed.

PASS if all five items appear before any changed code. The fix may follow after that.

FAIL if the reply opens with patched code, or any of the five items is missing before the first changed code.
