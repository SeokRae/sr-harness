#!/usr/bin/env bash
# Codex 설치용 사본(plugins/sr-harness/)을 루트 skills/와 .codex-plugin/plugin.json으로 다시 만든다 (#119)
#
# Codex는 .agents/plugins/marketplace.json이 가리키는 이 사본에서 sr-harness를 설치한다.
# 사본은 손으로 고치지 않는다. 루트를 고친 뒤 이 스크립트를 실행한다.
# 사본이 어긋나면 scripts/validate-structure.py(CI)가 실패한다.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
wrapper="$root/plugins/sr-harness"

mkdir -p "$wrapper/skills" "$wrapper/.codex-plugin"
rsync -a --delete --exclude '.DS_Store' "$root/skills/" "$wrapper/skills/"
cp "$root/.codex-plugin/plugin.json" "$wrapper/.codex-plugin/plugin.json"

echo "synced: plugins/sr-harness/skills/, plugins/sr-harness/.codex-plugin/plugin.json"
