# Task List: spec-20-03

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 각 footgun 은 TDD Red(test) → Green(impl) 2 commit. 모든 코드 변경은 sources↔installed **양쪽** 동시 반영.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 업데이트 (phase-20.md SPEC 표 — sdd 자동 갱신됨)
- [x] 사용자 Plan Accept

---

## Task 1: 브랜치 생성 + #2 시크릿 가드 오탐 머지

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-20-03-harness-footguns` (base: `phase-20-upstream-parity`)
- [x] Commit: 없음 (브랜치 생성만) — planning 산출물 `14f117d`

### 1-2. 테스트 작성 (TDD Red)
> 결정(2026-06-04): `_ph_re`(placeholder 필터) 제외 — fork Test 15 무회귀. 보간(`_var_re`/`_op_re`)만 머지.
- [x] `tests/test-check-secrets-dual-mode.sh` 에 Test 17/18/19 추가: 비-`.md` `${VAR:-default}`·파라미터 확장 통과 + 실제 시크릿 차단 + Test 15 보존
- [x] 테스트 실행 → Fail 확인 (Test 17/18 Red)
- [x] Commit: `test(spec-20-03): ...` — `e0456ec`

### 1-3. 구현 (TDD Green)
- [x] `sources/hooks/check-secrets.sh` + `.harness-kit/hooks/check-secrets.sh`: `_var_re`/`_op_re` 필터 추가 (`_ph_re` 제외)
- [x] 테스트 실행 → 19/19 PASS
- [x] `diff -q` → SYNCED
- [x] Commit: `fix(spec-20-03): exclude shell interpolation from secret check (#158)` — `a0525e5`

---

## Task 2: #1a update.sh 미커밋 산물 커밋 안내

### 2-1. 테스트 작성 (TDD Red)
- [x] `tests/test-update.sh` 시나리오 D 추가: untracked install + update 후 안내 출력
- [x] 테스트 실행 → Fail 확인 (1/12 FAIL)
- [x] Commit: `test(spec-20-03): ...` — `15525dd`

### 2-2. 구현 (TDD Green)
- [x] `update.sh` 종료 배너 직후 미커밋 install 산물 감지 + 커밋 안내 블록 추가 (자동 커밋 금지)
- [x] 테스트 실행 → 12/12 PASS
- [x] Commit: `fix(spec-20-03): warn on uncommitted install artifacts after update (#158)` — `2644149`

---

## Task 3: #1b 브랜치 생성 시 install drift 경고

### 3-1. 테스트 작성 (TDD Red)
- [x] `tests/test-sdd-spec-new-drift-warn.sh` 신규: dirty/clean install → spec new/specx new 경고 + rc=0 + 생성
- [x] 테스트 실행 → Fail 확인 (경고 assertion 2 Red)
- [x] Commit: `test(spec-20-03): ...` — `8431c4e`

### 3-2. 구현 (TDD Green)
- [x] `sources/bin/sdd` + `.harness-kit/bin/sdd`: `_warn_install_drift()` 헬퍼 + `spec_new`/`specx_new` 호출 추가
- [x] 테스트 실행 → 7/7 PASS (+ spec-new-seq 5/5 회귀)
- [x] `diff -q` → SYNCED
- [x] Commit: `fix(spec-20-03): warn on install drift before branch creation (#158)` — `4ef2b37`

---

## Task 4: #3 phase activate base 인자 + 재활성 시맨틱

### 4-1. 테스트 작성 (TDD Red)
- [x] `tests/test-sdd-phase-activate.sh` 에 Check 10(`--base=<branch>` + 메타 기입) / Check 11(재활성 spec 보존) 추가
- [x] 테스트 실행 → Fail 확인 (4 Red)
- [x] Commit: `test(spec-20-03): ...` — `384cc35`

### 4-2. 구현 (TDD Green)
- [x] `sources/bin/sdd` + `.harness-kit/bin/sdd`: `_set_phase_base_meta()` + `phase_activate` 재구현
- [x] 테스트 실행 → 17/17 PASS (기존 Check 1-9 회귀 보존)
- [x] `diff -q` → SYNCED
- [x] Commit: `fix(spec-20-03): phase activate --base arg + preserve active spec on reactivation (#158)` — `a780f0c`

---

## Task 5: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [x] 문법 점검: `bash -n` (변경 스크립트 — sdd/check-secrets/update 모두 ok)
- [x] 전체 단위 테스트 실행 → 모두 PASS (19/12/7/17 + seq 5/5)
- [x] 회귀: `test-governance-dedup.sh` → 7/8 (Check 3 = 기존 문서 비대화, 본 spec 무관)
- [x] sync 검증: `diff -q` sdd + check-secrets → SYNCED
- [x] **walkthrough.md 작성** (#2 병렬 진화 머지 결정 + Gemini 리뷰 포함)
- [x] **pr_description.md 작성** (템플릿 준수)
- [x] **코드 리뷰 게이트** (Gemini cross-model → Approve, Minor 2 미변경)
- [x] **Ship Commit**: `docs(spec-20-03): ship walkthrough and pr description` — `b02975f`
- [x] **Push**: `git push -u origin spec-20-03-harness-footguns`
- [x] **PR 생성**: gh api → LeoYoon7/harness-kit#34 (base: `phase-20-upstream-parity`)
- [x] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 5 |
| **실제 commit 수** | 11 (planning + 결정기록 + footgun 4종×2 + ship) |
| **현재 단계** | Ship 완료 — PR #34 머지 대기 |
| **마지막 업데이트** | 2026-06-04 |
