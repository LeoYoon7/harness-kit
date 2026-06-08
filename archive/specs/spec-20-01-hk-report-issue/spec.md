# spec-20-01: `/hk-report-issue` 커맨드 포팅

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-20-01` |
| **Phase** | `phase-20` (upstream-parity) |
| **Branch** | `spec-20-01-hk-report-issue` |
| **상태** | Planning |
| **타입** | Feature (port) |
| **Integration Test Required** | no (phase-20 시나리오 1 이 phase 레벨에서 커버) |
| **작성일** | 2026-06-04 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

upstream(Changsik00/harness-kit)은 `98912f0` 에서 **`/hk-report-issue`** 커맨드를 추가했다 — 다운스트림 사용자가 발견한 **harness-kit 자체 버그**(hook 오작동, `sdd` 오류, 설치 마찰)를 키트 GitHub repo 에 이슈로 환류하는 경로. fork 는 이 커맨드를 보유하지 않는다.

### 문제점

fork 사용자(및 도그푸딩 중인 본 repo)가 키트 결함을 발견해도 **메인테이너에게 구조화된 경로로 보고할 방법이 없다.** 실제로 이번 세션에서 발견한 **hook no-op 결함**(명령 검사 hook 전체 무력화)이 바로 이 커맨드의 대상인데, 환류 경로가 없어 수동 처리해야 했다.

### 해결 방안 (요약)

upstream 의 `hk-report-issue.md` 커맨드를 fork 로 **복사 포팅**한다. 이 커맨드는 `kitOrigin`·`gh`·`sdd doctor`·constitution §5.7 등 fork 가 이미 보유한 자산만 참조하므로 **분기 거버넌스에 비의존** — 거의 그대로 동작한다.

## 🎯 요구사항

### Functional Requirements

1. `sources/commands/hk-report-issue.md` + `.claude/commands/hk-report-issue.md`(설치본) 을 upstream 과 동일하게 설치 (sources ↔ installed 동기화).
2. 커맨드가 fork 의 `kitOrigin`(LeoYoon7/harness-kit)에서 repo slug 을 도출하도록 동작 (커맨드 로직이 이미 이를 수행 — 무수정).
3. `README.md` 커맨드 목록에 `/hk-report-issue` 추가.
4. 도그푸딩 `installed.json` 의 `installedCommands` 에 `"hk-report-issue"` 추가.
5. 구조 검증 단위 테스트 추가 (커맨드 파일 존재 + 핵심 섹션 + 등록 확인).

### Non-Functional Requirements

1. **macOS 1차 타깃** — upstream 커맨드는 macOS 에서 argv raw 바이트라 그대로 동작. 충실 포팅.
2. 커맨드 본문은 **upstream 원본 충실 복사** (자의적 변형 금지 — 향후 upstream sync 용이).
3. sources ↔ installed byte-identical.

## 🚫 Out of Scope

- **git-bash 한글 argv 적응** — 커맨드의 `gh issue create --body "$BODY"` 가 Windows git-bash 에서 한글 body 손상([[gitbash-nonascii-argv-codepage]]). 단 이는 **fork 전 커맨드(hk-pr-gh 등) 공통의 기존 quirk** 이고 키트 1차 타깃은 macOS 라 본 spec 범위 밖 (필요 시 별도 phase-wide 처리).
- **실제 이슈 게시** — 런타임 행위. 본 spec 은 커맨드 설치까지.
- **hook no-op 결함 자체의 리포팅/수정** — 본 커맨드로 *할 수 있게* 되는 것이지, 리포팅 실행은 별개.

## 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — 단순 포팅, 신규 아키텍처 결정 없음

## ✅ Definition of Done

- [ ] 구조 검증 단위 테스트 PASS (`tests/test-report-issue-cmd.sh`)
- [ ] sources ↔ installed 커맨드 파일 byte-identical
- [ ] `README.md` + `installed.json` 등록 반영
- [ ] `walkthrough.md` / `pr_description.md` 작성 및 ship commit
- [ ] `spec-20-01-hk-report-issue` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
