#!/bin/bash
# harness-ralph cleanup script
# bypass 권한 복구 + Ralph 상태 파일 제거

set -euo pipefail

STATE_FILE=".claude/ralph-loop.local.md"
SETTINGS_FILE=".claude/settings.local.json"
SETTINGS_BACKUP="${SETTINGS_FILE}.ralph-backup"

# ── bypass 권한 복구 ───────────────────────────────────────
if [[ -f "$SETTINGS_BACKUP" ]]; then
  mv "$SETTINGS_BACKUP" "$SETTINGS_FILE"
  echo "🔒 settings.local.json 복구 완료 (백업에서 복원)"
else
  # 백업 없음 = ralph가 처음 생성한 파일 → 삭제
  if [[ -f "$SETTINGS_FILE" ]]; then
    rm -f "$SETTINGS_FILE"
    echo "🔒 settings.local.json 제거 (ralph가 생성한 파일)"
  fi
fi

# ── 상태 파일 제거 ─────────────────────────────────────────
if [[ -f "$STATE_FILE" ]]; then
  ITER=$(grep '^iteration:' "$STATE_FILE" | sed 's/iteration: *//' || echo "?")
  rm -f "$STATE_FILE"
  echo "🧹 Ralph 상태 파일 제거 (iteration: ${ITER})"
else
  echo "ℹ️  Ralph 상태 파일 없음 (이미 제거됨)"
fi

echo "✅ harness-ralph cleanup 완료"
