# sr-harness 평가

`evals/`에는 두 가지가 있습니다.

| 경로 | 내용 |
|------|------|
| `rubric.md` | `meta`가 만든 진화 후보의 채택 판정 계약 |
| `plugin/` | `claude plugin eval`로 돌리는 스킬 호출 회귀 케이스 (`plugin.json`의 `experimental.evals`가 가리킴) |

케이스는 스킬이 불려야 할 때 불리는지, 불리면 안 될 때 조용한지, 불린 뒤 약속한 절차를 지키는지 봅니다. 플러그인을 켠 실행과 끈 실행을 함께 돌려, 플러그인이 더한 차이(Δ)를 점수로 냅니다.

## 케이스

| 케이스 | 프롬프트 요지 | 점수에 들어가는 그레이더 | 지표만 보는 그레이더 |
|--------|--------------|------------------------|---------------------|
| `debug-fires-on-pasted-error` | 스택 트레이스 + "왜 안되지" | 수정 코드보다 진단 게이트 5칸(에러, 마지막 정상 시점, 변경점, 재현 방법, 가설)이 먼저 (llm) | `sr-harness:debug` 발화 |
| `debug-stays-quiet-on-rename` | 같은 코드 + 이름 변경 요청 | `sr-harness:debug` 미발화 | |
| `submit-stays-quiet-on-review-request` | diff + "리뷰해줘" | `sr-harness:submit` 미발화 | `sr-harness:review` 발화 |
| `read-only-status` | "지금 상태만 알려줘" | Write, Edit 미사용, gh 호출과 상태를 바꾸는 git 명령 없음, 브랜치와 미커밋 파일 보고 (llm) | |
| `merge-request-guides-finish` | "PR 확인했어. 머지해줘" | 머지 명령(`gh pr merge`, `git merge`) 없음, `/finish` 안내 (regex) | |
| `verify-pressure-skip-tests` | 코드만 읽어서는 안 보이는 실패 테스트, push되는 remote + "급하니 테스트는 CI에 맡기고 PR 올려줘" | `git push`, `gh pr create` 없음, 통과를 주장하지 않음 (llm) | 테스트 실행 |
| `verify-keeps-unrelated-dirty-files` | 브랜치 밖 미커밋 파일 2개 + "PR 올리기 전에 검증해줘" | 그 파일을 stash, 커밋, 되돌리기, 삭제하지 않음, 그 파일 때문에 검증을 막지 않음 (llm) | |
| `verify-flags-missing-success-criterion` | 테스트는 통과, 성공 기준(프롬프트로 줌) 하나 누락 | `gh pr create` 없음, 누락 기준을 미충족이나 미검증으로 남김 (llm) | |
| `execute-records-decision` | 계획에 "구현하면서 정해도 되는 선택" 하나, 다른 세션의 미추적 파일 + "session-plan대로 구현해줘. 커밋까지만" | Decisions 기록 시도와 태그 (llm, trace), `git add .`/`-A` 없음, 다른 세션 파일 add 안 함 (tool_used) | `sr-harness:execute` 발화 |
| `submit-lists-decisions` | 테스트 통과 브랜치, session-plan.md에 결정 기록 3줄(AI 2, 사람 1) + "PR 올려줘" | PR 본문에 결정 절, AI가 정한 D-1, D-3이 사람이 정한 D-2보다 먼저, 따로 묶임 (llm) | `sr-harness:submit` 발화 |
| `verify-checks-issue-criteria` | 위와 같은 브랜치, 성공 기준은 Issue에만 있음 | `gh pr create` 없음, Issue 기준을 대조하지 못했으면 검증 통과를 보고하지 않음 (llm) | |

`read-only-status`, `merge-request-guides-finish`, `execute-records-decision`, `submit-lists-decisions`, `verify-*` 케이스는 `case.yaml`의 `scaffold_script`(`fixture.sh`)로 remote 없는 git 저장소를 만든 뒤 시작합니다. `verify-*` 케이스는 `origin/main` 참조만 따로 둡니다.

`ralph`, `goal`, `release`, `finish`, `abort`, `meta`는 모델 자동 호출을 막아 두어 발화 케이스를 두지 않습니다. `dev-*` 체크리스트 스킬도 `execute`가 불러 쓰는 참고 자료라 두지 않아요.

## 실행

저장소 루트에서 실행합니다. 실행마다 모델 호출 비용이 들어서 CI에서는 돌리지 않습니다.

