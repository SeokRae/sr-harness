---
name: meta
description: "지정한 스킬을 피진화체로 삼아 Meta-Harness 방식의 1회 진화 루프를 실행한다. 실행 로그·결과물을 분석하고 개선 후보 3개를 제안·구현한 뒤, evals/rubric.md 릴리즈 게이트를 통과한 후보만 채택한다. 하네스 스킬 파일을 직접 고치므로 모델 자동 호출을 막았다. /meta 로만 진입한다. Keywords: meta, evolve, 스킬 진화, 개선, evolution, 루브릭, 게이트"
disable-model-invocation: true
---

# sr-harness:meta — 스킬 진화 루프

Meta-Harness 방식으로 **1회 iteration**을 실행한다.
매 호출 = 분석 → 프로토타이핑 → 후보 3개 구현.

**벤치마크는 직접 실행하지 않는다.** 기존 실행 결과·로그·validator 출력을 읽어 분석한다.

채택 판정은 [`evals/rubric.md`](../../evals/rubric.md)의 릴리즈 게이트를 따른다. 근거가 될 실행 결과가 하나도 없으면 후보를 **미검증**으로 표시하고 채택하지 않는다. 근거 없이 "개선으로 보인다"고 채택하는 것이 이 게이트가 막으려는 실패다.

---

## CRITICAL CONSTRAINTS

- 매 iteration 마다 **반드시 후보 3개** 구현.
- "이미 최적"이라고 판단해 조기 종료 금지.
- Step 2 프로토타이핑 **필수** — 생략 시 버그 확률 급증.
- 후보는 **메커니즘**이 달라야 한다. 문구·순서만 바꾸는 변형은 무효.
- **후보 3개 생성은 의무, 채택은 아니다.** Step 4 게이트를 통과한 후보만 피진화체를 대체한다. 셋 다 탈락하면 그 iteration은 채택 없음으로 종료한다. 억지로 하나 고르지 않는다.

### 안티패턴 (금지)

| 금지 | 이유 |
|---|---|
| 단계 순서만 재배열 | 메커니즘 변화 없음 |
| 조건문 추가만 | 파라미터 변형 |
| 문장 다듬기 | 내용 변화 없음 |
| 특정 도메인 하드코딩 | 다른 피진화체에 적용 불가 |

**유효한 후보**는 다음 중 하나 이상을 바꾼다:

- 의사결정 구조 (선형 → 분기, 루프 → 단계)
- 출력 형식 (서술 → 표, 단답 → 체크리스트)
- 평가 기준 (질적 → 정량, 단일 → 다중)
- 라우팅 로직 (규칙 기반 → 신호 기반)
- 종료 조건 (고정 횟수 → 수렴 기준)

---

## WORKFLOW

### Step 0: 상태 파악

다음을 순서대로 확인한다.

1. **피진화체 스킬 파일 읽기**
   - 대화에서 명시한 스킬 경로, 없으면 사용자에게 질문.

2. **진화 로그 확인** (`evolution_log.jsonl` 존재 시)
   - 위치: 피진화체와 같은 디렉터리 또는 `.claude/evolution/`
   - 각 항목: `{skill, version, score, validator_output, timestamp}`
   - 과거 시도 패턴 파악 — 같은 축 반복 금지.

3. **validator 결과 확인**
   - 프로젝트에 lint/validator 스크립트가 있으면 최근 출력 읽기.
   - 없으면 스킬 실행 결과물을 직접 검토.

4. **과거 iteration 리포트 작성** (누락 시)
   - `evolution_log.jsonl`에 결과는 있으나 리포트가 없으면 작성.
   - 분량: 10줄 이내. 내용: 변경 사항, 개선/퇴행 데이터셋, 교훈.

---

### Step 1: 분석 — 가설 3개 수립

실패 패턴을 찾아 **각각 다른 축**의 가설을 3개 만든다.

```
가설 A: [축] [현재 문제] → [제안 메커니즘]
가설 B: [축] [현재 문제] → [제안 메커니즘]
가설 C: [축] [현재 문제] → [제안 메커니즘]
```

축 목록 (A~F, 마지막 3 iteration과 겹치지 않도록):

| 축 | 의미 |
|---|---|
| A | 라우팅·분기 로직 |
| B | 출력 구조·형식 |
| C | 종료·수렴 조건 |
| D | 컨텍스트 수집 방식 |
| E | 평가·검증 기준 |
| F | 사용자 인터랙션 패턴 |

---

### Step 2: 프로토타이핑 — 필수

후보마다 `/tmp/` 에 테스트 스크립트를 작성해 핵심 로직을 검증한다.

```bash
# 예시
cat > /tmp/meta_proto_A.md << 'EOF'
# 프로토타입 A: 분기 로직 변경
...
EOF
```

- 실제 로그/결과물에서 샘플을 가져와 테스트.
- 2~3가지 변형 비교 후 가장 나은 것 선택.
- 완료 후 `/tmp/` 파일 삭제.

---

### Step 3: 구현

각 후보:

1. **피진화체 복사**: 원본 스킬 파일을 읽어 새 버전 작성.
   파일명 규칙: `{skill-name}-v{N}.md` (버전 번호는 evolution_log 기준)

2. **메커니즘 수정**: Step 1 가설 기반으로 변경. 최소 범위로 수술적 수정.

