#!/usr/bin/env python3
"""스킬 본문(SKILL.md)의 금지, 강제 문구 수를 스킬별로 센다 (#130).

출력만 한다. 실패 조건으로 쓰지 않는다. 측정 기록은 evals/README.md에 남긴다.

  python3 scripts/count-prohibitions.py          # 스킬별 건수, 많은 순
  python3 scripts/count-prohibitions.py --json   # 기계용 출력
"""
import json
import re
import sys
from pathlib import Path

PATTERN = re.compile(r"금지|반드시|절대|MUST|NEVER")
ROOT = Path(__file__).resolve().parent.parent


def count() -> dict[str, int]:
    result = {}
    for skill_md in sorted((ROOT / "skills").glob("*/SKILL.md")):
        text = skill_md.read_text(encoding="utf-8")
        result[skill_md.parent.name] = len(PATTERN.findall(text))
    return result


def main() -> None:
    counts = count()
    total = sum(counts.values())
    if "--json" in sys.argv[1:]:
        print(json.dumps({"total": total, "skills": counts}, ensure_ascii=False))
        return
    print(f"금지 문구 합계: {total} (패턴: {PATTERN.pattern})")
    for name, n in sorted(counts.items(), key=lambda kv: (-kv[1], kv[0])):
        if n:
            print(f"{n:4d}  {name}")


if __name__ == "__main__":
    main()
