# Task List: spec-x-gitignore-archive-coverage

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 업데이트 (queue.md specx 섹션 — sdd 자동)
- [ ] 사용자 Plan Accept

---

## Task 1: 가드 테스트 (TDD Red)

### 1-1. 브랜치 생성
- [ ] `git checkout -b spec-x-gitignore-archive-coverage`
- [ ] Commit: 없음 (브랜치 생성만)

### 1-2. 실패 테스트 작성
- [ ] `tests/test-gitignore-config.sh` 에 `archive/specs/**/code-review*.md` 커버 케이스 추가 (`.gitignore` + install fixture 출력)
- [ ] `tests/test-doctor-ignore-coverage.sh` 에 archive 패턴 doctor 점검 케이스 추가
- [ ] 실행 → Fail 확인 (현재 패턴 미존재)
- [ ] Commit: `test(spec-x-gitignore-archive-coverage): add failing guard for archive review-output coverage`

---

## Task 2: symmetry 사이트 fix (TDD Green, 원자)

> ADR-005 symmetry — 세 사이트를 한 commit 으로 동기 변경.

- [ ] `.gitignore` — `archive/specs/**/code-review*.md` 추가
- [ ] `install.sh` (~552) — `_gi_ensure` archive 라인 추가
- [ ] `uninstall.sh` — awk 제거 패턴에 archive 라인 추가 (install/uninstall 대칭, ADR-005)
- [ ] `sources/bin/sdd` (~2383) — doctor 점검에 archive 패턴 추가
- [ ] `.harness-kit/bin/sdd` — sdd 변경 미러 동기 (parity)
- [ ] 테스트 실행 → Pass 확인 (test-gitignore-config / test-doctor-ignore-coverage / governance-dedup 미러 parity)
- [ ] Commit: `fix(spec-x-gitignore-archive-coverage): cover archive review outputs in ignore symmetry sites`

---

## Task 3: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차.

- [ ] 코드 리뷰 게이트 — `/hk-gemini-review` 또는 `/hk-code-review` 또는 Skip(사유 기록)
- [ ] 전체 영향권 테스트 실행 → 모두 PASS
- [ ] **walkthrough.md 작성**
- [ ] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-x-gitignore-archive-coverage): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-gitignore-archive-coverage`
- [ ] **PR 생성**: `gh pr create` (base = `main`, repo = fork)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고
- [ ] 머지 후: `sdd specx done gitignore-archive-coverage`

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 3 (가드 + fix + Ship) |
| **예상 commit 수** | 3 |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-08 |
