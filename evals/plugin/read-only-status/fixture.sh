#!/usr/bin/env bash
# feature 브랜치에 커밋 1개, 커밋하지 않은 수정 파일 1개가 있는 저장소
set -euo pipefail
g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }
git init -q -b main
printf "# sample\n" > README.md
g add README.md && g commit -q -m "chore: init"
git checkout -q -b feature/5-fee-rate
printf "RATE = 3\n" > fee.py
g add fee.py && g commit -q -m "feat: 수수료율 상수 (#5)"
printf "RATE = 4\n" > fee.py
