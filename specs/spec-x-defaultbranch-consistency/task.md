# Task List: spec-x-defaultbranch-consistency

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 phase.md 갱신 불요 (constitution §5.1). 완료 시 `sdd specx done`
- [x] 사용자 Plan Accept (critique 1회 수행 후)

---

## Task 1: base 해석 체인 회귀 테스트 (TDD Red)

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-defaultbranch-consistency`

### 1-2. 테스트 작성 (Red)
- [x] 신규 `tests/test-sdd-base-resolution.sh` — sdd source 후 `_resolve_base_branch` 직접 단위 테스트(test-sdd-ship-scope 패턴). fixture: git repo + state.json + installed.json + develop 브랜치 실제 생성. 6 케이스(baseBranch 우선 / defaultBranch / 둘다없음→main / installed 부재→main / JIT 미존재→defaultBranch / defaultBranch 미존재→main)
- [x] 실행 → Fail 확인 (helper 미정의, exit 1)
- [x] Commit: `test(spec-x-defaultbranch-consistency): assert base resolution chain`

---

## Task 2: sdd `_resolve_base_branch()` 헬퍼 + 하드코딩 대체 (Green)

### 2-1. 헬퍼 도입 + 적용
- [x] `sources/bin/sdd` 에 `_resolve_base_branch()` 신설 — baseBranch → defaultBranch → main, 각 후보 `git rev-parse --verify` 실재 확인 후 미존재면 다음 단계 (2단 fallback) + installed.json/jq/null graceful 가드
- [x] 517, 1941 의 하드코딩 블록을 헬퍼 호출로 대체
- [x] `test-sdd-base-resolution.sh` 6/6 PASS, `bash -n` OK, `test-sdd-base-branch.sh` 4/4 PASS. (status-cross-check·phase-done-accuracy 의 사전 실패 2건은 stash 비교로 내 변경 무관 확정 — fixture 가 master 브랜치/미구현 placeholder)
- [x] Commit: `refactor(spec-x-defaultbranch-consistency): resolve base branch via defaultBranch chain`

---

## Task 3: hk-ship / hk-cleanup 커맨드 defaultBranch 정합

### 3-1. 커맨드 문서 정합
- [x] `hk-ship.md` — **정정**: plan 의 "line 139 병합" 은 phase-base-mode 감지를 깨므로, 별도 `default_branch` 추출(status --json 캐시) + line 144 `checkout -b ... "$default_branch"` + line 150 `PR_BASE="$default_branch"` 로 적용. line 139 는 baseBranch 전용 유지 (walkthrough 결정 기록)
- [x] `hk-cleanup.md` defaultBranch `git rev-parse --verify --quiet` 실재 점검 항목 추가
- [x] Commit: `docs(spec-x-defaultbranch-consistency): align hk-ship/hk-cleanup to defaultBranch`

---

## Task 4: constitution §3.3 정합 + ADR-015

### 4-1. 거버넌스 정합 + ADR
- [x] `constitution.md` §3.3 "always main" → "defaultBranch (default main)" + §3.2 `else main` → `else defaultBranch` (→ ADR-015)
- [x] `docs/decisions/ADR-015-review-base-resolution-chain.md` 작성 (type: tradeoff) — 체인 + origin/HEAD 비채택 근거 + init.defaultBranch 구분 + 3벌 부채 가시화 (템플릿 준수)
- [x] 예산 선검증 const+agent = 6400w ≤ 6500. (dedup Check 2 sync 는 설치본 동기화 의존 → Task 5 에서 전체 PASS 검증)
- [x] Commit: `docs(spec-x-defaultbranch-consistency): amend §3.2/§3.3 to defaultBranch and add ADR-015`

---

## Task 5: 도그푸딩 동기화

### 5-1. 설치본 sync
- [x] targeted cp: `.harness-kit/bin/sdd`, `.claude/commands/hk-ship.md`, `.claude/commands/hk-cleanup.md`, `.harness-kit/agent/constitution.md` (ADR 은 docs/ 라 설치 대상 아님)
- [x] `bash tests/test-governance-dedup.sh` → 8/8 PASS, sources↔설치본 diff 4쌍 일치
- [x] Commit: `chore(spec-x-defaultbranch-consistency): sync installed copies (dogfood)`

---

## Task N: Ship (필수)

- [ ] 전체 영향 테스트 실행 → PASS (base-branch, governance-dedup, phase-done-accuracy 등)
- [ ] 코드 리뷰 게이트 (sdd 로직 변경 포함 — 리뷰 권장, Skip 시 사유 기록)
- [ ] **walkthrough.md 작성**
- [ ] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-x-defaultbranch-consistency): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-defaultbranch-consistency`
- [ ] **PR 생성**: `/hk-pr-gh` (base = fork main)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 5 (+ Ship) |
| **예상 commit 수** | test / refactor / docs / docs / chore + 1 ship |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-16 |
