# Task List: spec-20-01

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit). TDD 는 test/impl 2 commit.
> 매 commit 직후 본 파일의 체크박스를 갱신.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 업데이트 (phase-20.md SPEC 표 — sdd 자동 갱신 완료)
- [x] 사용자 Plan Accept

---

## Task 1: `/hk-report-issue` 커맨드 포팅 (TDD)

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-20-01-hk-report-issue`
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. 구조 검증 테스트 작성 (TDD Red)
- [x] `tests/test-report-issue-cmd.sh` 작성 — sources/installed 커맨드 존재 + byte-identical + 핵심 섹션 + installedCommands 등록 + README 언급
- [x] 테스트 실행 → **Fail 확인** (5 FAIL, exit 1 — 커맨드 미설치)
- [x] Commit: `test(spec-20-01): add failing structure test for hk-report-issue command`

### 1-3. 커맨드 포팅 + 등록 (TDD Green)
- [ ] `git show upstream/main:sources/commands/hk-report-issue.md` → `sources/commands/hk-report-issue.md`
- [ ] 동일 파일을 `.claude/commands/hk-report-issue.md` 로 복사 (byte-identical)
- [ ] `README.md` 커맨드 목록에 `/hk-report-issue` 추가
- [ ] `.harness-kit/installed.json` installedCommands 에 `"hk-report-issue"` 추가
- [ ] 테스트 실행 → **Pass 확인**
- [ ] Commit: `feat(spec-20-01): port /hk-report-issue command from upstream`

---

## Task 2: Ship (필수)

- [ ] `bash tests/test-report-issue-cmd.sh` → PASS (+ 기존 테스트 무 회귀 확인)
- [ ] sources ↔ installed byte-identical + upstream 사본 diff 0 확인
- [ ] **walkthrough.md 작성**
- [ ] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-20-01): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-20-01-hk-report-issue`
- [ ] **코드 리뷰 게이트** (§6.3 — 포팅+소규모라 판단; skip 시 사유 기록)
- [ ] **PR 생성**: base `phase-20-upstream-parity` (base 브랜치 자동 생성), `/hk-pr-gh` 또는 gh api
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 2 (+ Ship) |
| **예상 commit 수** | 3 (test + impl + ship) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-04 |
