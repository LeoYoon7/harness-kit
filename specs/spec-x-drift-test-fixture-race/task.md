# Task List: spec-x-drift-test-fixture-race (재설계)

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 이전 plan(fs-visibility) 무효 → 본 task 로 대체.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 재작성 (정정된 근본원인)
- [x] plan.md 재작성
- [x] task.md 재작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 phase.md 없음, 해당 없음
- [ ] 사용자 Plan Accept (재요청 — 이전 accept 무효)

---

## Task 1: drift-stale-adr 단언 fixture-특정화

### 1-1. 브랜치
- [x] `spec-x-drift-test-fixture-race` (이미 생성됨)

### 1-2. 단언 교체 (Steps 1~6)
- [ ] `tests/test-drift-stale-adr.sh` 각 step 의 stale 단언을 *자기 fixture basename* 기준으로 교체 (plan.md 표 참조). 픽스처 생성/내용/순서는 불변.

### 1-3. deterministic 검증 (Green)
- [ ] foreign fixture(`ADR-999-phase16-integration-fixture.md`) + 자기 fixture 동시 존재 시 `sdd status` 1회 → 구 단언 `grep "stale ADR: 1"` 실패 / 신 단언 `grep "ADR-999-stale-fixture"` 통과 확인 (간섭 견고 증명)
- [ ] `bash tests/test-drift-stale-adr.sh` 1회 solo → 6/6 PASS (회귀 sanity, ~8분 background)
- [ ] Commit: `test(spec-x-drift-test-fixture-race): make drift-stale-adr assertions fixture-specific`

---

## Task 2: phase16-integration 대칭 견고화

### 2-1. 평가 + 반영
- [ ] `tests/test-phase16-integration.sh` 단언이 전역 count/부재 의존인지 확인
- [ ] 동일 패턴이면 자기 fixture(`ADR-999-phase16-integration-fixture`) 특정으로 교체; 아니면 OOS 로 보고
- [ ] (수정 시) `bash tests/test-phase16-integration.sh` solo → PASS
- [ ] Commit: `test(spec-x-drift-test-fixture-race): make phase16-integration assertion fixture-specific` (수정 시에만)

---

## Task 3: queue 하우스키핑 (docs)

### 3-1. queue.md 갱신
- [ ] 본 항목(`test-drift-stale-adr.sh Step 2 Windows 플래키`) strike → ✓ **정정된 원인**(cross-test fixture 간섭, fs-visibility 아님) + 본 spec
- [ ] 신규 Icebox: `sdd status` Windows 성능 저하 (solo ~1m24s)
- [ ] Commit: `docs(spec-x-drift-test-fixture-race): resolve flaky item (corrected cause) + perf icebox`

---

## Task N: Ship (필수)

- [ ] deterministic 검증 + full 테스트 PASS 확인
- [ ] **walkthrough.md 작성** (오진→정정 경위 + 검증 수치 포함)
- [ ] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-x-drift-test-fixture-race): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-drift-test-fixture-race`
- [ ] **PR 생성**: fork(LeoYoon7) main base, `gh api --input`
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 2~3 (+ Ship, phase16 수정 여부에 따라) |
| **예상 commit 수** | 3~4 |
| **현재 단계** | Planning (재설계) |
| **마지막 업데이트** | 2026-06-09 |
