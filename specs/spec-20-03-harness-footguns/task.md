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
- [ ] `git checkout -b spec-20-03-harness-footguns` (base: `phase-20-upstream-parity`)
- [ ] Commit: 없음 (브랜치 생성만)

### 1-2. 테스트 작성 (TDD Red)
> 결정(2026-06-04): `_ph_re`(placeholder 필터) 제외 — fork Test 15 무회귀. 보간(`_var_re`/`_op_re`)만 머지.
- [ ] `tests/test-check-secrets-dual-mode.sh` 에 케이스 추가: 비-`.md` 파일의 `${VAR:-default}`·`$VAR` 보간 통과(오탐 없음) + 실제 시크릿 계속 차단 + Test 15(맨 placeholder 차단) 보존 확인
- [ ] 테스트 실행 → Fail 확인 (fork 현재는 보간 오탐)
- [ ] Commit: `test(spec-20-03): add env-interpolation false-positive cases for check-secrets`

### 1-3. 구현 (TDD Green)
- [ ] `sources/hooks/check-secrets.sh` + `.harness-kit/hooks/check-secrets.sh`: `.md` 제외 파이프라인에 `_var_re`/`_op_re` 필터 추가 (`_ph_re` 제외)
- [ ] 테스트 실행 → Pass 확인
- [ ] `diff -q` 로 sources↔installed sync 확인
- [ ] Commit: `fix(spec-20-03): exclude shell interpolation/placeholder from secret check (#158)`

---

## Task 2: #1a update.sh 미커밋 산물 커밋 안내

### 2-1. 테스트 작성 (TDD Red)
- [ ] `tests/test-update.sh` 에 케이스 추가: update 후 dirty `.harness-kit/` → 안내 문구 출력
- [ ] 테스트 실행 → Fail 확인
- [ ] Commit: `test(spec-20-03): add uncommitted-artifact notice case for update.sh`

### 2-2. 구현 (TDD Green)
- [ ] `update.sh` 종료 메시지 직후 미커밋 install 산물 감지 + 커밋 안내 블록 추가 (자동 커밋 금지)
- [ ] 테스트 실행 → Pass 확인
- [ ] Commit: `fix(spec-20-03): warn on uncommitted install artifacts after update (#158)`

---

## Task 3: #1b 브랜치 생성 시 install drift 경고

### 3-1. 테스트 작성 (TDD Red)
- [ ] `tests/test-sdd-spec-new-drift-warn.sh` 신규 작성: dirty install 상태 → `sdd spec new`/`specx new` 경고 출력 + rc=0 + 정상 생성
- [ ] 테스트 실행 → Fail 확인 (fork 현재는 경고 없음)
- [ ] Commit: `test(spec-20-03): add install-drift warn test for sdd spec/specx new`

### 3-2. 구현 (TDD Green)
- [ ] `sources/bin/sdd` + `.harness-kit/bin/sdd`: `_warn_install_drift()` 헬퍼 포팅 + `spec_new`/`specx_new` 의 `die_if_active_spec` 직후 호출 추가
- [ ] 테스트 실행 → Pass 확인
- [ ] `diff -q` 로 sources↔installed sync 확인
- [ ] Commit: `fix(spec-20-03): warn on install drift before branch creation (#158)`

---

## Task 4: #3 phase activate base 인자 + 재활성 시맨틱

### 4-1. 테스트 작성 (TDD Red)
- [ ] `tests/test-sdd-phase-activate.sh` 에 케이스 추가: `--base=<branch>` 인자 / 같은 phase 재활성 시 active spec 보존 / 메타 자동 기입
- [ ] 테스트 실행 → Fail 확인
- [ ] Commit: `test(spec-20-03): add --base arg and reactivation-preservation cases`

### 4-2. 구현 (TDD Green)
- [ ] `sources/bin/sdd` + `.harness-kit/bin/sdd`: `_set_phase_base_meta()` 헬퍼 포팅 + `phase_activate` 재구현(`--base=<branch>` 파싱 / `same_phase` 가드·리셋 생략 / base 우선순위 / 메타 자동 기입)
- [ ] 테스트 실행 → Pass 확인 (기존 Check 회귀 보존)
- [ ] `diff -q` 로 sources↔installed sync 확인
- [ ] Commit: `fix(spec-20-03): phase activate --base arg + preserve active spec on reactivation (#158)`

---

## Task 5: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] 문법 점검: `bash -n` (변경 스크립트 4종)
- [ ] 전체 단위 테스트 실행 → 모두 PASS (check-secrets / update / spec-new-drift / phase-activate)
- [ ] 회귀: `bash tests/test-governance-dedup.sh` → PASS
- [ ] sync 검증: `diff -q sources/bin/sdd .harness-kit/bin/sdd` + `diff -q sources/hooks/check-secrets.sh .harness-kit/hooks/check-secrets.sh` → SYNCED
- [ ] **walkthrough.md 작성** (증거 로그 — #2 병렬 진화 머지 결정 포함)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] **코드 리뷰 게이트** (§6.3 — Gemini/Opus/Skip 중 선택, Skip 시 사유 기록)
- [ ] **Ship Commit**: `docs(spec-20-03): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-20-03-harness-footguns`
- [ ] **PR 생성**: `/hk-pr-gh` (base: `phase-20-upstream-parity`)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 5 |
| **예상 commit 수** | 9 (footgun 4종 × Red+Green = 8 + ship 1) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-04 |
