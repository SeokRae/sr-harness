---
name: harness-finish
description: 브랜치 마무리 및 PR 생성 스킬. "완료", "PR 올려줘", "마무리", "push해줘" 시 사용. 항상 push + PR(Closes #N)로 마무리. 다른 선택지(로컬 머지, 브랜치 폐기 등) 없음.
---

# harness-finish

구현이 완료되면 반드시 push + PR로 마무리한다.
**다른 선택지는 없다.** 로컬 머지, 브랜치 폐기는 이 프로젝트에서 선택지가 아니다.

## 실행 순서

### 1. 최종 확인
```bash
git status   # 미커밋 변경사항 없는지
# 프로젝트에 맞는 테스트 실행 (예: ./gradlew test, npm test, pytest ...)
```

### 2. Push
```bash
git push origin feature/{N}-{description}
```

### 3. PR 생성
```bash
gh pr create \
  --title "{type}: {설명}" \
  --body "## 변경 내용

{변경 내용 요약}

## 테스트

- [ ] 통합 테스트 통과

Closes #{N}"
```

**PR body `Closes #N` 필수** — 커밋 메시지의 `(#N)`은 Issue를 자동 close하지 않음.

### 4. 완료 보고
```
✅ PR 생성: #{PR-number}
✅ Closes #{issue-number}
브랜치: feature/{N}-{description}
```

## session-plan.md 정리

PR 생성 후:
- 완료 → 파일 삭제 또는 아카이브
- 미완료 항목 있으면 → 파일 유지 (다음 세션에서 이어서 사용)
