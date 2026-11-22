#!/usr/bin/env bash
# 수수료 계산 버그가 있는 작은 저장소. 원 단위 정수 대신 부동소수를 돌려준다 (#141)
set -euo pipefail
g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }
git init -q -b main
cat > fee.py <<'PY'
RATE = 0.03


def fee(amount):
    return amount * RATE
PY
cat > test_fee.py <<'PY'
import unittest

from fee import fee


class FeeTest(unittest.TestCase):
    def test_zero(self):
        self.assertEqual(fee(0), 0)


if __name__ == "__main__":
    unittest.main()
PY
printf "# fee\n\n테스트: python3 -m unittest -q\n" > README.md
g add . && g commit -q -m "chore: init"
