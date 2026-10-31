---
name: analyze
description: execute 완료 후 verify 직전에 실행하는 의도 정합성 게이트. GitHub Issue 요구사항과 git diff 구현을 누락·범위이탈·모순 3가지로 교차검증한다. 통과 시 verify 호출, 불일치 시 execute 재진입. "계획대로 만들었는지 확인", "정합성 검증", "구현이 이슈와 맞는지" 시 사용. spec-kit analyze 단계의 issue-driven 대응.
---

# analyze

**"빌드가 되는가"가 아니라 "계획한 것을 만들었는가"를 검증한다.**
execute가 끝나면, verify(빌드·테스트)를 호출하기 전에 이 게이트를 먼저 통과한다.

## 역할 분리

| 스킬 | 검증 대상 | 묻는 질문 |
|------|----------|----------|
| `analyze` | 의도 정합성 | Issue 요구사항대로 만들었는가? |
| `verify` | 기술 정상성 | 빌드·테스트가 통과하는가? |

analyze는 코드를 실행하지 않는다. **Issue(계획)와 diff(구현)를 텍스트로 대조**한다.

## 실행 주체: 구현 맥락이 없는 새 에이전트

판정은 이 스킬을 부른 세션이 하지 않습니다. 무엇을 의도했는지 아는 쪽은 누락과 범위 이탈을 놓치기 쉬워서, Issue와 diff만 보는 새 에이전트에게 맡겨요. execute의 세 모드(단일, 팀, 순차 서브에이전트)와 사용자가 직접 부른 경우가 모두 같습니다.

1. 이슈 번호(아래 입력 수집 규칙)와 저장소 루트(`git rev-parse --show-toplevel`)를 정한다
2. [`references/analyzer-prompt.md`](references/analyzer-prompt.md)의 프롬프트에 자리표시자만 채워 `Agent(subagent_type: "general-purpose")`로 띄운다
3. 돌아온 `[analyze 결과]` 블록을 그대로 보이고, "결과에 따른 전환"은 이 세션이 진행한다. verify도 빌드와 테스트를 돌리는 단계라 이 세션에 남는다

- fork(`subagent_type: "fork"`)는 대화 맥락을 물려받으니 쓰지 않는다
- 프롬프트에 구현 요약, 의도 설명, 플랜 내용을 덧붙이지 않는다
- 에이전트 판정을 고쳐 쓰지 않는다. 이견이 있으면 판정과 이견을 함께 사용자에게 올린다
- 이름 없는 단발 호출로 띄운다. 되돌림은 이 에이전트가 아니라 execute로 가므로 이름이 필요 없다. execute 재진입 뒤 다시 analyze할 때도 이전 판정에 기대지 않게 새로 띄운다
- 에이전트가 `[analyze 결과]` 블록 없이 끝나면 spawn 결과의 agentId로 같은 에이전트에 `SendMessage`를 보내 블록만 다시 요청한다. 새로 띄우거나 부른 세션이 직접 판정해 대신하지 않는다
- Agent 도구가 없는 런타임이면 이 세션이 직접 대조하고, 보고 첫 줄을 `[analyze 결과] (독립 실행 아님)`으로 적는다

## 입력 수집

두 축을 모은다.

### 계획 축 — GitHub Issue
브랜치명에서 이슈 번호를 추출해 Issue 본문을 읽는다.
```bash
NUM=$(git branch --show-current | grep -oE '[0-9]+' | head -1)
gh issue view "$NUM" --json title,body
```
이슈 번호를 못 찾으면 → `.claude/session-plan.md`의 `issue:` 필드를 사용한다.

### 구현 축 — git diff
```bash
git diff origin/main --stat
git diff origin/main
```

## 3가지 교차검증

### 1. 누락 (Coverage gap)
Issue 본문의 요구사항·체크박스·`Closes` 기준 중 **diff에 반영되지 않은 것**.
→ 있으면 미구현 상태다. `execute` 재진입.

머지 뒤에야 확인할 수 있는 조건(릴리즈 태그, 재설치, 실사용 확인)은 diff로 볼 수 없습니다. K에서 빼고 근거 칸에 "사후 조건 {n}개 제외"로 따로 적어요.

### 2. 범위 이탈 (Scope creep) — karpathy §3
diff에 있는데 **Issue에 근거가 없는 변경**.
→ 사용자 확인. 의도된 것이면 Issue에 추가, 아니면 되돌린다.

### 3. 모순 (Inconsistency)
요구사항과 구현이 **충돌**하는 부분 (다른 값·반대 동작·어긋난 명세).
→ `execute` 재진입 또는 사용자 확인.

## 결과 보고 형식

```
[analyze 결과]
계획 축: Issue #N "{제목}" — 요구사항 {K}개
구현 축: 변경 {M}개 파일

| 검증 | 결과 | 근거 |
|------|------|------|
| 누락 | ✅/⚠️ | 요구사항 {K}개 중 {K}개 반영 |
| 범위 이탈 | ✅/⚠️ | Issue 밖 변경 {유/무} |
| 모순 | ✅/⚠️ | 충돌 {유/무} |
```

각 항목은 **이번 메시지에서 Issue 본문과 diff를 직접 대조한 근거**가 있을 때만 ✅로 적는다.

## 결과에 따른 전환

| 결과 | 다음 단계 |
|------|----------|
| 3개 모두 ✅ | `verify` 호출 |
| 누락 있음 | `execute` 재진입 (미구현 보완) |
| 범위 이탈 | 사용자 확인 → Issue 보강 또는 되돌림 |
| 모순 있음 | `execute` 재진입 또는 사용자 확인 |

## 금지 사항

- Issue 본문·diff를 이번 메시지에서 직접 확인하지 않고 ✅ 표시 금지
- 부른 세션이 판정을 직접 하거나 에이전트 판정을 고쳐 쓰기 금지 (Agent 도구가 없을 때만 예외)
- 범위 이탈을 사용자 확인 없이 통과 금지
- analyze를 건너뛰고 바로 `verify`·`submit` 진행 금지
