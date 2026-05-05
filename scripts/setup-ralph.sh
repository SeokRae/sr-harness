#!/bin/bash
# harness-ralph setup script
# session-plan.md 기반으로 Ralph 상태 파일 + bypass 권한 설정

set -euo pipefail

PLAN_FILE=".claude/session-plan.md"
STATE_FILE=".claude/ralph-loop.local.md"
SETTINGS_FILE=".claude/settings.local.json"
SETTINGS_BACKUP="${SETTINGS_FILE}.ralph-backup"

# ── 전제 조건 확인 ─────────────────────────────────────────
if [[ ! -f "$PLAN_FILE" ]]; then
  echo "❌ .claude/session-plan.md 없음. plan 스킬로 먼저 계획을 작성하세요." >&2
  exit 1
fi

WORKTREE_CHECK=$(git worktree list | grep "$(pwd)" | grep -v "bare" || true)
if [[ -z "$WORKTREE_CHECK" ]]; then
  echo "❌ worktree 밖에서 실행됨. .claude/worktrees/ 안으로 이동하세요." >&2
  exit 1
fi

if [[ -f "$STATE_FILE" ]]; then
  echo "⚠️  활성 Ralph 루프가 이미 존재합니다: $STATE_FILE" >&2
  echo "   취소하려면: /cancel-ralph 또는 bash \"\${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-ralph.sh\"" >&2
  exit 1
fi

# ── session-plan.md 파싱 ───────────────────────────────────
GOAL=$(grep -m1 '^goal:' "$PLAN_FILE" | sed 's/^goal: *//' || echo "목표 미정의")
ISSUE=$(grep -m1 '#[0-9]' "$PLAN_FILE" | grep -o '#[0-9]*' | head -1 || echo "#?")
TEST_CMD=$(grep -m1 '^test-command:' "$PLAN_FILE" | sed 's/^test-command: *//' || echo "")

# 미완료 Tasks 추출
TASKS=$(grep '^\- \[ \]' "$PLAN_FILE" || echo "- [ ] (Tasks 항목 없음)")

# max_iterations 결정
TASK_COUNT=$(echo "$TASKS" | grep -c '^\- \[ \]' || echo 0)
if [[ $TASK_COUNT -le 3 ]]; then
  MAX_ITER=10
elif [[ $TASK_COUNT -le 6 ]]; then
  MAX_ITER=15
else
  MAX_ITER=20
fi

# 테스트 명령어 자동 감지
if [[ -z "$TEST_CMD" ]]; then
  if [[ -f "./gradlew" ]]; then
    TEST_CMD="./gradlew test"
  elif [[ -f "package.json" ]]; then
    TEST_CMD="npm test"
  elif [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]]; then
    TEST_CMD="pytest"
  else
    TEST_CMD="(테스트 명령어 미확인 — 수동 실행 필요)"
  fi
fi

# ── bypass 권한 설정 ───────────────────────────────────────
mkdir -p .claude

# 기존 파일 백업
if [[ -f "$SETTINGS_FILE" ]]; then
  cp "$SETTINGS_FILE" "$SETTINGS_BACKUP"
  echo "📋 settings.local.json 백업: $SETTINGS_BACKUP"
fi

# bypass 권한 파일 생성
cat > "$SETTINGS_FILE" <<'SETTINGS_EOF'
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
SETTINGS_EOF

echo "🔓 bypass 권한 설정 완료"

# ── Ralph 상태 파일 생성 ────────────────────────────────────
SESSION_ID="${CLAUDE_CODE_SESSION_ID:-}"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 상태 파일 헤더 작성
cat > "$STATE_FILE" <<HEADER
---
active: true
iteration: 1
session_id: ${SESSION_ID}
max_iterations: ${MAX_ITER}
completion_promise: "READY_FOR_PR"
started_at: "${STARTED_AT}"
---

HEADER

# Ralph 프롬프트 본문 추가 (변수 확장 없는 heredoc)
cat >> "$STATE_FILE" <<'PROMPT_EOF'
sr-harness execute + verify 자동화 루프

## 현재 컨텍스트
PROMPT_EOF

# 변수 포함 줄은 일반 echo로 추가
echo "목표: ${GOAL}" >> "$STATE_FILE"
echo "Issue: ${ISSUE}" >> "$STATE_FILE"
echo "" >> "$STATE_FILE"
echo "## 미완료 Tasks" >> "$STATE_FILE"
echo "${TASKS}" >> "$STATE_FILE"

cat >> "$STATE_FILE" <<PROMPT_MID

## karpathy 원칙 (매 반복 적용)

- Read before Write: 수정 전 대상 파일 반드시 먼저 읽기
- git add . 사용 금지 — 관련 파일만 명시적으로 지정
- worktree 경로 내에서만 파일 수정 (main 워크트리 직접 수정 금지)
- 요청한 것만 구현 — 추가 기능·리팩터 금지

## 매 반복 실행 순서

### 1. 상태 파악
\`\`\`bash
git status && git diff origin/main --name-only
\`\`\`

### 2. 미완료 Tasks 구현

session-plan.md의 [ ] 항목을 위에서부터 순서대로 구현한다.
각 항목 완료 시:
  - [ ]를 [x]로 갱신 (session-plan.md 직접 수정)
  - git add {관련 파일만} && git commit -m "{설명} (${ISSUE})"

### 3. verify 실행

3-1. git status → "nothing to commit" 확인
3-2. 테스트 실행:
\`\`\`bash
${TEST_CMD}
\`\`\`
3-3. git diff origin/main --name-only → 의도한 파일만 변경됐는지 확인

### 4. 판단

모든 Tasks [x] 완료 AND verify 전부 통과:
  → cleanup 스크립트 실행:
    \`\`\`bash
    bash "\${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-ralph.sh"
    \`\`\`
  → 다음 출력 후 promise:

    ✅ verify 통과. Ralph 루프 종료.
    변경 파일: (git diff origin/main --name-only 결과)
    다음 단계: /submit

  → <promise>READY_FOR_PR</promise>

미완료 Tasks 있거나 verify 실패:
  → 원인 분석 후 수정, 다음 반복에서 재시도
  → promise 출력 절대 금지 (테스트 실패 = READY_FOR_PR 아님)
PROMPT_MID

# ── 완료 보고 ──────────────────────────────────────────────
echo ""
echo "🔄 harness-ralph 설정 완료!"
echo ""
echo "   목표: ${GOAL}"
echo "   Issue: ${ISSUE}"
echo "   Tasks: ${TASK_COUNT}개"
echo "   max_iterations: ${MAX_ITER}"
echo "   테스트: ${TEST_CMD}"
echo ""
echo "Stop hook이 활성화됩니다. 종료 시도 → 같은 프롬프트 재주입."
echo "완료 조건: <promise>READY_FOR_PR</promise>"
echo ""
echo "수동 중단: /cancel-ralph"
