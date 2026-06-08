# Task List: spec-x-gemini-review-edgecases

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성 (`sdd specx new gemini-review-edgecases`)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 — spec-x 라 phase.md 불요. queue.md specx 마커 등록 완료(specx new).
- [ ] 사용자 Plan Accept

---

## Task 1: 브랜치 생성 + 계획 산출물 커밋

### 1-1. 브랜치 생성
- [ ] `git checkout -b spec-x-gemini-review-edgecases` (main 기준 사전 분기)
- [ ] Commit: 없음 (브랜치 생성만)

### 1-2. 계획 산출물 커밋
- [ ] `git add specs/spec-x-gemini-review-edgecases/{spec,plan,task}.md backlog/queue.md`
- [ ] Commit: `docs(spec-x-gemini-review-edgecases): add spec/plan/task`

---

## Task 2: 검증 테스트 추가 (TDD Red)

### 2-1. T6/T7 테스트 작성
- [ ] `tests/test-gemini-review-guard.sh` — stub `gemini` 에 `capture` 모드 추가(argv/stdin 을 repo 밖 `$CAPTURE_DIR` 로 기록).
- [ ] **T6**: argv 순수 ASCII 검증(`LC_ALL=C grep '[^[:print:][:space:]]'` 무매치) + 지시문이 stdin 에 존재.
- [ ] **T7**: state.json `baseBranch`=`phase-99-missing` 주입 → 리뷰 성공(main fallback) + 리뷰 파일 생성.
- [ ] 테스트 실행 → Fail 확인 (T6/T7 Red, 기존 T1~T5 유지)
- [ ] Commit: `test(spec-x-gemini-review-edgecases): add edge-case tests for argv safety and base fallback`

---

## Task 3: (b) 비-ASCII argv 안전 구현 (TDD Green)

### 3-1. 지시문을 argv → stdin 이동
- [ ] `sources/bin/gemini-review.sh`: INPUT_FILE 최상단에 `INSTRUCTION` prepend, `-p` 를 ASCII 영어 포인터로 교체.
- [ ] `.harness-kit/bin/gemini-review.sh` 미러 동기화 (`cp`).
- [ ] 테스트 실행 → T6 Green
- [ ] Commit: `fix(spec-x-gemini-review-edgecases): pass reviewer instruction via stdin to avoid non-ascii argv`

---

## Task 4: (a) base 브랜치 fallback 구현 (TDD Green)

### 4-1. base 실재 확인 + main fallback
- [ ] `sources/bin/gemini-review.sh`: base 결정부 뒤 `git rev-parse --verify --quiet "${BASE}^{commit}"` 가드 추가 (부재 + base≠main → main fallback + ⚠).
- [ ] `.harness-kit/bin/gemini-review.sh` 미러 동기화 (`cp`).
- [ ] 테스트 실행 → T7 Green (전체 14/14)
- [ ] Commit: `fix(spec-x-gemini-review-edgecases): fall back to main when phase base branch is absent`

---

## Task 5: stale Icebox 라인 정리

### 5-1. queue.md Icebox 정리
- [ ] plan-mode 위반 라인 → strike-through + `spec-x-gemini-review-sandbox` 해결 참조.
- [ ] 엣지케이스 2종 라인 → strike-through + `spec-x-gemini-review-edgecases` 해결 참조.
- [ ] Commit: `chore(spec-x-gemini-review-edgecases): tidy resolved gemini-review icebox items`

---

## Task 6: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] 전체 테스트 실행 → `test-gemini-review-guard.sh` 14/14 PASS + 회귀 무
- [ ] 코드 리뷰 게이트 — **Opus(/hk-code-review)** (gemini 가 본 spec 의 수정 대상 → 자기 리뷰 회피, sandbox 와 동일 논리)
- [ ] **walkthrough.md 작성**
- [ ] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-x-gemini-review-edgecases): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-gemini-review-edgecases`
- [ ] **PR 생성**: `gh pr create --base main` (spec-x → main)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고
- [ ] **specx done** (post-merge): `sdd specx done gemini-review-edgecases`

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 6 (계획커밋 + 테스트 + fix×2 + 정리 + Ship) |
| **예상 commit 수** | 6 (docs-plan / test / fix-b / fix-a / chore / ship) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-09 |