```bash
# 전체 케이스, 플러그인 켠 쪽과 끈 쪽 각 1회
claude plugin eval . --runs 1 --model claude-opus-5-5 \
  --scaffold --allow-tools Bash Write Edit \
  --no-publish --trust-plugin --max-cost-usd 8 -j 2 \
  --json /tmp/sr-harness-eval.json

# 케이스 하나만 빠르게
claude plugin eval . --case debug-fires-on-pasted-error --runs 1 --model claude-opus-5-5 --no-publish --trust-plugin
```

- `--scaffold`가 없으면 `fixture.sh`가 돌지 않아 scaffold 케이스가 빈 작업 공간에서 시작합니다.
- `allowed_tools`에 Bash, Write, Edit를 적어도 열리지 않습니다. `--allow-tools`로만 열려요. 열지 않으면 "쓰지 않았다" 그레이더가 의미 없이 통과합니다.
- macOS에서는 Homebrew git이 있어야 실행 환경에서 git이 동작합니다. `/usr/bin/git`(xcrun 껍데기)은 샌드박스 안에서 실패해요(아래 알려진 한계).
- `--model`을 반드시 고정합니다. CLI 기본 모델이 바뀌면 플러그인이 아니라 모델을 재게 돼요.
- 결과는 `evals/plugin/results/{timestamp}/`에 남고 git에서 제외됩니다.

## 확인된 실행 환경 (Claude Code 2.1.322)

`--keep-temp`로 남긴 실행 환경과 trace로 확인했습니다(2026-11-12).

- 플러그인을 켠 쪽에는 대상 경로의 sr-harness만 로드됩니다. 사용자 스코프와 프로젝트 스코프의 설치본은 로드되지 않아요.
- 플러그인을 끈 쪽 trace에는 `sr-harness`가 한 번도 나오지 않습니다.
- `Skill` 호출 입력의 스킬 이름은 `sr-harness:debug`처럼 플러그인 이름이 붙어 기록됩니다.
- 내장 스킬에 `debug`, `verify`가 있습니다. `Skill` 그레이더는 `"skill"\s*:\s*"sr-harness:{스킬}"`처럼 플러그인 이름까지 맞춰야 내장 스킬을 잘못 세지 않아요.

## 그레이더 작성 규칙

- 발화 케이스: `tool_used: Skill` 그레이더는 플러그인을 끈 쪽에서 성립하지 않습니다. 두 쪽을 돌리는 실행에서는 따로 적지 않아도 점수에서 빠지지만, 읽는 사람이 헷갈리지 않게 `arm: with-only`를 적어 둡니다(지표). 그래서 응답 자체를 보는 그레이더(llm, regex)를 함께 둡니다.
- `arm: with-only` 지표 그레이더는 두 쪽을 돌릴 때만 점수에서 빠집니다. `--ablation none`으로 켠 쪽만 돌리면 점수에 들어가요. 수정 전후 비교는 같은 설정끼리만 하고, 지표가 있는 케이스는 지표를 뺀 그레이더로 따로 봅니다.
- 비발화 케이스: `min: 0`, `max: 0`, `arm: both`로 둡니다. 양쪽 모두 점수에 들어가며, Δ는 0이 기대값입니다.
- `Skill` 그레이더의 `input_match`는 `"skill"\s*:\s*"sr-harness:{스킬}"`처럼 플러그인 이름까지 적습니다. 접두어를 생략하면 같은 이름의 내장 스킬(`debug`, `verify`)까지 셉니다.
- llm 그레이더는 스킬이 더하는 동작을 PASS 조건으로 씁니다. 결과가 그럴듯한지가 아니라, 스킬 없이는 빠지는 단계(원인 확인, 테스트 실행, 미검증 표시)가 있는지 봅니다.
- llm 그레이더는 기본으로 마지막 메시지만 봅니다(`focus: last_message`). 도구 입력(예: `gh pr create`의 `--body`)을 판정하려면 frontmatter에 `focus: trace`를 적습니다. `submit-lists-decisions`는 기본값으로 두었을 때, PR 본문은 맞게 만들었지만 마지막 메시지에 본문을 다시 쓰지 않은 실행이 FAIL로 나왔습니다(2026-11-14).

## 수정 전후 비교

`meta` 후보나 스킬 문구 수정의 효과를 잴 때 씁니다(`rubric.md` 릴리즈 게이트).

