---
id: ADR-014
type: invariant
date: 2026-06-09
status: accepted
---

# ADR-014: 리뷰 value 측정은 피측정 모델과 독립된 채점자/GT 로 한다

> **Note — 경로 표기와 stale ADR 검사 대상**: 본 ADR 의 inline backtick 경로(예: `sources/commands/hk-gemini-review.md`)는 `sdd status` 의 stale ADR 검사 대상입니다. 코드 경로가 이동/삭제되면 stale 라인이 떠 갱신 신호가 됩니다.

## 📚 Context

phase-22 의 측정은 동일 Opus 가 패널·baseline·채점을 모두 수행해 self-preference bias(순환 평가) 위험이 있었다. 후속 #48 은 채점자를 Gemini(cross-model) blind 로 분리해 이를 교정하고 결론 신뢰도를 확보했다. 더불어 동일-모델 self-consistency(Opus×N)는 PoLL(Panel of LLMs)·self-preference 문헌상 **correlated blind spot 을 공유** — 같은 모델이 구조적으로 못 보는 버그는 N회 돌려도 모두 놓친다. 즉 동일-모델 N회는 *독립 채점자가 아니다*.

## 🎯 Decision

리뷰 기법의 value 측정은 **채점자/ground-truth 가 피측정 모델과 독립**(cross-model 또는 사람 blind)이어야 한다. 따름정리(corollary): 동일-모델 self-consistency 는 독립 채점자가 아니므로, 그 독립성 결핍은 cross-model 채널(`sources/commands/hk-gemini-review.md`)이 시스템 차원에서 분담한다. 피측정 모델이 자기 산출을 채점하는 구성은 측정 근거로 인정하지 않는다.

## 📊 Consequences

- **긍정**: 순환 평가(self-preference) 차단 → 측정 신뢰도↑. 동일-모델 self-consistency 의 독립성 한계를 명문화해 "N=3 이면 충분히 독립" 이라는 오해 위에 후속 결정이 쌓이는 것을 방지.
- **부정**: cross-model 도구(Gemini 등) 의존 — 미설치 환경에선 측정 독립성이 약화(사람 blind 로 대체 필요).
- **중립**: `sources/commands/hk-gemini-review.md` 가 이미 cross-model 채널로 존재 — 본 ADR 은 그 역할(독립성 분담)을 명확화할 뿐 신규 도구 불요.

## 🔀 Alternatives

- **동일-모델 self-eval**: 피측정 모델이 자기 산출을 채점 — 비채택: self-preference bias(문헌) + #48 이 cross-model 로 교정한 이유.
- **동일-모델 N회를 "독립" 으로 간주**: 비채택 — correlated blind spot(PoLL 문헌). N 을 늘려도 상관된 사각지대는 안 사라짐.

## 📌 Status

Accepted (2026-06-09, `spec-x-review-b1-default` 머지 시점). 첫 적용: #48 의 Gemini blind 채점 + B1 의 cross-model 분담 설계(self-consistency 독립성 결핍을 `hk-gemini-review` 가 보완).

## 🔗 Related

- `spec-x-persona-hybrid-research`(#48) — Gemini blind 채점으로 순환 평가를 피한 실증 사례.
- ADR-013 (review-value-baseline) — 측정의 *존재* 를 규정하는 짝 불변식(본 ADR 은 측정의 *독립성*).
- `spec-x-review-b1-default` — 첫 적용 spec.
