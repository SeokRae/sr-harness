# sr-harness

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> Claude Code 플러그인 — Karpathy guidelines + Issue-Driven Development 통합 워크플로우 하네스

## 구조

```
.claude-plugin/
  plugin.json       # 스킬 목록, 버전 (설치 시 사용)
  marketplace.json  # 마켓플레이스 메타데이터 + 버전
skills/
  {skill-name}/
    SKILL.md        # 스킬 정의 (frontmatter + 실행 절차)
```

## 스킬 추가 체크리스트

새 스킬을 추가할 때 **반드시** 같은 PR에 포함:

- [ ] `skills/{name}/SKILL.md` 생성
- [ ] `plugin.json` → `skills` 배열에 `"./skills/{name}"` 추가
- [ ] `plugin.json` → `version` MINOR 올리기
- [ ] `marketplace.json` → `metadata.version` + `plugins[0].version` 동일하게 올리기
- [ ] `README.md` / `README.ko.md` 스킬 표에 추가

버전 bump 누락 시 설치본과 소스가 불일치한다 — 버전 bump는 별도 PR 금지.

## 버전 규칙 (semver)

| 변경 | 올릴 자리 |
|------|----------|
| 스킬 추가 / 기능 확장 | MINOR |
| 버그 픽스 / 문서 수정 | PATCH |
| 스킬 제거 / 인터페이스 변경 | MAJOR |

## 릴리즈 절차 (PR 머지 후)

```bash
git checkout main && git pull origin main
git tag -a v{version} -m "v{version}: {한 줄 요약}"
git push origin v{version}
gh release create v{version} --title "v{version}" --generate-notes
```

## 작업 흐름

```
gh issue create → git checkout -b feature/{N}-{desc} → 구현 + 버전 bump
→ git commit -m "... (#N)" → gh pr create (Closes #N) → gh pr merge → 릴리즈 태그
```

커밋 prefix: `feat:` (스킬 추가), `fix:` (버그), `chore:` (설정·버전 bump), `docs:` (문서)

## Git 훅

`.githooks/commit-msg`가 이슈 드리븐 워크플로우를 강제한다 (#85 후속):

- main 직접 커밋 차단 (feature 브랜치 필수)
- 커밋 메시지에 이슈번호 `(#N)` 필수
- prefix(`feat:|fix:|chore:|docs:`) 필수
- `Merge`/`Revert`/`fixup!`/`squash!` 커밋은 예외

클론 후 1회 활성화:

```bash
chmod +x .githooks/commit-msg
git config core.hooksPath .githooks
```
