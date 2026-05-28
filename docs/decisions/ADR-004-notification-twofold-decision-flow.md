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

## 🔄 Amendments

### 2026-05-29 (spec-x-notify-channel-coherence)

**단일 소스 위반 위험 식별 + 보조 규칙 도입**

**배경 — 실증 사례**: PR #9 직후 라이브 검증에서 §5 stop 의 사람-작성 옵션 순서 (1.Gemini/2.Opus/3.Skip, 권장 3번) 와 AskUserQuestion 의 권장-첫번째 관행 (1.Skip(권장)/2.Gemini/3.Opus) 이 *번호 충돌*. Telegram=3 Skip / Desktop=1 Skip → 사용자가 Telegram 의 "3번" 으로 보고 Desktop 에서 3 누르면 Opus 선택 → 혼동/무반응.

추가 결함: Telegram 경유 응답 시 (a) `mcp_telegram_reply` + (b) `notify-telegram.sh` 의 `[ack]` notify 둘 다 발송되어 *같은 ack 중복*.

**결정 — ADR-004 양방향 컨벤션의 발화 sink 단일성 보강**:

1. **AUQ 옵션 충분성 조건부 생략**: AUQ 가 옵션 표현으로 충분한 케이스 (옵션 ≤4 + free-text 미요구) 에서만 §5 stop 자동 생략. 옵션 5개 이상 등 생략 불가 케이스는 §5 stop 발송 + AUQ 와 옵션 순서 sync (권장-첫번째 강제). 단일 sink = 주, 옵션 순서 sync = fallback 이중화.
2. **응답 측 단일 채널**: Telegram 경유 응답일 때 `mcp__plugin_telegram_telegram__reply` 단독 (본문에 `[ack]` 포맷 포함), `notify.sh` 발송 생략. PC chat 경유 응답일 때 `notify.sh` 단독.
3. **Discord 절차 미명시 — dispatcher 만**: 현재 fragment 의 `notify.sh` 호출이 `NM_NOTIFY_CHANNEL` 라우팅으로 Discord 자동 cover. Discord MCP reply 패턴은 active 화 시점의 별도 spec 에서 다룸.
4. **Fragment §1-§8 의 dispatcher 통일**: 11곳의 `notify-telegram.sh` 호출을 `notify.sh` 로 일괄 교체. Telegram/Discord channel-agnostic 보장.

**Consequences/부정 절 추가**:
- **단일 소스 위반 위험**: 같은 의사결정에 대해 *복수 채널/포맷* (예: §5 stop + AUQ, mcp reply + §9 ack) 으로 발산 시 *번호/내용 충돌*. multi-device 사용자가 본 라벨과 다른 선택 의도를 가져 잘못된 응답 → *회복 어려움*. 단일 sink 원칙 + 옵션 순서 sync fallback 의 이중화로 차단.

**관련 spec**: `specs/spec-x-notify-channel-coherence/` — fragment §5/§9 갱신, §1-§8 의 dispatcher 통일.

**상태**: Accepted (2026-05-29, spec-x-notify-channel-coherence 머지 시점).
