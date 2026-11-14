---
description: execute-records-decision과 같은 fixture와 프롬프트. 첫 응답에서 sr-harness:execute가 발화하는지만 본다. 구현 전에 끝나도록 턴을 짧게 둔다 (#137).
expected_outcome: 첫 응답의 도구 호출에 sr-harness:execute가 있다.
max_turns: 2
allowed_tools: [Read, Glob, Grep, Skill]
tags: [execute, firing]
---

session-plan대로 구현해줘. 커밋까지만 하고 PR은 아직 올리지 마.
