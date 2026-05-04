---
name: harness-review
description: PR 리뷰 피드백 수신 및 반영 스킬. "리뷰 달렸어", "코멘트 반영해줘", "PR 피드백" 시 사용. 피드백을 반영/무시/논의로 분류하고 harness-execute 재진입. force push 없이 일반 push로 마무리.
---

# harness-review

PR 리뷰 피드백은 새로운 작업 사이클의 시작이다.
**피드백을 하나씩 확인하고, 반영 여부를 결정한 후 실행한다.**

## 피드백 처리 흐름

### 1. 피드백 분류
리뷰어 코멘트를 세 종류로 분류한다:

| 분류 | 기준 | 처리 |
|------|------|------|
| **반영** | 코드 변경이 필요한 지적 | session-plan에 step 추가 |
| **무시** | 스타일 의견, 선호 차이 | 이유를 코멘트로 달고 넘어감 |
| **논의** | 방향이 불명확한 것 | 리뷰어와 답글로 확인 후 결정 |

분류 결과를 사용자에게 보여주고 확인받는다:
```
[피드백 분류 결과]
반영 (N건): ...
무시 (N건): ...
논의 필요 (N건): ...

계속 진행할까요?
```

### 2. session-plan.md 업데이트
반영 항목을 plan의 새 step으로 추가한다:
```yaml
# session-plan.md에 추가
- [ ] review: {반영 항목 설명} → verify: {확인 방법}
```

### 3. harness-execute 재진입
session-plan의 새 step을 하나씩 실행한다.
기존 코드를 수정하므로 karpathy §3 Surgical Changes를 반드시 적용한다.

### 4. 완료 후 push
```bash
git add {변경 파일}
git commit -m "fix: 리뷰 반영 — {반영 항목 요약} (#N)"
git push origin feature/{N}-{description}
```

**force push 금지** — 일반 push로 PR 업데이트. 히스토리를 재작성하지 않는다.

### 5. 리뷰 재요청
```bash
gh pr review {PR-number} --request-review {리뷰어}
# 또는 PR 코멘트로 re-review 요청
```

## 무시 처리 방법

무시하는 코멘트는 PR에 이유를 명시한다:
```
"이 부분은 [이유]로 현재 방식을 유지합니다."
```
설명 없는 무시는 하지 않는다.

## 금지 사항

- 피드백 분류 없이 바로 코드 수정 금지
- force push / rebase로 히스토리 재작성 금지
- 논의 미완료 항목을 임의로 반영 또는 무시 금지
