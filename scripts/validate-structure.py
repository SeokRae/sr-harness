#!/usr/bin/env python3
"""sr-harness 저장소 구조 검사 (#119)

실패한 항목을 모두 출력하고, 하나라도 있으면 exit 1로 끝난다. 표준 라이브러리만 쓴다.

1. 버전 5곳 일치 (Claude 매니페스트 3곳, 루트와 사본의 Codex 매니페스트)
2. Codex 설치용 사본 plugins/sr-harness/가 루트 skills/, .codex-plugin/plugin.json과 같은지
3. skills/ 폴더 목록과 .claude-plugin/plugin.json의 skills 배열 일치
4. README.md, README.ko.md 스킬 표에 모든 스킬이 있는지
5. SKILL.md 안의 상대 경로 링크가 가리키는 파일이 있는지
6. disable-model-invocation: true 스킬과 CLAUDE.md "현재 대상" 목록 일치

사용: python3 scripts/validate-structure.py
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WRAPPER = ROOT / "plugins" / "sr-harness"
IGNORED_NAMES = {".DS_Store"}
SYNC_HINT = "scripts/sync-codex-wrapper.sh를 실행해 사본을 다시 만드세요"

errors = []


def load_json(rel):
    return json.loads((ROOT / rel).read_text(encoding="utf-8"))


def skill_names():
    return sorted(p.name for p in (ROOT / "skills").iterdir() if p.is_dir())


def files_under(base):
    return {
        p.relative_to(base).as_posix(): p
        for p in base.rglob("*")
        if p.is_file() and p.name not in IGNORED_NAMES
    }


def frontmatter(text):
    match = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    return match.group(1) if match else ""


def check_versions():
    claude = load_json(".claude-plugin/plugin.json")
    market = load_json(".claude-plugin/marketplace.json")
    plugins = market.get("plugins") or [{}]
    versions = {
        ".claude-plugin/plugin.json": claude.get("version"),
        ".claude-plugin/marketplace.json metadata.version": market.get("metadata", {}).get("version"),
        ".claude-plugin/marketplace.json plugins[0].version": plugins[0].get("version"),
        ".codex-plugin/plugin.json": load_json(".codex-plugin/plugin.json").get("version"),
        "plugins/sr-harness/.codex-plugin/plugin.json": load_json(
            "plugins/sr-harness/.codex-plugin/plugin.json"
        ).get("version"),
    }
    if len(set(versions.values())) != 1:
        lines = "\n".join(f"    {v}  {k}" for k, v in versions.items())
        errors.append(f"버전 5곳이 다릅니다:\n{lines}")


def check_wrapper():
    src = files_under(ROOT / "skills")
    dst = files_under(WRAPPER / "skills")
    missing = sorted(src.keys() - dst.keys())
    extra = sorted(dst.keys() - src.keys())
    differ = sorted(k for k in src.keys() & dst.keys() if src[k].read_bytes() != dst[k].read_bytes())
    manifest_differs = (ROOT / ".codex-plugin/plugin.json").read_bytes() != (
        WRAPPER / ".codex-plugin/plugin.json"
    ).read_bytes()

    problems = []
    problems += [f"    사본에 없음: skills/{k}" for k in missing]
    problems += [f"    사본에만 있음: skills/{k}" for k in extra]
    problems += [f"    내용 다름: skills/{k}" for k in differ]
    if manifest_differs:
        problems.append("    내용 다름: .codex-plugin/plugin.json")
    if problems:
        errors.append("Codex 설치용 사본 plugins/sr-harness/가 루트와 다릅니다:\n" + "\n".join(problems) + f"\n    → {SYNC_HINT}")


def check_manifest_skills(names):
    listed = set(load_json(".claude-plugin/plugin.json").get("skills", []))
    expected = {f"./skills/{n}" for n in names}
    for s in sorted(expected - listed):
        errors.append(f".claude-plugin/plugin.json skills 배열에 없음: {s}")
    for s in sorted(listed - expected):
        errors.append(f".claude-plugin/plugin.json skills 배열에만 있음(폴더 없음): {s}")
    for n in names:
        if not (ROOT / "skills" / n / "SKILL.md").is_file():
            errors.append(f"SKILL.md 없음: skills/{n}/")


def check_readme_tables(names):
    row = re.compile(r"^\|\s*`([a-z0-9-]+)`", re.M)
    for readme in ("README.md", "README.ko.md"):
        rows = set(row.findall((ROOT / readme).read_text(encoding="utf-8")))
        for n in names:
            if n not in rows:
                errors.append(f"{readme} 스킬 표에 없음: {n}")


def check_skill_links():
    link = re.compile(r"\]\(([^)\s]+)\)")
    for skill_md in sorted((ROOT / "skills").glob("*/SKILL.md")):
        for target in link.findall(skill_md.read_text(encoding="utf-8")):
            if target.startswith("#") or re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", target):
                continue
            path = target.split("#", 1)[0]
            if not (skill_md.parent / path).exists():
                errors.append(f"링크 대상 없음: {skill_md.relative_to(ROOT)} → {target}")


def check_disable_model_invocation(names):
    flag = re.compile(r"^disable-model-invocation:\s*true\s*$", re.M)
    flagged = {
        n
        for n in names
        if flag.search(frontmatter((ROOT / "skills" / n / "SKILL.md").read_text(encoding="utf-8")))
    }
    line = next(
        (l for l in (ROOT / "CLAUDE.md").read_text(encoding="utf-8").splitlines() if l.startswith("현재 대상:")),
        None,
    )
    if line is None:
        errors.append('CLAUDE.md에 "현재 대상:" 줄이 없습니다 (disable-model-invocation 목록)')
        return
    declared = set(re.findall(r"`([a-z0-9-]+)`", line))
    for n in sorted(flagged - declared):
        errors.append(f"disable-model-invocation: true인데 CLAUDE.md 현재 대상에 없음: {n}")
    for n in sorted(declared - flagged):
        errors.append(f"CLAUDE.md 현재 대상에 있는데 frontmatter에 disable-model-invocation: true 없음: {n}")


def main():
    names = skill_names()
    check_versions()
    check_wrapper()
    check_manifest_skills(names)
    check_readme_tables(names)
    check_skill_links()
    check_disable_model_invocation(names)

    if errors:
        print(f"✖ 구조 검사 실패 ({len(errors)}건)")
        for e in errors:
            print(f"  - {e}")
        return 1
    print(f"✔ 구조 검사 통과 (스킬 {len(names)}개, 6개 항목)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
