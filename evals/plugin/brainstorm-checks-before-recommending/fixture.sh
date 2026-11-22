#!/usr/bin/env bash
# 갈림길(설정 형식)이 저장소 조회로 정해지는 작은 CLI 저장소. YAML 의존성과 YAML 기본 설정이 이미 있다 (#140)
set -euo pipefail
g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }
git init -q -b main
printf "PyYAML==6.0.2\nclick==8.1.7\n" > requirements.txt
mkdir -p config
cat > config/defaults.yaml <<'YML'
output: table
color: true
timeout_sec: 30
YML
cat > cli.py <<'PY'
import click
import yaml


def load_defaults(path="config/defaults.yaml"):
    with open(path, encoding="utf-8") as f:
        return yaml.safe_load(f)


@click.command()
def main():
    settings = load_defaults()
    click.echo(settings["output"])


if __name__ == "__main__":
    main()
PY
printf "# sample-cli\n\n기본 설정은 config/defaults.yaml에 있다.\n" > README.md
g add . && g commit -q -m "chore: init"
