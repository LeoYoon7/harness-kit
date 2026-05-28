# Walkthrough: spec-x-notify-choice-context

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| Scope (input/output) | A) 현재 spec 통합 / B) 별도 spec / C) park 후 재설계 | A | 의사결정 UX 라는 단일 주제. 사용자 결정 (Telegram) |
| 응답 알림 구현 | A) 에이전트 절차 (fragment §9) / B) UserPromptSubmit hook 자동화 / C) Telegram editMessageText | A | Out-of-Scope 명시. 데이터 누적 후 자동화 spec 평가 |
| 응답 알림 레벨 | A) `info` 재사용 / B) 신규 `decided` 추가 | A | 노이즈 최소화. 헬퍼/dispatcher 변경 불필요 |
| (b) 패턴 매칭 범위 | A) 전체 transcript text / B) 마지막 5줄 단락 | B | Critique 권장. false positive 차단 |
| `^\d+\)` 패턴 포함 | A) 포함 / B) 제거 | B | Critique 발견. 본 프로젝트는 `1.` 점 표기 사용 |
| AskUserQuestion `header` 처리 | A) 무시 / B) `[<header>] ` prefix | B | Critique 권장. 탭 라벨 손실 방지 |
| ack prefix | A) 없음 / B) `[ack]` 필수 | B | Critique 권장. 사후 grep 가능 |
| ADR 작성 | A) 없음 / B) `notification-twofold-decision-flow` | B | Critique 권장. cross-spec / long-lived |

### ADR 승격 가이드

- [x] ADR 승격 대상 있음 → 작성됨: `docs/decisions/ADR-004-notification-twofold-decision-flow.md`
- [ ] 없음

## 💬 사용자 협의

- **주제**: Telegram/Discord 의사결정 선택지 누락
  - **사용자 의견**: "권한승인대기로 메시지가 수신되나 선택지가 노출되지 않음. 탭으로 여러 질문 한번에 요청할 때도 고려"
  - **합의**: hook 본문 분기 정교화 (a)/(b)/(c)
- **주제**: multi-device 응답 측 알림 부재
  - **사용자 의견**: "PC 응답 후 모바일에서 진행 상태 추측해야 함"
  - **합의**: Reconciliation A — fragment §9 신규
- **주제**: Critique 권장 5항목 반영
  - **사용자 응답**: "권장 진행"
  - **합의**: 1-4 + ADR 후보 모두 반영

## 🧪 검증 결과

### 1. 자동화 테스트

해당 없음 (bash hook + 마크다운).

### 2. 수동 검증 (Hook smoke test)

4 케이스 dry-run — 모두 PASS.

#### 케이스 (a) — 순수 권한
- **입력**: `{"hook_event_name":"Notification","message":"Claude needs your permission to use Bash"}` + transcript: 평범한 text
- **출력**:
  ```
  권한 승인 대기
  Branch: spec-x-notify-choice-context
  Claude needs your permission to use Bash
  ```
- **결과**: ✓ PASS — IS_PERMISSION=1, (b)/(c) 미감지 → brief

#### 케이스 (b) — 텍스트 선택지
- **입력**: 권한 메시지 + transcript 마지막 5줄 `[선택지]` + `[권장]`
- **출력**:
  ```
  사용자 선택 대기
  Branch: spec-x-notify-choice-context

  [최근 Claude 메시지]
  분석 결과 두 방향이 있습니다.

  [선택지]
  1. A안 — 빠른 fix
  2. B안 — 근본 해결

  [권장] 2번 — 장기적 관점
  ```
- **결과**: ✓ PASS — HAS_TEXT_CHOICE=1 → "사용자 선택 대기"

#### 케이스 (c) — AskUserQuestion (탭 멀티)
- **입력**: tool_use AskUserQuestion (questions x2, header/question/options.label)
- **출력**:
  ```
  사용자 질문 대기
  Branch: spec-x-notify-choice-context

  [질문 2개]
  1. [모드] 어떤 모드?
     옵션: A 옵션 / B 옵션
  2. [범위] 범위?
     옵션: 전체 / 일부
  ```
- **결과**: ✓ PASS — ASK_USER_Q_BODY 생성, `header` prefix, 옵션 라벨

#### 케이스 (FP) — False positive 회피
- **입력**: 회고 `1) gitattributes 추가\n2) renormalize 실행\n3) sync 완료`
- **출력**: `사용자 입력 대기 중` (일반 모드)
- **결과**: ✓ PASS — `1) 2)` 가 (b) 로 오판되지 않음. 마지막 5줄 + `^\d+\)` 제거 작동.

### 3. 메타 dogfood (출력 측 §9)

§9 작성 (`1d14dc1`) 이후 모든 응답에 `[ack]` prefix:
- Item 선택 응답 "권장 진행" → ✓ (회고적, fragment 작성 전)
- Plan Accept "1" → ✓ (작성 직후)
- Ship §1.5 응답 → 발송 예정

## 🔍 발견 사항

- **Telegram editMessageText 의 push 미발생**: 원 메시지 edit 으로 ack 표시하면 노이즈 0 이나 *모바일 push 트리거 없음*. multi-device 가치와 정면 모순. ADR-004 의 대안 C 비채택 이유로 명시.
- **응답 알림 자동화의 surface area**: UserPromptSubmit hook + state 마커 패턴으로 자동화 가능 (Critique 대안 B). Out-of-Scope 로 보류 — 데이터 누적 후 평가.
- **`sdd ship` 의 spec-x 스코프 트렁케이션 (3번째 발견)**: 이전 #6/#7 에서 발견된 ship commit subject 의 slug 자동 잘림. 본 spec 도 동일 — amend 정정 필요.

## 🚧 이월 항목

- `sdd ship` 의 spec-x slug 트렁케이션 fix (3번째 발견, 별도 spec-x)
- UserPromptSubmit hook 기반 §9 자동화 평가 (6개월 후 walkthrough/RCA 빈도 확인)
- Discord 채널의 §9 응답 알림 dogfood 확인 (dispatcher 양쪽 발송 시 자동 cover)
- **모바일 응답 불가 한계** (Task 7 ship 도중 사용자 추가 지적, Telegram msg #3054): 본 spec 의 fix 는 *알림에 선택지 보이게* 하는 것까지. AskUserQuestion 모달은 CLI 전용이라 모바일 사용자는 *응답을 위해* 여전히 PC 필요. 다음 단계 (현재 Out-of-Scope): UserPromptSubmit hook + Telegram 답장 → CLI 자동 입력 (ADR-004 의 대안 B 와 일치). 데이터 누적 후 별도 spec 평가.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Opus 4.7 main) + Leo |
| **작성 기간** | 2026-05-28 |
| **최종 commit** | (ship 후 갱신) |