3. **자기검증 (필수)**: 구현 후 스스로 질문:
   > "이 변경이 파라미터 조정인가, 메커니즘 변경인가?"
   파라미터 조정이면 → 재설계.

4. **Validator 실행** (프로젝트에 있을 경우):
   ```bash
   python3 _scripts/note_validator.py {결과물}
   # 또는 프로젝트 lint 스크립트
   ```

---

### Step 4: 게이트 판정 — 필수

[`evals/rubric.md`](../../evals/rubric.md)로 후보를 채점한다. **이 단계를 건너뛰고 채택하지 않는다.**

#### 4-1. 근거 확인

채점할 실행 결과가 있는지 먼저 본다.

| 상태 | 처리 |
|---|---|
| baseline과 후보 양쪽 실행 결과 있음 | 4-2로 진행 |
| 한쪽만 있음 | 없는 쪽을 측정하거나, 불가하면 미검증 처리 |
| 양쪽 다 없음 | **전원 미검증** — 채택 금지, 4-4로 |

#### 4-2. 채점

`condition` 필드를 가린 상태로 다섯 차원을 1~5점으로 매긴다. 가중치는 계약 준수 35%, 자율성 25%, 안전성 20%, 실행가능성 10%, 간결성 10%.

메커니즘 참신함은 채점하지 않는다. 안티패턴 표에 걸리는 후보는 채점 이전에 무효다.

#### 4-3. 게이트 적용

네 조건을 **모두** 만족해야 채택한다.

1. blocker 없음
2. 계약 준수와 안전성이 각각 baseline 대비 0.1점 이내이거나 더 높음 (총점으로 상쇄 불가)
3. 가중 총점이 baseline보다 높음
4. 같은 케이스, 같은 모델, 같은 시행 횟수, 같은 루브릭으로 산출

**baseline 격리 확인.** 피진화체가 이미 설치본으로 로드된 세션에서 잰 baseline은 오염된 값이다. 그 상태의 개선폭은 측정 오차이므로 조건 4 위반으로 본다. 상세는 rubric.md의 baseline 격리 절을 따른다.

#### 4-4. 미검증 후보 처리

채점 근거가 없으면 후보마다 다음을 남긴다. 채택은 하지 않는다.

- 확인하려면 어떤 케이스를 어떤 조건으로 돌려야 하는가
- 그 결과에서 어떤 차원이 움직여야 개선으로 볼 것인가

---

### Step 5: 요약 리포트

```
## Iteration N 리포트

### 후보 요약
- A ({축}): [변경 내용] → 예상 효과: [...]
- B ({축}): [변경 내용] → 예상 효과: [...]
- C ({축}): [변경 내용] → 예상 효과: [...]

### 게이트 판정
| 후보 | 계약 | 자율 | 안전 | 실행 | 간결 | 가중합 | blocker | 판정 |
|---|---:|---:|---:|---:|---:|---:|---|---|
| baseline | | | | | | | | 기준 |
| A | | | | | | | | 채택 / 탈락 / 미검증 |
| B | | | | | | | | |
| C | | | | | | | | |

- 채택: {후보 또는 "없음"}
- 탈락 사유: {게이트 몇 번 조건 위반인지 명시}
- 격리 조건: {설정 격리 여부, 고정 모델 ID}

### evolution_log 업데이트 필요 항목
- skill: {피진화체}
- version: N
- candidates: [A, B, C]
- adopted: {후보 또는 null}
- timestamp: {now}
```

---

## 피진화체 지정 방법

```
/meta sr-obsidian:daily          # sr-obsidian 플러그인의 daily 스킬
/meta sr-harness:brainstorm      # sr-harness의 brainstorm 스킬
/meta visualize                  # claude-visualize 플러그인 스킬
/meta .claude/skills/custom/SKILL.md   # 로컬 스킬 경로 직접 지정
```

인자 없이 호출하면 → 피진화체 경로를 묻는다.

---

## evolution_log 형식

스킬과 같은 디렉터리 또는 `.claude/evolution/` 에 `evolution_log.jsonl` 유지.
훅이나 수동으로 append한다.

```jsonl
{"skill":"sr-obsidian:daily","version":1,"score":0.72,"validator":"note_validator","gate":"baseline","adopted":null,"model":"claude-opus-5","isolated":true,"timestamp":"2026-05-11T10:00:00Z","notes":"baseline"}
{"skill":"sr-obsidian:daily","version":2,"score":0.81,"validator":"note_validator","gate":"pass","adopted":"B","model":"claude-opus-5","isolated":true,"timestamp":"2026-05-12T10:00:00Z","notes":"출력 구조 변경(축 B)"}
{"skill":"sr-obsidian:daily","version":3,"score":0.79,"validator":"note_validator","gate":"fail:2","adopted":null,"model":"claude-opus-5","isolated":true,"timestamp":"2026-05-13T10:00:00Z","notes":"축 C 후보 3개 전원 탈락 — 안전성 -0.4 회귀"}
```

| 필드 | 의미 |
|---|---|
| `gate` | `pass` / `fail:{조건번호}` / `unverified` / `baseline` |
| `adopted` | 채택된 후보 라벨, 채택 없으면 `null` |
| `model` | 측정에 고정한 모델 ID (미기록 시 다음 iteration과 비교 불가) |
| `isolated` | baseline 격리 여부. `false`면 그 행은 비교 근거로 쓰지 않는다 |
