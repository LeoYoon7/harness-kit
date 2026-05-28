# Task List: spec-x-gemini-review

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성 (`sdd specx new gemini-review`)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [ ] 사용자 Plan Accept

> 본 spec 은 spec-x 이므로 phase.md 갱신 단계 없음.

---

## Task 1: 브랜치 생성

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-gemini-review`
- [x] Commit: 없음 (브랜치 생성만)

---

## Task 2: `gemini-review.sh` 신규 작성

### 2-0. Spec 스캐폴드 commit (pre-flight 산출물 정리)
- [ ] `git add backlog/queue.md specs/spec-x-gemini-review/`
- [ ] Commit: `chore(spec-x-gemini-review): scaffold spec artifacts and queue update`

### 2-1. 키트 원본 작성
- [ ] `sources/bin/gemini-review.sh` 작성 (plan.md §Proposed Changes 의 NEW 블록 참조)
- [ ] 실행 권한 부여: `chmod +x sources/bin/gemini-review.sh`
- [ ] Commit: `feat(spec-x-gemini-review): add gemini-review.sh for cross-model code review`

### 2-2. 도그푸딩 sync
- [ ] `cp sources/bin/gemini-review.sh .harness-kit/bin/gemini-review.sh`
- [ ] `chmod +x .harness-kit/bin/gemini-review.sh`
- [ ] Commit: `chore(spec-x-gemini-review): sync gemini-review.sh to installed bin`

### 2-3. 수동 smoke test
- [ ] `bash .harness-kit/bin/gemini-review.sh` 실행 (현재 spec 자체에 적용)
- [ ] `specs/spec-x-gemini-review/code-review-gemini.md` 가 생성되었는지 확인
- [ ] Critical/Major/Minor 요약이 stderr 로 출력되는지 확인
- [ ] 실패 케이스 (no spec / no diff) 도 빠르게 한 번 확인
- [ ] Commit: 없음 (검증만 — 생성된 review 파일은 본 task 가 아닌 별도 결정으로 PR 에 포함할지 결정. 기본은 포함 안 함 = .gitignore 또는 명시적 add 안 함)

> 검증 후 생성된 `code-review-gemini.md` 는 본 PR 에 포함하지 *않는다* (리뷰 결과는 spec 산출물이 아니라 일회성 검증 결과). git status 에서 제외 처리.

---

## Task 3: `/hk-gemini-review` 슬래시 커맨드 추가

### 3-1. 키트 원본 작성
- [ ] `sources/commands/hk-gemini-review.md` 작성 (plan.md §Proposed Changes 의 NEW 블록 참조)
- [ ] Commit: `feat(spec-x-gemini-review): add /hk-gemini-review slash command`

### 3-2. 도그푸딩 sync
- [ ] `cp sources/commands/hk-gemini-review.md .claude/commands/hk-gemini-review.md`
- [ ] Commit: `chore(spec-x-gemini-review): sync hk-gemini-review command to installed commands`

---

## Task 4: `/hk-ship` 리뷰 게이트 삽입

### 4-1. 키트 원본 수정
- [ ] `sources/commands/hk-ship.md` 의 §1 직후, §2 직전에 §1.5 코드 리뷰 게이트 블록 삽입 (plan.md §Proposed Changes 의 MODIFY 블록 참조)
- [ ] Commit: `feat(spec-x-gemini-review): add review gate to /hk-ship pre-flight`

### 4-2. 도그푸딩 sync
- [ ] `cp sources/commands/hk-ship.md .claude/commands/hk-ship.md`
- [ ] Commit: `chore(spec-x-gemini-review): sync hk-ship.md to installed commands`

---

## Task 5: `agent.md` §6.3 갱신

### 5-1. 키트 원본 수정
- [ ] `sources/governance/agent.md` §6.3 Walkthrough & Description Protocol 마지막에 "Code Review Gate (선택)" 한 줄 추가
- [ ] Commit: `docs(spec-x-gemini-review): document review gate in agent.md §6.3`

### 5-2. 도그푸딩 sync
- [ ] `cp sources/governance/agent.md .harness-kit/agent/agent.md`
- [ ] Commit: `chore(spec-x-gemini-review): sync agent.md to installed governance`

---

## Task 6: Ship

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] 본 spec 자체에 신규 §1.5 게이트가 발화되는지 확인 (dogfood smoke). 본 게이트에서 "1) Gemini" 를 선택해 self-review 실행.
- [ ] Gemini 리뷰 결과의 Critical 이슈 점검. 있으면 해결 후 재 ship 또는 사용자에게 보고.
- [ ] 단위 테스트 없음 → skip
- [ ] **walkthrough.md 작성** (수동 smoke test 결과, Gemini 리뷰 발견사항 요약, 도그푸딩 sync 확인)
- [ ] **pr_description.md 작성** (변경 요약, 동기, cross-model 리뷰 이론적 근거, 사용법 예시)
- [ ] **Ship Commit**: `docs(spec-x-gemini-review): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-gemini-review`
- [ ] **PR 생성**: `/hk-pr-gh --no-confirm` (LeoYoon7/harness-kit fork main 으로)
- [ ] **사용자 알림**: 푸시 완료 + PR URL Telegram 보고 (ship 레벨)

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 6 |
| **예상 commit 수** | 10 (브랜치 생성 제외) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-05-28 |
