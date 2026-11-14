---
name: submit
description: 구현 완료 후 push + PR 생성 스킬. "PR 올려줘", "push해줘", "submit", "리뷰 요청" 시 사용. 항상 push + PR(Closes #N)로 제출. 사용자가 PR을 눈으로 확인한 뒤 finish로 머지.
---

# submit

검증이 완료된 브랜치를 리뷰에 제출한다.
push + PR 생성이 이 스킬의 끝이다. **머지는 사용자가 확인 후 `finish`에서 처리한다.**

## 실행 순서

### 1. 최종 확인
```bash
git diff --name-only origin/main...HEAD   # 이 브랜치가 커밋한 변경
git diff --cached --name-only             # 스테이징한 변경
git status --short                        # 범위 안 파일에 미커밋 수정이 없는지
```

범위(앞 두 목록) 안 파일에 미커밋 수정이 있으면 커밋한 뒤 세 명령을 다시 돌려 확인하고 진행한다. 범위 밖 미커밋 파일과 미추적 파일은 목록만 보이고 손대지 않는다(verify 1단계와 같음).

테스트 명령어는 다음 순서로 결정한다:
1. `.claude/session-plan.md`의 `test-command` 필드가 있으면 → 그 명령어 실행
2. 없으면 → 프로젝트 루트에서 `./gradlew test` / `npm test` / `pytest` 순으로 시도
3. 어느 것도 없으면 → 사용자에게 테스트 명령어 확인 후 실행

```yaml
# session-plan.md 예시
test-command: ./gradlew integrationTest
```

사용자가 "테스트는 CI에 맡겨", "급하니 생략"처럼 테스트를 건너뛰라고 해도 push 전에 테스트를 먼저 실행한다.
- 실패하면 push와 PR 생성을 하지 않고 실패 출력을 보고한다(verify Iron Law).
- 테스트를 실행할 수 없으면(테스트 명령이 없거나 실행 환경이 없어 돌릴 수 없으면) push 전에 멈추고, 테스트 미검증 상태로 PR을 올릴지 한 번 묻는다. 오래 걸린다는 이유만으로 건너뛰지 않는다.
- 사용자가 미검증 제출을 승인하면 PR 본문 테스트 항목에 미검증이라고 적고 진행한다.

### 2. Push
```bash
git push origin feature/{N}-{description}
```

### 3. PR 생성

`.claude/session-plan.md`의 `## Decisions` 절을 PR 본문 "결정" 절로 옮긴다.
- `결정: AI`인 줄을 "AI가 정한 것 (먼저 확인)"에 먼저 두고, `결정: 사람`인 줄을 "사람이 정한 것"에 둔다. 리뷰어가 AI 단독 선택부터 보게 하려는 순서다
- 뒤집힌 결정은 옛 줄과 새 줄을 함께 옮긴다
- 절이 없거나 비어 있으면 "새로 정한 것 없음"이라고 적는다. 절을 빼지 않는다

```bash
gh pr create \
  --title "{type}: {설명}" \
  --body "## 변경 내용

{변경 내용 요약}

## 결정

### AI가 정한 것 (먼저 확인)
- D-{번호} {무엇을 정했나}: {고른 것} | 이유: {한 줄} | 제안: {사람|AI}

### 사람이 정한 것
- D-{번호} ...

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

PR을 확인하고 머지할 준비가 되면 /finish 를 실행하세요.
```

## session-plan.md 정리

PR 생성 후:
- 완료 → 파일 삭제 또는 아카이브
- 미완료 항목 있으면 → 파일 유지 (다음 세션에서 이어서 사용)
