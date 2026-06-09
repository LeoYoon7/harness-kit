# Task List: spec-x-drift-test-fixture-race (재설계)

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 이전 plan(fs-visibility) 무효 → 본 task 로 대체.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 재작성 (정정된 근본원인)
- [x] plan.md 재작성
- [x] task.md 재작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 phase.md 없음, 해당 없음
- [x] 사용자 Plan Accept (재요청 — 이전 accept 무효, 2026-06-09 재승인)

---

## Task 1: drift-stale-adr 단언 fixture-특정화

### 1-1. 브랜치
- [x] `spec-x-drift-test-fixture-race` (이미 생성됨)

### 1-2. 단언 교체 (Steps 1~6)
- [x] `tests/test-drift-stale-adr.sh` 각 step 의 stale 단언을 *자기 fixture basename* 기준으로 교체 + 헤더 주석 갱신. 픽스처 불변.

### 1-3. deterministic 검증 (Green)
- [x] foreign + 자기 fixture 동시 존재 → `stale ADR: 2` → 구 단언 `grep "stale ADR: 1"` **NO MATCH(실패)** / 신 단언 `grep "ADR-999-stale-fixture"` **MATCH(통과)** 확인
- [x] `bash tests/test-drift-stale-adr.sh` solo → **6/6 PASS** (회귀 sanity)
- [x] Commit: `test(spec-x-drift-test-fixture-race): make drift-stale-adr assertions fixture-specific` (ebef28e)

---

## Task 2: phase16-integration 대칭 견고화

### 2-1. 평가 + 반영
- [x] `tests/test-phase16-integration.sh` Scenario 2 가 동일 fragile 패턴(`grep "stale ADR: 1"`)임을 확인
- [x] 자기 fixture(`ADR-999-phase16-integration-fixture`) 특정으로 교체 (대칭 견고화)
- [x] Scenario 2 신 단언 검증 — deterministic verify run 출력에 `ADR-999-phase16-integration-fixture.md` 가 stale 로 나타남(`stale ADR: 2 — ...phase16...; ...stale-fixture.md`) → phase16 의 `grep "ADR-999-phase16-integration-fixture"` 통과 확인. (full phase16 통합테스트 end-to-end 는 다중 sdd status 로 매우 느려 미실행 — 변경은 Scenario 2 grep 1줄, Scenario 1/3 무관)
- [x] Commit: `test(spec-x-drift-test-fixture-race): make phase16-integration assertion fixture-specific` (92ad334)

---

## Task 3: queue 하우스키핑 (docs)

### 3-1. queue.md 갱신
- [x] 본 항목 strike → ✓ **정정된 원인**(cross-test fixture 간섭) + 본 spec
- [x] 신규 Icebox: `sdd status` Windows 성능 저하 (solo ~1m24s)
- [x] Commit: `docs(spec-x-drift-test-fixture-race): resolve flaky item (corrected cause) + perf icebox` (c460ebd)

---

## Task N: Ship (필수)

- [x] deterministic 검증 + full 테스트 6/6 PASS 확인
- [x] 코드 리뷰 게이트 — Gemini cross-model **Approve** (Critical 0/Major 0/Minor 1, 의도된 trade-off)
- [x] **walkthrough.md 작성** (오진→정정 경위 + 검증 수치 포함)
- [x] **pr_description.md 작성**
- [x] **Ship Commit**: `docs(spec-x-drift-test-fixture-race): ship walkthrough and pr description`
- [x] **Push**: `git push -u origin spec-x-drift-test-fixture-race`
- [x] **PR 생성**: fork(LeoYoon7) main base, `gh api --input`
- [x] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 3 (drift / phase16 / queue) + Ship |
| **실제 commit 수** | 6 (planning / drift / phase16 / queue / ship / finalize) |
| **현재 단계** | Ship |
| **마지막 업데이트** | 2026-06-09 |
