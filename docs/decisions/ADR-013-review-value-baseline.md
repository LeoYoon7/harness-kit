---
id: ADR-013
type: invariant
date: 2026-06-09
status: accepted
---

# ADR-013: 다관점 리뷰 도입은 baseline 대비 value 측정을 전제로 한다

> **Note — 경로 표기와 stale ADR 검사 대상**: 본 ADR 의 inline backtick 경로(예: `sources/commands/hk-code-review.md`)는 `sdd status` 의 stale ADR 검사 대상입니다. 코드 경로가 이동/삭제되면 stale 라인이 떠 갱신 신호가 됩니다.

## 📚 Context

리뷰 기법은 직관적으로 "관점이 많을수록 낫다"(페르소나 패널, 다에이전트, 추가 렌즈)로 보인다. 그러나 phase-22(`spec-22-01-persona-panel-research`)와 후속 연구(`spec-x-persona-hybrid-research`, #48)는 cross-model blind 채점으로 측정한 결과, **블랭킷 페르소나 패널이 self-consistency baseline 을 ROI 로 지배하지 못함**을 실증했다(폭 지배 리뷰 한정 순기여, 깊이 지배 리뷰에선 비용만 추가). 측정 없이 직관으로 다관점 기법을 채택하면 ceremony·비용만 늘고 가치 입증이 안 된다.

## 🎯 Decision

harness-kit 의 리뷰 기법(다관점·다에이전트·패널·렌즈 추가) **도입 또는 기본값 변경은 baseline 대비 value 측정(recall/precision proxy + 비용/지연)을 Go 전제로 한다.** baseline 정의는 **직전 채택된 리뷰 구성**(상대적) — self-consistency 등 특정 구성을 절대 baseline 으로 고정하면 그 구성 자체의 가치가 무엇 대비 측정되는지 순환이 생기므로 금지한다. "관점이 많으니 더 낫다" 식 무측정 채택은 위반.

## 📊 Consequences

- **긍정**: 리뷰 ceremony 비대화 방지. 비용 정당화 강제. #48 같은 *기각 사례*(블랭킷 패널 No-Go)가 자산으로 남아 재논의 비용 절감.
- **부정**: 새 리뷰 기법 도입에 측정(POC) 선행 마찰. 가벼운 변경에도 측정틀 적용 부담.
- **중립**: 측정틀은 #48 `report.md §3`(value 축 / issue retention / 비용)을 재사용 — 매번 새로 설계 불요.

## 🔀 Alternatives

- **직관 기반 채택**: 측정 없이 "좋아 보이면" 도입 — 비채택: #48 이 직관(패널=더 좋음)이 틀릴 수 있음을 실증.
- **절대 baseline 고정**(예: self-consistency 를 영구 baseline 으로): 비채택 — self-consistency 자체 가치 측정의 순환. 상대적("직전 채택 구성") 정의로 회피.

## 📌 Status

Accepted (2026-06-09, `spec-x-review-b1-default` 머지 시점). 첫 적용: B1 패턴(self-consistency + generalist 정독) 채택을 #48 측정으로 정당화 + 블랭킷 페르소나 패널 기각.

## 🔗 Related

- `spec-x-persona-hybrid-research`(#48) — 본 불변식의 실증 사례(블랭킷 패널 Conditional No-Go).
- ADR-014 (review-eval-independence) — 측정의 *독립성* 을 규정하는 짝 불변식.
- `spec-x-review-b1-default` — 첫 적용 spec.
