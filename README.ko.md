# sr-harness

Claude Code의 작업 방식을 직접 설계하는 하네스

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)](https://claude.ai/code)

> [English](./README.md) | 한국어

---

## superpowers의 문제

[superpowers](https://github.com/anthropics/claude-plugins-official)는 Claude Code의 강력한 워크플로우 플러그인이다. 하지만 실제로 쓰다 보면 세 가지가 항상 걸린다.

- Karpathy 원칙이 배경 규칙으로만 로드될 뿐, 각 단계에서 강제되지 않는다
- Issue-Driven Development가 워크플로우에 없다 — CLAUDE.md 규칙으로만 존재한다
- 워크플로우가 고정되어 있어, 실제 작업 방식과 맞지 않는 경우가 많다

sr-harness는 이 세 가지를 하나의 플러그인으로 통합한다.

---

## 뭐가 다른가

**superpowers** — Karpathy 원칙이 배경 규칙

```
# coding-guidelines.md (로드되지만 강제되지 않음)
§1 Handle Uncertainty First
§2 Simplicity First
§3 Surgical Changes
§4 Incremental, Verified Execution
```

**sr-harness** — Karpathy 원칙이 구조적 체크포인트

```
harness-execute 진입 시:
  [ ] 요청이 명확한가? → 불명확하면 먼저 질문
  [ ] 더 단순한 방법이 있는가? → 있으면 먼저 제안
  [ ] 성공 기준이 있는가? → 없으면 정의 후 시작

harness-execute 기존 코드 수정 시:
  [ ] 수정 전 파일을 먼저 읽는다
  [ ] 요청과 직접 관련된 줄만 변경한다
  [ ] 주변 코드·주석·포맷은 건드리지 않는다
```

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

## 워크플로우

```
harness-start
      │  작업 유형 파악 · session-plan.md 로드 · 라우팅
      │
      ├─ harness-brainstorm
      │    아이디어를 한 번에 펼치지 않는다
      │    한 라운드 = 구체적 출력 하나 + 확인 질문 하나
      │    종료 기준: 하나의 Issue로 만들기에 충분한 크기
      │
      ├─ harness-plan
      │    각 단계에 verify 기준 필수
      │    형식: "X를 한다 → verify: [완료 조건]"
      │    verify 없는 단계는 계획에 포함하지 않는다
      │
      ├─ harness-issue
      │    GitHub Issue 생성 → origin/main 기준 브랜치 생성
      │    규칙: 1 Issue = 1 Branch = 1 PR
      │    체인 브랜치 금지 · 복수 Issue 혼재 금지
      │
      ├─ harness-execute ←─────────────────────┐
      │    단계 진입 시 Karpathy 체크포인트      │
      │    단계 → verify → 커밋 → 다음 단계   │
      │                                         │
      ├─ harness-debug  ────────────────────────┘
      │    코드 수정 전 원인 진단 필수
      │    같은 방법 두 번 시도 금지
      │
      └─ harness-finish
           push → PR (body에 "Closes #N" 필수)
           다른 마무리 방식 없음
```

---

## 스킬

| 스킬 | 역할 | 대체 |
|------|------|------|
| `harness-start` | 세션 진입점 · 라우팅 | superpowers:using-superpowers |
| `harness-brainstorm` | 반복 피드백 기반 아이디어 구체화 | superpowers:brainstorming |
| `harness-plan` | step → verify 형식 계획 수립 | superpowers:writing-plans |
| `harness-issue` | GitHub Issue + 브랜치 생성 | *(신규)* |
| `harness-execute` | 구현 실행 · karpathy 체크포인트 | superpowers:executing-plans |
| `harness-finish` | push + PR (Closes #N) | superpowers:finishing-a-development-branch |
| `harness-debug` | 진단 우선 디버깅 | superpowers:systematic-debugging |

---

## 핵심 원칙

### Karpathy 4원칙 (각 스킬에 체크포인트로 내장)

| 원칙 | 적용 단계 | 막는 것 |
|------|----------|--------|
| **§1 Think Before Coding** | start · brainstorm · debug | 불명확한 상태에서 구현 시작 |
| **§2 Simplicity First** | execute | 50줄로 될 걸 200줄로 쓰는 것 |
| **§3 Surgical Changes** | execute | 요청과 무관한 코드 수정 |
| **§4 Goal-Driven Execution** | plan · execute | verify 없이 다음 단계로 넘어가는 것 |

### Issue-Driven Development

```
Issue 생성 → 브랜치(origin/main) → 구현 → 커밋(#N) → PR(Closes #N) → Merge
```

핵심 규칙: Issue를 close하는 것은 **PR body의 `Closes #N`** 이다. 커밋 메시지의 `(#N)`이 아니다.

---

## 잘 동작하고 있다면

- brainstorm이 끝날 때 항상 하나의 구체적인 계획이 나온다
- 계획의 각 단계마다 완료 조건이 명시되어 있다
- diff에 요청과 무관한 줄이 없다
- 모든 PR에 `Closes #N`이 있다

---

## 스킬 수정 및 업데이트

```bash
cd ~/IdeaProjects/sr-harness
# skills/{skill-name}/SKILL.md 편집 후

git add . && git commit -m "fix: 스킬 내용 수정" && git push
claude plugins marketplace update sr-harness
```

---

## 기여

워크플로우 패턴, Karpathy 체크포인트 개선, Issue-Driven 규칙 보완 환영.

- 🐛 [버그 신고](https://github.com/SeokRae/sr-harness/issues/new)
- ✨ [기능 제안](https://github.com/SeokRae/sr-harness/issues/new)

---

## 참고

- [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) — Karpathy 원칙 원본

---

MIT License
