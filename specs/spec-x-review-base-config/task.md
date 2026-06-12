# Task List: spec-x-review-base-config

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성 (`sdd specx new review-base-config`)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] critique 수행 + 반영 (all, 7건 — critique.md)
- [-] 백로그 업데이트 — spec-x 는 phase.md 없음 (queue.md specx 등록은 sdd 가 자동 수행)
- [x] 사용자 Plan Accept

---

## Task 1: 브랜치 생성 + 계획 산출물 커밋

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-review-base-config`
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. 계획 산출물 + Icebox 등록 커밋
- [x] `backlog/queue.md` Icebox 에 4건 등록 (멀티레포 리뷰 / sdd 내부 main fallback + deferred ADR / hk-ship PR_BASE·governance main 전제 / hk-cleanup defaultBranch 검사)
- [x] Commit: `docs(spec-x-review-base-config): add spec/plan/task/critique and icebox entries` (`5d60b4f`)

---

## Task 2: sdd config default-branch + status JSON/doctor 노출 (TDD)

### 2-1. 테스트 작성 (TDD Red)
- [x] `tests/test-sdd-config.sh` 에 default-branch 케이스 4종 추가 (T7~T10: 미설정 조회 main / 설정 후 조회 + 부재 경고 / 부적합 이름 거부 / status --json 노출)
- [x] 테스트 실행 → Fail 확인 (PASS=8 FAIL=6)
- [x] Commit: `test(spec-x-review-base-config): add failing tests for sdd config default-branch` (`9e0ecde`)

### 2-2. 구현 (TDD Green)
- [x] `sources/bin/sdd`: `_config_default_branch()` (형식 검증 + 실재 경고) + cmd_config 분기 + usage 한 줄
- [x] `sources/bin/sdd`: `cmd_status --json` 에 defaultBranch 주입 (state 부재 fallback 포함) + `cmd_doctor` 한 줄 노출
- [x] `.harness-kit/bin/sdd` 동기 반영 (pre-edit IDENTICAL 확인 후 cp)
- [x] 테스트 실행 → Pass 확인 (PASS=14 FAIL=0)
- [x] Commit: `feat(spec-x-review-base-config): add sdd config default-branch with status and doctor exposure` (`0b347c5`)

---

## Task 3: gemini-review.sh base 해석 체인 (TDD)

### 3-1. 테스트 작성 (TDD Red)
- [x] `tests/test-gemini-review-guard.sh` 에 T8 (defaultBranch=develop 반영) / T9 (2단 fallback 종착 → main 진행) 추가
- [x] 테스트 실행 → T8 Fail 확인 (T9 는 종착 회귀 가드 — 현 동작도 main 종착이라 사전 PASS)
- [x] Commit: `test(spec-x-review-base-config): add failing tests for review base chain` (`c7e3c58`)

### 3-2. 구현 (TDD Green)
- [x] `sources/bin/gemini-review.sh` base 결정부 교체 (2단 fallback 종착 — plan.md 의사코드) + 주석 갱신
- [x] `.harness-kit/bin/gemini-review.sh` 동기 반영 (pre-edit IDENTICAL 확인 후 cp)
- [x] 테스트 실행 → T1~T9 Pass 확인 (PASS=20 FAIL=0)
- [x] Commit: `fix(spec-x-review-base-config): resolve review base via defaultbranch chain` (`ed12374`)

---

## Task 4: 명령 문서 base 결정 절차 교체 (hk-code-review + hk-gemini-review)

### 4-1. 명령 문서 수정
- [x] `sources/commands/hk-code-review.md`: 하드코딩 3곳 → `${REVIEW_BASE}` (status --json 단일 소스 jq 체인 + ref 부재 fallback 명시)
- [x] `sources/commands/hk-gemini-review.md`: base 서술 2곳 새 체인 반영
- [x] `.claude/commands/hk-code-review.md`, `.claude/commands/hk-gemini-review.md` 동기 반영 (pre-edit IDENTICAL 확인 후 cp)
- [x] `bash tests/test-review-b1.sh` 회귀 확인 (PASS=18 FAIL=0)
- [x] Commit: `fix(spec-x-review-base-config): make review command diff base configurable` (`a8b3425`)

---

## Task 5: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [x] 전체 테스트 실행 → 모두 PASS (config 14/14, guard 20/20, base-branch 4/4, b1 18/18, manifest 6/6, doctor 7/7) + `sdd test passed` 기록
- [x] 수동 검증 시나리오 1~4 수행 (config 조회/설정/거부 + doctor 표기)
- [x] **walkthrough.md 작성** (증거 로그)
- [x] **pr_description.md 작성** (템플릿 준수)
- [x] 코드 리뷰 게이트: Gemini cross-model → **Approve** (0/0/2 — walkthrough 에 Minor 처리 기록)
- [x] **Ship Commit**: `docs(spec-x-review-base-config): ship walkthrough and pr description`
- [x] **Push**: `git push -u origin spec-x-review-base-config`
- [x] **PR 생성**: `/hk-pr-gh` (base: fork main)
- [x] **사용자 알림**: 푸시 완료 + PR URL 보고
- [-] (머지 후) `sdd specx done review-base-config` — 머지 signal 후 수행 (ship 범위 밖, Post-Merge Protocol)

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 5 |
| **예상 commit 수** | 7 |
| **현재 단계** | Ship |
| **마지막 업데이트** | 2026-06-12 |
