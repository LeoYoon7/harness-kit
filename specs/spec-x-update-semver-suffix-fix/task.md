# Task List: spec-x-update-semver-suffix-fix

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 phase.md 없음 (queue.md specx 는 sdd 자동 등록 완료)
- [x] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

- [x] `git checkout -b spec-x-update-semver-suffix-fix`
- [x] Commit: 없음 (브랜치 생성만)

---

## Task 2: 단위 테스트 작성 (TDD Red)

- [x] `tests/test-update-semver.sh` 신규 작성 — `update.sh` 에서 `semver_lt` awk 추출 후 source, plan.md 6개 케이스 검증
- [x] `bash tests/test-update-semver.sh` 실행 → suffix 케이스에서 `leo: unbound variable` crash(Red) 확인
- [x] Commit: `test(spec-x-update-semver-suffix-fix): add semver_lt suffix crash test`

---

## Task 3: semver_lt fix 구현 (TDD Green)

- [x] `update.sh` 의 `semver_lt` 에 선행 숫자 정규화 2줄 추가 (`${x%%[!0-9]*}` + `:-0` fallback)
- [x] `bash tests/test-update-semver.sh` 실행 → ALL PASS(6/6, Green) 확인
- [x] Commit: `fix(spec-x-update-semver-suffix-fix): strip pre-release suffix in semver_lt`

---

## Task 4: 회귀 + Ship

- [ ] `bash .harness-kit/bin/sdd test passed` → 회귀 PASS
- [ ] **walkthrough.md 작성** (증거 로그)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] **Ship Commit**: `docs(spec-x-update-semver-suffix-fix): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-update-semver-suffix-fix`
- [ ] **PR 생성**: `/hk-pr-gh` 또는 `gh pr create` (base = fork main)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 4 (Pre-flight 제외) |
| **예상 commit 수** | 3 (Task 2 + Task 3 + Ship) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-01 |
