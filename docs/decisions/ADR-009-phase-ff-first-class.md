---
id: ADR-009
type: decision
date: 2026-06-04
status: accepted
---

# ADR-009: phase-FF 를 phase 내 1급 작업 모드로 (upstream ADR-004 parity)

> **Note — 경로 표기와 stale ADR 검사 대상**: 본 ADR 의 inline backtick 경로는 `sdd status` 의 stale ADR 검사 대상입니다 (inline backtick + 슬래시 + 확장자 패턴).

## 📚 Context

SDD ceremony 는 작업 크기와 무관하게 고정비(spec/plan/task/walkthrough/pr_description + Plan Accept + PR + 리뷰, 약 6,000–8,000 토큰)를 가진다 (ADR-002 Planning Economy). 그런데 fork 에서 phase 안의 작업은 암묵적으로 **전부 spec** 으로 처리돼 왔다 — 3줄짜리 변경에도 5개 산출물이 붙고, "관련된 것끼리 묶자"는 bundle 본능이 작은 항목을 spec 으로 승격시키는 압력으로 작동했다.

phase base 브랜치는 main 이 아니므로, 그 안의 직접 커밋은 main 보호 불변식(constitution §10.1)을 깨지 않는다 — ceremony 의 안전 근거(main 오염 방지 + 리뷰 가능 PR)가 phase 브랜치 안에서는 거의 사라진다.

fork 는 phase-FF "용어"를 agent.md §11.4(재조정 옵션)·CLAUDE.fragment(Good Pattern)에 보유하지만, **착수 시점의 1급 구도**·constitution 명문·정식 ADR 이 빠져 있었다. upstream(Changsik00)은 ADR-004 로 이를 1급화했으나, fork 의 ADR-004 는 이미 notification-twofold-decision-flow 라 **번호가 충돌**한다.

## 🎯 Decision

phase 내 작업은 **항목별로 크기에 맞는 모드를 착수 시점에 선택**한다. 실질적/불확실한 작업은 full Spec, 작고 명확하고 가역적인 1–2 commit 항목은 **phase-FF** — phase base 브랜치에 spec 산출물 없이 직접 커밋. phase-FF 는 재조정 fallback 이 아니라 **upfront 1급 선택지**이며, 승인된 phase plan 이 이미 항목 실행을 위임하므로 항목마다 재승인이 필요 없다. "phase 안이면 무조건 spec" 편향과 "FF 회피용 bundle" 을 금지한다.

upstream ADR-004 의 결정을 그대로 채택하되, fork 의 두 분기 지점을 명시한다.

1. **notify 프로토콜 정합**: phase-FF 직접 커밋은 *개별 의사결정 게이트* 를 발생시키지 않으므로 CLAUDE.fragment 의 §5(Ad-hoc 선택지)·§9(응답 ack) 알림을 발화하지 않는다 — 최소 알림. (의사결정이 필요한 순간이 생기면 그건 더 이상 phase-FF 가 아니라 재정렬 신호다.)
2. **pre-push gate de-hardcode (보수적)**: phase-FF 항목도 testable 변경이면 테스트는 유지한다(constitution §9 불변). 해제되는 것은 *개별 spec PR review* 강제뿐 — phase-FF 의 검토는 phase-ship PR 한 곳의 통합검증으로 이동한다.

## 📊 Consequences

- **긍정**: 작은 작업의 ceremony 고정비 제거 — 토큰·사용자 검토 피로 감소. phase 가 "작업 묶음"의 자연 단위가 됨.
- **긍정**: 리뷰가 phase-ship PR 로 모임 — 솔로/도그푸딩 맥락에서 per-spec PR 리뷰 과잉 완화.
- **부정**: per-spec 리뷰 입자도 상실 — phase 가 크면 phase-ship PR 이 큰 덩어리가 됨. 완화: 결정 로그를 phase.md `📌 결정 기록 (Review)` 에 누적.
- **부정**: phase-FF 는 base 브랜치 모드 전제(커밋할 non-main 위치 필요) — base 모드를 더 적극 채택.
- **중립**: phase-FF 는 FF(Mode C)와 구별 — phase PR 에 실리고 state.json 의 active spec 을 바꾸지 않는다(constitution §2.3 FF 의 state 규칙과 대비).

## 🔀 Alternatives

- **upstream ADR-004 cherry-pick**: 번호·본문 그대로 가져오기 — 비채택 이유: fork ADR-004(notification)와 번호 충돌 + fork notify 정합 기술 누락. 신규 번호 009 로 재작성.
- **ceremony 단위를 spec→phase 로 재설계**: phase 전체를 무거운 경계로, 내부 전면 경량화 — 비채택 이유: 과설계. 기존 spec/FF 모드 유지 + "phase 내 강제 spec" 규칙만 푸는 게 단순.
- **산출물 통합(5 md → 1 work.md)**: spec 자체를 경량화 — 보류(직교 레버, 본 ADR 범위 밖. upstream ADR-004 도 동일 분류).

## 📌 Status

Accepted (2026-06-04, spec-20-04 머지 시점). 규약 반영: constitution §3.1(In-Phase Work Sizing) + §10.2(pre-push 예외), agent.md §11.4(In-Phase Work Sizing & Re-Adjustment), CLAUDE.fragment 패턴.

## 🔗 Related

- upstream ADR-004 (phase-ff-first-class) — 본 ADR 의 parity 원천 (Changsik00/harness-kit).
- ADR-002 (Planning Economy) — phase plan 은 contract 아닌 draft + ceremony 고정비 인식.
- ADR-004 (notification-twofold-decision-flow) — fork 고유, 번호 충돌의 당사자. §1 정합 근거.
- spec-20-04 (phase-ff-first-class) — 본 ADR 을 거버넌스에 반영한 spec.
