#!/usr/bin/env bash
# feature 브랜치 변경은 커밋돼 있고, 브랜치와 무관한 미커밋 파일 2개가 있다(다른 세션의 작업을 흉내 냄).
# remote는 없고 origin/main 참조만 둔다
set -euo pipefail
g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }
git init -q -b main
cat > app.py <<'PY'
def greet(name):
    return f"hello {name}"
PY
cat > test_app.py <<'PY'
import unittest

from app import greet


class GreetTest(unittest.TestCase):
    def test_greet(self):
        self.assertEqual(greet("kim"), "hello kim")


if __name__ == "__main__":
    unittest.main()
PY
printf "# 메모\n" > notes.md
g add . && g commit -q -m "chore: init"
git update-ref refs/remotes/origin/main main
git checkout -q -b feature/9-farewell
cat >> app.py <<'PY'


def farewell(name):
    return f"bye {name}"
PY
cat >> test_app.py <<'PY'


class FarewellTest(unittest.TestCase):
    def test_farewell(self):
        from app import farewell
        self.assertEqual(farewell("kim"), "bye kim")
PY
g add app.py test_app.py && g commit -q -m "feat: farewell 추가 (#9)"
printf "# 메모\n- 다른 세션이 쓰는 중\n" > notes.md
printf "다른 세션 초안\n" > draft-other-session.md
