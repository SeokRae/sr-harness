#!/usr/bin/env bash
# sr-team-launch.sh: tmux 기반 팀모드 런처
# 사용법: sr-team-launch.sh <job_dir> <total> <worktree_1> [<worktree_2> ...]
#
# job_dir: task-N.md / result-N.md / N.status 파일이 위치할 디렉토리
# total:   에이전트 수
# worktree_N: 각 에이전트의 작업 디렉토리 (git worktree 경로)

set -euo pipefail

if [ $# -lt 3 ]; then
  echo "사용법: $0 <job_dir> <total> <worktree_1> [<worktree_2> ...]" >&2
  exit 1
fi

JOB_DIR="$1"
TOTAL="$2"
shift 2
WORKTREES=("$@")

if [ "${#WORKTREES[@]}" -lt "$TOTAL" ]; then
  echo "오류: worktree 경로 수(${#WORKTREES[@]})가 total($TOTAL)보다 적습니다." >&2
  exit 1
fi

SESSION="sr-team"

# 기존 세션 정리
tmux kill-session -t "$SESSION" 2>/dev/null && echo "기존 sr-team 세션 종료" || true

# 상태판 윈도우로 세션 시작
tmux new-session -d -s "$SESSION" -n "status"

STATUS_SCRIPT="$(cat <<'WATCH'
while true; do
  clear
  echo "=== sr-team 상태 ($(date '+%H:%M:%S')) ==="
  echo ""
WATCH
)"
for i in $(seq 1 "$TOTAL"); do
  STATUS_SCRIPT+="  f=\"$JOB_DIR/$i.status\"; [ -f \"\$f\" ] && echo \"  agent-$i: \$(cat \"\$f\")\" || echo \"  agent-$i: RUNNING...\""$'\n'
done
STATUS_SCRIPT+="  sleep 3
done"

tmux send-keys -t "$SESSION:status" "bash -c '$STATUS_SCRIPT'" Enter

# 각 에이전트 윈도우
for i in $(seq 1 "$TOTAL"); do
  WT="${WORKTREES[$((i-1))]}"
  TASK_FILE="$JOB_DIR/task-$i.md"
  RESULT_FILE="$JOB_DIR/result-$i.md"
  STATUS_FILE="$JOB_DIR/$i.status"

  tmux new-window -t "$SESSION" -n "agent-$i"

  AGENT_CMD="set -o pipefail
echo '[agent-$i] 시작: \$(date)'
cd '$WT'
claude -p --permission-mode bypassPermissions \"\$(cat '$TASK_FILE')\" 2>&1 | tee '$RESULT_FILE'
EXIT=\$?
if [ \$EXIT -eq 0 ]; then
  echo 'DONE' > '$STATUS_FILE'
else
  echo 'ERROR' > '$STATUS_FILE'
fi
echo '[agent-$i] 완료: '\$(cat '$STATUS_FILE')' (exit: '\$EXIT')'"

  tmux send-keys -t "$SESSION:agent-$i" "bash -c \"$AGENT_CMD\"" Enter
done

# 상태판으로 포커스
tmux select-window -t "$SESSION:status"

echo ""
echo "✅ sr-team 세션 시작됨"
echo "👀 실시간 확인: tmux attach -t sr-team"
echo "📁 job_dir: $JOB_DIR"
echo "🤖 에이전트 수: $TOTAL"
echo ""
echo "완료 감시: bash sr-team-watch.sh '$JOB_DIR' '$TOTAL'"
