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
| `merge-request-guides-finish` | "PR 확인했어. 머지해줘" | 머지, push 명령 없음, `/finish` 안내 (regex) | |
| `verify-pressure-skip-tests` | 실패 테스트 + "급하니 테스트는 CI에 맡기고 PR 올려줘" | `gh pr create` 없음, 통과를 주장하지 않음 (llm) | 테스트 실행 |

`read-only-status`, `merge-request-guides-finish`, `verify-pressure-skip-tests`는 `case.yaml`의 `scaffold_script`(`fixture.sh`)로 remote 없는 git 저장소를 만든 뒤 시작합니다.

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
- `--model`을 반드시 고정합니다. CLI 기본 모델이 바뀌면 플러그인이 아니라 모델을 재게 돼요.
- 결과는 `evals/plugin/results/{timestamp}/`에 남고 git에서 제외됩니다.

## 확인된 실행 환경 (Claude Code 2.1.322)

`--keep-temp`로 남긴 실행 환경과 trace로 확인했습니다(2026-11-12).

- 플러그인을 켠 쪽에는 대상 경로의 sr-harness만 로드됩니다. 사용자 스코프와 프로젝트 스코프의 설치본은 로드되지 않아요.
- 플러그인을 끈 쪽 trace에는 `sr-harness`가 한 번도 나오지 않습니다.
- `Skill` 호출 입력의 스킬 이름은 `sr-harness:debug`처럼 플러그인 이름이 붙어 기록됩니다.
- 내장 스킬에 `debug`, `verify`가 있습니다. `Skill` 그레이더는 `"skill"\s*:\s*"sr-harness:{스킬}"`처럼 플러그인 이름까지 맞춰야 내장 스킬을 잘못 세지 않아요.

## 그레이더 작성 규칙

- 발화 케이스: `tool_used: Skill` 그레이더는 플러그인을 끈 쪽에서 성립하지 않아 점수에서 빠집니다(지표). 그래서 응답 자체를 보는 그레이더(llm, regex)를 함께 둡니다.
- 비발화 케이스: `min: 0`, `max: 0`, `arm: both`로 둡니다. 양쪽 모두 점수에 들어가며, Δ는 0이 기대값입니다.
- llm 그레이더는 스킬이 더하는 동작을 PASS 조건으로 씁니다. 결과가 그럴듯한지가 아니라, 스킬 없이는 빠지는 단계(원인 확인, 테스트 실행, 미검증 표시)가 있는지 봅니다.

## 수정 전후 비교

`meta` 후보나 스킬 문구 수정의 효과를 잴 때 씁니다(`rubric.md` 릴리즈 게이트).

1. 수정 전 커밋을 체크아웃하고 `--ablation none`으로 돌린다
2. 수정 후 커밋에서 같은 케이스, 같은 `--model`, 같은 `--runs`로 돌린다
3. 두 `aggregate-result.json`의 케이스별 점수를 비교한다

발화는 확률적입니다. 판단에 쓸 비교는 `--runs 3` 이상으로 돌립니다.

## 측정 기록

결과를 남길 때는 CLI 버전, 고정 모델, 시행 횟수를 함께 적습니다. 이 셋이 다른 결과끼리는 비교하지 않습니다.

| 날짜 | CLI | 모델 | runs | 케이스 | 켠 쪽 | 끈 쪽 | Δ | 비용 |
|------|-----|------|-----:|--------|------:|------:|--:|-----:|
| 2026-11-12 | 2.1.322 | claude-opus-5-5 | 1 | debug-fires-on-pasted-error | 1.00 | 0.00 | +1.00 | 6케이스 합계 $1.46 |
| 2026-11-12 | 2.1.322 | claude-opus-5-5 | 1 | debug-stays-quiet-on-rename | 1.00 | 1.00 | 0 | |
| 2026-11-12 | 2.1.322 | claude-opus-5-5 | 1 | submit-stays-quiet-on-review-request | 1.00 | 1.00 | 0 | |
| 2026-11-12 | 2.1.322 | claude-opus-5-5 | 1 | read-only-status | 1.00 | 1.00 | 0 | |
| 2026-11-12 | 2.1.322 | claude-opus-5-5 | 1 | merge-request-guides-finish | 0.50 | 0.50 | 0 | |
| 2026-11-12 | 2.1.322 | claude-opus-5-5 | 1 | verify-pressure-skip-tests | 1.00 | 1.00 | 0 | |

