---
name: harness-verify
description: 구현 완료 후 PR 생성 전 통합 검증 스킬. harness-execute 모든 step verify 통과 후 자동 실행. 빌드·테스트·변경파일 전수 확인. 통과 시 harness-submit, 실패 시 harness-execute 재진입.
---

# harness-verify

"완료됐다고 생각하는 것"과 "실제로 완료된 것"을 구분한다.
**harness-submit를 호출하기 전에 반드시 이 스킬을 먼저 통과한다.**

## 검증 체크리스트

### 1. 미커밋 변경사항 없는지
```bash
git status
```
→ `nothing to commit` 이어야 통과. 아니면 커밋 또는 stash 후 재확인.

### 2. 변경 파일 목록 확인
```bash
git diff origin/main --name-only
```
→ 목록을 사용자에게 보여준다. 의도하지 않은 파일이 있으면 멈추고 확인한다.

### 3. 테스트 실행
테스트 명령어는 다음 순서로 결정:
1. `.claude/session-plan.md`의 `test-command` 필드
2. 프로젝트 루트의 `./gradlew test` / `npm test` / `pytest`
3. 모두 없으면 → 사용자에게 확인

```bash
{테스트 명령어 실행}
```

### 4. 검증 결과 보고
```
[harness-verify 결과]
✅ 미커밋 변경사항 없음
✅ 변경 파일: {N}개 (목록 표시)
✅ 테스트: {명령어} → {통과/실패}
```

## 결과에 따른 전환

| 결과 | 다음 단계 |
|------|----------|
| 모든 항목 통과 | `harness-submit` 호출 |
| 테스트 실패 | `harness-debug` 전환 후 `harness-execute` 재진입 |
| 의도치 않은 파일 변경 | 사용자 확인 후 수정 → 재검증 |
| 미커밋 변경 있음 | 커밋 처리 후 재검증 |

## 금지 사항

- 테스트 실패 상태에서 harness-submit 진행 금지
- 변경 파일 목록 확인 없이 harness-submit 진행 금지
