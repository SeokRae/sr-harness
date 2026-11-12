---
name: release
description: GitHub Release 생성 스킬. "릴리즈 만들어줘", "release 올려줘", "배포해줘", "태그 만들어줘", "v1.x.x 릴리즈", "릴리즈 노트 작성", "배포 태그" 시 사용. 버전 결정 → 태그 → 릴리즈 노트 → GitHub Release 생성까지 자동 처리. 태그 push와 Release는 외부로 나가므로 모델 자동 호출을 막았다. /release 로만 진입한다.
disable-model-invocation: true
---

# release

main 브랜치를 기준으로 GitHub Release를 생성한다.

## 실행 순서

### 1. 현재 상태 파악

```bash
# 현재 버전 확인 (우선순위: build.gradle → package.json → pom.xml)
grep "^version" build.gradle 2>/dev/null \
  || node -p "require('./package.json').version" 2>/dev/null \
  || grep -m1 "<version>" pom.xml 2>/dev/null

# 기존 릴리즈/태그 확인
gh release list --limit 5
git tag --sort=-creatordate | head -5

# main이 최신인지 확인
git log --oneline -5
```

### 2. 버전 결정

기존 릴리즈가 없으면 → `v1.0.0`으로 시작.

기존 릴리즈가 있으면 semver 기준 사용자에게 버전 제안:

| 변경 내용 | 예시 | 범프 |
|-----------|------|------|
| 하위 호환 불가 변경 | API 스펙 변경, DB 스키마 변경 | major (v1.x.x → v2.0.0) |
| 새 기능 추가 (하위 호환) | 새 엔드포인트, 새 전략 클래스 추가 | minor (v1.0.x → v1.1.0) |
| 버그 수정, 리팩토링 | 오류 수정, 성능 개선 | patch (v1.0.0 → v1.0.1) |

버전이 불명확하면 머지된 PR 목록과 함께 사용자에게 확인.

### 3. 릴리즈 노트 방식 선택

**자동 생성** (기본값 — 직전 태그 이후 머지된 PR을 GitHub이 자동 수집):
```bash
gh release create {tag} \
  --title "{tag}" \
  --generate-notes \
  --target main \
  --latest
```

**수동 작성** (사용자가 내용을 지정하거나 첫 릴리즈일 때):
```bash
gh release create {tag} \
  --title "{tag}" \
  --notes "{릴리즈 노트}" \
  --target main \
  --latest
```

수동 릴리즈 노트 형식:
```markdown
## What's Changed

### Bug Fixes
- fix: {설명} (#{PR번호})

### Features
- feat: {설명} (#{PR번호})

### Refactoring
- refactor: {설명} (#{PR번호})

**Full Changelog**: https://github.com/{owner}/{repo}/commits/{tag}
```

### 4. 완료 보고

```
✅ GitHub Release {tag} 생성 완료
   {release URL}
```

## 주의사항

- **반드시 main 브랜치에서 실행** — feature 브랜치에서 실행하지 않는다
- `--generate-notes`는 직전 태그가 있어야 정확히 동작한다. 첫 릴리즈는 수동 작성 권장
- SNAPSHOT 버전이라도 릴리즈는 정식 버전(v1.0.0)으로 생성한다
- 태그는 GitHub Release 생성 시 자동으로 만들어지므로 `git tag`를 따로 실행할 필요 없다

## 다음 릴리즈 빠른 참고

```bash
# 직전 태그 이후 머지된 PR 목록 확인
gh pr list --state merged --limit 20

# 자동 노트로 다음 릴리즈 (가장 일반적인 케이스)
gh release create v{next} --generate-notes --target main --latest
```
