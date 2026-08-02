---
name: goal
description: "plan/worktree 없이 자율 실행. /goal \"목표\" → Stop hook 기반으로 목표 달성까지 반복. pause/resume/clear/status 지원. Keywords: goal, 목표, 자율 실행, 자동 반복, ralph 대안"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-goal.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-goal.sh:*)"]
---

# sr-harness:goal

목표 텍스트 하나로 자율 실행을 시작한다.
plan / worktree 없이도 동작하는 가벼운 자율 실행 모드.

## 명령 형식

| 명령 | 동작 |
|------|------|
| `/goal "목표 텍스트"` | goal 설정 + 즉시 실행 시작 |
| `/goal status` | 현재 goal 상태 출력 |
| `/goal pause` | 일시 중단 (상태 보존) |
| `/goal resume` | 재개 |
| `/goal clear` | 강제 종료 + 상태 파일 제거 |

---

## `/goal "목표 텍스트"`

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-goal.sh" "목표 텍스트"
```

setup 완료 즉시 목표 달성을 향한 작업을 시작한다.
Stop hook이 `<promise>GOAL_ACHIEVED</promise>` 를 감지할 때까지 반복된다.

### 실행 원칙

- plan / worktree 없이 시작 가능
- 목표가 달성됐다고 판단하면 반드시 `<promise>GOAL_ACHIEVED</promise>` 출력
- 달성되지 않은 상태에서 promise 출력 금지
- 각 반복에서 `verify` 스킬의 completion audit 기준으로 달성 여부 판단
- 사람 개입 없이 반복되는 루프이므로 `ownership-principles`(§1 outer loop 체크포인트, §2 설명 가능 게이트) 원칙이 매 반복 stop-hook 프롬프트에 포함돼 적용된다

### 완료 처리

목표 달성 확인 후:
1. `<promise>GOAL_ACHIEVED</promise>` 출력
2. 다음 단계 안내: `/submit` 또는 `/verify`

---

## `/goal status`

`.claude/goal-state.json` 존재 여부 확인 후 출력:

```bash
# 활성 goal이 있을 때
cat .claude/goal-state.json
```

없으면: "활성 goal 없음"

출력 형식:
```
🎯 현재 Goal
   목표: {goal 텍스트}
   상태: {active|paused}
   반복: {iteration} / {max_iterations}
   시작: {started_at}
```

---

## `/goal pause`

```bash
# goal-state.json의 status를 paused로 변경
jq '.status = "paused"' .claude/goal-state.json > .claude/goal-state.json.tmp && \
  mv .claude/goal-state.json.tmp .claude/goal-state.json
echo "⏸ goal 일시 중단. 재개: /goal resume"
```

---

## `/goal resume`

```bash
# goal-state.json의 status를 active로 변경
jq '.status = "active"' .claude/goal-state.json > .claude/goal-state.json.tmp && \
  mv .claude/goal-state.json.tmp .claude/goal-state.json
echo "▶️ goal 재개. Stop hook이 다시 활성화됩니다."
```

현재 세션 session_id로 갱신도 함께 수행:
```bash
jq --arg sid "${CLAUDE_CODE_SESSION_ID:-}" '.status = "active" | .session_id = $sid' \
  .claude/goal-state.json > .claude/goal-state.json.tmp && \
  mv .claude/goal-state.json.tmp .claude/goal-state.json
```

---

## `/goal clear`

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-goal.sh"
```

---

## ralph와의 차이

| | ralph | goal |
|---|---|---|
| 시작 조건 | session-plan.md + feature 브랜치 필수 | 목표 텍스트만 필요 |
| 권한 변경 | bypass 권한 추가 | 변경 없음 |
| 종료 조건 | verify 통과 | 목표 달성 선언 |
| 재개 | 불가 | pause/resume 지원 |

ralph가 이미 활성 상태이면 goal 루프는 동작하지 않는다 (ralph 우선).

## 금지 사항

- 목표 미달성 상태에서 `<promise>GOAL_ACHIEVED</promise>` 출력 금지
- 활성 goal이 있는 상태에서 중복 `/goal "..."` 시작 금지 → `/goal status` 로 확인 후 `/goal clear` 먼저
