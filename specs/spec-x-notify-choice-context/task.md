# Task List: spec-x-notify-choice-context

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성 (`sdd specx new notify-choice-context`)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [ ] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-notify-choice-context`
- [x] Commit: 없음

---

## Task 2: Spec 스캐폴드 commit

### 2-1. Pre-flight 산출물 정리
- [ ] `git add backlog/queue.md specs/spec-x-notify-choice-context/`
- [ ] Commit: `chore(spec-x-notify-choice-context): scaffold spec artifacts and queue update`

---

## Task 3: 입력 측 — `notify-on-input-wait.sh` 본문 분기 갱신

### 3-1. 키트 원본 수정
- [ ] `sources/hooks/notify-on-input-wait.sh` 의 lines 62-97 교체 (plan.md MODIFY 블록)
   - AskUserQuestion tool_use 추출 로직 추가
   - 텍스트 선택지 패턴 감지 추가
   - 본문 분기 우선순위 재정렬 (c) → (b) → (a) → 일반
- [ ] Commit: `fix(spec-x-notify-choice-context): preserve choice context in notification hook`

### 3-2. 도그푸딩 sync
- [ ] `cp sources/hooks/notify-on-input-wait.sh .harness-kit/hooks/notify-on-input-wait.sh`
- [ ] `chmod +x .harness-kit/hooks/notify-on-input-wait.sh`
- [ ] Commit: `chore(spec-x-notify-choice-context): sync notify-on-input-wait.sh to installed hooks`

---

## Task 4: 입력 측 — 수동 smoke test (3 케이스 dry-run)

### 4-1. (a) 순수 권한 케이스
- [ ] temp transcript jsonl 생성 — 선택지 / AskUserQuestion 없는 상태
- [ ] hook 직접 호출 (stdin 으로 Notification + 권한 메시지 JSON 전달)
- [ ] 출력 본문이 `"권한 승인 대기"` 로 시작하는지 확인

### 4-2. (b) 텍스트 선택지 케이스
- [ ] temp transcript jsonl — 마지막 assistant text 에 `[선택지]\n1. A\n2. B\n[권장]` 포함
- [ ] hook 호출
- [ ] 출력 본문이 `"사용자 선택 대기"` 로 시작 + `[선택지]` 포함 확인

### 4-3. (c) AskUserQuestion 케이스
- [ ] temp transcript jsonl — 마지막 assistant tool_use 가 AskUserQuestion (question/options 명시)
- [ ] hook 호출
- [ ] 출력 본문이 `"사용자 질문 대기"` 로 시작 + `[질문 N개]` + 옵션 라벨 포함 확인

### 4-4. 검증 commit
- [ ] Commit: 없음 (smoke test 만, 결과는 walkthrough 에 기록)

---

## Task 5: 출력 측 — CLAUDE.fragment.md §9 신규 섹션 추가

### 5-1. 키트 원본 수정
- [ ] `sources/claude-fragments/CLAUDE.fragment.md` 의 §8 직후, "### Strict Loop 중 Task 완료 알림 정책" 직전에 §9 삽입 (plan.md MODIFY 블록 참조)
- [ ] Commit: `feat(spec-x-notify-choice-context): add §9 user-response notification protocol to fragment`

### 5-2. 도그푸딩 sync
- [ ] `cp sources/claude-fragments/CLAUDE.fragment.md .harness-kit/CLAUDE.fragment.md`
- [ ] Commit: `chore(spec-x-notify-choice-context): sync CLAUDE.fragment.md to installed fragment`

### 5-3. 메타 dogfood — §9 가 작성된 *직후* 모든 응답부터 적용
- [ ] §9 가 fragment 에 작성된 이후 (Task 5-1 commit 직후) Plan Accept 게이트 등 모든 사용자 응답에 `[ack]` prefix 알림 발송
- [ ] 절차 위반 발견 시 walkthrough 캡처 + (다른 절차보다 누락 비용이 비대칭 높음) RCA 작성 우선 고려

---

## Task 6: ADR 작성 — `notification-twofold-decision-flow`

### 6-1. ADR 파일 작성
- [ ] `docs/decisions/ADR-004-notification-twofold-decision-flow.md` 작성 (NNN = max+1, 3-digit pad)
  - frontmatter `type: convention`
  - 결정: 의사결정 요청 알림 (자동 hook) + 응답 ack 알림 (에이전트 절차) 양방향 패턴
  - 이유: cross-spec / long-lived / fragment 핵심 규약
  - Out-of-Scope 의 자동화 옵션 (대안 B/C) 도 트레이드오프 절에 포함 — 향후 자동화 spec 의 참고
- [ ] Commit: `docs(spec-x-notify-choice-context): add ADR-004 notification-twofold-decision-flow`

---

## Task 7: Ship

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] §1.5 리뷰 게이트 — 사용자에게 Gemini / Opus / Skip 선택 제시 (직접 결정 임의 skip 금지)
- [ ] 단위 테스트 없음 → skip
- [ ] **walkthrough.md 작성** (3 케이스 smoke test 결과, 본문 샘플)
- [ ] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-x-notify-choice-context): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-notify-choice-context`
- [ ] **PR 생성**: `gh pr create` 또는 `/hk-pr-gh --no-confirm`
- [ ] **사용자 알림**: 푸시 완료 + PR URL Telegram 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 7 |
| **예상 commit 수** | 7 + ship (브랜치 생성 + smoke test 제외) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-05-28 (Critique 권장 5항목 반영 — ADR 후보 채택, false positive 차단, header 파싱, dogfood 시점 명확화, [ack] prefix) |
