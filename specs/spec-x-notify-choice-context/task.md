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
- [x] `git add backlog/queue.md specs/spec-x-notify-choice-context/`
- [x] Commit: `chore(spec-x-notify-choice-context): scaffold spec artifacts and queue update` (5929a7c)

---

## Task 3: 입력 측 — `notify-on-input-wait.sh` 본문 분기 갱신

### 3-1. 키트 원본 수정
- [x] `sources/hooks/notify-on-input-wait.sh` 의 lines 62-97 교체
   - AskUserQuestion tool_use 추출 로직 추가 (.header 포함)
   - 텍스트 선택지 패턴 감지 추가 (마지막 5줄 매칭, `^\d+\)` 제외)
   - 본문 분기 우선순위 재정렬 (c) → (b) → (a) → 일반
- [x] Commit: `fix(spec-x-notify-choice-context): preserve choice context in notification hook` (0bb0e7c)

### 3-2. 도그푸딩 sync
- [x] `cp sources/hooks/notify-on-input-wait.sh .harness-kit/hooks/notify-on-input-wait.sh`
- [x] `chmod +x .harness-kit/hooks/notify-on-input-wait.sh`
- [x] Commit: `chore(spec-x-notify-choice-context): sync notify-on-input-wait.sh to installed hooks` (883b957)

---

## Task 4: 입력 측 — 수동 smoke test (3 케이스 dry-run)

### 4-1. (a) 순수 권한 케이스
- [x] temp transcript jsonl 생성 — 선택지 / AskUserQuestion 없는 상태
- [x] hook 직접 호출 (debug 변형 — dispatcher 호출 → echo NOTIFY_BODY)
- [x] PASS: 출력 본문 `"권한 승인 대기"` 로 시작

### 4-2. (b) 텍스트 선택지 케이스
- [x] temp transcript jsonl — `[선택지]\n1. A안\n2. B안\n[권장]` 포함
- [x] hook 호출
- [x] PASS: 출력 본문 `"사용자 선택 대기"` 시작 + transcript 발췌 포함

### 4-3. (c) AskUserQuestion 케이스
- [x] temp transcript jsonl — tool_use AskUserQuestion (questions x2, header/question/options.label)
- [x] hook 호출
- [x] PASS: `"사용자 질문 대기"` + `[질문 2개]` + `[모드]`/`[범위]` header + 옵션 라벨

### 4-4. False positive 회피 (Critique 권장 1 검증)
- [x] temp transcript — 회고 `1) gitattributes 추가\n2) renormalize 실행`
- [x] hook 호출
- [x] PASS: `"사용자 입력 대기 중"` (일반 모드) — `1) 2)` 오판 없음

### 4-5. 검증 commit
- [-] Commit: 없음 (smoke test, 결과 walkthrough 에 기록)

---

## Task 5: 출력 측 — CLAUDE.fragment.md §9 신규 섹션 추가

### 5-1. 키트 원본 수정
- [x] `sources/claude-fragments/CLAUDE.fragment.md` 의 §8 직후 §9 신규 섹션 삽입
- [x] Commit: `feat(spec-x-notify-choice-context): add section 9 user-response notification protocol to fragment` (1d14dc1)

### 5-2. 도그푸딩 sync
- [x] `cp sources/claude-fragments/CLAUDE.fragment.md .harness-kit/CLAUDE.fragment.md`
- [x] Commit: `chore(spec-x-notify-choice-context): sync CLAUDE.fragment.md to installed fragment` (6adeb55)

### 5-3. 메타 dogfood — §9 가 작성된 *직후* 모든 응답부터 적용
- [x] Plan Accept 응답 시점에 `[ack]` prefix 알림 발송 (5929a7c 직전, 회고적 — fragment 작성 전이라 strict 적용 외이나 multi-device 가치를 위해 발송)
- [x] 이후 모든 응답 (item 선택 → 권장 진행 → Plan Accept → 추후 ship 등) 에 `[ack]` prefix 알림 발송 진행

### 5-3. 메타 dogfood — §9 가 작성된 *직후* 모든 응답부터 적용
- [ ] §9 가 fragment 에 작성된 이후 (Task 5-1 commit 직후) Plan Accept 게이트 등 모든 사용자 응답에 `[ack]` prefix 알림 발송
- [ ] 절차 위반 발견 시 walkthrough 캡처 + (다른 절차보다 누락 비용이 비대칭 높음) RCA 작성 우선 고려

---

## Task 6: ADR 작성 — `notification-twofold-decision-flow`

### 6-1. ADR 파일 작성
- [x] `docs/decisions/ADR-004-notification-twofold-decision-flow.md` 작성
  - frontmatter `type: convention`, `status: accepted`
  - 결정: 양방향 패턴 (요청 자동 / 응답 절차)
  - 대안 A/B/C 트레이드오프 절 포함 — 향후 자동화 spec 참고용
  - 누락 비용 비대칭 부정적 결과로 명시
- [x] Commit: `docs(spec-x-notify-choice-context): add ADR-004 notification-twofold-decision-flow` (5e91a7b)

---

## Task 7: Ship

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [x] §1.5 리뷰 게이트 — Gemini 선택 (사용자 응답) → Approve (Critical 0 / Major 0 / Minor 1)
- [-] 단위 테스트 없음 → skip
- [x] **walkthrough.md 작성** (4 케이스 smoke test, 이월 항목, 모바일 응답 불가 한계 캡처)
- [x] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-x-notify-choice-context): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-notify-choice-context`
- [ ] **PR 생성**: `gh pr create`
- [ ] **사용자 알림**: 푸시 완료 + PR URL Telegram 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 7 |
| **예상 commit 수** | 7 + ship (브랜치 생성 + smoke test 제외) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-05-28 (Critique 권장 5항목 반영 — ADR 후보 채택, false positive 차단, header 파싱, dogfood 시점 명확화, [ack] prefix) |
