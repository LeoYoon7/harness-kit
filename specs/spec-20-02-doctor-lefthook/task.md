# Task List: spec-20-02

> 모든 task 는 한 commit 에 대응 (One Task = One Commit). TDD 는 test/impl 2 commit.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 업데이트 (phase-20.md SPEC 표 — sdd 자동 갱신)
- [x] 사용자 Plan Accept

---

## Task 1: lefthook × hooksPath 검사 추가 (TDD)

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-20-02-doctor-lefthook` (phase-20-upstream-parity 기준)
- [x] Commit: 없음

### 1-2. 검사 테스트 작성 (TDD Red)
- [x] `tests/test-doctor-hookspath-lefthook.sh` (upstream 테스트 충실 포팅 — fork lib 구조 호환)
- [x] 실행 → **Fail 확인** (PASS 2 / FAIL 2 — Case 1·2 검사 미구현)
- [x] Commit: `test(spec-20-02): add failing test for lefthook×hooksPath doctor check`

### 1-3. 검사 구현 (TDD Green)
- [ ] `sources/bin/sdd` + `.harness-kit/bin/sdd` `cmd_doctor()` 에 `_check_lefthook_hookspath()` + `_check_hooks` 직후 호출
- [ ] `doctor.sh` 에 동일 검사
- [ ] sdd sources↔installed 해당 블록 동일 확인
- [ ] 실행 → **Pass 확인** + 기존 doctor 회귀 없음
- [ ] Commit: `fix(spec-20-02): detect lefthook×core.hooksPath conflict in doctor`

---

## Task 2: Ship (필수)

- [ ] `bash tests/test-doctor-hookspath-lefthook.sh` → PASS
- [ ] `bash .harness-kit/bin/sdd doctor` 실행 → 기존 출력 회귀 없음 육안 확인
- [ ] **walkthrough.md 작성**
- [ ] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-20-02): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-20-02-doctor-lefthook`
- [ ] **코드 리뷰 게이트** (§6.3 — additive 진단 검사; skip 시 사유 기록)
- [ ] **PR 생성**: base `phase-20-upstream-parity`
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 1 (+ Ship) |
| **예상 commit 수** | 2 (test + impl) + ship |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-04 |
