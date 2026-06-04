# Implementation Plan: spec-20-01

## 📋 Branch Strategy

- 신규 브랜치: `spec-20-01-hk-report-issue`
- 시작 지점: `main`
- **base 모드**: PR base = `phase-20-upstream-parity` (첫 hk-ship 시 자동 생성). 첫 task 가 spec 브랜치 생성.

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] **충실 포팅 방침** — upstream `hk-report-issue.md` 를 자의적 변형 없이 복사 (향후 upstream sync 용이). 동의?
> - [ ] **git-bash argv 이슈 비처리** — 키트 1차 타깃 macOS 기준이라 한글 argv 손상(Windows 한정)은 본 spec 범위 밖, 기존 fork 커맨드 공통 quirk 로 둠. 동의?

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **커맨드 본문** | upstream 원본 **복사** (`git show upstream/main:sources/commands/hk-report-issue.md`) | 분기 거버넌스 비의존 + 충실 포팅으로 sync 용이 |
| **sources↔installed** | 동일 파일 양쪽 설치 | dogfood sync (ADR-003) |
| **등록** | README + installed.json installedCommands | 커맨드 목록 일관성 |

### 📑 ADR 후보

- [x] 없음 — 단순 포팅

## 📂 Proposed Changes

#### [NEW] `sources/commands/hk-report-issue.md`
upstream `98912f0` 의 커맨드 본문 그대로 복사. (키트 자체 버그 → kit GitHub 이슈 환류: 판정 게이트 / 진단 컨텍스트 수집 / 중복 검색 / 시크릿 점검 / `[Y/n]` 확인 / graceful degradation)

#### [NEW] `.claude/commands/hk-report-issue.md`
설치본 (sources 와 byte-identical).

#### [MODIFY] `README.md`
커맨드 목록 섹션에 `/hk-report-issue` 한 줄 추가.

#### [MODIFY] `.harness-kit/installed.json`
`installedCommands` 배열에 `"hk-report-issue"` 추가 (도그푸딩 기록 일관성).

#### [NEW] `tests/test-report-issue-cmd.sh`
구조 검증: ① sources/installed 커맨드 파일 존재 + byte-identical, ② 핵심 섹션(판정 게이트·`gh issue create`·시크릿 점검·`[Y/n]`) 포함, ③ installedCommands 등록, ④ README 언급.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
bash tests/test-report-issue-cmd.sh
```

### 수동 검증 시나리오
1. 커맨드 파일을 열어 `kitOrigin` 도출 로직이 fork(LeoYoon7) 에 맞는지 육안 확인 — 기대: 무수정으로 fork repo slug 도출.
2. `git show upstream/main:sources/commands/hk-report-issue.md` 와 fork 사본 diff — 기대: 동일(충실 포팅).

## 🔁 Rollback Plan

- 신규 파일 추가 + 2파일 소폭 수정 → 완전 가역. `git revert` 또는 파일 삭제로 복구. state 영향 없음.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
