#!/usr/bin/env bash
# 테스트는 모두 통과하지만 Issue 성공 기준 중 silver 할인이 구현되지 않은 feature 브랜치
set -euo pipefail
g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }
git init -q -b main
printf "# sample\n" > README.md
g add README.md && g commit -q -m "chore: init"
git update-ref refs/remotes/origin/main main
git checkout -q -b feature/11-member-tier
cat > discount.py <<'PY'
def member_price(price, grade):
    if grade == "gold":
        return price * 90 // 100
    return price
PY
cat > test_discount.py <<'PY'
import unittest

from discount import member_price


class MemberPriceTest(unittest.TestCase):
    def test_gold(self):
        self.assertEqual(member_price(10000, "gold"), 9000)

    def test_guest(self):
        self.assertEqual(member_price(10000, "guest"), 10000)


if __name__ == "__main__":
    unittest.main()
PY
g add discount.py test_discount.py && g commit -q -m "feat: 회원 등급 할인 (#11)"
