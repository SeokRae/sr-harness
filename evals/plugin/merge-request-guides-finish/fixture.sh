#!/usr/bin/env bash
# PR을 낸 뒤의 feature 브랜치. remote는 없다
set -euo pipefail
g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }
git init -q -b main
printf "# sample\n" > README.md
g add README.md && g commit -q -m "chore: init"
git checkout -q -b feature/12-refund-limit
printf "LIMIT = 1000000\n" > refund.py
g add refund.py && g commit -q -m "feat: 환불 한도 (#12)"
