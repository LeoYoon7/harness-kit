# Task List: spec-x-stale-adr-archive-path

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성 (`sdd specx new`)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 phase.md 없음, 해당 없음
- [x] 사용자 Plan Accept

---

## Task 1: archive 경로 회귀 테스트 추가 (TDD Red)

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-stale-adr-archive-path`
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. 테스트 작성 (TDD Red)
- [x] `tests/test-drift-stale-adr.sh` 에 Step 5 추가: archived **spec** 참조 ADR 픽스처가 stale 로 잡히지 **않음** 검증
  - `archive/specs/spec-x-archived-fixture/spec.md` + `docs/decisions/ADR-996-archived-path-fixture.md` 픽스처 생성, trap 정리
- [x] Step 6 추가: archived **backlog** 참조 ADR 픽스처도 stale 미탐지 검증 (prefix 일반성)
  - `archive/backlog/phase-fixture.md` + `docs/decisions/ADR-995-archived-backlog-fixture.md` 픽스처 생성, trap 정리
- [x] `bash tests/test-drift-stale-adr.sh` → Step 5 에서 FAIL 확인 (Red, ADR-996 missing-path)
- [x] Commit: `test(spec-x-stale-adr-archive-path): add failing tests for archived spec/backlog paths` (4b3a897)

---

## Task 2: archive fallback 존재 검사 구현 (TDD Green)

### 2-1. 구현
- [x] `sources/bin/sdd` `_drift_stale_adr()` line 401 직후 `[ -e "$SDD_ROOT/archive/$token" ] && continue` 추가
- [x] `.harness-kit/bin/sdd` 동일 반영 (dogfood sync)
- [x] `bash tests/test-drift-stale-adr.sh` → 전 6 step PASS 확인 (Green)
- [x] `bash .harness-kit/bin/sdd status` → dogfood sync mismatch 경고 없음 (sources↔installed 동일 편집)
- [x] Commit: `fix(spec-x-stale-adr-archive-path): resolve archived ADR refs to avoid false stale` (67f2841)

---

## Task 3: queue 하우스키핑 — line 56 정리 (docs)

### 3-1. queue.md line 56 strike-through
- [x] `backlog/queue.md` 의 "sdd ship spec-x 커밋 subject slug truncation 버그" 항목을 `~~...~~` 로 표시 + `→ ✓ #50 (f495749)` 포인터 추가 (#50 이 이미 해결, strike 누락분 정리)
- [x] Commit: `docs(spec-x-stale-adr-archive-path): mark #50-resolved ship-scope item in queue` (99d5a68)

---

## Task N: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [x] 전체 drift/ship-scope 테스트 실행 → 모두 PASS (`tests/test-drift-stale-adr.sh` 6/6, `tests/test-sdd-ship-scope.sh` 5/5)
- [x] 코드 리뷰 게이트 — Gemini cross-model **Approve** (Critical 0/Major 0/Minor 0)
- [x] **walkthrough.md 작성** (증거 로그)
- [x] **pr_description.md 작성** (템플릿 준수)
- [x] **Ship Commit**: `docs(spec-x-stale-adr-archive-path): ship walkthrough and pr description`
- [x] **Push**: `git push -u origin spec-x-stale-adr-archive-path`
- [x] **PR 생성**: `/hk-pr-gh` 로 생성 (PR base = fork main)
- [x] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 3 (+ Ship) |
| **실제 commit 수** | 6 (planning docs / test / fix / queue docs / ship / finalize) |
| **현재 단계** | Ship |
| **마지막 업데이트** | 2026-06-09 |
