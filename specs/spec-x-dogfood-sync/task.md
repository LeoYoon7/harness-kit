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
- [ ] 사용자 Plan Accept

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
- [ ] `diff -rq sources/governance .harness-kit/agent | tee /tmp/dogfood-pre-diff.txt` — 기대: agent.md 만 등장
- [ ] `git status --porcelain` — Task 0 commit 후 워킹트리 클린 확인
- [ ] install.sh 매핑 sanity 확인: `grep -E "^(cp |install_|copy_)" install.sh | head -20`
- [ ] Commit: 없음

### 1-2. `bash update.sh --yes` 실행 (직렬 단일 호출)
- [ ] `bash update.sh --yes` → exit 0 확인 — **이 호출 동안 다른 Bash/Edit/Write 발사 금지**
- [ ] doctor 출력 모두 ✓ 또는 ⚠ (non-blocking) — ✗ 있으면 STOP + 보고
- [ ] Commit: 없음 (단일 sync commit 은 1-3 에서)

### 1-3. 결과 검증 + 단일 sync commit
- [ ] `diff -rq sources/governance .harness-kit/agent` → 빈 출력
- [ ] `diff -rq sources/templates .harness-kit/agent/templates` → 빈 출력
- [ ] `ls .harness-kit/hooks/notify-on-input-wait.sh .harness-kit/bin/notify.sh .harness-kit/bin/notify-telegram.sh .harness-kit/bin/notify-discord.sh` → 모두 존재
- [ ] `ls telegram.sh discord.sh .env.telegram.example .env.discord.example` → 모두 존재
- [ ] `ls .claude/state/current.json` → 존재
- [ ] **placeholder secret 검증**: `.env.telegram.example` / `.env.discord.example` 가 `check-secrets.sh` false positive 안 걸림 확인 (`bash .harness-kit/hooks/check-secrets.sh` dry-run 또는 staged 상태에서 한 번 commit 시도해 통과)
- [ ] `git add -A`
- [ ] `git diff --stat --cached` → LF 단일성 + 변경 범위 확인 (~1500줄 예상)
- [ ] Commit: `chore(spec-x-dogfood-sync): apply update.sh — sync installed kit assets with sources@v0.13.6`
  - check-diff-size warn 출력 정상 (block 아님). PR 본문에 노이즈 기록 예정.

---

## Task 2: sdd doctor smoke (state 인식 확인)

> critique 과잉설계 반영 — dummy specx new 대신 doctor 로 갈음.

### 2-1. doctor 실행
- [ ] `bash .harness-kit/bin/sdd doctor` → exit 0
- [ ] `.claude/state/current.json` 인식되어 state 관련 경고 없음
- [ ] `git status --porcelain` → 클린 (doctor 가 워킹트리 안 건드림)
- [ ] Commit: 없음 (read-only 검증)

---

## Task 3: 회귀 테스트 (영향권 한정)

### 3-1. install 멱등성 / 레이아웃 회귀
- [ ] `bash tests/test-gitignore-idempotent.sh` → 22/22 PASS
- [ ] `bash tests/test-install-layout.sh` → 15/15 PASS
- [ ] 다른 결과 시 → STOP + 보고
- [ ] Commit: 없음 (read-only 검증)

---

## Task 4: backlog/queue.md Icebox 등록 (재발 방지 후속)

> critique 권장안 — walkthrough 캡처만으론 약함. queue.md Icebox 에 *즉시* 등록하여 후속 작업 트래킹 보장.

### 4-1. queue.md Icebox 항목 추가
- [ ] `backlog/queue.md` 의 Icebox 섹션에 다음 2개 항목 추가:
  - `도그푸딩 sync 자동화 — sdd doctor 의 sources vs installed drift 경고 / CI check / post-merge auto-update 옵션 검토 (#spec-x-dogfood-sync 후속)`
  - `ADR-NNN-dogfood-sync-policy 작성 (convention) — sources → installed SSOT = update.sh, link 모델 거부, drift-visibility-deferred 흡수 (#spec-x-dogfood-sync 머지 직후)`
- [ ] `git add backlog/queue.md`
- [ ] `git diff --cached --stat` → queue.md 만 변경
- [ ] Commit: `docs(spec-x-dogfood-sync): capture dogfood-sync follow-ups in icebox`

---

## Task N: Ship (필수)

> 모든 작업 task 완료 후 walkthrough/pr_description 작성 + push + PR.

### N-1. 산출물 작성
- [ ] **walkthrough.md 작성** — 증거 로그:
  - `update.sh` stdout 요약 + `git diff --stat` 발췌
  - critique 권장안 9개 반영 결과 요약
  - 후속 ideabox (queue.md Icebox 등록 완료) 링크
- [ ] **pr_description.md 작성** — 한국어, 템플릿 준수:
  - 배경: drift 표 + 영향
  - 변경 요약: update.sh 1회 호출 + 4 commit 구조
  - check-diff-size warn 노이즈 정당화 (~1500줄 예상)
  - critique 반영 항목 목록
  - 후속: queue.md Icebox 등록 항목
- [ ] **Ship Commit**: `docs(spec-x-dogfood-sync): ship walkthrough and pr description`
- [ ] task.md 모든 체크박스 `[x]` 또는 `[-]` 확인

### N-2. Push + PR
- [ ] **Push**: `git push -u origin spec-x-dogfood-sync`
- [ ] **PR 생성**: `/hk-pr-gh` 호출
  - 확인 블록에서 **base = `LeoYoon7/harness-kit:main`**, **head = `LeoYoon7:spec-x-dogfood-sync`** 명시 확인 (upstream 오송신 방지)
  - 또는 직접: `gh pr create --repo LeoYoon7/harness-kit --base main --head LeoYoon7:spec-x-dogfood-sync --title <PR_TITLE> --body-file specs/spec-x-dogfood-sync/pr_description.md`
- [ ] **사용자 알림**: fork PR URL 보고 + 머지 대기

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 4 + Ship |
| **예상 commit 수** | 4 (spec docs 1 + sync 1 + icebox 1 + ship 1) |
| **현재 단계** | Planning (critique 반영 완료) |
| **마지막 업데이트** | 2026-05-28 |
