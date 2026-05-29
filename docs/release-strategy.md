# 릴리스 전략 (이 저장소 전용)

> 이 룰은 **harness-kit 본 저장소** 의 릴리스 절차이며, 거버넌스(`sources/governance/`) 에는 포함하지 않습니다. 다른 프로젝트에 install 되어도 강제되지 않습니다.

사용자가 "배포하자" / "릴리스하자" 등으로 새 버전 출시를 지시하면, **alignment phase 없이 spec-x 산출물 없이** 다음 절차를 즉시 수행합니다.

## 절차

1. 브랜치 생성: `release-X.Y.Z` (main 기준)
2. **Commit 1** — `chore: release X.Y.Z` 단일 commit 에 다음 파일을 묶어 변경:
   - `version.json` — `{"version": "X.Y.Z"}` 로 갱신
   - `CHANGELOG.md` — 최상단에 `## [X.Y.Z] — YYYY-MM-DD` 섹션 추가. `Added` / `Fixed` / `Changed` 소제목으로 정리, 각 항목 끝에 `(#PR번호)` 인용
   - `.harness-kit/installed.json` — `kitVersion`, `installedAt` 갱신 (도그푸딩 동기화)
3. push: `git push -u origin release-X.Y.Z`
4. PR 생성:
   - 제목: `chore: release X.Y.Z`
   - 본문: `## X.Y.Z Release` + CHANGELOG 의 해당 섹션 내용 그대로
5. **PR 머지 후 — Post-release Protocol** (사용자가 "머지 했어" 신호 시 즉시 수행):
   - `git checkout main && git pull --ff-only`
   - **Annotated git tag**: `git tag -a vX.Y.Z -m "Release X.Y.Z"` — release commit (squash 결과) 의 main SHA 를 가리킴
   - **Push tag**: `git push origin vX.Y.Z`
   - **GitHub Release 생성**: `gh release create vX.Y.Z --title "vX.Y.Z" --notes-file <CHANGELOG 의 해당 섹션>` — CHANGELOG 의 `## [X.Y.Z]` 본문을 그대로 notes 로. 사용자에게 GitHub Release URL 보고.
   - 본 단계 누락 시 `version.json` 만 갱신되고 *tag / GitHub Release 부재* → `--version X.Y.Z` install 옵션 동작 안 함 + `gh release list` 에 미반영. 0.9.1 의 실패 패턴.

## 룰

- **spec-x 산출물 만들지 않음** — release 는 메타 작업. spec/plan/task/walkthrough/pr_description 미생성.
- **alignment phase 생략** — 사용자가 "배포하자" 하면 분류·옵션 제시 없이 위 절차 즉시 수행.
- **버전 결정**: `MAJOR.MINOR.PATCH` (semver). 사용자가 버전을 지정하지 않으면 변경 성격으로 추정 (`feat`만 있으면 minor, `fix/docs/chore`만 있으면 patch, breaking change 가 있으면 major) 후 한 줄로 알린 뒤 진행.
- **변경 항목 출처**: `git log {직전버전tag}..main --oneline` 으로 PR 머지 commit 을 식별해 CHANGELOG 작성.
- **Phase ship 시 CHANGELOG draft 갱신**: phase 머지 commit 직후, `CHANGELOG.md` 최상단의 `## [Unreleased]` 섹션 (없으면 신설) 에 해당 phase 의 주요 변경 항목 draft entry 를 추가. 다음 release commit 에서 `## [Unreleased]` → `## [X.Y.Z] — YYYY-MM-DD` 로 stamp. 목적: 다중 phase 누적 시 catch-up 부담 분산.
- **본 룰 자체의 변경**: 본 섹션 갱신은 정식 SDD-x 또는 FF 로 처리 (release PR 안에 룰 변경을 끼우지 않음. 단, 본 룰을 *처음 박는 0.9.1* 은 자기-적용 예외).

## Fork 버전 suffix (LeoYoon7/harness-kit 전용)

본 저장소는 Changsik00/harness-kit 의 fork 이며, upstream 과 *별도 운영* 됩니다. upstream 의 차기 release 와 버전 충돌·의미 혼동을 방지하기 위해 본 fork 의 release 는 **`-leo.N` semver pre-release suffix** 를 사용합니다.

### 형식

```
MAJOR.MINOR.PATCH-leo.SEQ
```

- 예: `0.14.0-leo.1`, `0.14.0-leo.2`, `0.15.0-leo.1`
- Git tag: `v0.14.0-leo.1`
- `MAJOR.MINOR.PATCH` 는 upstream semver 와 동일 규칙 (feat → minor, fix → patch, breaking → major)
- `SEQ` 는 같은 `MAJOR.MINOR.PATCH` 기준으로 1 부터 increment. 새 PATCH 이상 진입 시 `SEQ` 1 부터 재시작
- 예시:
  - 첫 fork release: `0.14.0-leo.1`
  - 같은 0.14.0 내 후속 (hotfix 등): `0.14.0-leo.2`
  - 다음 patch: `0.14.1-leo.1`

### 의미 / 표기 주의

- semver 상 `0.14.0-leo.1 < 0.14.0` 으로 평가됨 (pre-release 는 정렬상 *낮음*). 본 fork 의 release 는 *unstable* 이 아니라 **fork-distinct stable** 이라는 점을 GitHub Release notes 본문 첫 줄에 명시:
  ```
  > **Fork-distinct stable release** — LeoYoon7/harness-kit (forked from Changsik00/harness-kit).
  > `-leo.N` suffix 는 upstream 충돌 방지용 식별자이며 unstable 의미 없음.
  ```
- upstream 으로 contribute back 시 suffix 제거된 commit 으로 정리 (rebase 또는 cherry-pick)

### 적용 시점

- 본 룰 도입 이후 모든 fork release 에 적용
- 첫 적용: `0.14.0-leo.1` (2026-05-29)
- 이전 release 들 (`v0.13.5` 이하) 은 upstream 과 동일 시퀀스라 retroactive 변경 없음

## `.harness-kit/installed.json` 동기화 주의

본 프로젝트는 도그푸딩이라 자기 자신을 install 한 상태입니다. release commit 시 `installed.json.kitVersion` 도 새 버전과 일치시켜야 `sdd status` 의 drift 검사가 정상.
