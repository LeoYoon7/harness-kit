# Task List: spec-x-notify-auq-scope-fix

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).

## Pre-flight

- [x] Spec ID 확정 (`sdd specx new notify-auq-scope-fix`)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성
- [ ] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-notify-auq-scope-fix`
- [x] Commit: 없음

---

## Task 2: Spec 스캐폴드 commit

### 2-1.
- [x] `git add backlog/queue.md specs/spec-x-notify-auq-scope-fix/`
- [x] Commit: `chore(spec-x-notify-auq-scope-fix): scaffold spec artifacts and queue update` (bafda0b)

---

## Task 3: hook AUQ scope 좁힘 + sync

### 3-1. 키트 원본 수정
- [x] `sources/hooks/notify-on-input-wait.sh` 의 AUQ_JSON 쿼리 scope 좁힘
- [x] Commit: `fix(spec-x-notify-auq-scope-fix): scope AskUserQuestion extraction to last assistant turn` (0940c50)

### 3-2. 도그푸딩 sync
- [x] `cp sources/hooks/notify-on-input-wait.sh .harness-kit/hooks/notify-on-input-wait.sh`
- [x] `chmod +x .harness-kit/hooks/notify-on-input-wait.sh`
- [x] Commit: `chore(spec-x-notify-auq-scope-fix): sync notify-on-input-wait.sh to installed hooks` (b124e91)

---

## Task 4: Smoke test — 5 케이스 (1 신규 + 4 회귀)

### 4-1. 신규 케이스 (FP-stale) — fix 효과 입증
- [x] transcript: AUQ tool_use + user tool_result + assistant text + Bash tool_use
- [x] hook 호출
- [x] PASS: `"권한 승인 대기"` brief — (c) 미선택 ✓

### 4-2. 회귀 (a) 순수 권한
- [x] hook 호출
- [x] PASS: `"권한 승인 대기"` brief ✓

### 4-3. 회귀 (b) 텍스트 선택지
- [x] hook 호출
- [x] PASS: `"사용자 선택 대기"` + transcript 발췌 ✓

### 4-4. 회귀 (c) AUQ 정상
- [x] hook 호출 — 마지막 turn 안 AUQ
- [x] PASS: `"사용자 질문 대기"` + 질문/옵션 ✓

### 4-5. 회귀 (FP) 회고텍스트
- [x] hook 호출
- [x] PASS: `"사용자 입력 대기 중"` 일반 ✓

### 4-6. Commit
- [-] Commit: 없음 (smoke test 만, walkthrough 기록)

---

## Task 5: Ship

> §1.5 리뷰 게이트 — 사용자에게 Gemini/Opus/Skip 선택 제시 (직접 결정 임의 skip 금지).

- [x] §1.5 리뷰 게이트 — 사용자 응답 "Skip" (변경 규모 작고 회귀 검증 완료)
- [-] 단위 테스트 → skip
- [x] **walkthrough.md 작성**
- [x] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-x-notify-auq-scope-fix): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-notify-auq-scope-fix`
- [ ] **PR 생성**: `gh pr create`
- [ ] **사용자 알림**: 푸시 완료 + PR URL Telegram 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 5 |
| **예상 commit 수** | 4 + ship (브랜치 + smoke test 제외) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-05-28 |
