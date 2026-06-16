---
id: ADR-{NNN}
type: decision    # decision | invariant | convention | tradeoff
date: YYYY-MM-DD
status: proposed  # proposed | accepted | superseded | deprecated
---

# ADR-{NNN}: <한 줄 제목>

> **Note — 경로 표기와 stale ADR 검사 대상**: 본 ADR 의 inline backtick 경로는 `sdd status` 의 stale ADR 검사 대상입니다.
> 검사 패턴은 *inline backtick + 슬래시 + 확장자* 를 가진 토큰입니다 (예: 백틱으로 감싼 src/foo.ts 형태 — 이 예시는 평문이라 검사에 안 걸림). ` ``` ` code fence 안 경로, 슬래시 없는 토큰, `../` 로 시작하는 상대경로, URL 은 무시됩니다.
> 코드 경로가 이동/삭제되면 stale 라인이 떠 ADR 갱신 신호가 됩니다.

## 📚 Context
<!-- 어떤 상황/제약/요구가 이 결정을 *필요하게* 만들었는가. 2~5 줄.
     배경 사실만. 결정 자체나 대안은 아래 섹션. -->

## 🎯 Decision
<!-- *무엇을* 정했는가. 1~3 줄. 구체적이고 모호하지 않게.
     예: "산출물 frontmatter `type:` 슬롯에 5 어휘 closure 를 도입한다." -->

## 📊 Consequences
<!-- 결정으로 인해 생기는 *결과* — 긍정 / 부정 / 중립 모두.
     실제로 일어날 변화 (예: 코드, 워크플로, 호환성, 학습 곡선) -->

- **긍정**: <항목>
- **부정**: <항목>
- **중립**: <항목 (선택)>

## 🔀 Alternatives
<!-- 고려했으나 채택하지 않은 안 1~3 개. 각 안의 *핵심 아이디어 + 비채택 이유* 1~2 줄. -->

- **<대안 A>**: <아이디어> — 비채택 이유: <이유>
- **<대안 B>**: <아이디어> — 비채택 이유: <이유>

## 📌 Status
<!-- proposed: 제안만 됨 / accepted: 채택, 적용 중 / superseded: 다른 ADR 로 대체 / deprecated: 폐기.
     superseded 인 경우 대체 ADR 링크 명시. -->

<예: Accepted (2026-05-16, spec-16-02 머지 시점). 첫 사용자: <module/component>.>

## 🔗 Related
<!-- 관련 spec / RCA / PR / 외부 ADR. [[wikilink]] 컨벤션: [[spec-NN-NN]] · [[ADR-NNN]] · [[RCA-NNN]] · [[wiki/page]] (docs/wiki/purpose.md). 없으면 섹션 삭제 가능. -->
