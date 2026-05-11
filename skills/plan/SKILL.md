---
name: plan
description: 구현 계획을 단계별 검증 기준과 함께 수립하는 스킬. "어떻게 구현할까", "계획 세워줘", "설계해줘" 또는 brainstorm 완료 후 자동 실행. 각 단계에 verify 기준 포함, karpathy §4 내장.
---

# plan

계획의 각 단계는 반드시 검증 가능한 완료 조건을 포함한다.
단계는 작게 — 하나의 단계가 하나의 논리적 변경 단위를 넘지 않는다.

## 계획 수립 형식

```
## 🎯 목표
{한 문장: 무엇을 만드는가}

---

## ✅ 성공 기준
- [ ] {전체 완료 시 확인할 수 있는 것 1}
- [ ] {전체 완료 시 확인할 수 있는 것 2}

---

## 📋 단계 요약

| Step | 제목 | 규모 |
|------|------|------|
| 1 | {제목} | S/M/L |
| 2 | {제목} | S/M/L |

---

## 📝 단계별 상세

---

### Step 1: {제목}

**할 일:** {구체적 변경 내용}

> 🔍 verify: {이 단계가 완료됐는지 확인하는 방법}

---

### Step 2: {제목}

**할 일:** {구체적 변경 내용}

> 🔍 verify: {확인 방법}

---
```

## karpathy §4 내장 규칙

각 단계 작성 전에 확인:
- "Add validation" → "Write tests for invalid input, make them pass" 형태로 변환
- "Fix bug" → "Write a reproducing test, make it pass" 형태로 변환
- verify 없는 단계는 계획에 포함하지 않는다

## 계획 완료 후

1. 사용자에게 계획 확인 요청
2. 승인되면 → `issue` 호출 (Issue 생성 + 브랜치 생성)
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

## 자기보고 (evolution_log)

계획 확정 후 아래 명령어를 실행해 메트릭을 기록한다.
`step_count`와 `has_verify_criteria`는 실제 작성한 계획 기준으로 채운다.

```bash
python3 ~/.claude/hooks/evolution-log-skill.py \
  '{"skill":"sr-harness:plan","outcome":"completed","metrics":{"step_count":{N},"has_verify_criteria":{true|false}}}'
```

계획이 중단되거나 사용자가 승인하지 않은 경우:
```bash
python3 ~/.claude/hooks/evolution-log-skill.py \
  '{"skill":"sr-harness:plan","outcome":"abandoned","metrics":{"step_count":{N},"has_verify_criteria":{true|false}}}'
```
