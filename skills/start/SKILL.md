---
name: start
description: sr-harness 세션 진입점. 모든 대화 시작 시 반드시 먼저 실행. 작업 유형(아이디어 탐색/계획/구현/디버깅/마무리)을 파악하고 적절한 harness 스킬로 라우팅. 코딩 작업 전 karpathy 체크 강제 실행.
---

# sr-harness 진입점

**모든 응답 전에 이 스킬을 먼저 실행한다.**

## 세션 시작 루틴

1. `.claude/session-plan.md` 존재 여부 확인
   - 있으면: 목표와 미완료 항목 로드 → 사용자에게 한 줄로 상태 보고
   - 없으면: 작업 시작 전에 생성 (목표 + scope + tasks 포함)

2. 활성 worktree 감지
   ```bash
   git worktree list
   ```
   - `.claude/worktrees/`에 활성 worktree가 있으면 → 해당 작업 재개 안내
   - 없으면 → 새 작업 시작

3. 아래 라우팅 표로 적절한 스킬 호출

## 라우팅 표

| 사용자 의도 | 호출할 스킬 |
|------------|------------|
| 아이디어 탐색, 방향 논의, 뭔가 만들고 싶어 | `brainstorm` |
| 구현 계획 수립, 설계 | `plan` |
| Issue 생성, 브랜치 생성 | `issue` |
| 코드 작성, 기능 구현, PR 작업 | `execute` |
| 자동으로 구현, ralph 모드, bypass로 실행 | `ralph` |
| 버그, 테스트 실패, 에러 | `debug` |
| PR 올리기, push, 리뷰 요청 | `submit` |
| 머지, 마무리, 브랜치 정리 | `finish` |
| 세션 중단, 다음 세션에서 이어서, 여기까지만 | `pause` |

### 의도 모호 시 질문 목록

라우팅 표에 매핑되지 않으면 구현을 시작하지 않고 다음 중 하나를 질문한다:

- "지금 하려는 게 새 아이디어 탐색인가요, 아니면 이미 계획이 있나요?"
- "현재 진행 중인 Issue가 있나요? 있다면 번호를 알려주세요."
- "코드를 작성하려는 건가요, 아니면 방향을 논의하려는 건가요?"

의도가 명확해지기 전에 `execute`나 `plan`을 호출하지 않는다.

## 코딩 작업 전 karpathy 즉시 체크

작업이 코드 수정을 포함하면, 시작 전에 다음을 확인한다:

- **명확성**: 요청이 불명확하면 → 구현 전에 먼저 질문
- **단순성**: 더 단순한 방법이 있으면 → 먼저 제안
- **성공 기준**: 완료 조건이 없으면 → 정의 후 시작

## superpowers와의 관계

이 플러그인이 설치된 경우, superpowers 워크플로우 스킬 대신 sr-harness 스킬을 우선 사용한다.
superpowers의 유틸리티 스킬(dispatching-parallel-agents 등)은 그대로 사용 가능.
워크트리 관리는 sr-harness가 자체 처리한다 (`issue` Step 3, `finish` Step 4).

## 워크플로우 전체 흐름

```
brainstorm → plan → issue → execute → verify → submit → [사용자 확인] → finish
                                        ↑ debug ↓
                                    review (리뷰 피드백 반영 시)
                               또는 ralph (bypass 자동화 모드)
```
