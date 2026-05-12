#!/bin/bash
# harness-goal cleanup script
# .claude/goal-state.json 제거

set -euo pipefail

STATE_FILE=".claude/goal-state.json"

if [[ -f "$STATE_FILE" ]]; then
  GOAL=$(jq -r '.goal' "$STATE_FILE" 2>/dev/null || echo "(읽기 실패)")
  ITER=$(jq -r '.iteration' "$STATE_FILE" 2>/dev/null || echo "?")
  rm -f "$STATE_FILE"
  echo "🧹 goal 상태 파일 제거 (iteration: ${ITER})"
  echo "   목표: ${GOAL}"
else
  echo "ℹ️  goal 상태 파일 없음 (이미 제거됨)"
fi

echo "✅ harness-goal cleanup 완료"
