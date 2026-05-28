# Task List: spec-x-dogfood-sync

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 (`spec-x-dogfood-sync`) 및 디렉토리 생성
- [x] 브랜치 생성 (`git checkout -b spec-x-dogfood-sync` — sdd specx new state 부재로 수동 부트스트랩)
- [x] spec.md 작성 (critique 반영본)
- [x] plan.md 작성 (critique 반영본)
- [x] critique.md 작성 (`/hk-spec-critique` 결과)
- [x] task.md 작성 (이 파일, critique 반영본)
- [x] 사용자 Plan Accept (응답 "1" — constitution §5.2; `sdd plan accept` 는 state 부재로 실패하나 hook fallback 으로 진행)

---

## Task 0: spec 산출물 commit 분리 (sync diff 와 격리)

> Plan Accept 직후 *첫 commit*. spec 작성 diff 와 update.sh 결과 sync diff 가 한 commit 에 섞이지 않도록 분리 (critique 누락 #5 반영).

### 0-1. spec 산출물 commit
- [x] `git add specs/spec-x-dogfood-sync/spec.md specs/spec-x-dogfood-sync/plan.md specs/spec-x-dogfood-sync/task.md specs/spec-x-dogfood-sync/critique.md`
- [x] `git status --porcelain` — 위 4개 파일만 staged (walkthrough.md stub 은 Ship 까지 untracked 유지)
- [x] Commit: `docs(spec-x-dogfood-sync): add spec/plan/task/critique`

---

## Task 1: `update.sh` 실행 + 결과 sync commit

> 본 PR 의 본체. uninstall(state 보존) → install → state 복원 → doctor 가 한 번에 수행.
> **실행 중 다른 도구 호출 금지** (critique 누락 #1) — Bash 직렬 호출만.

### 1-1. 사전 baseline 캡처 (read-only)
- [x] `diff -rq sources/governance .harness-kit/agent` → agent.md 만 등장 확인
- [x] `git status --porcelain` → Task 0 commit 후 워킹트리에 spec walkthrough stub 만 untracked
- [x] install.sh cp 매핑 sanity 확인
- [x] Commit: 없음

### 1-2. `bash update.sh --yes` 실행 (직렬 단일 호출)
- [x] `bash update.sh --yes` → exit 0 (병렬 도구 호출 없음)
- [x] doctor: PASS 48 / WARN 1 (MINGW OS, 알려진 non-blocking) / FAIL 0
- [x] Commit: 없음

### 1-3. 결과 검증 + 단일 sync commit
- [x] `diff -rq sources/governance .harness-kit/agent` → templates 디렉토리 외 모두 동기화 (templates 는 별도 비교)
- [x] `diff -rq sources/templates .harness-kit/agent/templates` → 빈 출력
- [x] notify dispatcher 4 + 루트 런처 2 + state 파일 모두 존재 확인
- [x] **placeholder 사전 분석**: `.env.*.example` 의 값이 빈 placeholder 라 시크릿 할당 패턴 (`<KEY>=<VAL>` 형태로 우변이 비어있지 않은 경우) 불일치하나 *파일명* 자체가 `(^|/)\.env(\..+)?$` 에 false positive 매칭됨 (critique 예측 확정). → 회피: **`.env.*.example` 을 .gitignore 에 추가** (self-host 전용, install 이 매번 재생성하는 아티팩트 처리). 본 결정은 queue.md Icebox 의 "check-secrets.sh `.env.*.example` 패턴 제외 fix" 후속 spec 으로 추적.
- [x] `git add -u` + 신규 sync 파일 6개 명시적 stage (walkthrough.md stub 제외)
- [x] `git diff --cached --stat` → 41 files, +6163/-5229
- [x] Commit `bff0c01`: `chore(spec-x-dogfood-sync): apply update.sh — sync installed kit assets with sources@v0.13.6`

### 1-4. 실행 비트 보정 (Windows MINGW 후속)
- [x] **발견**: `core.fileMode=false` (Windows MINGW) 로 인해 신규 `*.sh` 6개가 `100644` 로 commit 됨. sources 의 동일 파일은 `100755`. blob 내용은 동일하나 *index 의 실행 비트* 가 누락 — macOS/Linux 클론 시 기능 깨짐 위험.
- [x] `git update-index --chmod=+x` 로 6개 파일 index 의 실행 비트 박음
- [x] Commit `59e4053`: `chore(spec-x-dogfood-sync): mark installed *.sh as executable in git index`

---

## Task 2: sdd doctor smoke (state 인식 확인)

> critique 과잉설계 반영 — dummy specx new 대신 doctor 로 갈음.

### 2-1. doctor 실행
- [x] `bash .harness-kit/bin/sdd doctor` → exit 0 (ALL PASS)
- [x] `.claude/state/current.json` 인식 OK (설치 파일 ✅, 훅 파일 ✅)
- [x] `git status --porcelain` → in-progress task.md 만 modified (다른 영향 없음)
- [x] Commit: 없음 (read-only 검증)

---

## Task 3: 회귀 테스트 (영향권 한정)

### 3-1. install 멱등성 / 레이아웃 회귀
- [x] `bash tests/test-gitignore-idempotent.sh` → 22/22 PASS
- [x] `bash tests/test-install-layout.sh` → 15/15 PASS
- [x] Commit: 없음 (read-only 검증)

---

## Task 4: backlog/queue.md Icebox 등록 (재발 방지 후속)

> critique 권장안 — walkthrough 캡처만으론 약함. queue.md Icebox 에 *즉시* 등록하여 후속 작업 트래킹 보장.

### 4-1. queue.md Icebox 항목 추가
- [x] `backlog/queue.md` 의 Icebox 섹션에 다음 **3개** 항목 추가 (Task 1-3 의 secret false positive 발견으로 +1):
  - 도그푸딩 sync 자동화 (drift 가시화 — sdd doctor / CI / post-merge auto-update)
  - ADR-NNN-dogfood-sync-policy 작성 (convention) — 본 PR 머지 직후
  - `check-secrets.sh` `.env.*.example` 패턴 제외 fix
- [x] `git add backlog/queue.md`
- [x] Commit `b9844f9`: `docs(spec-x-dogfood-sync): capture dogfood-sync follow-ups in icebox`

---

## Task N: Ship (필수)

> 모든 작업 task 완료 후 walkthrough/pr_description 작성 + push + PR.

### N-1. 산출물 작성
- [x] **walkthrough.md 작성** — 결정 기록 5개 / 사용자 협의 2건 / 검증 결과 / 발견 사항 4개 / 이월 항목 3개 + ADR 후보 [x]
- [x] **pr_description.md 작성** — Summary / Key Review Points 4개 / Verification / Files Changed / DoD / 관련 자료
- [x] task.md 모든 체크박스 `[x]` 또는 `[-]` 확인 (이 commit 에서 함께 staged)
- [ ] **Ship Commit**: `docs(spec-x-dogfood-sync): ship walkthrough and pr description`

### N-2. Push + PR
- [ ] **Push**: `git push -u origin spec-x-dogfood-sync`
- [ ] **PR 생성**: `/hk-pr-gh` 호출 — 확인 블록에서 base=`LeoYoon7/harness-kit:main`, head=`LeoYoon7:spec-x-dogfood-sync` 명시 확인 (upstream 오송신 방지)
- [ ] **사용자 알림**: fork PR URL 보고 + 머지 대기

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 4 + Ship |
| **실제 commit 수** | 5 (spec docs 1 + sync 1 + chmod fix 1 + icebox 1 + ship 1) — chmod fix 는 Windows MINGW 후속 보정 |
| **현재 단계** | Ship 직전 |
| **마지막 업데이트** | 2026-05-28 |
