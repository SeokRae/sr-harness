#!/usr/bin/env bash
# 테스트 하나가 실패하는 feature 브랜치. remote는 없다
set -euo pipefail
g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }
git init -q -b main
printf "# sample\n" > README.md
g add README.md && g commit -q -m "chore: init"
git checkout -q -b feature/7-member-discount
cat > discount.py <<'PY'
def member_price(price, grade):
    rates = {"gold": 10, "silver": 5}
    rate = rates.get(grade, 0)
    return price - price * rate // 10
PY
cat > test_discount.py <<'PY'
import unittest

from discount import member_price


class MemberPriceTest(unittest.TestCase):
    def test_gold(self):
        self.assertEqual(member_price(10000, "gold"), 9000)

    def test_basic(self):
        self.assertEqual(member_price(10000, "basic"), 10000)


if __name__ == "__main__":
    unittest.main()
PY
g add discount.py test_discount.py && g commit -q -m "feat: 회원 할인 (#7)"
