---
name: ralph
description: execute + verify 단계를 Ralph Loop bypass 모드로 자동화. plan 확정 후 사용. verify 통과까지 반복 → READY_FOR_PR 출력 → submit 안내.
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-ralph.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-ralph.sh:*)"]
---

# harness-ralph

plan이 확정된 상태에서 execute → verify 루프를 자동화한다.
verify 통과까지 사람 개입 없이 반복한다.

## 실행 순서

### 1. setup 스크립트 실행

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-ralph.sh"
```

스크립트가 자동으로 처리하는 것:
- `.claude/session-plan.md` 존재 + feature 브랜치 확인
- 기존 Ralph 루프 중복 실행 방지
- `.claude/settings.local.json` 백업 → bypass 권한 추가
- `.claude/ralph-loop.local.md` 상태 파일 생성 (session_id, max_iterations, karpathy 원칙 포함 프롬프트)

에러가 있으면 스크립트가 메시지와 함께 종료된다:
- `session-plan.md 없음` → `plan` 스킬로 먼저 계획 작성
- `main 브랜치` 또는 `detached HEAD` → `issue` 스킬로 feature 브랜치 생성
- `활성 루프 존재` → cleanup 스크립트 실행

### 2. 첫 번째 반복 즉시 시작

상태 파일 생성 직후, Ralph 프롬프트 내용을 따라 Step 1부터 실행한다.
Stop hook이 이후 반복을 자동 처리한다.

## 중단 방법

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-ralph.sh"
```

상태 파일 제거 + bypass 권한 복구를 함께 처리한다.

## verify 통과 시 처리 (Ralph 루프 내 지침)

모든 Tasks 완료 + verify 통과 확인 후:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-ralph.sh"
```

실행 후 다음을 출력하고 promise를 선언한다:

```
✅ verify 통과. Ralph 루프 종료.
변경 파일: (git diff origin/main --name-only)
다음 단계: /submit
```

```
<promise>READY_FOR_PR</promise>
```

## 금지 사항

- plan 없이 ralph 시작 금지
- main 브랜치에서 실행 금지 (feature 브랜치 필요 — vault·code 공통)
- Tasks 미완료 상태에서 promise 출력 금지
- 테스트 실패 상태에서 promise 출력 금지
