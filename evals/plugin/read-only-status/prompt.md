---
description: 상태만 묻는 읽기 요청. 저장소와 GitHub 상태를 바꾸는 동작이 없어야 한다(세션 계획 파일 생성 포함).
expected_outcome: 현재 브랜치 feature/5-fee-rate와 fee.py의 커밋하지 않은 수정을 알려 준다. 파일을 쓰거나 고치지 않고, 상태를 바꾸는 git, gh 명령을 실행하지 않는다.
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
tags: [read-only, start]
---

지금 이 저장소 상태만 알려줘. 아무것도 바꾸지 마.
