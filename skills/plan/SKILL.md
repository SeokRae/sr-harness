---
name: harness-plan
description: 구현 계획을 단계별 검증 기준과 함께 수립하는 스킬. "어떻게 구현할까", "계획 세워줘", "설계해줘" 또는 harness-brainstorm 완료 후 자동 실행. 각 단계에 verify 기준 포함, karpathy §4 내장.
---

# harness-plan

계획의 각 단계는 반드시 검증 가능한 완료 조건을 포함한다.
단계는 작게 — 하나의 단계가 하나의 논리적 변경 단위를 넘지 않는다.

## 계획 수립 형식

```
## 목표
{한 문장: 무엇을 만드는가}

## 성공 기준
- [ ] {전체 완료 시 확인할 수 있는 것 1}
- [ ] {전체 완료 시 확인할 수 있는 것 2}

## 단계

### Step 1: {제목}
- 할 일: {구체적 변경 내용}
- verify: {이 단계가 완료됐는지 확인하는 방법}

### Step 2: {제목}
- 할 일: {구체적 변경 내용}
- verify: {확인 방법}

...
```

## karpathy §4 내장 규칙

각 단계 작성 전에 확인:
- "Add validation" → "Write tests for invalid input, make them pass" 형태로 변환
- "Fix bug" → "Write a reproducing test, make it pass" 형태로 변환
- verify 없는 단계는 계획에 포함하지 않는다

## 계획 완료 후

1. 사용자에게 계획 확인 요청
2. 승인되면 → `harness-issue` 호출 (Issue 생성 + 브랜치 생성)
3. 미승인이면 → 피드백 반영 후 재작성

## session-plan.md 연동

계획 확정 시 `.claude/session-plan.md`에 저장:
```yaml
---
session: YYYY-MM-DD
goal: {목표}
scope:
  - {단계 목록}
---
```
