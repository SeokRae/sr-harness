---
name: execute
description: 구현 계획을 실행하는 스킬. "구현해줘", "만들어줘", "코드 작성" 또는 issue 완료 후 자동 실행. 태스크 수 ≥ 3이면 서브에이전트 모드로 자동 전환. karpathy 4원칙 구조적 내장.
---

# execute

구현 시작 전 karpathy 체크포인트를 통과해야 한다.
단계별로 실행하고, 각 단계가 끝나면 verify 후 다음으로 넘어간다.

## 전제 조건 (브랜치/Worktree 확인)

먼저 프로젝트 유형을 감지한다:

```bash
ls .obsidian/ 2>/dev/null && echo "vault" || echo "code"
```

**코드 프로젝트**: 현재 디렉토리가 worktree(`.claude/worktrees/{description}`) 안인지 확인한다.
- 맞으면 → 진행
- 아니면 → `issue`로 돌아가서 worktree 생성

```bash
git worktree list | grep "$(pwd)"
```

**Obsidian vault**: feature 브랜치에 있는지 확인한다. main이면 → `issue`로 돌아가서 브랜치 생성.

```bash
git branch --show-current  # feature/* 여야 함, main이면 안 됨
```

## 시작 전 체크포인트 (karpathy §1 Think Before Coding)

다음을 확인하고 넘어간다:

```
[ ] 요청이 명확한가? → 불명확하면 먼저 질문
[ ] 여러 해석이 가능한가? → 모두 제시하고 선택받기
[ ] 더 단순한 방법이 있는가? → 있으면 먼저 제안
[ ] 성공 기준이 정의되어 있는가? → plan의 verify 기준 확인
```

## 실행 모드 판단

플랜 파일(`.claude/session-plan.md`)을 읽어 실행 모드를 결정한다.

```
독립 태스크 수 ≥ 3           → 서브에이전트 모드
태스크가 다른 파일/모듈 분산  → 서브에이전트 모드 (수 무관)
그 외                        → 단일 실행 모드
```

- 태스크 "독립" 기준: 서로 다른 파일·모듈을 건드리거나, 선행 태스크 결과에 의존하지 않음
- 판단 불확실 시 → 단일 모드로 진행 (보수적 기본값)

## 단일 실행 모드

태스크 수 < 3이고 단일 파일/모듈에 집중된 경우 이 모드로 실행한다.

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

## 서브에이전트 실행 모드

태스크 수 ≥ 3 또는 태스크가 다른 파일/모듈에 분산된 경우 이 모드로 실행한다.

### 원칙

- 동일 feature 브랜치 + 순차 dispatch → PR 충돌 없음 (코드 프로젝트는 동일 worktree에서)
- 서브에이전트 병렬 dispatch 절대 금지
- 각 태스크 완료 후 2단계 리뷰(스펙 → 코드 품질) 통과 시 다음 태스크 진행

### 실행 흐름

```
1. 플랜 파일에서 태스크 전문(全文) 추출
2. [태스크 N] 구현 서브에이전트 dispatch
     컨텍스트: 태스크 전문 + 관련 파일 경로 + 브랜치명 + worktree 경로
     서브에이전트 결과: DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED
3. [태스크 N] 스펙 리뷰 서브에이전트 dispatch
     ❌ 불일치 → 구현 서브에이전트 재dispatch → 재리뷰
     ✅ 통과 →
4. [태스크 N] 코드 품질 리뷰 서브에이전트 dispatch
     ❌ 이슈 → 구현 서브에이전트 재dispatch → 재리뷰
     ✅ 통과 → 다음 태스크
5. 모든 태스크 완료 → verify → submit
```

### 서브에이전트 상태 처리

| 상태 | 처리 |
|------|------|
| `DONE` | 스펙 리뷰로 진행 |
| `DONE_WITH_CONCERNS` | concerns 확인 후 스펙 리뷰 진행 |
| `NEEDS_CONTEXT` | 누락 컨텍스트 제공 후 재dispatch |
| `BLOCKED` | 원인 파악 → 컨텍스트 보강 재시도 / 더 강한 모델 / 태스크 분할 / 사용자 에스컬레이션 |

### 충돌 방지 규칙 (서브에이전트에게 명시 전달)

- 코드 프로젝트: 모든 파일 수정은 반드시 전달받은 worktree 경로 내에서 수행 — main 워크트리 파일 직접 수정 금지
- Vault 프로젝트: feature 브랜치에서 직접 수정 (worktree 없음)
- `git add .` 사용 금지 — 태스크 관련 파일만 명시적으로 지정
- 커밋 전 `git pull --rebase origin {브랜치명}` 실행
- 모든 커밋에 이슈 번호 포함: `feat: 설명 (#이슈번호)`
- 구현 완료 후 반드시 커밋까지 완료하고 종료

### 모델 선택 기준

| 태스크 유형 | 모델 |
|------------|------|
| 단순 구현 (1~2 파일, 명확한 스펙) | haiku (빠르고 저렴) |
| 멀티파일 통합, 패턴 매칭 | sonnet |
| 아키텍처 판단, 리뷰 | opus |

## 완료 조건

**단일 모드**: plan의 모든 단계 verify 통과 → `verify` 호출 (통합 검증 후 submit)
**서브에이전트 모드**: 모든 태스크 2단계 리뷰 통과 → `verify` 호출 → `submit` (PR 1개)

## 예외 상황

- 테스트 실패 / 예상 밖 에러 → `debug` 전환
- 범위 밖 작업 발견 → session-plan.md Deviations 기록, 현재 작업 계속
- 서브에이전트 BLOCKED → 원인 분석: 컨텍스트 보강 재시도 / 모델 업그레이드 / 태스크 분할 / 사용자 에스컬레이션
