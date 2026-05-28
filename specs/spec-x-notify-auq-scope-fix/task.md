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
- [ ] `git add backlog/queue.md specs/spec-x-notify-auq-scope-fix/`
- [ ] Commit: `chore(spec-x-notify-auq-scope-fix): scaffold spec artifacts and queue update`

---

## Task 3: hook AUQ scope 좁힘 + sync

### 3-1. 키트 원본 수정
- [ ] `sources/hooks/notify-on-input-wait.sh` 의 AUQ_JSON 쿼리를 plan.md MODIFY 블록의 새 형태로 교체
- [ ] Commit: `fix(spec-x-notify-auq-scope-fix): scope AskUserQuestion extraction to last assistant turn`

### 3-2. 도그푸딩 sync
- [ ] `cp sources/hooks/notify-on-input-wait.sh .harness-kit/hooks/notify-on-input-wait.sh`
- [ ] `chmod +x .harness-kit/hooks/notify-on-input-wait.sh`
- [ ] Commit: `chore(spec-x-notify-auq-scope-fix): sync notify-on-input-wait.sh to installed hooks`

---

## Task 4: Smoke test — 5 케이스 (1 신규 + 4 회귀)

### 4-1. 신규 케이스 (FP-stale)
- [ ] transcript: AUQ tool_use + user tool_result + assistant text + Bash tool_use (plan.md sample)
- [ ] hook 호출 (Notification + 권한 메시지)
- [ ] 기대 PASS: `"권한 승인 대기"` brief — (c) 미선택

### 4-2. 회귀 (a) 순수 권한
- [ ] PR #8 (a) 케이스 재실행
- [ ] 기대 PASS: `"권한 승인 대기"` brief

### 4-3. 회귀 (b) 텍스트 선택지
- [ ] PR #8 (b) 케이스 재실행
- [ ] 기대 PASS: `"사용자 선택 대기"` + transcript 발췌

### 4-4. 회귀 (c) AUQ 정상
- [ ] PR #8 (c) 케이스 재실행 — 마지막 turn 안 AUQ
- [ ] 기대 PASS: `"사용자 질문 대기"` + 질문/옵션

### 4-5. 회귀 (FP) 회고텍스트
- [ ] PR #8 (FP) 케이스 재실행
- [ ] 기대 PASS: `"사용자 입력 대기 중"` 일반

### 4-6. Commit
- [ ] Commit: 없음 (smoke test 만, walkthrough 기록)

---

## Task 5: Ship

> §1.5 리뷰 게이트 — 사용자에게 Gemini/Opus/Skip 선택 제시 (직접 결정 임의 skip 금지).

- [ ] §1.5 리뷰 게이트 선택지 제시 → 사용자 응답
- [-] 단위 테스트 → skip
- [ ] **walkthrough.md 작성** (5 케이스 smoke 결과, stale AUQ 실증 사례 캡처)
- [ ] **pr_description.md 작성**
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
