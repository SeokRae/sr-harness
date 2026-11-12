---
name: abort
description: 작업 중단 및 브랜치 정리 스킬. "그만할게", "방향 바꿀게", "이 작업 취소", "브랜치 정리" 시 사용. session-plan Deviations 기록 + 브랜치 삭제 여부 확인. 워크플로우 어느 단계에서든 진입 가능하되, 브랜치 삭제가 포함되므로 모델 자동 호출을 막았다. /abort 로만 진입한다.
disable-model-invocation: true
---

# abort

작업을 중단할 때 흔적을 정리한다.
**정리하지 않으면 다음 세션에서 좀비 브랜치와 stale session-plan이 남는다.**

## 중단 유형

| 유형 | 설명 | 처리 방식 |
|------|------|----------|
| **방향 전환** | 더 나은 접근법 발견, 다음 세션에서 재시도 | session-plan 유지, 브랜치 보존 |
| **완전 폐기** | 이 작업 자체를 하지 않기로 결정 | session-plan 삭제, 브랜치 삭제 |
| **일시 중단** | 지금은 못 하지만 나중에 재개 | session-plan 유지, 브랜치 보존 |

## 실행 순서

### 1. 중단 이유 기록
`.claude/session-plan.md`의 Deviations 섹션에 기록한다:
```markdown
## Deviations

- [중단] {날짜}: {이유} → {유형: 방향전환/폐기/일시중단}
```

### 2. 미완료 변경사항 처리
```bash
git status
```

- 커밋할 가치가 있는 변경 → `git stash` 또는 WIP 커밋
- 버릴 변경 → `git checkout -- .`

### 3. 브랜치 삭제 여부 확인
사용자에게 선택을 묻는다:

```
현재 브랜치: feature/{N}-{description}
원격 브랜치: origin/feature/{N}-{description}

브랜치를 삭제할까요?
A. 로컬 + 원격 모두 삭제
B. 로컬만 삭제 (원격 보존)
C. 보존 (나중에 재개)
```

A 선택 시:
```bash
git checkout main
git branch -d feature/{N}-{description}
git push origin --delete feature/{N}-{description}
```

### 4. Issue 상태 업데이트
```bash
# 완전 폐기인 경우 Issue close
gh issue close {N} --comment "작업 중단: {이유}"

# 방향 전환 / 일시 중단인 경우 코멘트만
gh issue comment {N} --body "일시 중단: {이유}. 추후 재개 예정."
```

### 5. 완료 보고
```
[abort 완료]
중단 유형: {유형}
기록 위치: session-plan.md Deviations
브랜치: {삭제됨 / 보존됨}
Issue #{N}: {closed / commented}
```

## 금지 사항

- 이유 기록 없이 브랜치 삭제 금지
- session-plan.md를 확인하지 않고 삭제 금지 (미완료 항목 확인 필수)
- force push로 브랜치 내용 덮어쓰기 금지
