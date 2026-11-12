---
name: ownership-principles
description: "에이전트 자동화 시대의 소유권·판단력 원칙 체크리스트. execute의 병렬/자동 실행 구간, ralph·goal처럼 사람 개입 없이 반복되는 루프에서 참조. inner/outer loop 구분·판결(verdict)·세 가지 위험(인지적 부채·굴복·오케스트레이션 세금) 세 섹션으로 구성. Keywords: 소유권, ownership, verdict, 판결, inner loop, outer loop, 인지적 부채, cognitive debt, cognitive surrender, orchestration tax, 오케스트레이션 세금, agency, taste, 취향"
---

# ownership-principles

에이전트가 실행을 대신할수록, 사람이 유지해야 하는 것은 "무엇을 했는가"가 아니라 "왜 그것을 승인했는가"다.

## §1 Inner Loop / Outer Loop 구분

- **Inner loop (에이전트 실행)**: 조사·구현·테스트·보고 — 위임 가능
- **Outer loop (사람 소유)**: 결정·검증·승인·책임 — 위임 불가
- 에이전트는 실행 지침(runbook)을 따를 수는 있어도 결과를 상속받거나 책임질 수 없다 — 최종 승인은 항상 사람의 turn이어야 한다
- 사람 개입 없이 반복하는 구간(ralph·goal)일수록 outer loop 체크포인트를 매 반복 명시적으로 남긴다 — 자동 반복이 outer loop 자체를 지워버리면 안 된다

## §2 Verdict (판결)

- "만들 수 있는가"보다 "이게 존재할 가치가 있는가"를 먼저 판단한다
- 객관적 지표가 없는 상황(설계 방향·우선순위·트레이드오프)에서 고품질 판단을 내리는 것 — 이게 희소 자원(취향, taste)이다
- **게이트**: 설명할 수 없다면 출시하지 마라 (Explain it or don't ship it) — 변경 이유를 한 문장으로 말할 수 없으면 merge·promise 금지

## §3 경계해야 할 세 가지 위험

- **인지적 부채 (Cognitive Debt)**: 시스템을 이해하고 설명할 능력이 침식되는 것 — AI 산출물을 그대로 커밋하기 전에 "이걸 내가 남에게 설명할 수 있는가" 자문한다
- **인지적 굴복 (Cognitive Surrender)**: 자기 의견을 세우기 전에 AI 답변을 그대로 수용하는 것 — 특히 debug·verify에서 "왜 이게 원인인지"를 스스로 재구성한 뒤 채택한다
- **오케스트레이션 세금 (Orchestration Tax)**: 너무 많은 에이전트를 동시에 돌려 인지 대역폭이 바닥나는 것 — 병렬 dispatch 규모를 키우기 전에 "내가 이 결과를 다 검토할 수 있는가"부터 확인한다

## 체크리스트 (자동/병렬 실행 구간 진입 전)

```
[ ] 이 반복·이 dispatch에서 사람이 검증할 지점(outer loop)이 명시돼 있는가?
[ ] 이번 변경을 한 문장으로 설명할 수 있는가? (설명 못하면 promise·merge 금지)
[ ] AI가 제시한 원인·해법을 내가 재구성해서 납득했는가, 그대로 받아쓴 건 아닌가?
[ ] 동시 실행 규모가 내가 결과를 다 검토할 수 있는 범위인가?
```
