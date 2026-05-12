#!/usr/bin/env bash
# sr-team-watch.sh: 팀모드 완료 감시
# 사용법: sr-team-watch.sh <job_dir> <total>
#
# 모든 에이전트 완료 시 stdout에 출력:
#   ALL_DONE             — 전원 성공
#   DONE_WITH_ERRORS:N   — N개 에이전트 실패

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "사용법: $0 <job_dir> <total>" >&2
  exit 1
fi

JOB_DIR="$1"
TOTAL="$2"

while true; do
  DONE=0
  ERRORS=0

  for i in $(seq 1 "$TOTAL"); do
    STATUS_FILE="$JOB_DIR/$i.status"
    if [ -f "$STATUS_FILE" ]; then
      DONE=$((DONE + 1))
      STATUS=$(cat "$STATUS_FILE")
      [ "$STATUS" = "ERROR" ] && ERRORS=$((ERRORS + 1))
    fi
  done

  if [ "$DONE" -eq "$TOTAL" ]; then
    if [ "$ERRORS" -eq 0 ]; then
      echo "ALL_DONE"
    else
      echo "DONE_WITH_ERRORS:$ERRORS"
    fi
    exit 0
  fi

  sleep 10
done
