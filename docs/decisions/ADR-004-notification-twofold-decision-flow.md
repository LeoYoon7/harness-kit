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

### 2026-05-29 (spec-x-notify-bidirectional-policy)

**정책 전환 — 보조 채널 → 양방향 채널 + AUQ 사용 제거**

**배경 — fragment 내부 모순 식별**:
- 섹션 서두 (line 93): "원격 판단을 내릴 수 있도록 지원" (양방향 의도)
- 정책 표 (line 379): "보조 채널 — Telegram 답장으로 명령을 수행하지 않음" (응답 차단)
- → 정책 표 라인이 *anomaly*. 서두 의도와 모순.
- 추가: 제목 "Telegram 의사결정..." vs Discord 병행 현실. fragment 내 18곳 Telegram 명시.
- line 122 "에이전트는 아무것도 안 함" 도 양방향 정책과 모순 (응답 도착 시 처리 필요).

**라이브 사례**:
- Telegram msg #3054: AUQ 모달이 모바일 응답 불가 → "이런경우 상호작용 안됨"
- Telegram msg #3113: §1.5 AUQ 알림에 선택지 미노출 → hook (c) 분기 발화 실패 가설

**결정**:

1. **정책 전환**: "보조 채널 (응답 비활성)" → "양방향 채널 (알림 + 응답 인식)". Telegram/Discord 답장을 *해당 의사결정 게이트의 응답* 으로 처리.
2. **AUQ 사용 제거**: 에이전트 절차에서 AskUserQuestion 도구 호출 금지. 모든 게이트 텍스트 형식 통일. 적용: 본 에이전트 + sub-agent. 외부 도구는 OOS.
3. **dead branch/text 솔직 인지**: hook (c) AUQ 분기 + §5 AUQ 조건부 생략 규칙 = AUQ 미사용 정책 하 *이론상 발화 불가*. "legacy 보호" 표현 대신 *dead 인지*. 6개월 누적 후 완전 제거 별도 spec 트리거.
4. **채널 중립화 — 축소 적용**: fragment 의 Telegram 명시 7곳 (제목/정책/§10/line 122 등 핵심) 만 채널 중립화. 환경변수 예시/dedupe/비활성화 안내는 Discord active 시점 별도 spec 보호.
5. **신규 §10**: 채널 답장 → 의사결정 응답 처리 절차 명문화. 응답 매핑 알고리즘 (숫자/권장 키워드/라벨 substring) 포함.
6. **Layer 7 — cross-document 정합**: governance/agent.md L401 영문 출처도 채널 중립화.

**Consequences 의 긍정 절 추가**:
- multi-device 환경의 *외부 지속 작업* (사용자 원래 의도) 가 정상화. 모바일에서 plan accept, 옵션 선택 가능.

**Consequences 의 부정 절 추가**:
- AUQ 의 native UI 장점 (PC 클릭) 상실. 사용자는 텍스트 입력 필요. UX 트레이드오프.
- 채널 응답 처리는 *에이전트 절차 의존* — MCP 신뢰 전제. 위반/race 케이스의 사후 학습.
- **결정 ID 부재로 복수 게이트 사이 응답은 휴리스틱 매핑** — 동시 활성 게이트 다수 시 누락 위험. 본 프로젝트 규모에서 trade-off 수용 (Slack action_id / Step Functions taskToken 패턴 미도입).
- **dead branch/text 잔존**: hook (c) AUQ 분기 + §5 의 AUQ 조건부 생략 규칙이 이론상 발화 불가 상태로 유지. 6개월 후 완전 제거 재평가.

**관련 spec**: `specs/spec-x-notify-bidirectional-policy/` — fragment 전 layer 정합화.

**상태**: Accepted (2026-05-29, spec-x-notify-bidirectional-policy 머지 시점).