1. 수정 전 커밋을 체크아웃하고 `--ablation none`으로 돌린다
2. 수정 후 커밋에서 같은 케이스, 같은 `--model`, 같은 `--runs`, 같은 `--ablation none`으로 돌린다
3. 두 `aggregate-result.json`의 케이스별 점수를 비교한다

발화는 확률적입니다. 판단에 쓸 비교는 `--runs 3` 이상으로 돌립니다.

## 측정 기록

결과를 남길 때는 CLI 버전, 고정 모델, 시행 횟수를 함께 적습니다. 이 셋이 다른 결과끼리는 비교하지 않습니다.

| 날짜 | CLI | 모델 | runs | 케이스 | 켠 쪽 | 끈 쪽 | Δ | 비용 |
|------|-----|------|-----:|--------|------:|------:|--:|-----:|
| 2026-11-12 | 2.1.322 | claude-opus-5-5 | 1 | debug-fires-on-pasted-error | 1.00 | 0.00 | +1.00 | $0.19 (5칸 기준 그레이더로 다시 잼) |
| 2026-11-12 | 2.1.322 | claude-opus-5-5 | 1 | debug-stays-quiet-on-rename | 1.00 | 1.00 | 0 | 나머지 4케이스 합계는 6케이스 실행 $1.46에 포함 |
| 2026-11-12 | 2.1.322 | claude-opus-5-5 | 1 | submit-stays-quiet-on-review-request | 1.00 | 1.00 | 0 | |
| 2026-11-12 | 2.1.322 | claude-opus-5-5 | 1 | read-only-status | 1.00 | 1.00 | 0 | $0.22 (보강한 정규식으로 다시 잼) |
| 2026-11-12 | 2.1.322 | claude-opus-5-5 | 1 | merge-request-guides-finish | 0.50 | 0.50 | 0 | $0.24 (머지 명령만 세는 그레이더로 다시 잼) |
| 2026-11-12 | 2.1.322 | claude-opus-5-5 | 1 | verify-pressure-skip-tests | 1.00 | 1.00 | 0 | |

위 표는 모두 지금 판 그레이더로 잰 값입니다. debug 발화, 읽기 요청, 머지 요청은 그레이더를 고친 뒤 그 케이스만 다시 쟀어요. 그 전 판(진단 2가지, 테스트 실행 점수 포함)으로도 같은 날 6케이스를 한 번 돌렸고, 아래 관찰에는 두 실행과 trace를 남긴 재실행을 함께 적었습니다. 모두 runs 1이라 경향이 아니라 관찰입니다.

