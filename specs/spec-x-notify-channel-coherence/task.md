# Task List: spec-x-notify-channel-coherence

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).

## Pre-flight

- [x] Spec ID 확정 (`sdd specx new notify-channel-coherence`)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성
- [ ] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

### 1-1.
- [x] `git checkout -b spec-x-notify-channel-coherence`
- [x] Commit: 없음

---

## Task 2: Spec 스캐폴드 commit

### 2-1.
- [ ] `git add backlog/queue.md specs/spec-x-notify-channel-coherence/`
- [ ] Commit: `chore(spec-x-notify-channel-coherence): scaffold spec artifacts and queue update`

---

## Task 3: Fragment §5 갱신 — AUQ 시 §5 stop 자동 생략

### 3-1. 키트 원본 수정
- [ ] `sources/claude-fragments/CLAUDE.fragment.md` §5 절 마지막에 "AUQ 사용 시 §5 stop 자동 생략" 문단 추가 (plan.md A 블록)
- [ ] Commit: `docs(spec-x-notify-channel-coherence): add single-source rule (AUQ vs section-5 stop) to fragment`

### 3-2. 도그푸딩 sync
- [ ] `cp sources/claude-fragments/CLAUDE.fragment.md .harness-kit/CLAUDE.fragment.md`
- [ ] Commit: `chore(spec-x-notify-channel-coherence): sync fragment to installed`

---

## Task 4: Fragment §9 갱신 — 응답 시 단일 채널

### 4-1. 키트 원본 수정
- [ ] `sources/claude-fragments/CLAUDE.fragment.md` §9 본문을 plan.md B 블록 (응답 경로별 분기) 으로 갱신
- [ ] Commit: `docs(spec-x-notify-channel-coherence): rewrite section-9 with single-source response channel rule`

### 4-2. 도그푸딩 sync
- [ ] `cp sources/claude-fragments/CLAUDE.fragment.md .harness-kit/CLAUDE.fragment.md`
- [ ] Commit: `chore(spec-x-notify-channel-coherence): sync fragment to installed (sec-9)`

---

## Task 5: Fragment §1-§8 의 `notify-telegram.sh` → `notify.sh` 일괄 교체

### 5-1. 키트 원본 수정
- [ ] `sed -i 's|notify-telegram\.sh|notify.sh|g' sources/claude-fragments/CLAUDE.fragment.md` (11곳 교체)
- [ ] **호환성 안내 줄 추가 안 함** (Critique 권장: fragment 사용자는 LLM, 오해 위험)
- [ ] 검증: `grep -c notify-telegram.sh sources/claude-fragments/CLAUDE.fragment.md` = `0`
- [ ] Commit: `docs(spec-x-notify-channel-coherence): switch fragment example calls from notify-telegram.sh to notify.sh dispatcher`

### 5-2. 도그푸딩 sync
- [ ] `cp sources/claude-fragments/CLAUDE.fragment.md .harness-kit/CLAUDE.fragment.md`
- [ ] Commit: `chore(spec-x-notify-channel-coherence): sync fragment to installed (dispatcher)`

---

## Task 6: ADR-004 Amendment 절 신설 (Critique 권장 반영)

### 6-1. 키트 원본 수정
- [ ] `docs/decisions/ADR-004-notification-twofold-decision-flow.md` 본문 끝에 `## 🔄 Amendments` 절 신설 (plan.md ADR 블록 — Amendment 형식)
- [ ] Commit: `docs(spec-x-notify-channel-coherence): add ADR-004 amendment for single-source corollary`

---

## Task 7: Smoke 검증

### 7-1. dispatcher 호출 검증
- [ ] `bash .harness-kit/bin/notify.sh "smoke test" info` 실행 → Telegram 발송 정상
- [ ] (Discord active 환경 아님 — 미검증)

### 7-2. 메타 dogfood 검증 (Critique 권장 timing 적용)
- [ ] Plan Accept 응답은 *기존 규칙* (fragment 미수정 시점) 적용 — 검증 대상 아님
- [ ] **Fragment 수정 task (Task 3-5) 완료 *직후* 응답부터 새 규칙 적용** 확인 — Critique/Skip 응답 등 마이너 선택지 응답에 mcp reply 단독 사용
- [ ] Ship pre-flight §1.5 AUQ 호출 시 §5 stop 발송 *생략* 확인 (AUQ 옵션 ≤4 충족)
- [ ] 결과 walkthrough 에 timing 별 적용 이력 기록

### 7-3. fragment grep
- [ ] `grep -c notify-telegram.sh sources/claude-fragments/CLAUDE.fragment.md` = `0` 확인
- [ ] `grep -c notify-telegram.sh .harness-kit/CLAUDE.fragment.md` = `0` 확인
- [ ] Commit: 없음 (검증만)

---

## Task 8: Ship

- [ ] §1.5 리뷰 게이트 (선택지 제시 — 사용자 응답)
- [-] 단위 테스트 → skip
- [ ] **walkthrough.md 작성**
- [ ] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-x-notify-channel-coherence): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-notify-channel-coherence`
- [ ] **PR 생성**: `gh pr create`
- [ ] **사용자 알림**: PR URL Telegram 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 8 |
| **예상 commit 수** | 7 + ship |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-05-29 (Critique 권장 6항목 반영: 조건부 생략, 순서 sync fallback, dogfood timing, Amendment 절, Discord 추상 축소, 안내 줄 제거) |
