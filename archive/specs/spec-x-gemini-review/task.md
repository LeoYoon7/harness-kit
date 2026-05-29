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
- [x] `git add backlog/queue.md specs/spec-x-gemini-review/`
- [x] Commit: `chore(spec-x-gemini-review): scaffold spec artifacts and queue update` (78f449b)

### 2-1. 키트 원본 작성
- [x] `sources/bin/gemini-review.sh` 작성
- [x] 실행 권한 부여: `chmod +x sources/bin/gemini-review.sh`
- [x] Commit: `feat(spec-x-gemini-review): add gemini-review.sh for cross-model code review` (750b289)

### 2-2. 도그푸딩 sync
- [x] `cp sources/bin/gemini-review.sh .harness-kit/bin/gemini-review.sh`
- [x] `chmod +x .harness-kit/bin/gemini-review.sh`
- [x] Commit: `chore(spec-x-gemini-review): sync gemini-review.sh to installed bin` (9a501d2)

### 2-3. 수동 smoke test
- [x] `bash .harness-kit/bin/gemini-review.sh` 실행 (현재 spec 자체에 적용)
- [x] `specs/spec-x-gemini-review/code-review-gemini.md` 생성 확인
- [x] Critical/Major/Minor 요약 stderr 출력 확인 (`Critical 3 / Major 1 / Minor 2`)
- [x] 발견 분석: false positive (Critical 4 — Task 3/4/5 미구현 시점 영향) + 유효 발견 (Major 1 stderr 차단 [이미 fix], Minor 2 sdd path/grep 경직)
- [x] Commit: 없음 — 생성된 review 파일은 본 PR 미포함 (일회성 검증 결과)

### 2-4. Smoke test 발견 fix
- [x] `sources/bin/gemini-review.sh` 추가 개선:
  - `gemini` stderr 캡처 → 호출 실패 시 노출 (mktemp)
  - prompt 를 argv → stdin 전환 (Windows argv 크기 한계 회피)
  - `sdd` 경로를 `$PROJECT_ROOT/.harness-kit/bin/sdd` 명시
  - 요약 추출 grep 패턴 유연화 (`^[-*]\s+`)
- [x] Commit: `fix(spec-x-gemini-review): improve robustness from gemini smoke test findings` (24b7040)

### 2-5. Fix 도그푸딩 sync
- [x] `cp sources/bin/gemini-review.sh .harness-kit/bin/gemini-review.sh`
- [x] `chmod +x .harness-kit/bin/gemini-review.sh`
- [x] Commit: `chore(spec-x-gemini-review): re-sync gemini-review.sh after smoke test fix` (6ecddd0)

---

## Task 3: `/hk-gemini-review` 슬래시 커맨드 추가

### 3-1. 키트 원본 작성
- [x] `sources/commands/hk-gemini-review.md` 작성
- [x] Commit: `feat(spec-x-gemini-review): add /hk-gemini-review slash command` (3306ff8)

### 3-2. 도그푸딩 sync
- [x] `cp sources/commands/hk-gemini-review.md .claude/commands/hk-gemini-review.md`
- [x] Commit: `chore(spec-x-gemini-review): sync hk-gemini-review command to installed commands` (9ffaaaa)

---

## Task 4: `/hk-ship` 리뷰 게이트 삽입

### 4-1. 키트 원본 수정
- [x] `sources/commands/hk-ship.md` 의 §1 직후, §2 직전에 §1.5 코드 리뷰 게이트 블록 삽입
- [x] CRLF → LF 정규화 (Edit tool 부작용 대응)
- [x] Commit: `feat(spec-x-gemini-review): add review gate to /hk-ship pre-flight` (d9c3a86, amended)

### 4-2. 도그푓딩 sync (.claude 는 CRLF 유지 — 기존 sibling 파일 컨벤션 매칭)
- [x] `awk` 로 LF → CRLF 변환 후 `.claude/commands/hk-ship.md` 작성
- [x] Commit: `chore(spec-x-gemini-review): sync hk-ship.md to installed commands` (f428557)

---

## Task 5: `agent.md` §6.3 갱신

### 5-1. 키트 원본 수정
- [x] `sources/governance/agent.md` §6.3 Walkthrough & Description Protocol 8번 항목으로 "Code Review Gate (optional)" 한 줄 추가
- [x] Commit: `docs(spec-x-gemini-review): document review gate in agent.md section 6.3` (a91b0ab, amended for shell-escape fix)

### 5-2. 도그푸딩 sync
- [x] `cp sources/governance/agent.md .harness-kit/agent/agent.md`
- [x] Commit: `chore(spec-x-gemini-review): sync agent.md to installed governance` (eded566)

---

## Task 6: Ship

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [x] 본 spec 자체에 신규 §1.5 게이트가 발화되는지 확인 (dogfood smoke). 사용자가 "1) Gemini" 선택. 최종 상태에서 재실행 — Approve (Critical 0 / Major 0 / Minor 0).
- [x] Gemini 리뷰 결과의 Critical 이슈 점검. 0건 — 진행.
- [-] 단위 테스트 없음 → skip (bash + 마크다운 변경)
- [x] **walkthrough.md 작성**
- [x] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-x-gemini-review): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-gemini-review`
- [ ] **PR 생성**: `/hk-pr-gh --no-confirm` (LeoYoon7/harness-kit fork main 으로)
- [ ] **사용자 알림**: 푸시 완료 + PR URL Telegram 보고 (ship 레벨)

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 6 |
| **예상 commit 수** | 10 + ship (브랜치 생성 제외). 실제 11 + ship (Task 2 smoke fix 추가) |
| **현재 단계** | Ship |
| **마지막 업데이트** | 2026-05-28 |
