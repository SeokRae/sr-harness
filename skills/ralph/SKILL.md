---
name: ralph
description: execute + verify 단계를 Ralph Loop bypass 모드로 자동화. plan 확정 후 사용. verify 통과까지 반복 → READY_FOR_PR 출력 → submit 안내.
---

# harness-ralph

plan이 확정된 상태에서 execute → verify 루프를 자동화한다.
verify 통과까지 사람 개입 없이 반복한다.

## 전제 조건 확인

### 1. session-plan.md 존재 확인
```bash
cat .claude/session-plan.md
```
없으면 → `plan` 스킬로 돌아간다.

### 2. Worktree 확인
```bash
git worktree list | grep ".claude/worktrees"
```
없으면 → `issue` 스킬로 돌아간다. worktree 밖에서 ralph 시작 금지.

### 3. 기존 Ralph 루프 확인
```bash
cat .claude/ralph-loop.local.md 2>/dev/null || echo "없음"
```
이미 활성 루프가 있으면 → 중단 여부를 사용자에게 확인한다.

## bypass 권한 설정

`.claude/settings.local.json`이 없으면 생성, 있으면 permissions.allow에 항목 추가.

```bash
cat .claude/settings.local.json 2>/dev/null || echo '{"permissions":{"allow":[]}}'
```

이 파일에 다음 항목을 포함한다:
```json
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read(*)",
      "Edit(*)",
      "Write(*)",
      "Agent(*)",
      "Skill(*)"
    ]
  }
}
```

저장 후 기존 권한 항목을 덮어쓰지 않도록 주의한다. 원래 있던 항목은 유지한다.

## Ralph 상태 파일 생성

session-plan.md에서 goal, tasks, issue-번호, test-command를 읽어서
`.claude/ralph-loop.local.md`를 생성한다.

```bash
SESSION_ID="${CLAUDE_CODE_SESSION_ID:-}"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat > .claude/ralph-loop.local.md << 'STATE_EOF'
---
active: true
iteration: 1
session_id: SESSION_ID_PLACEHOLDER
max_iterations: 20
completion_promise: "READY_FOR_PR"
started_at: "STARTED_AT_PLACEHOLDER"
---

[Ralph 프롬프트 — 아래 "Ralph 프롬프트 구조" 참조]
STATE_EOF
```

SESSION_ID_PLACEHOLDER와 STARTED_AT_PLACEHOLDER는 실제 값으로 치환해서 작성한다.

**max_iterations 기준**:
- Tasks ≤ 3: 10
- Tasks 4~6: 15
- Tasks ≥ 7: 20

## Ralph 프롬프트 구조

상태 파일 `---` 이후에 삽입할 프롬프트. session-plan.md 내용을 기반으로 동적으로 작성한다.

```
sr-harness execute + verify 자동화 루프

## 현재 컨텍스트
목표: {session-plan.md의 goal}
Issue: #{issue-번호}

## 미완료 Tasks
{session-plan.md에서 [ ] 항목 목록}

## 매 반복마다 실행 순서

### 1. 상태 파악
git status && git diff origin/main --name-only

### 2. 미완료 Tasks 구현
session-plan.md의 [ ] 항목을 위에서 순서대로 구현한다.
각 항목 완료 시:
  - [ ]를 [x]로 갱신
  - git add {파일} && git commit -m "{설명} (#{issue-번호})"

### 3. verify 실행
3-1. git status → "nothing to commit" 확인
3-2. {test-command 또는 자동 감지된 테스트 명령어} 실행
3-3. 변경 파일 목록이 의도한 범위인지 확인

### 4. 판단
모든 Tasks [x] 완료 AND verify 전부 통과:
  → .claude/settings.local.json 에서 bypass 권한 항목 제거 (또는 빈 allow 배열로 복구)
  → 다음 안내 출력:

    ✅ verify 통과. Ralph 루프 종료.
    변경 파일: {git diff origin/main --name-only 결과}
    다음 단계: /submit

  → <promise>READY_FOR_PR</promise>

미완료 Tasks 있거나 verify 실패:
  → 원인 분석 후 수정, 다음 반복에서 재시도
  → promise 출력 금지 (테스트 실패 상태에서 READY_FOR_PR 출력 절대 금지)
```

## 상태 파일 생성 완료 후

상태 파일을 생성한 직후, 첫 번째 반복을 즉시 시작한다.
Ralph 프롬프트 내용을 그대로 따라 Step 1부터 실행한다.

## 중단 방법

루프를 수동으로 멈춰야 하면:
```bash
rm .claude/ralph-loop.local.md
# bypass 권한도 수동 복구
```

또는 `/cancel-ralph` 스킬 사용.

## 완료 후 bypass 복구 세부 지침

promise 출력 직전에 실행:

기존 `.claude/settings.local.json`이 없었으면:
```bash
rm -f .claude/settings.local.json
```

기존 파일이 있었으면 (다른 항목 존재):
```bash
# ralph가 추가한 항목만 제거하고 나머지 유지
# permissions.allow 에서 추가된 항목 삭제
```

## 금지 사항

- plan 없이 ralph 시작 금지
- worktree 밖에서 실행 금지
- Tasks 미완료 상태에서 promise 출력 금지
- 테스트 실패 상태에서 promise 출력 금지
- 기존 settings.local.json의 다른 설정을 삭제하거나 덮어쓰기 금지
