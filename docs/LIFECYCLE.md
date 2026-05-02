# sr-harness 라이프사이클 정의

> v0.1.0 현황 분석 + v0.2.0 목표 사이클

---

## As-Is: v0.1.0 현재 사이클

7개 스킬이 선형으로 연결된 단방향 파이프라인.

```
┌─────────────────────────────────────────────────────────────────┐
│                     sr-harness v0.1 Lifecycle                   │
│                                                                 │
│   ┌──────────┐    ┌────────────┐    ┌──────────┐               │
│   │  START   │───▶│ BRAINSTORM │───▶│   PLAN   │               │
│   │ (라우터)  │    │ (구체화)    │    │ (설계)    │               │
│   └──────────┘    └────────────┘    └──────────┘               │
│        │                                  │                     │
│        │ (계획 있으면)                      ▼                     │
│        │                            ┌──────────┐               │
│        └──────────────────────────▶ │  ISSUE   │               │
│                                     │ (생성)    │               │
│                                     └──────────┘               │
│                                          │                     │
│                                          ▼                     │
│                                     ┌──────────┐    ┌────────┐ │
│                                     │ EXECUTE  │◀──▶│ DEBUG  │ │
│                                     │ (구현)    │    │ (진단)  │ │
│                                     └──────────┘    └────────┘ │
│                                          │                     │
│                                          ▼                     │
│                                     ┌──────────┐               │
│                                     │  FINISH  │               │
│                                     │  (PR)    │               │
│                                     └──────────┘               │
└─────────────────────────────────────────────────────────────────┘
```

**특징**: `idea → plan → issue → execute → PR` — 단일 패스, 반복 없음

---

## As-Is 갭 분석

### Critical Gaps (사이클 단절)

| # | Gap | 설명 | 영향 |
|---|-----|------|------|
| G1 | **코드 리뷰 단계 없음** | execute → finish 직행. PR 피드백 수신 시 재진입 경로 미정의 | 리뷰 피드백 반영 시 하네스 밖에서 작업 |
| G2 | **검증(Verification) 단계 없음** | "완료" 선언 전 최종 통합 확인 없음 | 빠뜨린 케이스로 PR reject |
| G3 | **중단/폐기 경로 없음** | 작업 도중 방향 전환/폐기 시 대응 미정의 | session-plan.md 좀비화 |

### High Gaps (효율 저하)

| # | Gap | 설명 |
|---|-----|------|
| G4 | **병렬 작업 미지원** | 한 번에 하나의 Issue만 처리 가능. worktree/subagent 패턴 없음 |
| G5 | **TDD 명시적 단계 없음** | execute에 "테스트 먼저" 힌트만 존재, 강제 안 됨 |
| G6 | **multi-Issue brainstorm** | brainstorm이 여러 Issue를 낳을 때 분할 루프 미정의 |

### Medium Gaps (UX 마찰)

| # | Gap | 설명 |
|---|-----|------|
| G7 | **stale session-plan 처리** | 오래된 plan 폐기 기준 없음 |
| G8 | **스킬 간 상태 전달** | brainstorm → plan 전환 시 맥락 전달 방식 미정의 |
| G9 | **에러 메시지 가이드** | debug의 "에러 전문 확인" 지시에 출력 포맷 없음 |

---

## To-Be: v0.2.0 목표 사이클

