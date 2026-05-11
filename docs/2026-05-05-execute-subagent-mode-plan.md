# execute 서브에이전트 모드 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `sr-harness:execute` 스킬에 서브에이전트 실행 모드를 추가해 복잡한 플랜을 태스크별 격리 컨텍스트로 실행하면서 PR 충돌 없이 단일 feature PR로 완료한다.

**Architecture:** `execute` 스킬 시작 시 플랜 태스크 수와 분산도를 기준으로 단일/서브에이전트 모드를 자동 분기한다. 서브에이전트 모드는 동일 worktree + 동일 feature 브랜치에서 태스크별 순차 dispatch → 2단계 리뷰 루프로 구성된다. 모든 커밋이 단일 브랜치에 쌓이므로 기존 `submit` 스킬이 PR 하나를 생성하면 끝난다.

**Tech Stack:** Markdown (SKILL.md), sr-harness 플러그인 규칙, Git worktree

---

## 파일 구조

| 파일 | 변경 |
|------|------|
| `skills/execute/SKILL.md` | 수정 — 실행 모드 판단·단일 모드·서브에이전트 모드 섹션 추가 |

---

### Task 1: frontmatter description 업데이트

**Files:**
- Modify: `skills/execute/SKILL.md:1-4` (frontmatter)

- [ ] **Step 1: 현재 파일 읽기**

```bash
head -5 skills/execute/SKILL.md
```

Expected output:
```
---
name: execute
description: 구현 계획을 실행하는 스킬. ...
---
```

- [ ] **Step 2: description 수정**

`description` 필드를 아래로 교체한다:

```yaml
description: 구현 계획을 실행하는 스킬. "구현해줘", "만들어줘", "코드 작성" 또는 issue 완료 후 자동 실행. 태스크 수 ≥ 3이면 서브에이전트 모드로 자동 전환. karpathy 4원칙(Think/Simplicity/Surgical/Goal-Driven) 구조적 내장.
```

- [ ] **Step 3: 변경 확인**

```bash
head -5 skills/execute/SKILL.md
```

Expected: description에 "서브에이전트 모드" 문구 포함.

- [ ] **Step 4: 커밋**

```bash
git add skills/execute/SKILL.md
git commit -m "chore: execute frontmatter — 서브에이전트 모드 언급 추가 (#이슈번호)"
```

---

### Task 2: 실행 모드 판단 섹션 추가

**Files:**
- Modify: `skills/execute/SKILL.md` — `## 시작 전 체크포인트` 섹션 바로 뒤에 삽입

- [ ] **Step 1: 삽입 위치 확인**

```bash
grep -n "## 시작 전 체크포인트\|## 구현 원칙" skills/execute/SKILL.md
```

Expected: 21번 줄 `## 시작 전 체크포인트`, 32번 줄 `## 구현 원칙`

- [ ] **Step 2: `## 구현 원칙` 바로 앞에 아래 섹션 삽입**

```markdown
## 실행 모드 판단

플랜 파일(`.claude/session-plan.md`)을 읽어 실행 모드를 결정한다.

```
독립 태스크 수 ≥ 3           → 서브에이전트 모드
태스크가 다른 파일/모듈 분산  → 서브에이전트 모드 (수 무관)
그 외                        → 단일 실행 모드
```

- 태스크 "독립" 기준: 서로 다른 파일·모듈을 건드리거나, 선행 태스크 결과에 의존하지 않음
- 판단 불확실 시 → 단일 모드로 진행 (보수적 기본값)
```

- [ ] **Step 3: 삽입 결과 확인**

```bash
grep -n "## 실행 모드 판단\|## 구현 원칙" skills/execute/SKILL.md
```

Expected: `## 실행 모드 판단`이 `## 구현 원칙` 앞에 위치.

- [ ] **Step 4: 커밋**

```bash
git add skills/execute/SKILL.md
git commit -m "feat: execute — 실행 모드 판단 섹션 추가 (#이슈번호)"
```

---

### Task 3: 기존 구현 원칙·커밋 섹션을 단일 실행 모드로 묶기

**Files:**
- Modify: `skills/execute/SKILL.md` — `## 구현 원칙` 헤더를 `## 단일 실행 모드` 하위로 이동

- [ ] **Step 1: 현재 섹션 구조 확인**

```bash
grep -n "^##" skills/execute/SKILL.md
```