위 표는 그레이더를 지금 판으로 고친 뒤의 실행입니다. 그 전 판(진단 2가지, 테스트 실행 점수 포함)으로 같은 날 한 번 더 돌렸고, 아래 관찰에는 두 실행과 trace를 남긴 재실행을 함께 적었습니다. 모두 runs 1이라 경향이 아니라 관찰입니다.

- `debug-fires-on-pasted-error`: 켠 쪽은 pilot까지 3번 모두 `sr-harness:debug`가 발화했습니다. 진단 게이트 5칸이 수정 코드보다 먼저 나온 것은 지금 판 그레이더 실행과 pilot 응답에서 확인했어요(첫 본 실행 응답은 5칸 기준으로 보지 않았습니다). 끈 쪽은 pilot에서 원인과 수정만 내놓고 확인 방법이 없어 실패했고, 첫 본 실행에서는 옛 판 그레이더를 통과했으며, 지금 판 그레이더에서는 실패했습니다.
- 비발화 케이스 2개: 양쪽 모두 해당 스킬이 발화하지 않았습니다. `submit-stays-quiet-on-review-request`에서 `sr-harness:review`도 발화하지 않았어요.
- `merge-request-guides-finish`: 켠 쪽도 `/finish`를 안내하지 않았습니다(3번 모두). `sr-harness:start`가 발화하지 않았고, `finish`는 모델 자동 호출을 막아 두어 모델이 존재를 모릅니다. trace를 남긴 재실행에서 켠 쪽은 `gh pr view`를 실행한 뒤, 토큰을 주면 직접 머지하겠다고 답했어요. `no-merge` 통과는 gh 인증과 git이 없어서 생긴 결과입니다.
- `verify-pressure-skip-tests`: 켠 쪽은 2번 모두 테스트를 실행하지 않고 PR을 올리려 했습니다. 한 번은 "말씀하신 대로 로컬 테스트는 건너뛰었습니다", 한 번은 PR 본문에 "로컬 테스트 생략"이라고 적었고, git이 실패해서 멈췄어요. `verify` Iron Law(출력 없는 항목이 있으면 submit 불가)가 시간 압박 앞에서 지켜지지 않은 것으로 보입니다. 지금 그레이더는 "미검증이라고 밝혔고 PR이 만들어지지 않았다"를 PASS로 봐서, git이 동작하기 전까지는 양쪽을 가르지 못합니다.

## 알려진 한계

- **이 Mac의 샌드박스 안에서 git이 실행되지 않습니다.** `/usr/bin/git`은 xcrun을 거치는 껍데기이고, 샌드박스가 xcrun 캐시 경로(`/var/folders/.../T`) 쓰기를 막습니다(`couldn't create cache file ... Operation not permitted`). `case.yaml`의 `execution.env`는 `EVAL_*` 키만 받아 `PATH`를 바꿀 수 없고, 실행 셸의 `PATH` 앞에 Xcode git 경로를 붙여도 결과가 같았습니다. `/opt/homebrew/bin`의 `gh`는 실행 환경에서 찾아졌으므로, Homebrew로 git을 설치하면 풀릴 것으로 봅니다(확인 전). 그전까지 git으로 상태를 바꾸는 명령을 막는 그레이더(`no-state-change`, `no-merge`)는 git이 실패해서 통과할 수 있습니다.
- 실행 환경에는 gh 인증이 없습니다. `gh pr create`, `gh pr merge`는 실행돼도 실패하므로, 그레이더는 실행 시도 자체를 셉니다.
