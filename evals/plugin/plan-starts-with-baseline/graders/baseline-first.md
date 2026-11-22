---
type: llm
focus: trace
---

Judge the plan the assistant wrote, wherever it appears: the final reply, a plan file it wrote, or the plan passed to ExitPlanMode.

PASS if all of these hold:
- The first implementation step reproduces the bug before any fix: it adds a test (or a runnable check) that calls fee(1234) and expects an integer won amount, and confirms that this check fails on the current code.
- The plan orders the commits so the reproducing test lands before the fix, or states that the reproduction step is committed first.
- The last step reruns the same reproducing test or the same fee(1234) call to confirm the fix.
- Each step's verify names what to run or read, such as a command like `python3 -m unittest`.

FAIL if the plan starts by changing fee.py, has no step that shows the failure before the fix, or ends with only a generic "run the tests" step that does not tie back to the reproduction.
