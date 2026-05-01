# sr-harness

Claude Code의 작업 방식을 직접 설계하는 하네스

---

## 왜 만들었나

Claude Code에는 superpowers라는 강력한 워크플로우 플러그인이 있다. 하지만 실제로 쓰다 보면 몇 가지 문제가 생긴다.

- 워크플로우가 고정되어 있어 내 방식과 맞지 않는 경우가 많다
- Karpathy 원칙이 배경 규칙으로만 존재하고 각 단계에 구조적으로 강제되지 않는다
- Issue-Driven Development가 워크플로우에 없다 — 별도 규칙으로만 존재한다

sr-harness는 이 세 가지를 하나의 플러그인으로 통합한다.

---

## 설치

```bash
# 마켓플레이스 추가
claude plugins marketplace add https://github.com/SeokRae/sr-harness.git

# 플러그인 설치
claude plugins install sr-harness@sr-harness
```

설치 확인:
```bash
claude plugins list
#   ❯ sr-harness@sr-harness
#     Version: 0.1.0
#     Scope: user
#     Status: ✔ enabled
```

---

## 스킬 구성

| 스킬 | 역할 | 대체 |
|------|------|------|
| `harness-start` | 세션 진입점 · 라우팅 | superpowers:using-superpowers |
| `harness-brainstorm` | 반복 피드백 기반 아이디어 구체화 | superpowers:brainstorming |
| `harness-plan` | step → verify 형식 계획 수립 | superpowers:writing-plans |
| `harness-issue` | GitHub Issue + 브랜치 생성 | *(신규)* |
| `harness-execute` | 구현 실행 · karpathy 4원칙 강제 | superpowers:executing-plans |
| `harness-finish` | push + PR (Closes #N) | superpowers:finishing-a-development-branch |
| `harness-debug` | 진단 우선 디버깅 | superpowers:systematic-debugging |

---

## 워크플로우

```
harness-start          세션 시작 · 작업 유형 파악 · 라우팅
      │
      ├─ harness-brainstorm
      │    아이디어를 한 번에 펼치지 않는다
      │    한 라운드 = 구체적 출력 하나 + 확인 질문 하나
      │    목표: 하나의 Issue로 만들기에 충분한 크기로 좁힌다
      │
      ├─ harness-plan
      │    각 단계에 verify 기준 포함
      │    step → verify: [완료 조건] 형식 필수
      │
      ├─ harness-issue
      │    GitHub Issue 생성 → origin/main 기준 브랜치 생성
      │    1 Issue = 1 Branch = 1 PR 규칙 강제
      │
      ├─ harness-execute ←─────────────────────┐
      │    karpathy 4원칙 체크포인트 적용       │
      │    단계별 verify → 커밋 → 다음 단계    │
      │                                         │
      ├─ harness-debug  ────────────────────────┘
      │    에러 발생 시 진단 우선
      │    원인 확인 후 execute로 복귀
      │
      └─ harness-finish
           push → PR 생성 (Closes #N 필수)
```

---

## 핵심 설계 원칙

### Karpathy 4원칙 (각 스킬에 구조적으로 내장)

superpowers에서는 이 원칙이 배경 규칙으로만 존재한다. sr-harness는 각 단계 진입 시 체크포인트로 강제한다.

| 원칙 | 적용 단계 | 하는 것 |
|------|----------|--------|
| **§1 Think Before Coding** | start · brainstorm · debug | 불명확하면 먼저 질문, 단순한 방법 있으면 먼저 제안 |
| **§2 Simplicity First** | execute | 요청한 것만, 200줄이 50줄로 가능하면 50줄로 |
| **§3 Surgical Changes** | execute | 관련 줄만 변경, Read before Write |
| **§4 Goal-Driven Execution** | plan · execute | 각 단계에 verify 기준, 통과 후 다음 단계 |

### Issue-Driven Development (harness-issue에 내장)

```
Issue 생성 → 브랜치 생성 → 구현 → 커밋(#N) → PR(Closes #N) → Merge
```

- 모든 코드 변경은 GitHub Issue에서 시작한다
- 항상 origin/main 기준으로 분기한다 (체인 브랜치 금지)
- PR body의 `Closes #N`이 Issue를 close한다 (커밋 메시지 `(#N)` 아님)

---

## 잘 동작하고 있다면

- brainstorm이 끝날 때 항상 하나의 구체적인 계획이 나온다
- 계획의 각 단계마다 "이걸로 완료를 확인한다"는 기준이 있다
- 코드 수정 범위가 요청한 것에서 벗어나지 않는다
- PR이 올라갈 때마다 `Closes #N`이 포함되어 있다

---

## 스킬 수정 및 업데이트

```bash
# 스킬 수정
cd ~/IdeaProjects/sr-harness
# skills/{skill-name}/SKILL.md 편집 후

git add . && git commit -m "fix: 스킬 내용 수정" && git push

# Claude Code에 반영
claude plugins marketplace update sr-harness
```

---

## superpowers와의 관계

sr-harness는 superpowers 워크플로우 스킬을 대체하지만, superpowers의 유틸리티 스킬은 그대로 사용 가능하다.

| 계속 사용 가능 |
|--------------|
| `superpowers:using-git-worktrees` |
| `superpowers:dispatching-parallel-agents` |
| `superpowers:requesting-code-review` |
| `superpowers:receiving-code-review` |
| `superpowers:subagent-driven-development` |

---

## 참고

- [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) — Karpathy 원칙 원본
- [claude-plugins-official](https://github.com/anthropics/claude-plugins-official) — superpowers 플러그인

---

MIT License
