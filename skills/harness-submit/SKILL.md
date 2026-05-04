---
name: harness-submit
description: 구현 완료 후 push + PR 생성 스킬. "PR 올려줘", "push해줘", "submit", "리뷰 요청" 시 사용. 항상 push + PR(Closes #N)로 제출. 사용자가 PR을 눈으로 확인한 뒤 harness-finish로 머지.
---

# harness-submit

검증이 완료된 브랜치를 리뷰에 제출한다.
push + PR 생성이 이 스킬의 끝이다. **머지는 사용자가 확인 후 `harness-finish`에서 처리한다.**

## 실행 순서

### 1. 최종 확인
```bash
git status   # 미커밋 변경사항 없는지
```

테스트 명령어는 다음 순서로 결정한다:
1. `.claude/session-plan.md`의 `test-command` 필드가 있으면 → 그 명령어 실행
2. 없으면 → 프로젝트 루트에서 `./gradlew test` / `npm test` / `pytest` 순으로 시도
3. 어느 것도 없으면 → 사용자에게 테스트 명령어 확인 후 실행

```yaml
# session-plan.md 예시
test-command: ./gradlew integrationTest
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

### 4. 제출 보고
```
✅ PR 생성: #{PR-number}
✅ Closes #{issue-number}
브랜치: feature/{N}-{description}

PR을 확인하고 머지할 준비가 되면 harness-finish를 실행하세요.
```

## session-plan.md 정리

PR 생성 후:
- 완료 → 파일 삭제 또는 아카이브
- 미완료 항목 있으면 → 파일 유지 (다음 세션에서 이어서 사용)
