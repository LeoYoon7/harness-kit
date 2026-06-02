# Task List: spec-x-skip-perms-launcher

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit). TDD task 는 Red/Green 두 commit.
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성 (`sdd specx new skip-perms-launcher`)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 phase.md/queue.md 갱신 불필요 (constitution §5.1). `sdd specx new` 가 queue specx 섹션 관리.
- [x] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-skip-perms-launcher` (브랜치 이름 = spec 디렉토리 이름)
- [x] Commit: 없음 (브랜치 생성만)

---

## Task 2: 런처 원본 작성

> 정적 자산 (한 줄 exec 래퍼) — 동작 검증은 Task 3 install 시나리오 B 에서 수행.

### 2-1. 런처 파일 생성
- [x] `sources/optional/claude-dangerously-skip-permissions.sh` 작성 (한국어 헤더 + `set -euo pipefail` + `exec claude --dangerously-skip-permissions "$@"`)
- [x] `chmod +x` (git 실행권한 비트 — `git update-index --chmod=+x`, mode 100755 확인)
- [x] Commit: `feat(spec-x-skip-perms-launcher): add opt-in dangerously-skip-permissions launcher source`

---

## Task 3: install.sh — 플래그 + 조건부 복사 + config + .gitignore

### 3-1. 테스트 작성 (TDD Red)
- [x] `tests/test-skip-launcher.sh` 생성 — 시나리오 A(플래그 없음→미설치+config false) / B(플래그→설치+gitignore+config true+내용) / C(재설치 멱등)
- [x] `bash tests/test-skip-launcher.sh` → 5 FAIL 확인 (B/C)
- [x] Commit: `test(spec-x-skip-perms-launcher): add failing install tests for --with-skip-launcher`

### 3-2. 구현 (TDD Green)
- [x] `install.sh`: 기본값 `HK_SKIP_LAUNCHER=0` + arg case `--with-skip-launcher` + usage 주석 추가
- [x] `install.sh`: §12c 조건부 복사(`sources/optional/*.sh` → 루트 + chmod) + §16 `.gitignore` 등재 + §17 config `skipLauncher` + §4 설치 계획 출력
- [x] `bash tests/test-skip-launcher.sh` (A/B/C) → 8/8 PASS. gitignore-config/idempotent/install-layout 회귀 없음
- [x] Commit: `feat(spec-x-skip-perms-launcher): install launcher only with --with-skip-launcher flag`

---

## Task 4: update.sh — skipLauncher 선택 보존

### 4-1. 테스트 작성 (TDD Red)
- [x] `tests/test-skip-launcher.sh` 에 시나리오 D(B 설치본 update → 런처·config·gitignore 보존) 추가
- [x] 실행 → D-2(config) Fail 확인 (Red)
- [x] Commit: `test(spec-x-skip-perms-launcher): add failing update preservation test`

### 4-2. 구현 (TDD Green)
- [x] `update.sh`: config `skipLauncher` 읽어 `HK_SKIP_LAUNCHER_ARG` 구성 + install.sh 재호출(L141)에 전달
- [x] 실행 → D 11/11 Pass 확인. update-stateful S4(Icebox) FAIL 은 main 동일 사전존재 (무관)
- [x] Commit: `fix(spec-x-skip-perms-launcher): preserve skipLauncher choice across update`

---

## Task 5: uninstall.sh — 런처 파일 + .gitignore 라인 대칭 제거

### 5-1. 테스트 작성 (TDD Red)
- [x] 시나리오 E(fresh fixture install+uninstall → 런처 파일·gitignore 라인 제거) 추가
- [x] 실행 → E-1/E-2 Fail 확인 (Red)
- [x] Commit: `test(spec-x-skip-perms-launcher): add failing uninstall symmetry test`

### 5-2. 구현 (TDD Green)
- [x] `uninstall.sh`: 백업 목록(L61) + 제거 목록(L86) + `.gitignore` awk(L159~) 에 런처 패턴 추가 (ADR-005 대칭)
- [x] 실행 → E 13/13 Pass 확인. (count 관용구 `|| echo 0`→`|| true` 버그 동시 수정)
- [x] Commit: `fix(spec-x-skip-perms-launcher): remove launcher and gitignore line on uninstall`

---

## Task 6: sdd doctor — .dockerignore 경고

### 6-1. 테스트 작성 (TDD Red)
- [x] 시나리오 F(런처 설치 + Dockerfile 존재 + `.dockerignore` 미등재→WARN / 등재→PASS) 추가
- [x] 실행 → F-1/F-2 Fail 확인 (Red)
- [x] Commit: `test(spec-x-skip-perms-launcher): add failing doctor dockerignore-launcher test`

### 6-2. 구현 (TDD Green)
- [x] `sources/bin/sdd`: dockerignore 점검(L2238~) 인접에 (c) 런처 경고 추가 (기존 `.harness-kit` 관대 패턴 스타일)
- [x] 실행 → F 15/15 Pass 확인. doctor-ignore-coverage 9/9 회귀 없음
- [x] Commit: `feat(spec-x-skip-perms-launcher): warn when installed launcher missing from .dockerignore`

---

## Task 7: 문서 — README + CHANGELOG

### 7-1. 문서 갱신
- [x] `README.md`: `--with-skip-launcher` 설명 + 보안 주의 + 컨테이너 빌드 가이드에 런처 항목 + 커맨드 표
- [-] `CHANGELOG.md`: Pass — release-strategy.md 상 CHANGELOG 항목은 release 롤업(`git log tag..main`) 시점에 PR `(#N)` 에서 기록. `## [Unreleased]` draft 는 *Phase ship* 규칙이라 spec-x 비해당. (#18/#19/#20 → release #21 동일 패턴). 본 PR 머지 후 다음 release 에서 자동 반영.
- [x] Commit: `docs(spec-x-skip-perms-launcher): document --with-skip-launcher option`

---

## Task 8: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [x] 전체 회귀 테스트 실행 → 신규/핵심 5종 ALL PASS. update-stateful S4 / uninstall-cmd-list hk-* 잔재는 main 동일 사전존재 (무관, Icebox 기등재)
- [x] **walkthrough.md 작성** (증거 로그)
- [x] **pr_description.md 작성** (템플릿 준수)
- [x] 이월 항목 Icebox 등재 (telegram/discord dockerignore 갭)
- [x] **Ship Commit**: `docs(spec-x-skip-perms-launcher): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-skip-perms-launcher`
- [ ] **PR 생성**: `/hk-pr-gh` (base = fork main)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 8 (Task 1 브랜치 + 2~7 작업 + 8 Ship) |
| **예상 commit 수** | 12 (planning:1, Task2:1, Task3:2, Task4:2, Task5:2, Task6:2, Task7:1, Ship:1) |
| **현재 단계** | Ship (push/PR 대기) |
| **마지막 업데이트** | 2026-06-02 |
