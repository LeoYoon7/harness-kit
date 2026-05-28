---
id: ADR-004
type: convention
date: 2026-05-28
status: accepted
---

# ADR-004: 의사결정 알림은 요청(자동) + 응답(절차) 양방향 컨벤션

> **Note — 경로 표기와 stale ADR 검사 대상**: 본 ADR 의 inline backtick 경로 (예: `sources/hooks/notify-on-input-wait.sh`) 는 `sdd status` 의 stale ADR 검사 대상입니다.

## 📚 Context

본 키트의 의사결정 알림 프로토콜 (`sources/claude-fragments/CLAUDE.fragment.md` §1-§8) 은 *에이전트가 사용자에게 선택지를 제시하는 시점* 의 알림만 정의했음. multi-device 환경에서 사용자가 PC 에서 응답하면 모바일 측에는 *응답됨* 신호가 없어 "응답을 해야 하는 상황인지, 응답 후 진행 중인지" 구분 불가. spec-x-notify-choice-context 의 dogfood 도중 이 비대칭이 명시적으로 식별됨.

기존 §1-§8 은 *요청 측 알림 (input)* 만 정의. 응답 측 알림 (output) 의 부재가 multi-device 사용자 경험의 핵심 결함.

## 🎯 Decision

의사결정 알림 프로토콜을 **양방향 컨벤션** 으로 정의한다:

1. **요청 측 (자동, hook)**: `sources/hooks/notify-on-input-wait.sh` 가 Claude Code 의 `Notification`/`Stop` 이벤트에서 자동 발화. (a) 순수 도구 권한 / (b) 텍스트 선택지 / (c) AskUserQuestion 3 케이스 구분.
2. **응답 측 (절차, agent)**: 사용자가 명시적 의사결정에 응답하면 에이전트가 즉시 `notify-telegram.sh ... "✅ [ack] 사용자 응답: ..." info` 호출. 본문에 `[ack]` prefix 필수 — 사후 grep 가능.

향후 모든 새 알림 게이트 추가 시 *요청 + 응답 양쪽 모두 정의* 가 컨벤션.

## 📊 Consequences

- **긍정**:
  - multi-device 사용자가 응답 상태를 즉시 인지 가능 — PC 응답이 모바일에서도 확인됨.
  - `[ack]` prefix 로 응답 누락 사례를 사후 grep 으로 검증 가능 (walkthrough/RCA 와 보완).
  - 새 게이트 추가 시 *요청만* 정의하는 부분 누락이 컨벤션 위반으로 식별됨.
- **부정**:
  - 응답 측이 *에이전트 절차* 에 의존 — 자동화 fallback 없음. 누락 위험 존재.
  - **누락 비용 비대칭**: §1-§8 의 다른 알림 누락은 PC 세션에서 회복 가능하나 §9 누락은 모바일 사용자가 *응답 여부 자체* 를 모름 → 회복 불가. 이 비대칭으로 §9 누락은 다른 절차보다 우선적 RCA 작성 대상.
  - 매 응답마다 알림 1건 추가 → 의사결정당 최소 2건 알림. 노이즈 증가.
- **중립**:
  - `info` 레벨 재사용 — 신규 레벨 추가 안 함 (노이즈 최소화).
  - hook 자동화는 의도적 보류 — 데이터 (walkthrough/RCA 누적) 가 쌓인 후 별도 spec 으로 자동화 평가.

## 🔀 Alternatives

- **대안 A — 입력 측만 정교화, 응답 측 보류**: hook 만 (a)/(b)/(c) 분기로 정교화, §9 응답 알림은 미도입. — 비채택 이유: multi-device 사용자의 *원래 pain point* (PC 응답 후 모바일 추측) 미해결.
- **대안 B — 응답 측을 hook 자동화 (UserPromptSubmit)**: §9 를 에이전트 절차가 아닌 hook 으로. state 마커로 직전이 의사결정 요청이었는지 판정 후 자동 ack. — 비채택 이유: surface area 큼 (settings.json 머지 + install/update 영향), 본 spec 의 Out-of-Scope 와 충돌. *향후 데이터 누적 후 별도 spec 으로 평가 가능*.
- **대안 C — Telegram editMessageText 로 원 메시지 update**: §9 *대신* 원 알림 메시지를 edit 하여 "✅ 응답됨" append. — 비채택 이유: Telegram edit 은 *push notification 트리거 안 함* → 모바일 사용자가 알림 못 받음. multi-device 가치 (PC 응답을 모바일에 알림) 와 정면 모순.

## 📌 Status

Accepted (2026-05-28, spec-x-notify-choice-context 머지 시점). 첫 사용자: `sources/claude-fragments/CLAUDE.fragment.md` §9.

## 🔗 Related

- Spec: `specs/spec-x-notify-choice-context/spec.md`
- Critique: `specs/spec-x-notify-choice-context/critique.md` — 대안 B/C 의 자세한 트레이드오프 분석
- Hook 구현: `sources/hooks/notify-on-input-wait.sh` — (a)/(b)/(c) 본문 분기
- Fragment §9: `sources/claude-fragments/CLAUDE.fragment.md` — 응답 측 절차 정의
