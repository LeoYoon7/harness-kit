# Task List: spec-x-sdd-drift-fixes

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 (spec-x 는 phase.md 없음 — 적용 불가; queue.md 의 specx 마커는 sdd 자동 관리)
- [ ] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

- [ ] `git checkout -b spec-x-sdd-drift-fixes`
- [ ] 현재 브랜치 확인
- [ ] Commit: 없음 (브랜치 생성만)

---

## Task 2: TDD Red — Test D 추가 (ADR `../` exclude false positive) + SDD_BIN 일관성

> stale_adr 검사가 ADR 본문의 `../` token 을 stale 로 잡지 않는지 검증.
> Plan deviation: `test-drift-stale-adr.sh` 의 `SDD_BIN` 을 `.harness-kit/bin/sdd` → `sources/bin/sdd` 로 변경 (test-sdd-drift.sh 와 일관성 — sources/ 패치가 즉시 테스트에 반영되도록).

### 2-1. 테스트 케이스 작성
- [x] `tests/test-drift-stale-adr.sh` 의 `SDD_BIN` 을 `sources/bin/sdd` 로 변경 + `RELATIVE_FIXTURE` cleanup trap 등록
- [x] Step 4 추가: ADR fixture 본문에 `\`../../sources/governance/agent.md\`` (`../` 시작 path token) → stale 카운트 0 기대
- [x] 테스트 실행: `bash tests/test-drift-stale-adr.sh`
- [x] 결과 확인: Step 1 부터 fail (clean state 인데 ADR-003 의 `../` token 으로 stale: 1 — 본 fix 대상). Step 1-4 모두 fix 후 PASS 예정.
- [ ] Commit: `test(spec-x-sdd-drift-fixes): switch test-drift-stale-adr to sources/bin/sdd + add Test D (../ exclude)`

---

## Task 3: TDD Green — `_drift_stale_adr` 에 `../` 제외 한 줄

### 3-1. sdd 패치
- [ ] `sources/bin/sdd` 의 `_drift_stale_adr` token 필터 체인 4) 검사 직전에 한 줄 추가:
  - `echo "$token" | grep -qE '^\.\./' && continue`
- [ ] 테스트 실행: `bash tests/test-drift-stale-adr.sh`
- [ ] 결과 확인: Step 4 PASS + 기존 Step 1-3 도 모두 PASS (regression 없음)
- [ ] Commit: `fix(spec-x-sdd-drift-fixes): exclude ../ relative-path tokens from stale ADR check`

---

## Task 4: TDD Red — Test A/B/C 추가 (dogfood-sync 검출)

> `_drift_dogfood_sync` 신규 함수의 동작 검증.

### 4-1. 테스트 케이스 작성
- [ ] `tests/test-sdd-drift.sh` 에 T6/T7/T8 추가:
  - T6: fixture 에 sources/hooks/foo.sh = .harness-kit/hooks/foo.sh (sync) → drift 섹션에 `도그푸딩 sync` 줄 없음
  - T7: fixture 에 sources/hooks/foo.sh ≠ .harness-kit/hooks/foo.sh (mismatch) → `도그푸딩 sync: 1 파일 ... 권장` 줄 출력
  - T8: fixture 에 sources/ 디렉토리 없음 → `_drift_dogfood_sync` skip (drift 섹션에 줄 없음)
- [ ] 테스트 실행: `bash tests/test-sdd-drift.sh`
- [ ] 결과 확인: T6/T8 PASS (현재는 함수 자체가 없어 호출 안 됨 → 줄 없음), T7 FAIL (mismatch 검출 안 됨)
- [ ] Commit: `test(spec-x-sdd-drift-fixes): add failing tests for dogfood-sync drift detection`

---

## Task 5: TDD Green — `_drift_dogfood_sync` 함수 추가 + 등록

### 5-1. sdd 패치
- [ ] `sources/bin/sdd` 에 `_drift_dogfood_sync` 함수 신규 추가 (plan.md §Proposed Changes §2 의 코드)
- [ ] `_status_drift` 의 `_drift_install` 호출 직후에 `_drift_dogfood_sync && has_drift=1` 추가
- [ ] 테스트 실행: `bash tests/test-sdd-drift.sh`
- [ ] 결과 확인: T1-T8 모두 PASS
- [ ] 회귀 가드 확인: 기존 T1-T5 PASS 유지
- [ ] Commit: `feat(spec-x-sdd-drift-fixes): add _drift_dogfood_sync to detect tracked .harness-kit drift`

---

## Task 6: Ship (walkthrough + pr_description + dogfood-sync + push + PR)

> 본 spec 자체가 dogfood-sync 를 fix 하므로 update.sh 호출이 *예상된* 단계.

### 6-0. Dogfood-sync (sources/bin/sdd → .harness-kit/bin/sdd)
- [ ] `bash update.sh --yes` 실행 → `.harness-kit/bin/sdd` 에 본 spec 패치 반영
- [ ] `bash .harness-kit/bin/sdd status` 실행 → 새 `_drift_dogfood_sync` + 보강된 `_drift_stale_adr` 가 *현재 환경* 에서 동작 확인:
  - `stale ADR` 줄 사라짐 (ADR-003 의 `../` token 제외)
  - `🔄 동기화 상태` 가 `깔끔` 또는 워킹트리 변경 1줄만
- [ ] Commit: `chore(spec-x-sdd-drift-fixes): apply dogfood sync for sdd drift fixes`

### 6-1. 산출물 작성
- [ ] 전체 테스트 PASS 재확인 (`bash tests/test-drift-stale-adr.sh && bash tests/test-sdd-drift.sh`)
- [ ] **walkthrough.md 작성** (결정 기록, Test 신규 4건, 수동 검증 3 시나리오, dogfood-sync 자기 검증)
- [ ] **pr_description.md 작성** (변경 요약, 회귀 가드, sdd status before/after 출력)

### 6-2. Ship Commit
- [ ] Commit: `docs(spec-x-sdd-drift-fixes): ship walkthrough and pr description`

### 6-3. Push & PR
- [ ] task.md 의 모든 `[ ]` 가 `[x]` 또는 `[-]` 인지 확인
- [ ] **Push**: `git push -u origin spec-x-sdd-drift-fixes`
- [ ] **PR 생성**: `gh pr create --repo LeoYoon7/harness-kit --base main`
- [ ] **사용자 알림**: PR URL 보고 후 머지 대기

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 6 (Pre-flight 제외) |
| **예상 commit 수** | 6 (test-D + fix-stale + test-ABC + feat-sync + chore-sync + docs/ship) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-05-28 |
