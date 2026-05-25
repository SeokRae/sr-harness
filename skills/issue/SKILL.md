---
name: issue
description: GitHub Issue 생성 및 feature 브랜치 생성 스킬. plan 완료 후 자동 실행. "이슈 만들어줘", "브랜치 생성", "작업 시작" 시 사용. 1 Issue = 1 Branch = 1 PR 규칙 강제.
---

# issue

모든 코드 변경은 GitHub Issue에서 시작한다.
**Issue 없이 브랜치를 만들지 않는다. 브랜치 없이 코드를 수정하지 않는다.**

## 실행 순서

### 1. Issue 생성
```bash
gh issue create \
  --title "{feat|fix|refactor}: {설명}" \
  --body "{계획 내용 또는 배경 설명}"
```

생성된 Issue 번호를 기억한다 (이후 모든 단계에서 사용).

### 2. 브랜치 생성 (origin/main 기준)
```bash
git checkout main
git pull origin main
git checkout -b feature/{issue-number}-{short-description}
```

**절대 금지**:
- 로컬 main에 커밋이 있는 상태에서 분기 (force push 사이클 발생)
- 다른 feature 브랜치에서 분기 (체인 브랜치 금지)
- 한 브랜치에 여러 Issue 혼재

### 3. 프로젝트 유형 감지

```bash
ls .obsidian/ 2>/dev/null && echo "vault" || echo "code"
```

브랜치가 이미 체크아웃된 상태이므로 별도 격리 작업은 없다.
모든 파일 작업은 프로젝트 루트에서 수행한다.

> **Worktree는 사용하지 않는다.** 단일 순차 개발에서 worktree를 쓰면
> 메인 IDE에서 변경 내용이 보이지 않아 PR 리뷰 전 코드 확인이 불편하다.
> 병렬 브랜치 작업이 필요한 경우에만 수동으로 worktree를 생성한다.

### 4. 확인 출력

```
✅ Issue #N 생성: {제목}
✅ 브랜치 생성 및 체크아웃: feature/{N}-{description}

다음 단계: execute
```

## 연동 규칙

- 이 스킬 완료 후 → `execute` 자동 진행
- 커밋 메시지에 항상 `(#N)` 포함
- PR body에 반드시 `Closes #N` 포함 (커밋 메시지의 #N은 closing 트리거 아님)
