---
name: harness-pause
description: 세션 중단 및 다음 세션 인계 스킬. "세션 마무리해줘", "여기까지만", "다음 세션에서 이어서", "오늘은 여기까지", "잠깐 끊을게" 시 사용. session-plan.md를 최신화하여 harness-start가 다음 세션에서 자동으로 이어받을 수 있게 한다.
---

# harness-pause

세션을 안전하게 중단하고, 다음 세션이 끊김 없이 이어갈 수 있도록 현재 상태를 저장한다.

## 실행 순서

### 1. 미커밋 변경사항 확인

```bash
git status
```

- 미커밋 변경사항이 있으면 → 커밋할지 사용자에게 확인
- 커밋하려면 `harness-execute`의 커밋 단계로 안내
- 커밋 안 해도 된다면 → 그대로 진행 (WIP 상태임을 session-plan에 기록)

### 2. 활성 worktree 확인

```bash
git worktree list
```

활성 worktree가 있으면 브랜치명과 Issue 번호를 session-plan에 기록한다.

### 3. session-plan.md 생성 또는 업데이트

파일 위치: `{프로젝트 루트}/.claude/session-plan.md`

**이미 있으면**: 완료된 항목을 `- [x]`로, 미완료 항목은 `- [ ]`로 업데이트.
**없으면**: 아래 형식으로 새로 생성.

```markdown
---
session: YYYY-MM-DD
goal: {이번 세션에서 한 일 한 줄 요약}
branch: feature/{N}-{description}   # 활성 worktree가 있을 때만
issue: {N}                           # 활성 worktree가 있을 때만
scope:
  - {완료한 작업 항목}
  - {남은 작업 항목}
out-of-scope:
  - {이번 세션에서 다루지 않기로 한 것}
---

## Tasks

- [x] {완료된 항목}
- [ ] {미완료 항목}

## Deviations

{범위 이탈 항목 — 새 세션 후보}
```

### 4. 인계 요약 출력

사용자에게 다음 형식으로 보고한다:

```
⏸ 세션 중단

✅ 완료: {완료된 항목 목록}
⏳ 남은 작업: {미완료 항목 목록}
📌 다음 세션 시작점: {다음에 해야 할 첫 번째 항목}

session-plan.md 저장됨 → 다음 세션에서 harness-start가 자동으로 이어받습니다.
```

## 주의

- worktree는 제거하지 않는다 — 다음 세션에서 harness-start가 감지해 재개 안내
- session-plan.md는 프로젝트 루트 `.claude/` 아래에 저장 (vault는 `.claude/session-plan.md`)
- 미완료 항목이 0개면 → harness-finish로 안내 (브랜치를 완전히 닫을 수 있는 상태)
