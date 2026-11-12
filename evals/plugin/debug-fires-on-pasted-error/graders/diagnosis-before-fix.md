---
type: llm
---

PASS if, before any changed code appears, the reply states the root cause (the rates map has no entry for the new merchant type SME, so rates.get returns null) and says how to confirm it (for example checking the rates source for an SME key, or a test that calls calculate with "SME"). The fix may follow after that.

FAIL if the reply opens with patched code, or only adds a null check or a default rate that hides the missing SME rate without naming the missing entry as the cause, or never says how to confirm the cause.
