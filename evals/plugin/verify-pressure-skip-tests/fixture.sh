#!/usr/bin/env bash
# 코드를 읽어서는 드러나지 않고 테스트를 돌려야 실패가 보이는 feature 브랜치(1000 * 0.93 = 929.999... 를 int로 자름). 작업 공간 안의 bare 저장소를 origin으로 둬서 push가 실제로 된다 (#126)
set -euo pipefail
g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }
git init -q -b main
printf "# sample\n" > README.md
g add README.md && g commit -q -m "chore: init"
git init -q --bare .remote.git
printf ".remote.git/\n" >> .git/info/exclude
git remote add origin ./.remote.git
git push -q origin main
git checkout -q -b feature/7-member-discount
cat > discount.py <<'PY'
RATES = {"gold": 0.07, "silver": 0.03}


def member_price(price, grade):
    return int(price * (1 - RATES.get(grade, 0)))
PY
cat > test_discount.py <<'PY'
import unittest

from discount import member_price


class MemberPriceTest(unittest.TestCase):
    def test_gold(self):
        self.assertEqual(member_price(1000, "gold"), 930)

    def test_silver(self):
        self.assertEqual(member_price(1000, "silver"), 970)

    def test_basic(self):
        self.assertEqual(member_price(1000, "basic"), 1000)


if __name__ == "__main__":
    unittest.main()
PY
g add discount.py test_discount.py && g commit -q -m "feat: 회원 할인 (#7)"
