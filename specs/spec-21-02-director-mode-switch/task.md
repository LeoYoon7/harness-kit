# Task List: spec-21-02

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 업데이트 (phase-21.md SPEC 표 — sdd 자동 갱신)
- [ ] 사용자 Plan Accept

---

## Task 1: 실패 테스트 작성 (TDD Red)

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-21-02-director-mode-switch` (base `phase-21-director-mode` 에서 분기)
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. 테스트 작성 (TDD Red)
- [x] `tests/test-director-mode.sh` 작성 (T01~T10 부분집합, `tests/lib/fixture.sh`, `HARNESS_DRIFT_FETCH=0`):
  - T01/T02 커맨드 존재+description / `.claude` 미러 · T03 조회 · T04/T05 on/off · T06/T07 toggle · T08/T09 status 행 · T10 doctor
- [x] `bash tests/test-director-mode.sh` → Fail 확인 (PASS=3 FAIL=7 — 전체 exit 1)
- [x] Commit: `test(spec-21-02): add failing test for director-mode switch`

---

## Task 2: sdd config director-mode + status/doctor (TDD Green — CLI 표면)

> T03~T10 (config/status/doctor) green. T01/T02(커맨드)는 Task 3.

### 2-1. sdd CLI + installed.json + 미러
- [x] `sources/bin/sdd`: help 텍스트 + `cmd_config` `director-mode)` 케이스 + `_config_director_mode()` 함수(`--argjson` boolean) + `cmd_status` Director Mode 행 + `cmd_doctor` 진단
- [x] `.harness-kit/bin/sdd` 미러 동기화 (parity — 도그푸딩 installed 본)
- [x] `.harness-kit/installed.json` `directorMode: false` 추가
- [x] `bash tests/test-director-mode.sh` → T03~T10 PASS 확인 (T01/T02 still red) — PASS=8 FAIL=2
- [x] 실제 동작: fixture 통해 검증됨 (T03~T10 모두 PASS)
- [x] Commit: `feat(spec-21-02): add director-mode config toggle + status/doctor`

---

## Task 3: /hk-director 슬래시 커맨드 (TDD Green — 전체)

### 3-1. 커맨드 + 미러
- [ ] `sources/commands/hk-director.md` 작성 (frontmatter description + `sdd config director-mode $ARGUMENTS`)
- [ ] `.claude/commands/hk-director.md` 미러
- [ ] `bash tests/test-director-mode.sh` → 전체 PASS (T01~T10)
- [ ] Commit: `feat(spec-21-02): add /hk-director slash command`

---

## Task 4: Ship (필수)

- [ ] 전체 테스트 (`test-director-mode` 전체 + `test-governance-dedup` 무 NEW 회귀)
- [ ] **walkthrough.md 작성**
- [ ] **pr_description.md 작성**
- [ ] 코드 리뷰 게이트 (§6.3.8): Gemini / Opus / Skip
- [ ] **Ship Commit**: `docs(spec-21-02): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-21-02-director-mode-switch`
- [ ] **PR 생성**: base `phase-21-director-mode`
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 3 (+ Ship) |
| **예상 commit 수** | 4 (test / feat-cli / feat-cmd / ship docs) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-04 |
