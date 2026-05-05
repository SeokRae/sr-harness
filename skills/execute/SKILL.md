---
name: execute
description: 구현 계획을 실행하는 스킬. "구현해줘", "만들어줘", "코드 작성" 또는 issue 완료 후 자동 실행. 태스크 수 ≥ 3이면 서브에이전트 모드로 자동 전환. karpathy 4원칙 구조적 내장.
---

# execute

구현 시작 전 karpathy 체크포인트를 통과해야 한다.
단계별로 실행하고, 각 단계가 끝나면 verify 후 다음으로 넘어간다.

## 전제 조건 (Worktree 확인)

현재 작업 디렉토리가 worktree(`.claude/worktrees/{description}`) 안인지 확인한다.
- 맞으면 → 진행
- 아니면 → `issue`로 돌아가서 worktree 생성

```bash
git worktree list | grep "$(pwd)"
```

## 시작 전 체크포인트 (karpathy §1 Think Before Coding)

다음을 확인하고 넘어간다:

```
[ ] 요청이 명확한가? → 불명확하면 먼저 질문
[ ] 여러 해석이 가능한가? → 모두 제시하고 선택받기
[ ] 더 단순한 방법이 있는가? → 있으면 먼저 제안
[ ] 성공 기준이 정의되어 있는가? → plan의 verify 기준 확인
```

## 구현 원칙 (각 단계마다 적용)

### karpathy §2 Simplicity First
코드를 작성하기 전:
- 요청한 것만 만든다 — 추가 기능, 미래 대비 추상화 금지
- 200줄로 쓸 수 있는 걸 50줄로 쓸 수 있으면 → 50줄로 쓴다

### karpathy §3 Surgical Changes
기존 코드를 수정할 때:
- 수정 대상 파일을 먼저 읽는다 (Read before Write)
- 값의 의미·범위가 바뀌는 변경(null 도입, 타입 변경, 기본값 변경 등)은 그 값의 소비처(호출부, 생성자, 파라미터)까지 추적한다 — 확인 방법은 언어마다 다름
- 요청과 직접 관련된 줄만 변경한다
- 주변 코드, 주석, 포맷은 건드리지 않는다
- 내 변경으로 생긴 unused import/변수만 제거한다 (기존 dead code 건드리지 않음)

### karpathy §4 Goal-Driven Execution
각 단계 실행 형식:
```
[Step N 실행 중]: {설명}
→ verify: {확인 방법}
→ 결과: ✅ 통과 / ❌ 실패 (실패 시 debug 전환)
```

## 단계 간 커밋

각 논리적 단위 완료 시 커밋:
```bash
git add {관련 파일만}
git commit -m "{type}: {설명} (#N)"
```

**`git add .` 사용 금지** — 관련 파일만 개별 지정한다.

**커밋 단위**: `plan`의 단계 하나에서 verify를 통과한 변경이 커밋 하나다.
- verify를 통과하기 전에 커밋하지 않는다
- 여러 step을 한 커밋에 묶지 않는다
- 커밋 후에 다음 step으로 넘어간다

## 완료 조건

plan의 모든 단계 verify 통과 → `verify` 호출 (통합 검증 후 submit)

## 예외 상황

- 테스트 실패 / 예상 밖 에러 → `debug` 전환
- 범위 밖 작업 발견 → session-plan.md Deviations 기록, 현재 작업 계속
