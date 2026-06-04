---
id: ADR-011
type: decision
date: 2026-06-05
status: accepted
---

# ADR-011: 디렉터 모드 — directorMode 토글의 사용자 호출형 운영 프로토콜

## 📚 Context

ADR-010 이 "메인 세션 = context orchestrator"(orchestrator–worker + offloading)를 *always-on 정책*으로 박았다(agent.md §6.6). spec-21-02 가 `/hk-director` 토글 + `directorMode` 플래그 영속화 + `sdd status`/`doctor` 노출이라는 *표면*을 깔았다. 그러나 **`directorMode=true` 가 실제로 무엇을 바꾸는지** — 의도를 확정하는 절차, 워커 위임 명세, 검수 절차, 게이트 보유 규칙 — 가 거버넌스에 비어 있다.

동시에 두 제약이 있다. ① 본 fork 의 §6.6(model allocation)·§6.7(workflow patterns)·ADR-007(native-feature 게이트 보존)·ADR-008(human-gate)과 정합해야 한다. ② upstream(Changsik00) 의 ADR-005/006(context-orchestration/director-mode)은 **번호가 fork 의 ADR-005/006(ignore-symmetry/code-review-gate)과 정면 충돌**해 그대로 재사용할 수 없다. 따라서 cherry-pick 이 아니라 *패턴 포팅 + 신규 번호(010/011)* 가 필요하다.

## 🎯 Decision

ADR-010 의 always-on 전략을 **사용자가 `/hk-director` 로 켜는 명시적 운영 프로토콜**로 구체화한다. directorMode 활성 시 Opus 디렉터는 6개 규칙을 따른다.

1. **의도 합의 핸드셰이크** — 위임 전 사용자 의도를 되물어 확정.
2. **scoped brief 위임** — 워커 브리핑에 대상 파일 / 기대 동작 / 테스트 명령 / 커밋 형식 / **산출물(planning/artifact files) 커밋 범위** 포함. 전체 히스토리는 주지 않음.
3. **distilled contract 반납** — 워커는 커밋 SHA·테스트 상태·결정 목록만 반납. transcript 전문 반납은 VIOLATION.
4. **행동 검증 불변식** — 디렉터 검수 = 테스트 재실행 + 동작 스모크 + 증류 계약 대조. 워커 transcript 전문 재흡수는 명시적 금지(ADR-010 ④축의 운영화).
5. **게이트 보유** — Plan Accept·Ship·§5/§9 알림 게이트는 디렉터+사용자가 보유, 워커에 위임 금지(ADR-008 정합).
6. **over-dispatch 금지** — §6.7 sub-agent dispatch threshold 준수. 디렉터 모드는 위임 *기본값을 높이는 것*이지 모든 것을 위임하는 게 아님.

**배치**: agent.md 에는 간결한 §6.8 *stub*(영어, 핵심 불변식 용어 보유) + §6.1 Director Mode delegation 단락만 두고, 운영 상세는 별도 `director-mode.md` 가이드(한국어, native-feature-usage.md 패턴)로 분리한다. 이유는 ① agent.md 단어 예산 압박 완화(거버넌스 단어 예산 6000w 상한 유지), ② 토글형 절은 always-on §6.6 과 달리 분리 후보(spec-21-01 결정)이기 때문. **거버넌스 다이어트(단어 예산 green 복구)는 본 결정과 분리해 spec-21-06 에서 다룬다** — 본 spec 은 순증 전용.

## 📊 Consequences

- **긍정**: 디렉터 context 가 워커의 토큰 무거운 노동에 오염되지 않아 긴 작업에서도 의도 흐름 보존. ceremony 노동이 싼 티어로 내려가 비용·속도 개선.
- **긍정**: 게이트 보유 규칙(5)으로 human-gate(ADR-008)·양방향 알림(§5/§9) 우회를 명시 차단 — 디렉터 자동화가 사용자 응답 기회를 박탈하지 않음.
- **부정**: 디렉터의 검수 의무 증가 — 워커 결과 맹신 시 silent 결함 유입(ADR-010 과 동일 위험). 검토 시 워커 *전문*을 재흡수하면 context 보존 목적이 반감 → distilled contract 만 반납해야 함(불변식).
- **검증 불변식**: 디렉터는 워커 transcript 전문 재흡수를 통한 검수를 명시적으로 금지한다. 검수는 테스트 재실행 + 동작 스모크 + 증류 계약 대조로만 수행. 워커 전문 재흡수는 VIOLATION.
- **중립**: 모드는 런타임 커널이 아니라 *지시 주입* — hk-align 이 거버넌스를 강제하는 것과 같은 규약 강도(convention). 강제력 기대치를 명시해야 함(hook 강제 아님, 위반은 walkthrough/RCA 로 학습).

## 🔀 Alternatives

- **ADR-010 암묵 정책 유지(명시 토글 없음)**: 단순. — 비채택: 사용자가 켤 수 없고 directorMode 플래그(21-02)가 행동 없이 비어 있게 됨.
- **모든 작업 무조건 워커 디스패치**: 분업 최대화. — 비채택: 단발(git commit 등)까지 디스패치하면 over-dispatch 로 느리고 비쌈(§6.7 threshold 위반).
- **§6.8 전체를 agent.md inline 작성(upstream 방식)**: 한 곳에 모임. — 비채택: agent.md 단어 예산 압박. fork 는 stub + 별도 가이드(native-feature-usage.md 패턴)로 순증 최소화.
- **upstream ADR-005/006 번호 재사용**: cherry-pick 단순. — 비채택: fork ADR-005/006(ignore-symmetry/code-review-gate)과 의미 충돌. 신규 010/011 부여, upstream 은 참조만.
- **단어 예산 상한 8000w 상향(upstream)**: 다이어트 불요. — 비채택: fork "컨텍스트 비용 0 우선" anti-bloat 원칙과 상충. 6000w 유지 + 다이어트(21-06).

## 📌 Status

Accepted (2026-06-05). 적용: `agent.md §6.8 Director Mode Protocol` stub + `§6.1 Director Mode delegation` 단락 + `director-mode.md` 운영 가이드 (spec-21-03).
선행: `/hk-director` 토글 + `directorMode` 영속화 (spec-21-02 → ADR-010 토대).

## 🔗 Related

- ADR-010 (context-orchestration) — 본 ADR 의 토대(always-on 전략), 이를 사용자 호출형 운영 프로토콜로 구체화
- ADR-007 (native-feature-adoption) — 자율 기능의 게이트 보존 원칙(5번 게이트 보유와 정합)
- ADR-008 (human-gate-model) — 사람 승인 게이트는 model-invocable 금지(5번 게이트 보유와 정합)
- upstream ADR-005/006 (context-orchestration/director-mode) — *참조만* (번호 충돌로 재사용 불가)
- phase-21 (director-mode) · agent.md §6.6 · §6.7
