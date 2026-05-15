---
name: finish
description: PR 머지 및 브랜치 정리 스킬. "머지해줘", "마무리해줘", "브랜치 정리", "완료 처리" 시 사용. submit으로 PR 생성 후 사용자 확인이 끝나면 실행. 머지 + 브랜치 삭제 + main pull까지 처리.
---

# finish

사용자가 PR을 확인하고 승인했다. 이제 진짜 마무리다.
머지 → 브랜치 삭제 → main 동기화 순서로 처리한다.

## 실행 순서

### 1. PR 상태 확인
```bash
gh pr view {PR-number}
```
→ 리뷰 코멘트나 미해결 이슈가 있으면 사용자에게 확인 후 진행.

### 2. 머지
```bash
gh pr merge {PR-number} --squash --delete-branch
```

머지 전략 선택 기준:
- `--squash`: 기본값. 단일 커밋으로 정리되어 main 히스토리가 깔끔함
- `--merge`: step별 커밋을 main에 그대로 남겨야 할 때
- `--rebase`: 리니어 히스토리를 유지하면서 각 커밋을 보존할 때

### 3. main 동기화
```bash
git checkout main
git pull origin main
```

> **Obsidian vault**: `git checkout main`이 feature 브랜치 → main 전환을 겸한다.
> pull 완료 시점에 Obsidian vault에 파일이 즉시 반영된다.

### 4. Worktree 정리 (코드 프로젝트 + worktree 사용 시)
```bash
git worktree remove .claude/worktrees/{description}
```

> **Obsidian vault**: worktree 없이 작업했으므로 이 단계 생략.

### 4.5. 로컬 브랜치 삭제
```bash
git branch -d feature/{N}-{description}
```
→ `-d` 는 머지된 브랜치만 삭제 (안전). 미머지 브랜치는 `-D` 를 쓰되 사용자 확인 필수.
→ 머지된 브랜치 전체 일괄 정리:
```bash
git branch --merged main | grep -v '^\* main' | xargs git branch -d
```

### 5. 플랜 파일 삭제
```bash
rm -f .claude/session-plan.md
```
파일이 없으면 그냥 넘어간다.

### 6. 완료 보고
```
✅ PR #{PR-number} 머지 완료
✅ Issue #{issue-number} close
✅ 브랜치 삭제: feature/{N}-{description}
✅ 로컬 브랜치 삭제: feature/{N}-{description}
✅ main 동기화 완료
✅ session-plan.md 삭제
```
