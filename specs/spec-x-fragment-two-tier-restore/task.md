# Task List: spec-x-fragment-two-tier-restore

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 phase.md 갱신 불요 (constitution §5.1). 완료 시 `sdd specx done` 으로 queue 반영
- [x] 사용자 Plan Accept

---

## Task 1: 회귀 테스트 확장 (TDD Red)

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-fragment-two-tier-restore`
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. 테스트 작성 (TDD Red)
- [x] `tests/test-two-tier-loading.sh` 에 신규 단언 추가:
  - notify.md 존재 + 알림 프로토콜 핵심 문구 보유
  - `hk-align.md` 가 `@.harness-kit/agent/notify.md` import
  - fragment 가 알림 프로토콜 본문 헤딩을 더 이상 보유 안 함
- [x] `bash tests/test-two-tier-loading.sh` → Fail 확인 (Check 4/6/7/8 = 4건 FAIL)
- [x] Commit: `test(spec-x-fragment-two-tier-restore): assert tier-2 notify.md relocation` (`2a06700`)

---

## Task 2: tier-2 신설 — notify.md 생성 + 로더 import (TDD Green 부분)

### 2-1. notify.md 생성 + hk-align import
- [x] `sources/governance/notify.md` 생성: 선택지 제시 규약 + 알림 프로토콜 §1~§10 + 마크다운 컨벤션 이전 (§ 번호 보존, verbatim relocation)
- [x] `sources/commands/hk-align.md` §1 로딩 목록에 `- @.harness-kit/agent/notify.md` 추가
- [x] `bash tests/test-two-tier-loading.sh` → Check 6/7 PASS (Check 4/8 은 Task 3 까지 FAIL 예상)
- [x] Commit: `feat(spec-x-fragment-two-tier-restore): add tier-2 notify.md and align loader import`

---

## Task 3: tier-1 정리 — fragment slim + 패턴 이전 (TDD Green 완료)

### 3-1. fragment 슬림화 + 패턴 align.md 이전
- [x] `sources/governance/align.md` 말미에 "검증된 패턴 & 안티패턴" 섹션 이전
- [x] `sources/claude-fragments/CLAUDE.fragment.md` 를 핵심 규칙 요약 + tier-2 포인터 1줄로 축소
- [x] `wc -w` ≤150 확인 (113w)
- [x] `bash tests/test-two-tier-loading.sh` → 전체 PASS (10/10)
- [x] Commit: `refactor(spec-x-fragment-two-tier-restore): slim fragment to summary, move detail to tier-2`

---

## Task 4: 도그푸딩 동기화

### 4-1. 설치본 sync
- [x] 변경 파일 targeted cp: `.harness-kit/CLAUDE.fragment.md`, `.harness-kit/agent/notify.md`, `.harness-kit/agent/align.md`, `.claude/commands/hk-align.md`
- [x] `bash tests/test-governance-dedup.sh` → PASS (8/8). sources↔설치본 diff 4건 모두 일치
- [x] 영향 테스트 회귀 점검 → install/context/director/config/queue/export 전부 PASS. 사전 존재 실패 2건(sdd-drift T1, phase17 4c)은 이 spec 무관 확인 (walkthrough 기록)
- [x] Commit: `chore(spec-x-fragment-two-tier-restore): sync installed copies (dogfood)`

---

## Task N: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] 전체 테스트 실행 → 모두 PASS (`test-two-tier-loading.sh`, `test-governance-dedup.sh`, 그 외 영향 테스트)
- [ ] 코드 리뷰 게이트 (docs-only 성격 — Skip 시 walkthrough 에 사유 1줄)
- [ ] **walkthrough.md 작성** (증거 로그)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] **Ship Commit**: `docs(spec-x-fragment-two-tier-restore): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-fragment-two-tier-restore`
- [ ] **PR 생성**: `/hk-pr-gh` (base = fork main)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 4 (+ Ship) |
| **예상 commit 수** | 4 (test / feat / refactor / chore) + 1 ship |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-16 |