리뷰 피드백 루프 + 통합 검증 + 중단 경로를 추가한 완성형 사이클.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    sr-harness v0.2 Full Cycle                            │
│                                                                         │
│  ① IDEATE ─────▶ ② PLAN ─────▶ ③ ISSUE ─────▶ ④ EXECUTE               │
│  (brainstorm)     (설계+TDD)     (생성)         (구현)                   │
│       ▲                                           │  ▲                  │
│       │                                    fail ──┘  │                  │
│       │                                    ▼         │                  │
│       │                               ④-b DEBUG ─────┘                  │
│       │                                                                 │
│       │            ⑤ VERIFY ◀──────────── (execute 완료)                 │
│       │            (통합 검증)                                            │
│       │                │                                                │
│       │         pass   │   fail ──────────▶ ④ EXECUTE                   │
│       │                ▼                                                │
│       │           ⑥ REVIEW ─────────▶ ⑦ FINISH                          │
│       │           (코드 리뷰)          (push+PR)                         │
│       │                │                    │                           │
│       │         feedback│                    ▼                           │
│       │                ▼               ⑧ CLEANUP                        │
│       │           ④ EXECUTE            (session-plan 정리)               │
│       │           (피드백 반영)               │                           │
│       │                                     ▼                           │
│       └──────────────── (새 작업 시작) ◀─── DONE                         │
│                                                                         │
│  ⑨ ABORT: 어느 단계에서든 → Deviations 기록 + 브랜치 정리                 │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 상태 전이 테이블

| From | To | 트리거 | 담당 스킬 |
|------|----|--------|----------|
| START | BRAINSTORM | 아이디어 탐색 의도 | harness-start → harness-brainstorm |
| START | PLAN | 구체적인 요구사항 이미 있음 | harness-start → harness-plan |
| START | EXECUTE | session-plan + Issue 존재 | harness-start → harness-execute |
| BRAINSTORM | PLAN | 종료 조건 3가지 충족 | harness-brainstorm → harness-plan |
| PLAN | ISSUE | 사용자 승인 | harness-plan → harness-issue |
| ISSUE | EXECUTE | 브랜치 생성 완료 | harness-issue → harness-execute |
| EXECUTE | DEBUG | 테스트 실패 / 예상 밖 에러 | harness-execute → harness-debug |
| DEBUG | EXECUTE | 원인 확인 + 수정 완료 | harness-debug → harness-execute |
| EXECUTE | VERIFY | 모든 step verify 통과 | harness-execute → **harness-verify** *(v0.2)* |
| VERIFY | REVIEW | 통합 검증 통과 | harness-verify → **harness-review** *(v0.2)* |
| VERIFY | EXECUTE | 검증 실패 → 추가 수정 필요 | harness-verify → harness-execute |
| REVIEW | FINISH | solo 진행 또는 approve | **harness-review** → harness-finish |
| REVIEW | EXECUTE | 리뷰 피드백 수신 → 반영 | **harness-review** → harness-execute |
| FINISH | CLEANUP | PR 생성 완료 | harness-finish (session-plan 정리) |
| ANY | ABORT | 방향 전환 / 폐기 결정 | **harness-abort** *(v0.2)* |

> **볼드** 표시: v0.2에서 신규 추가 예정 스킬

---

## v0.2 신규 스킬 명세 (예고)

| 우선순위 | 스킬명 | 역할 | 해소하는 Gap |
|---------|--------|------|-------------|
| P0 | `harness-verify` | 빌드+테스트+lint 실행, 변경 파일 전수 확인 | G2 |
| P0 | `harness-review` | PR 리뷰 피드백 수신 → execute 재진입 루프 | G1 |
| P1 | `harness-abort` | session-plan 정리, 브랜치 삭제 여부 확인, deviation 기록 | G3 |
| P2 | `harness-test` | TDD Red→Green→Refactor 강제 루프 | G5 |
| P2 | `harness-parallel` | worktree 기반 다중 Issue 병렬 처리 | G4 |

---

## v0.1.1 Quick Wins (기존 스킬 보강)

기존 7개 스킬에서 발견된 개선 포인트:

| 스킬 | 문제 | 개선 방향 |
|------|------|----------|
| harness-start | 의도 모호 시 판단 기준 부재 | AskUserQuestion 호출 패턴 추가 |
| harness-brainstorm | 종료 판단을 Claude에게 위임 | 종료 전 사용자 확인 강제 |
| harness-execute | 커밋 크기 판단 가이드 없음 | "커밋 크기 = 하나의 verify 통과 단위" 명시 |
| harness-finish | 테스트 명령어 추상화 | session-plan.md의 `test-command` 필드에서 읽기 |
