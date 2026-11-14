#!/usr/bin/env bash
# 테스트가 통과하는 feature 브랜치와, execute가 남긴 결정 기록 3줄이 있는 session-plan.md. 작업 공간 안의 bare 저장소를 origin으로 둬서 push가 실제로 된다 (#129)
set -euo pipefail
g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }
git init -q -b main
printf "# sample\n" > README.md
g add README.md && g commit -q -m "chore: init"
git init -q --bare .remote.git
printf ".remote.git/\n.claude/\n__pycache__/\n" >> .git/info/exclude
git remote add origin ./.remote.git
git push -q origin main
git checkout -q -b feature/12-member-discount
cat > discount.py <<'PY'
RATES = {"gold": 0.07, "silver": 0.03}


def member_price(price, grade):
    return price * (100 - round(RATES.get(grade, 0) * 100)) // 100
PY
cat > test_discount.py <<'PY'
import unittest

from discount import member_price


class MemberPriceTest(unittest.TestCase):
    def test_gold(self):
        self.assertEqual(member_price(1000, "gold"), 930)

    def test_unknown_grade(self):
        self.assertEqual(member_price(1000, "basic"), 1000)


if __name__ == "__main__":
    unittest.main()
PY
g add discount.py test_discount.py && g commit -q -m "feat: 회원 할인 (#12)"
mkdir -p .claude
cat > .claude/session-plan.md <<'MD'
---
session: 2026-11-14
goal: 회원 등급별 할인 구현
branch: feature/12-member-discount
issue: 12
test-command: python3 -m unittest -q
---

## Tasks

- [x] 등급별 할인율 적용
- [x] 테스트 작성

## Decisions

<!-- 구현 중 후보가 둘 이상인 선택을 하면 한 줄씩 남긴다. submit이 PR 본문 "결정" 절로 옮긴다.
- D-{번호} {무엇을 정했나}: {고른 것} | 이유: {한 줄} | 제안: 사람|AI, 결정: 사람|AI
결정: 사람은 사용자가 대화에서 직접 고른 경우만. 뒤집으면 옛 줄 끝에 → D-{새 번호}로 바뀜 -->

- D-1 등급이 없는 회원: 할인율 0 적용 | 이유: 기존 가격을 유지하는 쪽이 안전 | 제안: AI, 결정: AI
- D-2 원 단위 처리: 정수 연산 후 내림 | 이유: 정산 규칙과 맞춤 | 제안: AI, 결정: 사람
- D-3 할인율 보관 위치: 코드 상수 | 이유: 설정 파일이 아직 없음 | 제안: AI, 결정: AI

## Deviations
MD
