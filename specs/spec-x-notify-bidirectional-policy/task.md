# Task List: spec-x-notify-bidirectional-policy

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).

## Pre-flight

- [x] Spec ID 확정 (`sdd specx new notify-bidirectional-policy`)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성
- [ ] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

### 1-1.
- [x] `git checkout -b spec-x-notify-bidirectional-policy`
- [x] Commit: 없음

---

## Task 2: Spec 스캐폴드 commit

### 2-1.
- [ ] `git add backlog/queue.md specs/spec-x-notify-bidirectional-policy/`
- [ ] Commit: `chore(spec-x-notify-bidirectional-policy): scaffold spec artifacts and queue update`

---

## Task 3: 제목 채널 중립화 (line 91) + sync

### 3-1.
- [ ] `sources/claude-fragments/CLAUDE.fragment.md` line 91 제목 교체 (plan Layer 1)
- [ ] Commit: `docs(spec-x-notify-bidirectional-policy): neutralize notification protocol title to telegram/discord`

### 3-2. sync
- [ ] `cp sources/claude-fragments/CLAUDE.fragment.md .harness-kit/CLAUDE.fragment.md`
- [ ] Commit: `chore(spec-x-notify-bidirectional-policy): sync fragment to installed (title)`

---

## Task 4: 정책 표 라인 교체 (보조 → 양방향) + sync

### 4-1.
- [ ] `sources/claude-fragments/CLAUDE.fragment.md` line 379 정책 표 라인 교체 (plan Layer 2)
- [ ] Commit: `docs(spec-x-notify-bidirectional-policy): replace 'aux channel' policy with 'bidirectional channel'`

### 4-2. sync
- [ ] `cp sources/claude-fragments/CLAUDE.fragment.md .harness-kit/CLAUDE.fragment.md`
- [ ] Commit: `chore(spec-x-notify-bidirectional-policy): sync fragment to installed (policy)`

---

## Task 5: 신규 §10 응답 채널 인식 절차 추가 + sync

### 5-1.
- [ ] `sources/claude-fragments/CLAUDE.fragment.md` §9 직후 §10 신규 섹션 삽입 (plan Layer 3)
- [ ] Commit: `feat(spec-x-notify-bidirectional-policy): add section 10 channel-reply recognition procedure`

### 5-2. sync
- [ ] `cp sources/claude-fragments/CLAUDE.fragment.md .harness-kit/CLAUDE.fragment.md`
- [ ] Commit: `chore(spec-x-notify-bidirectional-policy): sync fragment to installed (sec-10)`

---

## Task 6: AUQ 사용 제거 명시 + §5 legacy 노트 + sync

### 6-1.
- [ ] `sources/claude-fragments/CLAUDE.fragment.md` §5 의 AUQ 조건부 생략 문단 상단에 "현재 정책 (본 spec 이후): 에이전트 AUQ 미사용 — legacy 보호 규칙" 한 줄 추가 (plan Layer 4)
- [ ] Commit: `docs(spec-x-notify-bidirectional-policy): mark section-5 AUQ rule as legacy after agent stops using AUQ`

### 6-2. sync
- [ ] `cp sources/claude-fragments/CLAUDE.fragment.md .harness-kit/CLAUDE.fragment.md`
- [ ] Commit: `chore(spec-x-notify-bidirectional-policy): sync fragment to installed (auq-legacy)`

---

## Task 7: Telegram 명시 *축소* 채널 중립화 (7곳) + line 122 모순 해소 + sync

### 7-1.
- [ ] `sources/claude-fragments/CLAUDE.fragment.md` 의 *7곳* Edit (plan Layer 5 축소 표 기준 — line 85/93/120/122/140 + 제목/정책표 이미 처리)
- [ ] line 122 양방향 정책 정합화 (Critique #4)
- [ ] 검증: 보호 대상 (line 102-107/233/299/300/316/353/373/380/389/392) *변경 안 됨* 확인
- [ ] Commit: `docs(spec-x-notify-bidirectional-policy): neutralize 7 telegram-only references and reconcile line-122 with bidirectional policy`

### 7-2. sync
- [ ] `cp sources/claude-fragments/CLAUDE.fragment.md .harness-kit/CLAUDE.fragment.md`
- [ ] Commit: `chore(spec-x-notify-bidirectional-policy): sync fragment to installed (neutralization)`

---

## Task 8: ADR-004 Amendment 추가 (부정 절 보강 포함)

### 8-1.
- [ ] `docs/decisions/ADR-004-notification-twofold-decision-flow.md` 의 `## 🔄 Amendments` 절에 2026-05-29 entry 추가 (plan ADR 블록 — 결정 ID 부재 + dead branch/text 부정 절 포함)
- [ ] Commit: `docs(spec-x-notify-bidirectional-policy): add ADR-004 amendment for bidirectional policy shift`

---

## Task 8b: Layer 7 — governance/agent.md 영문 출처 정합 + sync (Critique #8)

### 8b-1.
- [ ] `sources/governance/agent.md` L401 영문 줄 채널 중립화 (plan Layer 7 diff)
- [ ] Commit: `docs(spec-x-notify-bidirectional-policy): neutralize governance line 401 to remote channel notifications`

### 8b-2. sync
- [ ] `cp sources/governance/agent.md .harness-kit/agent/agent.md`
- [ ] Commit: `chore(spec-x-notify-bidirectional-policy): sync agent.md to installed governance`

---

## Task 9: 검증 smoke

### 9-1. grep
- [ ] `grep -ci "telegram" sources/claude-fragments/CLAUDE.fragment.md` — 사전 18 → 사후 ~11 확인 (축소 적용)
- [ ] `grep -c "보조 채널" sources/claude-fragments/CLAUDE.fragment.md` = 0 확인
- [ ] `grep -c "양방향 채널" sources/claude-fragments/CLAUDE.fragment.md` = 1 확인
- [ ] `grep -c "Telegram notifications" sources/governance/agent.md` = 0 확인 (Layer 7 검증)

### 9-2. 메타 dogfood (Critique #6 — 본질 보강)
- [ ] **본질 검증**: 본 spec 의 *한 게이트* (예: 항목 선택, Plan Accept 게이트 직후 추가 결정 등) 를 *실제 Telegram 답장* 으로 응답하여 §10 절차 실증 — 응답 매핑 알고리즘 + 단일 sink ack 동작 확인
- [ ] (부수적) AUQ 미사용 확인 — 텍스트만
- [ ] Telegram 답장 응답 → mcp reply 단독 사용 (단일 소스)
- [ ] PC chat 응답 → notify.sh 단독 사용
- [ ] Commit: 없음 (검증만)

---

## Task 10: Ship

- [ ] §1.5 리뷰 게이트 (텍스트 형식 — AUQ 미사용 dogfood)
- [-] 단위 테스트 → skip
- [ ] **walkthrough.md 작성**
- [ ] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-x-notify-bidirectional-policy): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-notify-bidirectional-policy`
- [ ] **PR 생성**: `gh pr create`
- [ ] **사용자 알림**: PR URL

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 10 (Task 8b 추가) |
| **예상 commit 수** | 16 + ship |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-05-29 (Opus critique 권장 10항목 all 반영 — Layer 5 축소, Layer 7 추가, dogfood 본질 보강, dead branch 솔직 인지) |
