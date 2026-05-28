# Walkthrough: spec-x-notify-auq-scope-fix

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| scope 좁힘 범위 | A) 마지막 turn / B) 마지막 2 turn / C) 직전 unanswered turn 추적 | A | 보수적. fast follow-up 은 Out-of-Scope. B/C 는 데이터 누적 후 평가 |
| jq null 처리 | A) `// empty` chain / B) try-catch | A | jq 표준 패턴, 가독성 |
| smoke test 회귀 범위 | A) FP-stale 만 / B) PR #8 4 케이스 + FP-stale | B | 회귀 보장 필수. PR #8 결과 무변경 확인 |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — ADR-004 의 컨벤션 구현 보강

## 💬 사용자 협의

- **주제**: PR #8 의 stale AUQ 잘못 선택 버그
  - **사용자 의견**: 스크린샷 (Telegram msg #3066) — "bash퍼미션 요청 아래의 메시지를 보라구 퍼미션 요청과 관련된 메시지가 아니라 직전 스샷과 동일 내용이잖아"
  - **합의**: jq 쿼리 scope 를 마지막 assistant turn 으로 좁힘 (안 A)
- **주제**: Idea Capture (Telegram 응답 ack 중복)
  - **사용자 응답**: "1" (현재 spec 계속)
  - **합의**: 현재 spec ship 완료 → 별도 spec-x-notify-ack-dedup 으로 fix. Icebox 캡처 완료.

## 🧪 검증 결과

### 1. 자동화 테스트

해당 없음 (bash hook).

### 2. 수동 검증 — Smoke test 5 케이스 모두 PASS

#### 신규 (FP-stale) — fix 효과 입증

- **입력 transcript**:
  ```jsonl
  {"type":"assistant","message":{"content":[{"type":"tool_use","name":"AskUserQuestion","input":{"questions":[{"question":"이전 질문","header":"테스트","options":[{"label":"A"},{"label":"B"}]}]}}]}}
  {"type":"user","message":{"content":[{"type":"tool_result","content":"A"}]}}
  {"type":"assistant","message":{"content":[{"type":"text","text":"응답 받음. 다음 작업 진행."},{"type":"tool_use","name":"Bash","input":{"command":"git status"}}]}}
  ```
- **hook 입력**: `{"hook_event_name":"Notification","message":"Claude needs your permission to use Bash"}`
- **출력**: `"권한 승인 대기 / Branch: ... / Claude needs your permission to use Bash"`
- **결과**: ✓ PASS — 이전 turn 의 AUQ 가 (c) 로 잘못 선택되지 않음. 마지막 assistant turn (Bash tool_use) 안에 AUQ 미존재 → ASK_USER_Q_BODY 빈 값 → (a) brief

#### 회귀 (a)/(b)/(c)/(FP)

| 케이스 | 입력 | 출력 시작 라인 | 결과 |
|---|---|---|---|
| **(a)** | 평범한 text + 권한 메시지 | `"권한 승인 대기"` | ✓ PASS |
| **(b)** | `[선택지]` + `[권장]` 마지막 5줄 | `"사용자 선택 대기"` + transcript | ✓ PASS |
| **(c)** | AUQ x2 questions (header/question/options) | `"사용자 질문 대기"` + `[질문 2개]` | ✓ PASS |
| **(FP)** | 회고 `1) 2) 3)` 텍스트 | `"사용자 입력 대기 중"` 일반 | ✓ PASS |

회귀 영향 0 — PR #8 의 4 케이스 모두 동작 무변경.

## 🔍 발견 사항

- **Critique 의 누락 발견 실증**: PR #8 의 Critique (`specs/spec-x-notify-choice-context/critique.md` §2 모호함) 에서 "직전 에이전트 발화" 정의 모호성을 지적. 본 spec 의 stale AUQ 버그가 그 실증 사례. Critique 발견은 가설이 아닌 *실제로 발생하는 결함의 사전 신호* 임을 데이터로 확인 — 향후 Critique 권장사항은 모두 반영하는 것이 안전.
- **Smoke test 의 path 함정**: 1차 테스트 시 `/tmp/notify-hook-test2/` 경로가 Write tool 과 Bash 가 다른 위치로 해석 — Bash 가 파일 못 찾아 transcript 빈 값으로 처리, (FP-stale) test 가 우연히 PASS 보임 (실은 모두 빈 transcript → (a) brief). `D:\tmp\notify-test\` 로 변경 후 명확한 검증 가능. 향후 smoke test 는 명시적 workspace path 사용.
- **Telegram ack 중복 (Icebox)**: Task 4 진행 중 사용자가 Plan Accept 응답 후 `mcp_telegram_reply` 와 `notify-telegram.sh [ack]` 중복 발송 발견. 본 spec 범위 외. 별도 spec-x-notify-ack-dedup 으로 진행 예정.

## 🚧 이월 항목

- **spec-x-notify-ack-dedup**: Telegram 경유 응답 시 mcp_telegram_reply + §9 ack 중복 제거. 다음 spec.
- **smoke test workspace path 표준화**: 향후 모든 hook smoke test 는 `D:\tmp` 또는 `$HARNESS_ROOT/tests/fixtures/_run` 사용 권장.
- **fast follow-up AUQ 시나리오**: 사용자 응답 직후 에이전트가 즉시 또 다른 AUQ 발화하는 케이스. 현재는 (c) 정상 (마지막 turn 안 AUQ 잡힘). 다중 AUQ in same turn 은 unrealistic 이라 cover 안 함.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Opus 4.7 main) + Leo |
| **작성 기간** | 2026-05-28 |
| **최종 commit** | (ship 후 갱신) |