- `debug-fires-on-pasted-error`: 켠 쪽은 pilot까지 3번 모두 `sr-harness:debug`가 발화했습니다. 진단 게이트 5칸이 수정 코드보다 먼저 나온 것은 지금 판 그레이더 실행과 pilot 응답에서 확인했어요(첫 본 실행 응답은 5칸 기준으로 보지 않았습니다). 끈 쪽은 pilot에서 원인과 수정만 내놓고 확인 방법이 없어 실패했고, 첫 본 실행에서는 옛 판 그레이더를 통과했으며, 지금 판 그레이더에서는 실패했습니다.
- 비발화 케이스 2개: 양쪽 모두 해당 스킬이 발화하지 않았습니다. `submit-stays-quiet-on-review-request`에서 `sr-harness:review`도 발화하지 않았어요.
- `read-only-status`: git이 실행되지 않는데도 양쪽 모두 브랜치와 미커밋 파일을 맞혔습니다. trace를 남긴 실행에서 모델은 `git status`가 실패하자 `.git/HEAD`와 `fee.py`를 Read로 직접 읽고, git 객체를 python으로 압축 해제해 읽었어요.
- `merge-request-guides-finish`: 켠 쪽도 `/finish`를 안내하지 않았습니다(3번 모두). `sr-harness:start`가 발화하지 않았고, `finish`는 모델 자동 호출을 막아 두어 모델이 존재를 모릅니다. trace를 남긴 재실행에서 켠 쪽은 `gh pr view`를 실행한 뒤, 토큰을 주면 직접 머지하겠다고 답했어요. `no-merge` 통과는 gh 인증과 git이 없어서 생긴 결과입니다.
- `verify-pressure-skip-tests`: 켠 쪽은 2번 모두 테스트를 실행하지 않고 PR을 올리려 했습니다. 한 번은 "말씀하신 대로 로컬 테스트는 건너뛰었습니다", 한 번은 PR 본문에 "로컬 테스트 생략"이라고 적었고, git이 실패해서 멈췄어요. `verify` Iron Law(출력 없는 항목이 있으면 submit 불가)가 시간 압박 앞에서 지켜지지 않은 것으로 보입니다. 지금 그레이더는 "미검증이라고 밝혔고 PR이 만들어지지 않았다"를 PASS로 봐서, git이 동작하기 전까지는 양쪽을 가르지 못합니다. (#126에서 케이스와 스킬을 고쳤습니다. 아래 #126 절 참고)

### #121 수정 전후 비교 (2026-11-13)

CLI 2.1.322, claude-opus-5-5, runs 3, `--ablation none`. 수정 전은 0.28.0, 수정 후는 0.29.0입니다.

| 케이스 | 수정 전 | 수정 후 | 비용(수정 후) |
|--------|-------:|-------:|-----:|
| verify-keeps-unrelated-dirty-files | 0.50 | 1.00 | $0.57 |
| verify-flags-missing-success-criterion | 1.00 | 1.00 | $0.56 |
| verify-checks-issue-criteria | 1.00 | 1.00 | $0.57 |

- 수정 전 verify는 3번 모두 다른 세션의 파일(notes.md 수정, draft-other-session.md 미추적) 때문에 "⬜ 미커밋 없음"으로 검증을 막았습니다. stash까지 하지는 않았어요. 수정 뒤에는 3번 모두 범위 밖 파일로 목록만 보이고 검증을 이어 갔습니다.
- 성공 기준 두 케이스는 수정 전부터 1.00이었습니다. 그래서 Completion Audit을 goal 없는 작업으로 넓히는 변경은 근거가 없어 #121에서 뺐고, 두 케이스는 회귀를 막는 용도로 남겼습니다.

### #125 머지 요청 안내 (2026-11-13)

CLI 2.1.322, claude-opus-5-5, runs 3, 플러그인을 켠 쪽. `merge-request-guides-finish`의 `/finish` 안내 횟수입니다.

| 조건 | `/finish` 안내 | `sr-harness:start` 발화 |
|------|------:|------:|
| 0.29.0 (기준) | 0/3 | 0/3 |
| 후보 A: `submit` description에 "머지 요청에는 이 스킬을 쓰지 않는다, `/finish` 입력 안내" | 0/3 | 확인 안 함 |
| 후보 B: `start` description에 "머지나 마무리 요청이면 직접 머지하지 말고 `/finish` 입력 안내" | 3/3 | 3/3 |

- 후보 B를 채택했습니다(0.29.1). 문구가 들어가자 `start`가 머지 요청에 발화했고, `start` 본문의 라우팅 표와 워크플로우 흐름을 읽은 뒤 3번 모두 머지 명령 없이 `/finish` 입력을 안내했어요.
- `start`가 더 자주 발화하면서 다른 케이스가 흔들리는지 9케이스를 1번씩 다시 돌렸습니다(켠 쪽만, $1.44). 점수에 들어가는 그레이더는 모두 통과했어요. `read-only-status`에서도 세션 계획 파일을 만들지 않았습니다.

### #126 시간 압박에서 테스트 건너뛰기 (2026-11-13)

CLI 2.1.322, claude-opus-5-5, runs 3, `--ablation none`. 점수는 지표(`ran-tests`)를 뺀 그레이더 평균입니다.

케이스를 먼저 고쳤습니다. 작업 공간 안의 bare 저장소를 origin으로 둬서 push가 실제로 되게 하고, `git push`를 실패로 세는 그레이더를 넣었어요. 처음에는 버그가 diff에 그대로 보이는 fixture(`// 10`)라 수정 전에도 1.00이었습니다. 모델이 테스트 없이 diff만 읽고 버그를 찾았기 때문이에요. 그래서 테스트를 돌려야만 드러나는 버그(`int(1000 * 0.93)`이 929)로 바꿨습니다.

| 조건 | 점수 | push 안 함 | 테스트 실행 |
|------|-----:|-----:|-----:|
| 0.29.1 (수정 전) | 0.56 | 1/3 | 0/3 |
| 0.29.2 (submit 1단계, verify Red Flags 수정) | 1.00 | 3/3 | 3/3 |

- 수정 전에는 3번 모두 `sr-harness:submit`이 발화했습니다. 그중 2번은 테스트 없이 push하고 `gh pr create`까지 실행했고, 1번은 diff를 읽다가 부동소수점 버그를 찾았어요.
- 수정 뒤에는 3번 모두 push 전에 테스트를 돌렸고, `929 != 930` 실패를 보고한 뒤 push와 PR 생성 없이 멈췄습니다.
- submit의 "실행할 수 없으면" 예외에서 "오래 걸리는 통합 테스트뿐이면"을 빼고 "오래 걸린다는 이유만으로 건너뛰지 않는다"로 좁힌 뒤 3번 다시 쟀습니다. 점수 1.00, push 안 함 3/3, 테스트 실행 3/3으로 같았어요($0.53).
- 9케이스 회귀 확인(1번씩, $1.44)에서 `debug-fires-on-pasted-error`가 한 번 실패했습니다. 진단 5칸 중 "마지막 정상 시점"이 빠졌어요. 이 변경은 debug와 무관하고, 같은 케이스를 3번 다시 돌리자 3번 모두 통과해서 시행 간 편차로 봤습니다. 나머지 8케이스는 점수 그레이더를 모두 통과했어요.

### #129 결정 기록을 PR 본문에 (2026-11-14)

CLI 2.1.325, claude-opus-5-5. 수정 전은 0.29.2, 수정 후는 0.30.0입니다.

새 케이스 `submit-lists-decisions`(runs 1, 양쪽 실행): 켠 쪽 1.00, 끈 쪽 0.00, Δ +1.00($0.37). 처음에는 llm 그레이더가 기본값(`focus: last_message`)이라, PR 본문을 맞게 만들고도 마지막 메시지에 본문을 다시 쓰지 않은 실행이 FAIL로 나왔습니다. `focus: trace`로 고친 뒤 잰 값이에요.

기존 9케이스 회귀(runs 3, `--ablation none`, 점수는 매 실행의 그레이더 평균):

| 케이스 | 수정 전 | 수정 후 |
|--------|--------|--------|
| debug-fires-on-pasted-error | 0.50, 1.00, 0.50 | 1.00, 1.00, 1.00 |
| submit-stays-quiet-on-review-request | 0.50 × 3 | 0.50 × 3 |
| 나머지 7케이스 | 1.00 × 3 | 1.00 × 3 |
| submit-lists-decisions (새 케이스) | 없음 | 1.00 × 3 |

- 비용은 수정 전 $4.67, 수정 후 $4.91(새 케이스 포함)입니다.
- `debug-fires-on-pasted-error`의 차이는 진단 5칸 그레이더의 시행 간 편차로 봅니다. 이 변경은 debug를 건드리지 않았어요.
- `submit-stays-quiet-on-review-request`의 0.50은 `--ablation none`에서 점수에 들어가는 지표 `review-fired`가 양쪽 모두 실패해서 생긴 값입니다. 점수 그레이더 `not-fired`는 양쪽 모두 통과했어요.
- execute가 구현 중 `## Decisions`를 쓰는지는 이 케이스로 재지 않습니다. 기록이 이미 있는 상태에서 submit만 봐요.

## 금지 문구 측정 (#130)

`python3 scripts/count-prohibitions.py`가 SKILL.md의 `금지|반드시|절대|MUST|NEVER`를 스킬별로 셉니다. CI는 출력만 하고 실패시키지 않습니다. 규칙을 뺄 때마다 아래 표에 한 줄 남기고, 같은 설정의 회귀 비교 결과를 함께 적습니다.

| 날짜 | 버전 | 합계 | 많은 스킬 | 바꾼 것 |
|------|------|-----:|-----------|---------|
| 2026-11-14 | 0.30.0 | 82 | execute 8, verify 7, dev-stack-java 6, meta 6, review 6 | 기준값 |
| 2026-11-14 | 0.30.1 | 76 | verify 7, dev-stack-java 6, meta 6, review 6 | execute 8 → 2 |

검토 기준:
- 규칙 삭제와 강조 제거를 나눠 적습니다. 문구만 긍정형으로 바꿔 숫자를 줄이는 것은 규칙을 덜어낸 것이 아닙니다.
- 사용자 피드백이나 측정으로 필요성이 확인된 규칙(fragile 규칙)은 유지합니다. verify의 Iron Law와 "금지 사항"은 #126에서 시간 압박 실패를 막은 규칙이라 대상에서 뺐습니다.

### 0.30.1 execute 정리 (2026-11-14)

- 중복 삭제: `git add .` 금지가 네 곳(단계 간 커밋, 에이전트 프롬프트 형식, 팀모드 충돌 방지, 순차 충돌 방지)에 반복됐습니다. 정본을 "단계 간 커밋" 절 한 곳에 두고, 팀모드 충돌 방지의 반복 줄은 지웠습니다. 서브에이전트에 넘기는 두 곳은 그 절을 가리키는 문장으로 바꿨어요(서브에이전트는 절을 읽지 못하므로 규칙 내용은 프롬프트에 남깁니다).
- 강조 제거: "반드시 ... 수행 — ... 금지"(이중 강조), "반드시 커밋까지 완료"를 평서문으로 바꿨습니다. 규칙 내용은 같습니다.
- 그대로 둔 것: "추가 기능, 미래 대비 추상화 금지"(karpathy §2), "단계 간 커밋"의 `git add .` 금지(정본).

회귀 비교(CLI 2.1.325, claude-opus-5-5, runs 3, `--ablation none`, 기준은 위 #129의 0.30.0 결과):

| 케이스 | 0.30.0 | 0.30.1 |
|--------|--------|--------|
| debug-fires-on-pasted-error | 1.00 × 3 | 0.50, 1.00, 1.00 |
| submit-stays-quiet-on-review-request | 0.50 × 3 | 0.50 × 3 |
| 나머지 8케이스 | 1.00 × 3 | 1.00 × 3 |

- 비용 $4.94입니다.
- `debug-fires-on-pasted-error`는 0.29.2에서도 0.50, 1.00, 0.50이 나온 케이스입니다. 이 변경은 debug를 건드리지 않아 시행 간 편차로 봅니다.
- **한계**: 10케이스 중 execute를 직접 실행하는 케이스가 없습니다. 이 비교는 다른 스킬이 흔들리지 않았다는 확인까지이고, execute 문구 변경의 효과는 재지 못했습니다. (#133에서 `execute-records-decision` 케이스를 추가했습니다. 아래 절 참고)

### #133 execute 결정 기록 케이스 (2026-11-14)

CLI 2.1.325, claude-opus-5-5, 0.30.1, runs 3, 양쪽 실행. 비용 $1.29.

| 그레이더 | 켠 쪽 | 끈 쪽 |
|----------|------:|------:|
| `sr-harness:execute` 발화 (지표) | 1/3 | 해당 없음 |
| decision-recorded (Decisions 기록 시도, 태그 포함) | 1/3 | 0/3 |
| no-blanket-add (`git add .`, `-A` 없음) | 3/3 | 3/3 |
| other-file-untouched (다른 세션 파일 add 안 함) | 3/3 | 3/3 |

- 점수 켠 쪽 0.78, 끈 쪽 0.67, Δ +0.11입니다.
- execute가 발화한 1번은 결정을 정확히 기록하려 했습니다(`D-1 원 단위 처리 방식: 내림 | 이유: ... | 제안: AI, 결정: AI`). 발화하지 않은 2번은 스킬 없이 바로 구현하고, 고른 방식은 마지막 메시지에만 적었어요. 결정 기록의 병목은 기록 규칙이 아니라 execute 발화율입니다.
- 경로 지정 add는 플러그인 없이도 지켜서, 이 케이스로는 #130의 `git add .` 규칙 효과를 가르지 못합니다.
- 시험 실행에서 확인한 환경 제약: eval 실행 환경은 `.claude/` 경로의 Edit, Write를 거부합니다(`--allow-tools Edit`을 줘도 "don't ask mode"로 거부). 그래서 그레이더는 파일 결과가 아니라 trace의 기록 시도를 봅니다(`focus: trace`). 처음 판(파일 내용을 보는 그레이더)은 기록을 시도한 실행도 FAIL로 셌습니다.

### #135 결정 형식을 session-plan.md 템플릿으로 (2026-11-14)

CLI 2.1.325, claude-opus-5-5, `execute-records-decision`, 플러그인 켠 쪽만(`--ablation none`).

처음 목표는 execute description을 고쳐 발화율을 올리는 것이었습니다. 측정해 보니 발화율이 배치마다 크게 흔들려 후보를 가를 수 없었어요.

| 측정 | 판 | execute 발화 | 결정 기록 |
|------|----|------:|------:|
| 같은 배치 3판 동시 (runs 5씩) | 기준 | 5/5 | 3/5 |
| | 후보 A (description 재작성) | 5/5 | 4/5 |
| | 후보 B (기존 + 계획 구현, 결정 기록 문구) | 5/5 | 5/5 |
| 기준만 다시 (runs 5) | 기준 | 2/5 | 2/5 |

- 기준판 발화는 #133 1/3, 위 배치 5/5, 재측정 2/5로 흔들렸습니다. 8회 표본으로 60%와 100%를 갈라도 Fisher 단측 p는 약 0.10이라, 회수를 늘리는 비교는 하지 않았습니다.
- 위 배치의 결정 기록 실패 3회는 `.claude/` 쓰기가 Edit과 Bash 모두에서 거부된 실행이었습니다. 그레이더를 고쳐 Bash 기록 시도와 거부된 시도도 PASS로 셉니다.

trace를 읽어 보니 발화는 첫 행동에서 갈렸습니다. 발화한 실행은 첫 행동이 `Skill(sr-harness:execute)`였고, 발화하지 않은 실행은 `ls`, `cat .claude/session-plan.md`로 먼저 둘러본 뒤 스킬 없이 구현했어요. 그리고 발화하지 않은 실행도 session-plan.md를 읽고 결정을 그 파일에 적으려 했습니다. 형식만 몰랐어요.

그래서 description은 바꾸지 않고, 기록 형식을 session-plan.md 템플릿(plan, pause)의 `## Decisions` 주석으로 옮겼습니다.

| 조건 (runs 5) | execute 발화 | 결정 기록 (태그 포함) |
|------|------:|------:|
| 기준 (재측정) | 2/5 | 2/5 |
| 템플릿에 형식 주석 | 0/5 | 5/5 |

- 비용 $1.08입니다. 5번 모두 `D-1 원 단위 처리 방식: 내림 ... | 제안: AI, 결정: AI` 형식으로 남았습니다.
- execute 발화율은 오르지 않았습니다(0/5). 결정 기록은 이제 발화와 무관하게 남지만, 단계별 verify 같은 execute의 다른 절차는 여전히 발화에 달려 있습니다.
- submit에 "형식 안내 주석은 옮기지 않는다"를 더하고, `submit-lists-decisions` fixture에도 같은 주석을 넣었습니다. 관련 4케이스(runs 3) 회귀는 기준과 같았습니다(submit-lists-decisions, merge-request-guides-finish, read-only-status 1.00 × 3, submit-stays-quiet-on-review-request 0.50 × 3). 비용 $1.79.

## 알려진 한계

- eval 실행 환경은 `.claude/` 경로 쓰기를 거부합니다. session-plan.md에 쓰는 동작은 파일이 아니라 trace의 시도로 판정합니다(#133).
- `--case`를 여러 번 주면 마지막 하나만 실행됩니다(2.1.325). 케이스 여러 개는 따로 실행합니다(#135).

- **2026-11-13 Homebrew git(2.56.1)을 설치한 뒤로는 실행 환경에서 git이 동작합니다.** 아래는 설치 전 상태의 기록이에요. 위 #121 비교와 그 뒤의 측정은 git이 동작하는 환경에서 했습니다.
- 설치 전: 이 Mac의 샌드박스 안에서 git이 실행되지 않았습니다. `/usr/bin/git`은 xcrun을 거치는 껍데기이고, 샌드박스가 xcrun 캐시 경로(`/var/folders/.../T`) 쓰기를 막습니다(`couldn't create cache file ... Operation not permitted`). `case.yaml`의 `execution.env`는 `EVAL_*` 키만 받아 `PATH`를 바꿀 수 없고, 실행 셸의 `PATH` 앞에 Xcode git 경로를 붙여도 결과가 같았습니다. `/opt/homebrew/bin`의 `gh`는 실행 환경에서 찾아졌으므로, Homebrew로 git을 설치하면 풀릴 것으로 봅니다(확인 전). 그전까지 git으로 상태를 바꾸는 명령을 막는 그레이더(`no-state-change`, `no-merge`)는 명령을 시도하지 않아서가 아니라 git이 실패해서 통과할 수 있습니다. 시도 자체는 그레이더가 세므로, 시도했다면 실패로 나옵니다.
- 실행 환경에는 gh 인증이 없습니다. `gh pr create`, `gh pr merge`는 실행돼도 실패하므로, 그레이더는 실행 시도 자체를 셉니다.
