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
SCRIPT_DIR="$(mktemp -d /tmp/sr-team-XXXXX)"

# 기존 세션 정리
tmux kill-session -t "$SESSION" 2>/dev/null && echo "기존 sr-team 세션 종료" || true

# 상태판 윈도우로 세션 시작
tmux new-session -d -s "$SESSION" -n "status"

# 상태판 스크립트 파일 작성
STATUS_SCRIPT="$SCRIPT_DIR/status.sh"
{
  echo "#!/usr/bin/env bash"
  echo "while true; do"
  echo "  clear"
  echo "  echo '=== sr-team 상태 (\$(date +%H:%M:%S)) ==='"
  echo "  echo ''"
  for i in $(seq 1 "$TOTAL"); do
    echo "  f='$JOB_DIR/$i.status'"
    echo "  [ -f \"\$f\" ] && echo \"  agent-$i: \$(cat \"\$f\")\" || echo '  agent-$i: RUNNING...'"
  done
  echo "  sleep 3"
  echo "done"
} > "$STATUS_SCRIPT"
chmod +x "$STATUS_SCRIPT"
tmux send-keys -t "$SESSION:status" "bash '$STATUS_SCRIPT'" Enter

# 각 에이전트 스크립트 파일 작성 후 tmux 윈도우에서 실행
for i in $(seq 1 "$TOTAL"); do
  WT="${WORKTREES[$((i-1))]}"
  TASK_FILE="$JOB_DIR/task-$i.md"
  RESULT_FILE="$JOB_DIR/result-$i.md"
  STATUS_FILE="$JOB_DIR/$i.status"
  AGENT_SCRIPT="$SCRIPT_DIR/agent-$i.sh"

  # 에이전트 스크립트 파일로 작성 — quoting 문제 없음
  cat > "$AGENT_SCRIPT" << AGENT_EOF
#!/usr/bin/env bash
set -o pipefail
echo "[agent-$i] 시작: \$(date)"
cd '$WT'
claude -p --permission-mode bypassPermissions < '$TASK_FILE' 2>&1 | tee '$RESULT_FILE'
EXIT=\${PIPESTATUS[0]}
[ \$EXIT -eq 0 ] && echo DONE > '$STATUS_FILE' || echo ERROR > '$STATUS_FILE'
echo "[agent-$i] 완료: \$(cat '$STATUS_FILE') (exit: \$EXIT)"
AGENT_EOF
  chmod +x "$AGENT_SCRIPT"

  tmux new-window -t "$SESSION" -n "agent-$i"
  tmux send-keys -t "$SESSION:agent-$i" "bash '$AGENT_SCRIPT'" Enter
done

# 상태판으로 포커스
tmux select-window -t "$SESSION:status"

echo ""
echo "✅ sr-team 세션 시작됨 (스크립트: $SCRIPT_DIR)"
echo "👀 실시간 확인: tmux attach -t sr-team"
echo "📁 job_dir: $JOB_DIR"
echo "🤖 에이전트 수: $TOTAL"
echo ""
echo "완료 감시: bash sr-team-watch.sh '$JOB_DIR' '$TOTAL'"
