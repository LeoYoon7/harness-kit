---
id: ADR-010
type: decision
date: 2026-06-04
status: accepted
---

# ADR-010: 메인 세션 = context orchestrator (orchestrator–worker + context offloading)

## 📚 Context

에이전트 작업에서 가장 비싼 자원은 **메인 세션의 context 창**이다. 다파일 구현·광역 탐색·로그 분류 같은 토큰 무거운 노동을 메인이 직접 수행하면 그 raw 산출물이 context 를 오염시켜 *의도의 흐름*을 잃는다(잘못된 가정 위에 작업이 쌓이는 understanding debt).

fork 의 agent.md §6.6 은 **모델 분배(WHO)** 만 규정하고 **context 정책(무엇을 위임/주입/반환할지)** 은 비어 있었다. phase-21(director-mode) 재구현 맥락에서, 이 context 정책은 토글형 director mode(→ ADR-011, spec-21-03)의 *기반*이 되는 always-on 정책이다.

## 🎯 Decision

메인 세션을 **context orchestrator** 로 명시하고, agent.md §6.6 에 context offloading 정책을 5축으로 규약화한다(orchestrator–worker 패턴). ① 위임 대상(토큰 무거운/오염성 노동 vs 판단·조정·검증), ② scoped slice 만 주입, ③ distilled result contract(완료 상태 포함)만 반환, ④ 검증은 orchestrator 보유(실패 시 §7 Hard Stop), ⑤ 독립 job fan-out. 본 정책은 director mode 토글과 무관하게 *항상* 적용된다.

## 📊 Consequences

- **긍정**: 메인 context 가 토큰 무거운 노동에 오염되지 않아 긴 작업에서도 의도의 흐름이 보존된다. 위임 시 컨텍스트·결과 형태가 명확해져 워커 결과의 품질·재현성이 오른다. 병렬 fan-out 으로 처리량 증가.
- **부정**: orchestrator 의 검증 의무가 커진다 — 워커 결과를 맹신하면 silent 결함이 유입된다. 그래서 ④축 검증 보유 + 검증 실패 시 §7 Hard Stop 을 명문화했다. 워커 transcript 전문을 재흡수하는 검수는 목적을 반감시키므로 금지(본격 불변식은 ADR-011/spec-21-03).
- **중립 (always-on disambiguation)**: 정책 텍스트는 *항상* 로드·적용되나, 실제 *위임 행동*은 토큰 무거운 노동이 있을 때만 발생한다. director mode 는 위임 *적극성*을 높이는 토글이지 본 정책의 on/off 스위치가 아니다.
- **중립 (net-neutral 작업 관행, convention)**: 거버넌스에 always-on 정책을 추가할 때, 단어 순증 0 을 *spec 단위로* 강제하지 않는다(5축 텍스트 부피가 상쇄 여지보다 크다). 중복 다이어트로 ±50w 이내로 억제하고, 완전 green(단어 예산 상한 충족)은 phase 누적으로 달성한다. spec-21-03 도 동일 적용.

## 🔀 Alternatives

- **별도 가이드 문서로 분리 (vs §6.6 인라인)**: always-on 정책을 install 배포되는 situational guide(native-feature-usage.md 패턴)로 빼는 안. — 비채택 이유: always-on 정책은 항상 로딩되는 agent.md 본문에 있어야 강제력이 일관된다. (토글형 director protocol §6.8 은 분리 후보로 spec-21-03 에서 별도 결정.)
- **본 spec 에서 적극 다이어트로 green 근접 (vs net-neutral)**: 5축 추가와 함께 agent.md 를 대폭 트림해 단어 예산 상한에 근접. — 비채택 이유: surgical-changes 위반·One-Task 응집도 저하. 대규모 다이어트는 별도 spec 영역.
- **upstream ADR-005 번호 재사용 (vs fork 신규 010)**: — 비채택 이유: fork ADR-005 는 ignore-symmetry-invariant — 의미가 정면 충돌한다. upstream ADR-005 는 참조로만 쓴다.

## 📌 Status

Accepted (2026-06-04, spec-21-01 머지 시점). 적용: agent.md §6.6. 첫 사용자: 본 spec 의 critique 위임(Opus 워커가 critique 를 파일에 작성하고 distilled 요약만 반납 — 5축의 ②·③ 실증).

## 🔗 Related

- agent.md §6.6 · §6.7
- ADR-009 (phase-FF) — ceremony/context 비용 절감 계열
- ADR-011 (director-mode) — 본 정책을 사용자 토글형 운영 프로토콜로 구체화 (예정, spec-21-03)
- 참조: upstream ADR-005 (context-orchestration) — 본 ADR 의 재구현 원본. 번호 충돌로 참조만.
