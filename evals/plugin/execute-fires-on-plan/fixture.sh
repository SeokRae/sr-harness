#!/usr/bin/env bash
# execute-records-decision과 같은 fixture. 첫 행동에서 execute가 발화하는지만 본다 (#137)
set -euo pipefail
g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }
git init -q -b main
printf "# sample\n" > README.md
g add README.md && g commit -q -m "chore: init"
printf ".claude/\n__pycache__/\n" >> .git/info/exclude
git checkout -q -b feature/21-coupon
cat > test_coupon.py <<'PY'
import unittest

from coupon import apply_coupon


class ApplyCouponTest(unittest.TestCase):
    def test_ten_percent(self):
        self.assertEqual(apply_coupon(10000, 10), 9000)

    def test_zero_percent(self):
        self.assertEqual(apply_coupon(10000, 0), 10000)

    def test_result_is_int(self):
        self.assertIsInstance(apply_coupon(999, 15), int)


if __name__ == "__main__":
    unittest.main()
PY
g add test_coupon.py && g commit -q -m "test: 쿠폰 할인 테스트 (#21)"
printf "다른 세션 메모: 정산 배치 확인할 것\n" > notes-other-session.md
mkdir -p .claude
cat > .claude/session-plan.md <<'MD'
---
session: 2026-11-14
goal: 쿠폰 할인 함수 구현
branch: feature/21-coupon
issue: 21
test-command: python3 -m unittest -q
---

## Tasks

- [ ] coupon.py에 apply_coupon(price, percent) 구현. 결과는 원 단위 정수
- [ ] test_coupon.py 통과

원 단위 처리 방식(반올림, 내림, 올림)은 정하지 않았다. 구현하면서 정해도 된다.

## Decisions

<!-- 구현 중 후보가 둘 이상인 선택을 하면 한 줄씩 남긴다. submit이 PR 본문 "결정" 절로 옮긴다.
- D-{번호} {무엇을 정했나}: {고른 것} | 이유: {한 줄} | 제안: 사람|AI, 결정: 사람|AI
결정: 사람은 사용자가 대화에서 직접 고른 경우만. 뒤집으면 옛 줄 끝에 → D-{새 번호}로 바뀜 -->

## Deviations
MD
