# Task List: spec-x-check-secrets-docs-context

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 (spec-x 는 phase.md 없음 — 적용 불가; queue.md 의 specx 마커는 sdd 자동 관리)
- [x] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

### 1-1. feature 브랜치 생성
- [x] `git checkout -b spec-x-check-secrets-docs-context`
- [x] 현재 브랜치 확인 (`git branch --show-current` → `spec-x-check-secrets-docs-context`)
- [x] Commit: 없음 (브랜치 생성만)

---

## Task 2: TDD Red — Test 14·15·16 추가 후 실패 확인

### 2-1. 테스트 케이스 작성
- [x] `tests/test-check-secrets-dual-mode.sh` 의 Test 13 블록 다음, "결과" 섹션 앞에 Test 14·15·16 추가
  - Test 14: `.md` 본문에 시크릿 할당 패턴 리터럴 staged → exit 0 (통과)
  - Test 15: `.py` 본문에 동일 패턴 staged → exit ≠ 0 (차단)
  - Test 16: `.md` 본문에 AWS 키 (`AKIA...`) staged → exit ≠ 0 (차단, regression 가드)
  - self-trigger 회피: 패턴 문자열을 변수 분리해서 작성 (Test 2 의 `_AKIA_PFX` 동일 기법)
- [x] 테스트 실행: `bash tests/test-check-secrets-dual-mode.sh`
- [x] 결과 확인:
  - Test 14: FAIL (현재 hook 이 `.md` 도 차단 → Red 확인)
  - Test 15·16: PASS (현재 hook 이 정상 동작)
  - 총합: `PASS: 15  FAIL: 1`
- [x] Commit: `test(spec-x-check-secrets-docs-context): add tests for .md docs context false positive`

---

## Task 3: TDD Green — check-secrets.sh 의 staged_diff_no_md 도입

### 3-1. hook 패치
- [x] `sources/hooks/check-secrets.sh` 의 line 42 `staged_diff=...` 다음 줄에 `staged_diff_no_md=...` (pathspec `:(exclude)*.md`) 추가
- [x] 시크릿 할당 패턴 검사 (현 line 58 의 `if echo "$staged_diff" | ...`) 한 곳만 `$staged_diff_no_md` 로 변경
- [x] AWS 키 / Private Key / GitHub 토큰 검사는 그대로 (모두 `$staged_diff`)
- [x] 테스트 실행: `bash tests/test-check-secrets-dual-mode.sh`
- [x] 결과 확인: `PASS: 16  FAIL: 0`
- [x] 회귀 가드 확인: Test 2/4/8/9/11/12/13/15/16 모두 PASS
- [x] Commit: `fix(spec-x-check-secrets-docs-context): exclude .md from secret-assignment pattern check`

---

## Task 4: Ship (walkthrough + pr_description + push + PR)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다. Hook 의 `.md` 제외가 Task 3 commit + 본 task 의 dogfood-sync 이후 적용되므로 산출물 본문은 시크릿 패턴 리터럴 사용 자유.

### 4-0. Dogfood-sync (Hard Stop 후 추가됨)

> 사전 검토에선 sources/ 패치만 작성했으나, `.harness-kit/` 가 PR #3 + 본 spec sources/ 패치와 비동기 (dogfood-sync drift) 라 Ship commit 차단됨. ADR-003 의 update.sh SSOT 정책으로 해소.

- [x] main checkout 후 `bash update.sh --yes` → `.harness-kit/hooks/check-secrets.sh` 에 PR #3 `.env.*.example` filter 반영
- [x] main 에 chore commit + push: `chore: dogfood sync after PR #3 (.env.*.example filter)` → `3ee4b1e`
- [x] spec branch checkout → `git rebase main` (linear history 유지, hash 변경: de71624→8a74595, 2b5b8cc→efc7b09)
- [x] spec branch 에서 다시 `bash update.sh --yes` → `.harness-kit/hooks/check-secrets.sh` 에 본 spec `.md` exclude 반영
- [x] Commit: `chore(spec-x-check-secrets-docs-context): apply dogfood sync for .md exclude` → `a86f086`

### 4-1. 산출물 작성
- [x] `tests/test-check-secrets-dual-mode.sh` 전체 PASS 재확인 (증거 로그용)
- [x] **walkthrough.md 작성** (분기 분석 결정 기록, Test 14·15·16 신규, 16/16 결과 로그, Task 3 commit 이후 docs 본문 자유 회복 확인)
- [x] **pr_description.md 작성** (변경 요약, 회귀 가드 목록, 테스트 결과)

### 4-2. Ship Commit
- [x] Commit: `docs(spec-x-check-secrets-docs-context): ship walkthrough and pr description`

### 4-3. Push & PR
- [x] task.md 의 모든 `[ ]` 가 `[x]` 또는 `[-]` 인지 확인
- [ ] **Push**: `git push -u origin spec-x-check-secrets-docs-context`
- [ ] **PR 생성**: `gh pr create --repo LeoYoon7/harness-kit --base main`
- [ ] **사용자 알림**: PR URL 보고 후 머지 대기

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 4 (Pre-flight 제외) + Task 4-0 dogfood-sync deviation |
| **예상 commit 수** | spec branch 4 (test + fix + chore-sync + docs/ship) + main 1 (PR #3 sync chore) |
| **현재 단계** | Ship |
| **마지막 업데이트** | 2026-05-28 |
