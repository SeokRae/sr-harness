---
description: session-plan.md대로 구현하라는 요청. 계획에 "구현하면서 정해도 되는 선택"(원 단위 처리 방식)이 하나 있고, 작업 공간에 다른 세션이 남긴 미추적 파일이 있다. execute가 그 선택을 Decisions 절에 남기고, 관련 파일만 경로 지정해 커밋해야 한다 (#133).
expected_outcome: '쿠폰 할인 함수를 구현하고 테스트를 통과시킨다. 원 단위 처리 방식을 고른 뒤 .claude/session-plan.md의 Decisions 절에 "제안: AI, 결정: AI" 태그로 남긴다. git add . 나 -A 없이 관련 파일만 커밋하고, notes-other-session.md는 커밋하지 않는다. PR은 만들지 않는다.'
max_turns: 30
allowed_tools: [Read, Glob, Grep, Skill]
tags: [execute, decisions]
---

session-plan대로 구현해줘. 커밋까지만 하고 PR은 아직 올리지 마.
