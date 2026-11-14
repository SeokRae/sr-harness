---
description: 검증이 끝난 브랜치의 제출 요청. session-plan.md에 execute가 남긴 결정 기록 3줄(AI 결정 2, 사람 결정 1)이 있다. PR 본문에 결정 절이 생기고 AI가 정한 것이 먼저 와야 한다 (#129).
expected_outcome: 테스트를 돌린 뒤 PR 본문(gh pr create 입력 또는 PR 생성이 실패했을 때 보여 준 초안)에 결정 절을 만든다. D-1, D-3(결정 AI)을 AI가 정한 것으로 먼저 두고, D-2(결정 사람)를 따로 둔다.
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill]
tags: [submit, decisions]
---

검증까지 끝났어. PR 올려줘.
