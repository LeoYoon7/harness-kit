# Task List: spec-x-check-secrets-env-example

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 (spec-x 는 phase.md 없음 — 적용 불가; queue.md 의 Active 마커는 sdd 자동 관리)
- [x] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

### 1-1. feature 브랜치 생성
- [x] `git checkout -b spec-x-check-secrets-env-example`
- [x] 현재 브랜치 확인 (`git branch --show-current` → `spec-x-check-secrets-env-example`)
- [x] Commit: 없음 (브랜치 생성만)

---

## Task 2: TDD Red — Test 12·13 추가 후 실패 확인

### 2-1. 테스트 케이스 작성
- [x] `tests/test-check-secrets-dual-mode.sh` 의 Test 11 블록 다음, "결과" 섹션 앞에 Test 12·13 추가
  - Test 12: `.env.telegram.example` staged → exit 0 (통과)
  - Test 13: `.env.discord.sample` staged → exit 0 (통과)
  - 셋업 패턴은 Test 9 (`.env` staged) 와 동일하게 `_run_secrets "$REPO" "HARNESS_GIT_HOOK_MODE=1"` 사용
- [x] 테스트 실행: `bash tests/test-check-secrets-dual-mode.sh`
- [x] 결과 확인: `PASS: 11  FAIL: 2` (Test 12·13 만 fail — Red 확인)
- [x] Commit: `test(spec-x-check-secrets-env-example): add failing tests for .env.*.example/.sample false positive`

---

## Task 3: TDD Green — check-secrets.sh regex 패치 후 전체 PASS

### 3-1. hook 패치
- [ ] `sources/hooks/check-secrets.sh` line 36 파이프라인 끝에 `grep -vE '\.(example|sample)$'` 추가
  - 다중 라인 (백슬래시 continuation) 으로 가독성 유지
- [ ] 테스트 실행: `bash tests/test-check-secrets-dual-mode.sh`
- [ ] 결과 확인: `PASS: 13  FAIL: 0`
- [ ] 회귀 가드 확인: Test 2/4/8/9/11 모두 PASS (출력 라인 확인)
- [ ] Commit: `fix(spec-x-check-secrets-env-example): exclude .env.*.example/.sample from staged check`

---

## Task 4: Ship (walkthrough + pr_description + push + PR)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

### 4-1. 산출물 작성
- [ ] `tests/test-check-secrets-dual-mode.sh` 전체 PASS 재확인 (증거 로그용)
- [ ] **walkthrough.md 작성** (Test 9 회귀 가드, Test 12·13 신규, 13/13 결과 로그 포함)
- [ ] **pr_description.md 작성** (변경 요약, before/after diff, 테스트 결과)

### 4-2. Ship Commit
- [ ] Commit: `docs(spec-x-check-secrets-env-example): ship walkthrough and pr description`

### 4-3. Push & PR
- [ ] task.md 의 모든 `[ ]` 가 `[x]` 또는 `[-]` 인지 확인
- [ ] **Push**: `git push -u origin spec-x-check-secrets-env-example`
- [ ] **PR 생성**: `/hk-pr-gh` 또는 `gh pr create` (base: fork main — `LeoYoon7/harness-kit:main`)
- [ ] **사용자 알림**: PR URL 보고 후 머지 대기

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 4 (Pre-flight 제외) |
| **예상 commit 수** | 3 (test + fix + docs/ship) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-05-28 |
