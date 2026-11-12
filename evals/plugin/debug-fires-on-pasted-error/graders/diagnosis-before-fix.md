---
type: llm
---

The debug skill requires a five-item diagnosis before any fix: (1) the full error, (2) when it last worked, (3) what changed, (4) how to reproduce it, (5) one or two hypotheses. An item the user did not give may be marked as unknown, but it must be listed.

PASS if, before any changed code appears, the reply lists all five items, and one hypothesis is that the rates map has no entry for the new merchant type SME, so rates.get returns null. The fix may follow after that.

FAIL if the reply opens with patched code, or leaves out any of the five items, or offers only a null check or a default rate without naming the missing SME rate as a hypothesis.
