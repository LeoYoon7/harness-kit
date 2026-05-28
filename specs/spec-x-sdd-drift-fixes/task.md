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
- [x] `sources/bin/sdd` 의 `_drift_stale_adr` token 필터 체인 4) 검사 직전에 한 줄 추가:
  - `echo "$token" | grep -qE '^\.\./' && continue`
- [x] 테스트 실행: `bash tests/test-drift-stale-adr.sh`
- [x] 결과 확인: Step 1-4 모두 PASS (ADR-003 의 false positive 해소 + regression 가드)
- [x] Commit: `fix(spec-x-sdd-drift-fixes): exclude ../ relative-path tokens from stale ADR check`

---

## Task 4: TDD Red — Test A/B/C 추가 (dogfood-sync 검출)

> `_drift_dogfood_sync` 신규 함수의 동작 검증.

### 4-1. 테스트 케이스 작성
- [x] `tests/test-sdd-drift.sh` 에 T6/T7/T8 추가
- [x] 테스트 실행: `bash tests/test-sdd-drift.sh`
- [x] 결과 확인: T6/T8 PASS, T7 FAIL (Red 확인). T1 의 첫 check FAIL 은 baseline pre-existing (본 변경 이전부터). 본 spec 무관.
- [x] Commit: `test(spec-x-sdd-drift-fixes): add failing tests for dogfood-sync drift detection`

---

## Task 5: TDD Green — `_drift_dogfood_sync` 함수 추가 + 등록

### 5-1. sdd 패치
- [x] `sources/bin/sdd` 에 `_drift_dogfood_sync` 함수 신규 추가
- [x] `_status_drift` 의 `_drift_install` 호출 직후에 `_drift_dogfood_sync && has_drift=1` 추가
- [x] 테스트 실행: `bash tests/test-sdd-drift.sh && bash tests/test-drift-stale-adr.sh`
- [x] 결과 확인: 본 spec 의 신규 T6/T7/T8 + Test D 모두 PASS. 기존 T1 baseline fail 만 존속 (본 spec 무관)
- [x] Commit: `feat(spec-x-sdd-drift-fixes): add _drift_dogfood_sync to detect tracked .harness-kit drift`

---

## Task 6: Ship (walkthrough + pr_description + dogfood-sync + push + PR)

> 본 spec 자체가 dogfood-sync 를 fix 하므로 update.sh 호출이 *예상된* 단계.

### 6-0. Dogfood-sync (sources/bin/sdd → .harness-kit/bin/sdd)
- [x] `bash update.sh --yes` 실행 → `.harness-kit/bin/sdd` 에 본 spec 패치 반영
- [x] `bash .harness-kit/bin/sdd status` 실행 → `stale ADR` 줄 사라짐 ✓
- [x] Commit: `chore(spec-x-sdd-drift-fixes): apply dogfood sync for sdd drift fixes` → `b4f73ae`

### 6-1. 산출물 작성
- [x] 전체 테스트 PASS 재확인 (`bash tests/test-drift-stale-adr.sh && bash tests/test-sdd-drift.sh`)
- [x] **walkthrough.md 작성** (결정 7개, Test 4건, 수동 검증 3 시나리오, dogfood self-verify + EOL 발견)
- [x] **pr_description.md 작성** (Key Review 5점, before/after sdd status 출력, EOL 노이즈 명시)

### 6-2. Ship Commit
- [x] Commit: `docs(spec-x-sdd-drift-fixes): ship walkthrough and pr description`

### 6-3. Push & PR
- [x] task.md 의 모든 `[ ]` 가 `[x]` 또는 `[-]` 인지 확인
- [ ] **Push**: `git push -u origin spec-x-sdd-drift-fixes`
- [ ] **PR 생성**: `gh pr create --repo LeoYoon7/harness-kit --base main`
- [ ] **사용자 알림**: PR URL 보고 후 머지 대기

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 6 (Pre-flight 제외) |
| **예상 commit 수** | 6 (test-D + fix-stale + test-ABC + feat-sync + chore-sync + docs/ship) |
| **현재 단계** | Ship |
| **마지막 업데이트** | 2026-05-28 |
