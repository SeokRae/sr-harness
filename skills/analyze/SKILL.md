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
- 범위 이탈을 사용자 확인 없이 통과 금지
- analyze를 건너뛰고 바로 `verify`·`submit` 진행 금지
