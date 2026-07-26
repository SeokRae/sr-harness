# sr-harness 라이프사이클 정의

> v0.20 현재 사이클 — 20개 스킬로 구성된 완성형 워크플로우

---

## 현재 사이클 (v0.18)

`start`가 작업 유형을 라우팅하고, 핵심 워크플로우가 idea → PR → merge를 단일 흐름으로 잇는다.
검증·리뷰·중단·자율 실행 경로가 모두 포함된 반복형 사이클이다.

```
start ─ 라우팅 ─┐
               ▼
  brainstorm → plan → issue → execute → analyze → verify → submit →(사용자 확인)→ finish → DONE
                                ▲▼                              ▲
                              debug                review ──────┘
                                                  (리뷰 피드백 → execute 재진입)

  자율 실행:  ralph (execute→verify 자동 루프, bypass)  ·  goal (목표 기반 Stop-hook 루프)
  중단·인계:  abort (어느 단계서든 정리)                 ·  pause (다음 세션 인계)
  릴리즈:     release (머지 후 GitHub Release)
  진화:       meta (스킬 1회 진화 루프)
  보조 체크:  dev-coding-principles · dev-architecture · dev-stack-java (execute가 자동 로드)
```

**특징**: `idea → plan → issue → execute → verify → submit → finish` — 검증·리뷰·중단 경로를 갖춘 반복형 사이클 (v0.1의 단일 패스에서 진화)

**v0.20**: `plan`이 내장 Plan Mode(opusplan)를 실행 엔진으로 흡수했다. 별도 브릿지 스킬이 아니라 `plan` 자체의 정의가 바뀐 것 —
"계획을 세운다" = "Plan Mode에 들어가 계획 파일을 쓰고 `ExitPlanMode`로 승인받는다". `ExitPlanMode` 승인이 곧 `PLAN → ISSUE` 전이 트리거이며,
`.claude/session-plan.md`는 그 산출물과 별개로 다시 쓰는 게 아니라 승인 시점에 함께 생성되는 요약이다. 필요 시 같은 계획 파일에 PRD 섹션을 포함할 수 있다(아래 참고).

---

## 스킬 맵 (20개)

| 분류 | 스킬 | 역할 |
|------|------|------|
| **진입** | `start` | 작업 유형 라우팅 · karpathy 즉시 체크 |
| **핵심 흐름** | `brainstorm` | 아이디어 → Issue 단위로 구체화 |
| | `plan` | 내장 Plan Mode(opusplan)로 조사 → (필요 시 PRD) → step → verify 형식 계획 |
| | `issue` | GitHub Issue + feature 브랜치 (1 Issue = 1 Branch = 1 PR) |
| | `execute` | karpathy 체크포인트 구현 (단일/팀/순차 모드) |
| | `debug` | 진단 우선 디버깅 (진단 게이트) |
| | `analyze` | 의도 정합성 게이트 (Issue ↔ diff, verify 전) |
| | `verify` | 증거 기반 통합 검증 (Iron Law) |
| | `review` | 리뷰 피드백 → execute 재진입 |
| | `submit` | push + PR (Closes #N) · 사용자 확인 대기 |
| | `finish` | 머지 + 브랜치 정리 + main pull |
| **자율 실행** | `ralph` | execute→verify 자동 루프 (bypass) |
| | `goal` | 목표 기반 자율 실행 (Stop hook) |
| **중단·인계** | `abort` | 작업 중단 · 브랜치 정리 |
| | `pause` | 세션 중단 · 다음 세션 인계 |
| **릴리즈** | `release` | GitHub Release 생성 (버전 + 자동 노트) |
| **진화** | `meta` | 스킬 진화 루프 (메커니즘이 다른 후보 3개 제안) |
| **보조 체크리스트** | `dev-coding-principles` | 네이밍·예외처리·테스트 |
| | `dev-architecture` | Hexagonal·레이어·패키지 구조 |
| | `dev-stack-java` | Spring Boot·JPA·예외 (스택 자동 감지) |

---

## 상태 전이 테이블

| From | To | 트리거 | 담당 |
|------|----|--------|------|
| START | BRAINSTORM | 아이디어 탐색 의도 | start → brainstorm |
| START | PLAN | 구체적 요구사항 존재 | start → plan |
| START | EXECUTE | session-plan + Issue 존재 | start → execute |
| BRAINSTORM | PLAN | 종료 조건 3가지 충족 | brainstorm → plan |
| PLAN | ISSUE | `ExitPlanMode` 승인 (= 사용자 승인) | plan → issue |
| ISSUE | EXECUTE | 브랜치 생성 완료 | issue → execute |
| EXECUTE | DEBUG | 테스트 실패 / 예상 밖 에러 | execute → debug |
| DEBUG | EXECUTE | 원인 확인 + 수정 완료 | debug → execute |
| EXECUTE | ANALYZE | 모든 step verify 통과 | execute → analyze |
| ANALYZE | VERIFY | 정합성 게이트 통과 | analyze → verify |
| ANALYZE | EXECUTE | 누락/모순 발견 | analyze → execute |
| VERIFY | SUBMIT | 통합 검증 통과 | verify → submit |
| VERIFY | EXECUTE | 검증 실패 → 추가 수정 | verify → execute |
| SUBMIT | (사용자 확인) | PR 생성 후 정지 | submit |
| (리뷰 수신) | REVIEW | PR 리뷰 피드백 도착 | review |
| REVIEW | EXECUTE | 피드백 반영 | review → execute |
| (확인 후) | FINISH | 사용자 머지 요청 | finish |
| FINISH | DONE | 머지 + 브랜치 정리 + main pull | finish |
| ANY | ABORT | 방향 전환 / 폐기 결정 | abort |
| ANY | PAUSE | 세션 중단 / 다음 세션 인계 | pause |
| PLAN 이후 | RALPH / GOAL | 자율 실행 요청 | ralph / goal |
| DONE 이후 | RELEASE | 릴리즈 태깅 | release |

---

## 해소된 갭 (v0.1 → v0.16)

v0.1.0 분석에서 식별한 갭의 현재 상태.

| # | 갭 | 상태 | 해소 |
|---|----|------|------|
| G1 | 코드 리뷰 단계 없음 | ✅ 해소 | `review` 스킬 |
| G2 | 통합 검증 단계 없음 | ✅ 해소 | `verify` 스킬 (증거 기반 Iron Law) |
| G3 | 중단/폐기 경로 없음 | ✅ 해소 | `abort` · `pause` |
| G4 | 병렬 작업 미지원 | ◐ 부분 | `execute` 팀모드 (Agent 병렬 dispatch) |
| G5 | TDD 명시적 단계 없음 | ◐ 부분 | `execute`·`debug`에 재현 테스트 우선 원칙 (전용 스킬은 미구현) |
| G6 | multi-Issue brainstorm | ✗ 미구현 | — |
| G7 | stale session-plan 처리 | ✅ 해소 | `pause`·`abort`의 session-plan 정리 |
| G8 | 스킬 간 상태 전달 | ✅ 해소 | `.claude/session-plan.md` 공유 |
| G9 | 에러 메시지 가이드 | ✅ 해소 | `debug` 진단 게이트 (출력 필수) |

---

## 남은 로드맵

| 우선순위 | 항목 | 해소할 갭 |
|---------|------|----------|
| P2 | TDD Red→Green→Refactor 강제 스킬 | G5 |
| P2 | 다중 Issue 병렬 처리 정식 스킬 (현재는 `execute` 팀모드로 일부 대체) | G4 |
| P3 | multi-Issue brainstorm 분할 루프 | G6 |
