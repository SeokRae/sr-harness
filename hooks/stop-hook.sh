#!/bin/bash

# Loop Stop Hook
# Handles both ralph-loop and goal-loop: prevents session exit while active,
# feeds Claude's output back as input to continue the loop.

set -euo pipefail

# Read hook input from stdin (advanced stop hook API)
HOOK_INPUT=$(cat)

RALPH_STATE_FILE=".claude/ralph-loop.local.md"
GOAL_STATE_FILE=".claude/goal-state.json"

# No active loop - allow exit
if [[ ! -f "$RALPH_STATE_FILE" ]] && [[ ! -f "$GOAL_STATE_FILE" ]]; then
  exit 0
fi

# ── Goal loop ─────────────────────────────────────────────
# Processed first so ralph (if also present) takes precedence below
if [[ ! -f "$RALPH_STATE_FILE" ]] && [[ -f "$GOAL_STATE_FILE" ]]; then

  GOAL_STATUS=$(jq -r '.status' "$GOAL_STATE_FILE" 2>/dev/null || echo "unknown")
  if [[ "$GOAL_STATUS" != "active" ]]; then
    exit 0
  fi

  # Session isolation
  GOAL_SESSION=$(jq -r '.session_id // ""' "$GOAL_STATE_FILE")
  HOOK_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""')
  if [[ -n "$GOAL_SESSION" ]] && [[ "$GOAL_SESSION" != "$HOOK_SESSION" ]]; then
    exit 0
  fi

  GOAL_ITER=$(jq -r '.iteration' "$GOAL_STATE_FILE")
  GOAL_MAX=$(jq -r '.max_iterations' "$GOAL_STATE_FILE")
  GOAL_TEXT=$(jq -r '.goal' "$GOAL_STATE_FILE")

  if [[ ! "$GOAL_ITER" =~ ^[0-9]+$ ]] || [[ ! "$GOAL_MAX" =~ ^[0-9]+$ ]]; then
    echo "⚠️  Goal loop: goal-state.json 손상됨 — 루프 중단" >&2
    bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-goal.sh" 2>/dev/null || true
    exit 0
  fi

  if [[ $GOAL_MAX -gt 0 ]] && [[ $GOAL_ITER -ge $GOAL_MAX ]]; then
    echo "🛑 Goal loop: Max iterations ($GOAL_MAX) reached."
    bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-goal.sh" 2>/dev/null || true
    exit 0
  fi

  TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')
  if [[ ! -f "$TRANSCRIPT_PATH" ]] || ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
    exit 0
  fi

  LAST_LINES=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -n 100)
  set +e
  LAST_OUTPUT=$(echo "$LAST_LINES" | jq -rs '
    map(.message.content[]? | select(.type == "text") | .text) | last // ""
  ' 2>&1)
  JQ_EXIT=$?
  set -e

  if [[ $JQ_EXIT -ne 0 ]]; then
    exit 0
  fi

  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")
  if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "GOAL_ACHIEVED" ]]; then
    echo "✅ Goal loop: <promise>GOAL_ACHIEVED</promise> 감지 — 루프 종료"
    bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-goal.sh" 2>/dev/null || true
    exit 0
  fi

  # Not complete — increment iteration and re-inject goal prompt
  NEXT_ITER=$((GOAL_ITER + 1))
  TEMP_FILE="${GOAL_STATE_FILE}.tmp.$$"
  jq --argjson n "$NEXT_ITER" '.iteration = $n' "$GOAL_STATE_FILE" > "$TEMP_FILE"
  mv "$TEMP_FILE" "$GOAL_STATE_FILE"

  GOAL_PROMPT="🎯 Goal: ${GOAL_TEXT}

이 목표가 달성될 때까지 계속 작업한다.
완료 조건에 도달하면 반드시 <promise>GOAL_ACHIEVED</promise> 를 출력한다.
(완료 조건: 목표에 기술된 상태가 실제로 달성된 것을 확인한 경우에만. 거짓으로 탈출 금지)

ownership: 이번 반복 변경을 한 문장으로 설명할 수 없으면 GOAL_ACHIEVED 선언 금지 (설명할 수 없다면 출시하지 마라)"

  jq -n \
    --arg prompt "$GOAL_PROMPT" \
    --arg msg "🔄 Goal iteration $NEXT_ITER / $GOAL_MAX | 완료: <promise>GOAL_ACHIEVED</promise>" \
    '{
      "decision": "block",
      "reason": $prompt,
      "systemMessage": $msg
    }'
  exit 0
fi

# ── Ralph loop ────────────────────────────────────────────
# Check if ralph-loop is active

# Restore bypass permissions and remove state file on any termination path.
# Called instead of bare `rm "$RALPH_STATE_FILE"` to avoid leaving
# settings.local.json with blanket Bash(*) permissions after loop ends.
cleanup_ralph() {
  local BACKUP=".claude/settings.local.json.ralph-backup"
  local SETTINGS=".claude/settings.local.json"
  if [[ -f "$BACKUP" ]]; then
    mv "$BACKUP" "$SETTINGS" 2>/dev/null || true
  elif [[ -f "$SETTINGS" ]]; then
    rm -f "$SETTINGS"
  fi
  rm -f "$RALPH_STATE_FILE"
}