Expected:
```
11:## 전제 조건 (Worktree 확인)
21:## 시작 전 체크포인트 (karpathy §1 Think Before Coding)
XX:## 실행 모드 판단
XX:## 구현 원칙 (각 단계마다 적용)
XX:## 단계 간 커밋
XX:## 완료 조건
XX:## 예외 상황
```

- [ ] **Step 2: `## 구현 원칙` 앞에 `## 단일 실행 모드` 헤더 삽입**

삽입할 내용:

```markdown
## 단일 실행 모드

태스크 수 < 3이고 단일 파일/모듈에 집중된 경우 이 모드로 실행한다.

```

- [ ] **Step 3: 결과 확인**

```bash
grep -n "^##" skills/execute/SKILL.md
```

Expected: `## 단일 실행 모드`가 `## 구현 원칙` 바로 앞에 위치.

- [ ] **Step 4: 커밋**

```bash
git add skills/execute/SKILL.md
git commit -m "feat: execute — 단일 실행 모드 헤더로 기존 섹션 묶기 (#이슈번호)"
```

---

### Task 4: 서브에이전트 실행 모드 섹션 추가

**Files:**
- Modify: `skills/execute/SKILL.md` — `## 완료 조건` 바로 앞에 삽입

- [ ] **Step 1: 삽입 위치 확인**

```bash
grep -n "## 완료 조건" skills/execute/SKILL.md
```

- [ ] **Step 2: `## 완료 조건` 바로 앞에 아래 전체 섹션 삽입**

```markdown
## 서브에이전트 실행 모드

태스크 수 ≥ 3 또는 태스크가 다른 파일/모듈에 분산된 경우 이 모드로 실행한다.

### 원칙

- 동일 worktree + 동일 feature 브랜치 + 순차 dispatch → PR 충돌 없음
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
```

- [ ] **Step 3: 삽입 결과 확인**

```bash
grep -n "^##\|^###" skills/execute/SKILL.md
```

Expected: `## 서브에이전트 실행 모드` + 하위 `###` 4개가 `## 완료 조건` 앞에 위치.

- [ ] **Step 4: 전체 파일 읽어서 논리 흐름 검토**

```bash
cat skills/execute/SKILL.md
```

흐름 확인: 전제 조건 → 체크포인트 → 모드 판단 → 단일 모드 → 서브에이전트 모드 → 완료 조건 → 예외

- [ ] **Step 5: 커밋**

```bash
git add skills/execute/SKILL.md
git commit -m "feat: execute — 서브에이전트 실행 모드 섹션 추가 (#이슈번호)"
```

---

### Task 5: 완료 조건 및 예외 상황 업데이트

**Files:**
- Modify: `skills/execute/SKILL.md` — `## 완료 조건`, `## 예외 상황` 섹션

- [ ] **Step 1: 현재 완료 조건 확인**

```bash
grep -A3 "## 완료 조건" skills/execute/SKILL.md
```

Expected:
```
plan의 모든 단계 verify 통과 → `verify` 호출 (통합 검증 후 submit)
```

- [ ] **Step 2: 완료 조건을 두 모드 포함으로 교체**

기존:
```
plan의 모든 단계 verify 통과 → `verify` 호출 (통합 검증 후 submit)
```

교체 후:
```
**단일 모드**: plan의 모든 단계 verify 통과 → `verify` 호출 (통합 검증 후 submit)
**서브에이전트 모드**: 모든 태스크 2단계 리뷰 통과 → `verify` 호출 → `submit` (PR 1개)
```

- [ ] **Step 3: 예외 상황에 서브에이전트 BLOCKED 항목 추가**

기존 예외 상황 끝에 추가:
```
- 서브에이전트 BLOCKED → 원인 분석: 컨텍스트 보강 재시도 / 모델 업그레이드 / 태스크 분할 / 사용자 에스컬레이션
```

- [ ] **Step 4: 최종 파일 전체 검토**

```bash
cat skills/execute/SKILL.md
```

확인 항목:
- frontmatter description에 "서브에이전트 모드" 언급 ✓
- `## 실행 모드 판단` 섹션 존재 ✓
- `## 단일 실행 모드` 아래 기존 구현 원칙 위치 ✓
- `## 서브에이전트 실행 모드` 섹션 존재 ✓
- `## 완료 조건` 두 모드 모두 커버 ✓
- `## 예외 상황` BLOCKED 처리 포함 ✓

- [ ] **Step 5: 최종 커밋**

```bash
git add skills/execute/SKILL.md
git commit -m "feat: execute — 완료 조건·예외 상황 서브에이전트 모드 반영 (#이슈번호)"
```
