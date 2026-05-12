#!/bin/bash
# harness-goal setup script
# goal 텍스트를 받아 .claude/goal-state.json 생성

set -euo pipefail

STATE_FILE=".claude/goal-state.json"

if [[ $# -lt 1 ]] || [[ -z "$1" ]]; then
  echo "❌ 사용법: setup-goal.sh \"목표 텍스트\"" >&2
  exit 1
fi

GOAL_TEXT="$1"

if [[ -f "$STATE_FILE" ]]; then
  STATUS=$(jq -r '.status' "$STATE_FILE" 2>/dev/null || echo "unknown")
  echo "⚠️  활성 goal이 이미 존재합니다 (status: ${STATUS})" >&2
  echo "   취소하려면: bash \"\${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-goal.sh\"" >&2
  exit 1
fi

mkdir -p .claude

SESSION_ID="${CLAUDE_CODE_SESSION_ID:-}"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq -n \
  --arg goal "$GOAL_TEXT" \
  --arg session_id "$SESSION_ID" \
  --arg started_at "$STARTED_AT" \
  '{
    goal: $goal,
    status: "active",
    session_id: $session_id,
    started_at: $started_at,
    iteration: 1,
    max_iterations: 20
  }' > "$STATE_FILE"

echo ""
echo "🎯 goal 설정 완료!"
echo ""
echo "   목표: ${GOAL_TEXT}"
echo "   session_id: ${SESSION_ID:-"(없음)"}"
echo "   max_iterations: 20"
echo ""
echo "Stop hook이 활성화됩니다. 완료 조건: <promise>GOAL_ACHIEVED</promise>"
echo "일시 중단: /goal pause   |   강제 종료: bash \"\${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-goal.sh\""
