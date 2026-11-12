---
name: verify
description: 구현 완료 후 PR 생성 전 통합 검증 스킬. execute 모든 step verify 통과 후 자동 실행. 빌드·테스트·변경파일 전수 확인. 통과 시 submit, 실패 시 execute 재진입.
---

# verify

"완료됐다고 생각하는 것"과 "실제로 완료된 것"을 구분한다.
**`analyze`(의도 정합성)를 통과한 뒤 진입**하며, **submit를 호출하기 전에 반드시 이 스킬을 먼저 통과한다.**

## ⛔ Iron Law

이번 메시지에서 직접 실행한 명령의 출력 없이는 어떤 항목도 ✅로 표시할 수 없다.
명령을 안 돌렸으면 그 항목은 ⬜(미검증)이고, ⬜가 하나라도 있으면 submit 불가.
**규칙의 문구를 어기는 것은 규칙의 정신을 어기는 것이다.**

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

### 4. Completion Audit (goal 활성 시만 실행)

```bash
cat .claude/goal-state.json 2>/dev/null | jq -r 'select(.status == "active") | .goal'
```

`.claude/goal-state.json`이 존재하고 `status == "active"`이면:
- goal 텍스트를 읽어 다음 질문에 답한다:
  **"현재 코드/파일 상태가 goal에 기술된 목표를 완전히 달성했는가?"**
  - YES → `<promise>GOAL_ACHIEVED</promise>` 출력 후 아래 보고에 포함
  - NO → 미달성 이유 명시 + execute 재진입 (submit 금지)

파일이 없거나 status != "active"이면 이 단계를 건너뛴다.

### 5. 검증 결과 보고 (증거 첨부 필수)

각 항목은 **이번 메시지에서 실행한 명령의 실제 출력**을 함께 적을 때만 ✅로 인정된다.

| 주장 | 통과로 인정되는 증거 |
|------|---------------------|
| 미커밋 없음 | `git status` 출력에 `nothing to commit` 포함 |
| 변경 파일 의도대로 | `git diff --name-only` 출력 전체 |
| 테스트 통과 | 테스트 출력 요약줄 (`N passed, 0 failed` 등) |
| Completion Audit | goal 문장과 1:1 대응하는 달성 근거 |

```
[verify 결과]
✅ 미커밋 없음 — `nothing to commit, working tree clean`
✅ 변경 {N}개 — {파일 목록}
✅ 테스트 {명령어} — `{출력 요약줄}`
✅ Completion Audit — {달성 근거 / 해당 없음}
```
출력을 첨부하지 못하는 항목은 ✅ 대신 ⬜로 적고, ⬜가 하나라도 있으면 submit하지 않는다.

## 결과에 따른 전환

| 결과 | 다음 단계 |
|------|----------|
| 모든 항목 통과 | `submit` 호출 |
| 테스트 실패 | `debug` 전환 후 `execute` 재진입 |
| Completion Audit 미달성 | execute 재진입 (submit 금지) |
| 의도치 않은 파일 변경 | 사용자 확인 후 수정 → 재검증 |
| 미커밋 변경 있음 | 커밋 처리 후 재검증 |

## 금지 사항

- 테스트 실패 상태에서 submit 진행 금지
- 변경 파일 목록 확인 없이 submit 진행 금지
- 이번 메시지에서 실행한 출력 없이 ✅ 표시 후 submit 금지

## Red Flags (이 생각이 들면 멈추고 ⬜ 처리)

| 떠오른 생각 | 현실 |
|------------|------|
| "테스트는 아마 통과할 것" | 미검증. 추측은 증거가 아니다 — ⬜. |
| "방금 전에 돌렸으니 또 안 돌려도 됨" | 마지막 수정 이후 출력이 이번 메시지에 없으면 ⬜. |
| "변경이 작으니 안전" | 변경 크기와 검증은 무관. 돌려서 확인한다. |
| "execute에서 통과하는 거 봤음" | 그건 다른 메시지다. verify는 이번 메시지의 출력으로만 통과. |

✅를 적기 전에 자문한다: **"이번 메시지에 이 명령의 출력이 실제로 있는가?"**
