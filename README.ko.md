# sr-harness

코딩 에이전트의 작업 방식을 직접 설계하는 하네스

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)](https://claude.ai/code)
[![Codex](https://img.shields.io/badge/Codex-Plugin-2563eb)](.codex-plugin/plugin.json)
[![Status](https://img.shields.io/badge/Status-Early%20Stage-orange)](.)
[![Workflow Cycle](https://img.shields.io/badge/워크플로우-인터랙티브%20다이어그램-68b6ff)](https://seokrae.github.io/sr-harness/)

> [English](./README.md) | 한국어 | [인터랙티브 워크플로우 →](https://seokrae.github.io/sr-harness/)

---

## 왜 만들었나

코딩 에이전트로 개발하다 보면 반복적으로 겪는 패턴이 있다.

- 원칙은 알고 있는데, 막상 구현할 때 지켜지지 않는다
- "Issue 먼저 만들고 브랜치 생성"이 규칙인데, 흐름이 끊기면 건너뛰게 된다
- 아이디어 탐색에서 구현까지 각 단계가 따로 놀고, 하나의 흐름으로 이어지지 않는다

sr-harness는 이 세 가지를 하나의 워크플로우로 구조화한다.

---

## 어떻게 작동하나

원칙을 규칙으로 외우는 게 아니라, 각 단계 진입 시 체크포인트로 강제한다.

```
execute 진입 시:
  [ ] 요청이 명확한가? → 불명확하면 먼저 질문
  [ ] 더 단순한 방법이 있는가? → 있으면 먼저 제안
  [ ] 성공 기준이 있는가? → 없으면 정의 후 시작

execute 기존 코드 수정 시:
  [ ] 수정 전 파일을 먼저 읽는다
  [ ] 요청과 직접 관련된 줄만 변경한다
  [ ] 주변 코드·주석·포맷은 건드리지 않는다
```

아이디어 단계부터 PR 생성까지, 각 스킬이 다음 스킬로 자연스럽게 이어진다.

---

## 설치

sr-harness는 Claude Code와 Codex manifest를 모두 제공한다:

- Claude Code: `.claude-plugin/plugin.json`
- Codex: `.codex-plugin/plugin.json`

### Claude Code

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
#     Version: 0.18.0
#     Scope: user
#     Status: ✔ enabled
```

### Codex

Codex 지원은 `.codex-plugin/plugin.json` manifest 기준으로 준비되어 있다. Codex plugin marketplace 또는 local plugin source 설정을 통해 설치하면, 동일한 `skills/*/SKILL.md` 스킬을 Codex에서 사용할 수 있다.

런타임별 차이는 [`docs/RUNTIME-COMPATIBILITY.md`](./docs/RUNTIME-COMPATIBILITY.md)에 정리되어 있다.

---

## 라이프사이클

전체 라이프사이클 — 상태 전이 테이블, 갭 분석, v0.2 로드맵은 [`docs/LIFECYCLE.md`](./docs/LIFECYCLE.md)에 정의되어 있다.

## 워크플로우

```
start
      │  작업 유형 파악 · session-plan.md 로드 · 라우팅
      │
      ├─ brainstorm
      │    아이디어를 한 번에 펼치지 않는다
      │    한 라운드 = 구체적 출력 하나 + 확인 질문 하나
      │    종료 기준: 하나의 Issue로 만들기에 충분한 크기
      │
      ├─ plan
      │    각 단계에 verify 기준 필수
      │    형식: "X를 한다 → verify: [완료 조건]"
      │    verify 없는 단계는 계획에 포함하지 않는다
      │
      ├─ issue
      │    GitHub Issue 생성 → origin/main 기준 브랜치 생성
      │    규칙: 1 Issue = 1 Branch = 1 PR
      │    체인 브랜치 금지 · 복수 Issue 혼재 금지
      │
      ├─ execute ←─────────────────────┐
      │    단계 진입 시 Karpathy 체크포인트      │
      │    단계 → verify → 커밋 → 다음 단계   │
      │                                         │
      ├─ debug  ────────────────────────┘
      │    코드 수정 전 원인 진단 필수
      │    같은 방법 두 번 시도 금지
      │
      ├─ analyze
      │    의도 정합성 검증: Issue 요구사항 ↔ git diff
      │    누락 · 범위 이탈 · 모순
      │
      ├─ verify
      │    제출 전 통합 검증
      │    git status · 변경 파일 · 테스트 스위트
      │
      ├─ submit
      │    push → PR (body에 "Closes #N" 필수)
      │    여기서 멈춤 — 사용자가 PR 리뷰
      │
      ├─ review
      │    리뷰 피드백 수신 → execute 복귀
      │
      └─ finish
           머지 + 브랜치 삭제 + main pull
```

---

## 스킬

| 스킬 | 역할 |
|------|------|
| `start` | 세션 진입점 · 라우팅 |
| `brainstorm` | 반복 피드백 기반 아이디어 구체화 |
| `plan` | step → verify 형식 계획 수립 |
| `issue` | GitHub Issue + 브랜치 생성 |
| `execute` | 구현 실행 · karpathy 체크포인트 |
| `debug` | 진단 우선 디버깅 |
| `analyze` | 의도 정합성 게이트 (Issue ↔ diff) · verify 전 |
| `verify` | PR 제출 전 통합 검증 |
| `submit` | push + PR (Closes #N) · 사용자 리뷰 대기 |
| `review` | 리뷰 피드백 수신 → execute 복귀 |
| `finish` 🔒 | 머지 + 브랜치 삭제 + main pull |
| `ralph` 🔒 | verify 통과까지 execute→verify 자동 반복 (bypass 모드) |
| `goal` 🔒 | Stop hook 기반 목표 주도 자율 실행 (Claude Code) · Codex는 워크플로우 가이드 제공 |
| `abort` 🔒 | 작업 취소 · 브랜치 정리 |
| `pause` | 세션 중단 · 다음 세션 인계 |
| `dev-coding-principles` | 코딩 품질 체크리스트 — 네이밍·예외처리·테스트 |
| `dev-architecture` | 아키텍처 체크리스트 — Hexagonal·레이어 분리·패키지 구조 |
| `dev-documentation-principles` | 문서화 체크리스트 — 결정 기록·드리프트 처리·기존 컨벤션 우선 |
| `dev-stack-java` | Java/Spring Boot 관용구 — Spring·JPA·예외처리 (자동 감지) |
| `dev-testing-strategy` | Spring 테스트 컨텍스트 구성 전략: 구성 방식(Runner vs Autowired), 컨텍스트 스코프, 프로퍼티 값 관리 |
| `dev-testing-conventions` | 테스트 코드 작성 컨벤션: 티어 구분(접미사), 단언 라이브러리, 파라미터화, 라이브 테스트 분리 |
| `dev-monitoring-design` | 이상탐지·스파이크 모니터링 대시보드/리포트 정보설계 체크리스트 — 측정·진단·탐지·표현 |
| `ownership-principles` | 에이전트 시대 소유권 체크리스트 — inner/outer loop·판결·인지적 부채/굴복·오케스트레이션 세금 |
| `meta` 🔒 | Meta-Harness 진화 루프 — 피진화체 스킬 분석 후 개선 후보 3개 제안·구현, `evals/rubric.md` 게이트 통과분만 채택 |
| `release` 🔒 | GitHub Release 생성 — 버전 결정·릴리즈 노트 작성·태그 생성 자동화 |

🔒 = `disable-model-invocation`. 사용자가 `/{스킬명}`을 직접 입력해야 진입하며, 모델이 자율적으로 호출하지 못합니다. 세션 전체를 자율 루프로 바꾸거나(`ralph`, `goal`), 외부로 나가거나(`release`), 되돌리기 어렵거나(`finish`, `abort`), 하네스 자신을 고치는(`meta`) 스킬이 대상입니다. 다른 스킬이 본문에서 지시하는 경로까지 막히므로, 체인이 그 앞에서 멈추면 슬래시 커맨드를 안내하고 대기합니다.

### 스택 자동 감지

`execute`가 프로젝트 스택을 자동 감지하여 해당 스킬을 로드한다:

| 감지 파일 | 로드되는 스킬 |
|-----------|-------------|
| `build.gradle` 또는 `pom.xml` | `dev-stack-java` |

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
cd sr-harness
# skills/{skill-name}/SKILL.md 편집 후

git add . && git commit -m "fix: 스킬 내용 수정" && git push
claude plugins marketplace update sr-harness
```

스킬 목록이나 버전을 변경할 때는 `.claude-plugin/plugin.json`과 `.codex-plugin/plugin.json`을 함께 갱신한다.

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
