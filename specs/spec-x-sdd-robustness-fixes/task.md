# Task List: spec-x-sdd-robustness-fixes

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 phase.md 미해당 (ship 시 `sdd specx done`)
- [x] 사용자 Plan Accept

---

## Task 1: ship scope 단위 테스트 (TDD Red)

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-sdd-robustness-fixes`
- [x] Commit: 없음

### 1-2. 테스트 작성 (TDD Red)
- [x] `tests/test-sdd-ship-scope.sh` — sdd source 후 `sdd_ship_scope` 단위 검증
  - spec-x-review-b1-default → spec-x-review-b1-default
  - spec-x-a-b-c → spec-x-a-b-c / spec-x-single → spec-x-single
  - spec-08-01-foo → spec-08-01 / spec-1-02-bar-baz → spec-1-02
  - 회귀: source 시 main 부작용 없음
- [x] `bash tests/test-sdd-ship-scope.sh` → **Fail** (sdd_ship_scope 미정의)
- [x] Commit: `test(spec-x-sdd-robustness-fixes): add failing unit test for ship scope`

---

## Task 2: Bug 1 fix — sdd_ship_scope 헬퍼 + 소스 가드 (+미러)

### 2-1. sources + 미러 동시 수정 (도그푸딩 sync — 같은 commit)
- [x] `sources/bin/sdd` — `sdd_ship_scope()` 헬퍼 추가 + `cmd_ship` 이 헬퍼 사용 + 말미 `main "$@"` 를 `[ "${BASH_SOURCE[0]}" = "$0" ] && main "$@"` 로 가드.
- [x] `.harness-kit/bin/sdd` — byte-identical 동기화.
- [x] (테스트 교정) 헬퍼를 source 후 고유 이름(t_ok/t_bad)으로 정의 — sdd 의 ok() 충돌로 카운터 0 오탐 수정.
- [x] `bash tests/test-sdd-ship-scope.sh` → **PASS** (5/5 genuine)
- [x] 직접 실행 회귀: `sdd help` / `sdd version` / `sdd status --brief` → 정상(exit 0).
- [x] Commit: `fix(spec-x-sdd-robustness-fixes): correct ship commit scope for spec-x slugs`

---

## Task 3: Bug 2 fix — stale-adr 프로세스치환 → here-string (+미러)

### 3-1. sources + 미러 동시 수정 (같은 commit)
- [ ] `sources/bin/sdd` — `_drift_stale_adr()` 의 `done < <(grep...)` 를 `toks="$(grep...)"; ... done <<< "$toks"` 로 교체.
- [ ] `.harness-kit/bin/sdd` — byte-identical 동기화.
- [ ] `bash tests/test-drift-stale-adr.sh` → **PASS** (Step 1-4, detection 회귀 없음)
- [ ] 미러 diff: `diff sources/bin/sdd .harness-kit/bin/sdd` → 차이 0.
- [ ] Commit: `fix(spec-x-sdd-robustness-fixes): replace process-substitution with here-string in stale-adr scan`

---

## Task 4: Ship (필수)

- [ ] 전체 관련 테스트 PASS (`test-sdd-ship-scope.sh`, `test-drift-stale-adr.sh`) + 직접 실행 회귀
- [ ] 코드 리뷰 게이트 (§6.3): bash 로직 변경이라 리뷰 가치 있음 — `/hk-gemini-review` 또는 `/hk-code-review`(이제 B1) 고려 / Skip 시 사유 기록
- [ ] **walkthrough.md 작성**
- [ ] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-x-sdd-robustness-fixes): ship walkthrough and pr description` (← Bug1 자기 도그푸딩: scope 온전 검증)
- [ ] **Push**: `git push -u origin spec-x-sdd-robustness-fixes`
- [ ] **PR 생성**: `/hk-pr-gh` (base = fork main, 승인 후)
- [ ] **사용자 알림**: push + PR URL
- [ ] (머지 후) `sdd specx done sdd-robustness-fixes`

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 4 |
| **예상 commit 수** | 4 (test 1 + fix 2 + ship 1) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-09 |
