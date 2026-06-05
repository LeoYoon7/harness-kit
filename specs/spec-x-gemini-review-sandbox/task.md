# Task List: spec-x-gemini-review-sandbox

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성 (`sdd specx new gemini-review-sandbox`)
- [x] 브랜치 생성 — `spec-x-gemini-review-sandbox` (main 에서 사전 분기)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 — spec-x 라 phase.md 불요. queue.md specx 마커 등록 완료(specx new).
- [x] 사용자 Plan Accept

---

## Task 1: 검증 테스트 (TDD Red)

> 브랜치는 사전 생성됨(main 기준). 본 task 는 테스트부터.

### 1-1. 테스트 작성 (TDD Red)
- [ ] `tests/test-gemini-review-guard.sh` 작성 — stub `gemini`(PATH 주입) + make_fixture. T1 rogue commit 감지+원복+리뷰파일 부재, T2 rogue 파일쓰기 감지, T3 비-리뷰 출력 거부, T4 정상 리뷰 성공.
- [ ] 테스트 실행 → Fail 확인 (현 gemini-review.sh 는 부수효과 무감지 → T1~T3 Red)
- [ ] Commit: `test(spec-x-gemini-review-sandbox): add guard test for workspace mutation`

---

## Task 2: 방어적 래퍼 구현 (TDD Green)

### 2-1. gemini-review.sh 하드닝
- [ ] `sources/bin/gemini-review.sh`: BEFORE 스냅샷(HEAD+porcelain) → gemini stdout 을 repo 밖 TEMP → AFTER 비교 → 부수효과 시 거부+원격경고+(clean-pre)자동원복+exit1 → 리뷰 형식 검증 → 통과 시 TEMP→OUTPUT_FILE. 헤더 주석 정정.
- [ ] `.harness-kit/bin/gemini-review.sh` 미러 동기화 (cp 로 보장).
- [ ] 검증: `bash tests/test-gemini-review-guard.sh` → **전체 PASS (GREEN)**
- [ ] 회귀: 기존 테스트 무 회귀 (`test-governance-dedup.sh` 등)
- [ ] Commit: `fix(spec-x-gemini-review-sandbox): guard gemini-review against workspace mutation`

---

## Task 3: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] 전체 테스트 실행 → `test-gemini-review-guard.sh` PASS + 회귀 무
- [ ] 코드 리뷰 게이트 — **Opus(/hk-code-review)** (gemini 회피 — 고치는 대상)
- [ ] **walkthrough.md 작성**
- [ ] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-x-gemini-review-sandbox): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-gemini-review-sandbox`
- [ ] **PR 생성**: `gh pr create --base main` (spec-x → main, leaked baseBranch 무시)
- [ ] **specx done**: `sdd specx done gemini-review-sandbox` (머지 후, queue.md done 이동)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 3 (작업 2 + Ship) |
| **예상 commit 수** | 4 (planning / test / fix / ship) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-05 |
