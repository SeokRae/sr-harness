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

### 3. 프로젝트 유형 감지 후 격리 방식 결정

```bash
ls .obsidian/ 2>/dev/null && echo "vault" || echo "code"
```

#### 코드 프로젝트 (`.obsidian/` 없음) → Worktree 생성

```bash
git worktree add .claude/worktrees/{short-description} feature/{issue-number}-{short-description}
```

이후 모든 파일 작업은 worktree 안에서 수행한다.

**컨벤션**:
- 위치: `.claude/worktrees/` (프로젝트 `.gitignore`에 포함 확인)
- 이름: 브랜치의 `{short-description}` 부분 그대로 사용
- `.gitignore`에 `.claude/worktrees/` 없으면 추가 후 커밋

#### Obsidian vault (`.obsidian/` 있음) → 브랜치에서 직접 작업

worktree를 생성하지 않는다. Obsidian은 vault 루트 하나만 바라보기 때문에
worktree 파일은 머지 전까지 Obsidian에서 보이지 않아 의미가 없다.
feature 브랜치에서 직접 작업하고, 작업 결과를 바로 Obsidian에서 확인할 수 있다.

```bash
git checkout feature/{issue-number}-{short-description}
```

### 4. 확인 출력

코드 프로젝트:
```
✅ Issue #N 생성: {제목}
✅ 브랜치 생성: feature/{N}-{description}
✅ Worktree 생성: .claude/worktrees/{description}
✅ 현재 위치: .claude/worktrees/{description}

다음 단계: execute
```

Obsidian vault:
```
✅ Issue #N 생성: {제목}
✅ 브랜치 생성: feature/{N}-{description}
ℹ️  Vault 프로젝트 — worktree 없이 브랜치에서 직접 작업

다음 단계: execute
```

## 연동 규칙

- 이 스킬 완료 후 → `execute` 자동 진행
- 커밋 메시지에 항상 `(#N)` 포함
- PR body에 반드시 `Closes #N` 포함 (커밋 메시지의 #N은 closing 트리거 아님)
