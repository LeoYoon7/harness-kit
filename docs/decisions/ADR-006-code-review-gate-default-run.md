---
id: ADR-006
type: decision
date: 2026-06-02
status: accepted
---

# ADR-006: 코드 리뷰 게이트를 기본 실행 + 감사형 Skip 으로 전환

## 📚 Context

ship 직전 코드 리뷰 게이트(`agent.md §6.3-8`, `hk-ship.md §1.5`)는 `(optional)` 로 정의돼 있었다. 그러나 "optional" 에 *언제 리뷰해야 하는가* 를 가르는 객관적 기준이 없었고, "사용자가 Skip 할 수 있다" 는 의미일 뿐이었다. 그 결과 (1) 리뷰 대상이라고 강제하는 트리거가 없고, (2) 리뷰는 추가 1스텝·Skip 은 즉시 push 라는 마찰 비대칭이 있으며, (3) Skip 해도 기록이 안 남아 책임이 0 이었다. 실제 운영에서 리뷰 제안 자체가 거의 발화되지 않아 게이트가 유명무실해졌다.

## 🎯 Decision

게이트의 **기본값을 "리뷰 실행" 으로 두고, Skip 은 `walkthrough.md` 의 코드 리뷰 칸에 한 줄 사유 기록을 의무화한 감사형(auditable) 행위로 전환**한다. 리뷰를 Skip 불가로 강제하지는 않는다 — "기록을 동반한 Skip" 까지만 강제한다. docs/markdown-only 변경은 사유 `docs-only` 한 단어로 충분하다.

## 📊 Consequences

- **긍정**: "리뷰 안 함" 이 침묵이 아니라 *기록되는 의도적 결정* 이 된다. Skip 사유가 walkthrough 에 누적돼 사후 grep/회고로 게이트 운영 실태를 추적할 수 있다. forcing function 을 차단(block)이 아닌 책임(accountability)으로 구현해 설계의 optional 의도와 양립한다.
- **부정**: 매 ship 마다 리뷰를 실행하거나 사유를 기록하는 마찰이 소폭 증가한다 (docs-only 한 단어 허용으로 완화).
- **중립**: 3지선다(Gemini/Opus/Skip) 구조와 cross-model(Gemini) 권장은 그대로 유지된다.

## 🔀 Alternatives

- **순수 optional 유지 (status quo)**: 현행대로 자유 재량. — 비채택 이유: 트리거·감사가 없어 always-skip 으로 붕괴하는 본 문제의 원인 그 자체.
- **완전 강제 (mandatory, Skip 불가)**: 리뷰를 무조건 실행. — 비채택 이유: `agent.md §6.3` 의 optional gate 의도와 충돌하고, docs-only·trivial 변경에 과도한 마찰.
- **스코프 기반 자동 트리거**: diff 크기·파일 타입으로 리뷰 강제 여부를 기계 판정. — 비채택 이유: 에이전트가 "이건 trivial" 이라 선언하고 빠져나갈 여지가 남아 누락 자체를 막지 못함. 복잡도 대비 ROI 낮음.

## 📌 Status

Accepted (2026-06-02, `spec-x-review-gate-default` 머지 시점). 첫 적용: `hk-ship.md §1.5` 게이트 + `walkthrough.md` 코드 리뷰 칸. 단, 본 변경은 `sources/` 원본에만 반영되며 실행 중인 repo 의 live 거버넌스(`.harness-kit/`)는 `update.sh` 가 동기화한다 (ADR-003).

## 🔗 Related

- spec: `specs/spec-x-review-gate-default/`
- ADR-003 (도그푸드 동기화 정책 — sources 원본만 변경하는 근거)