# Parse markdown frontmatter (YAML between ---) and extract values
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$RALPH_STATE_FILE")
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
# Extract completion_promise and strip surrounding quotes if present
COMPLETION_PROMISE=$(echo "$FRONTMATTER" | grep '^completion_promise:' | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')

# Session isolation: the state file is project-scoped, but the Stop hook
# fires in every Claude Code session in that project. If another session
# started the loop, this session must not block (or touch the state file).
# Legacy state files without session_id fall through (preserves old behavior).
STATE_SESSION=$(echo "$FRONTMATTER" | grep '^session_id:' | sed 's/session_id: *//' || true)
HOOK_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""')
if [[ -n "$STATE_SESSION" ]] && [[ "$STATE_SESSION" != "$HOOK_SESSION" ]]; then
  exit 0
fi

# Validate numeric fields before arithmetic operations
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Ralph loop: State file corrupted" >&2
  echo "   File: $RALPH_STATE_FILE" >&2
  echo "   Problem: 'iteration' field is not a valid number (got: '$ITERATION')" >&2
  echo "" >&2
  echo "   This usually means the state file was manually edited or corrupted." >&2
  echo "   Ralph loop is stopping. Run /ralph-loop again to start fresh." >&2
  cleanup_ralph
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Ralph loop: State file corrupted" >&2
  echo "   File: $RALPH_STATE_FILE" >&2
  echo "   Problem: 'max_iterations' field is not a valid number (got: '$MAX_ITERATIONS')" >&2
  echo "" >&2
  echo "   This usually means the state file was manually edited or corrupted." >&2
  echo "   Ralph loop is stopping. Run /ralph-loop again to start fresh." >&2
  cleanup_ralph
  exit 0
fi

# Check if max iterations reached
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "🛑 Ralph loop: Max iterations ($MAX_ITERATIONS) reached."
  cleanup_ralph
  exit 0
fi

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️  Ralph loop: Transcript file not found" >&2
  echo "   Expected: $TRANSCRIPT_PATH" >&2
  echo "   This is unusual and may indicate a Claude Code internal issue." >&2
  echo "   Ralph loop is stopping." >&2
  cleanup_ralph
  exit 0
fi

# Read last assistant message from transcript (JSONL format - one JSON per line)
# First check if there are any assistant messages
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  echo "⚠️  Ralph loop: No assistant messages found in transcript" >&2
  echo "   Transcript: $TRANSCRIPT_PATH" >&2
  echo "   This is unusual and may indicate a transcript format issue" >&2
  echo "   Ralph loop is stopping." >&2
  cleanup_ralph
  exit 0
fi

# Extract the most recent assistant text block.
#
# Claude Code writes each content block (text/tool_use/thinking) as its own
# JSONL line, all with role=assistant. So slurp the last N assistant lines,
# flatten to text blocks only, and take the last one.
#
# Capped at the last 100 assistant lines to keep jq's slurp input bounded
# for long-running sessions.
LAST_LINES=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -n 100)
if [[ -z "$LAST_LINES" ]]; then
  echo "⚠️  Ralph loop: Failed to extract assistant messages" >&2
  echo "   Ralph loop is stopping." >&2
  cleanup_ralph
  exit 0
fi

# Parse the recent lines and pull out the final text block.
# `last // ""` yields empty string when no text blocks exist (e.g. a turn
# that is all tool calls). That's fine: empty text means no <promise> tag,
# so the loop simply continues.
# (Briefly disable errexit so a jq failure can be caught by the $? check.)
set +e
LAST_OUTPUT=$(echo "$LAST_LINES" | jq -rs '
  map(.message.content[]? | select(.type == "text") | .text) | last // ""
' 2>&1)
JQ_EXIT=$?
set -e

# Check if jq succeeded
if [[ $JQ_EXIT -ne 0 ]]; then
  echo "⚠️  Ralph loop: Failed to parse assistant message JSON" >&2
  echo "   Error: $LAST_OUTPUT" >&2
  echo "   This may indicate a transcript format issue." >&2
  echo "   Ralph loop is stopping." >&2
  cleanup_ralph
  exit 0
fi

# Check for completion promise (only if set)
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  # Extract text from <promise> tags using Perl for multiline support
  # -0777 slurps entire input, s flag makes . match newlines
  # .*? is non-greedy (takes FIRST tag), whitespace normalized
  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")

  # Use = for literal string comparison (not pattern matching)
  # == in [[ ]] does glob pattern matching which breaks with *, ?, [ characters
  if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
    echo "✅ Ralph loop: Detected <promise>$COMPLETION_PROMISE</promise>"
    cleanup_ralph
    exit 0
  fi
fi

# Not complete - continue loop with SAME PROMPT
NEXT_ITERATION=$((ITERATION + 1))

# Extract prompt (everything after the closing ---)
# Skip first --- line, skip until second --- line, then print everything after
# Use i>=2 instead of i==2 to handle --- in prompt content
PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$RALPH_STATE_FILE")

if [[ -z "$PROMPT_TEXT" ]]; then
  echo "⚠️  Ralph loop: State file corrupted or incomplete" >&2
  echo "   File: $RALPH_STATE_FILE" >&2
  echo "   Problem: No prompt text found" >&2
  echo "" >&2
  echo "   This usually means:" >&2
  echo "     • State file was manually edited" >&2
  echo "     • File was corrupted during writing" >&2
  echo "" >&2
  echo "   Ralph loop is stopping. Run /ralph-loop again to start fresh." >&2
  cleanup_ralph
  exit 0
fi

# Update iteration in frontmatter (portable across macOS and Linux)
# Create temp file, then atomically replace
TEMP_FILE="${RALPH_STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$RALPH_STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$RALPH_STATE_FILE"

# Build system message with iteration count and completion promise info
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  SYSTEM_MSG="🔄 Ralph iteration $NEXT_ITERATION | To stop: output <promise>$COMPLETION_PROMISE</promise> (ONLY when statement is TRUE - do not lie to exit!)"
else
  SYSTEM_MSG="🔄 Ralph iteration $NEXT_ITERATION | No completion promise set - loop runs infinitely"
fi

# Output JSON to block the stop and feed prompt back
# The "reason" field contains the prompt that will be sent back to Claude
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

# Exit 0 for successful hook execution
exit 0
