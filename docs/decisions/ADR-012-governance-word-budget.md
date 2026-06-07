---
id: ADR-012
type: tradeoff
date: 2026-06-08
status: accepted
---

# ADR-012: 거버넌스 단어 예산 상한 6000 → 6500 재보정

## 📚 Context

`tests/test-governance-dedup.sh` Check 3 은 constitution.md + agent.md 합계 단어 수에 상한을 둬 *항상 로딩되는* 거버넌스의 비대화를 막는다(anti-bloat — fork "컨텍스트 비용 0 우선"). 이력: 5000(초기) → 6000(2026-05-10, §6.7 신설). 테스트 주석은 "6500+ 은 별도 정당화 필요" 라 명시해 왔다.

phase-21(director-mode)이 **정당한 거버넌스**를 추가했다: §6.6(orchestrator–worker, ADR-010), §6.8(Director Mode Protocol, ADR-011), §6.1 delegation, role-based model config 참조. 그 결과 합계가 7494w(상한 +1494w)로 red 가 됐고, spec-21-03 은 "상한 6000 유지 + 다이어트(spec-21-05)" 로 결정했다.

spec-21-05 에서 **enforcement 무손실 안전 압축**(추출 §6.7 stub, §8.4 압축, 최대 섹션 prose/예시/중복 축약)을 광범위 적용해 **~1100w 를 제거**(agent 4696→4096, const 2798→2295, 합계 6391w)했다. 그러나 이 지점에서 남은 콘텐츠는 대부분 *규칙(법)* 이라, <6000 도달은 (a) 핵심 운영 절(§11.3 등, 매 spec 사용)을 가이드로 추출 → read-friction, 또는 (b) 법의 공격적 압축 → 명료성/뉘앙스 손실, 둘 중 하나를 강요했다.

## 🎯 Decision

상한을 **6000 → 6500** 으로 재보정한다(Check 3 `LIMIT=6500`). 동시에 spec-21-05 의 안전 압축(~1100w 제거)은 유지해 *진짜 bloat* 는 걷어낸다. 즉 "다이어트 + 현실적 상한 보정" 하이브리드.

- 상한은 여전히 **하드 캡**(초과 시 red) — 무절제 증가를 막는 ratchet 유지.
- 6500 은 upstream(Changsik00) 의 8000 대비 **19% 낮다** — anti-bloat 규율 유지, upstream 추종 아님.
- 차기 상향(7000+)은 다시 별도 ADR 정당화 필요(주석 명시).

## 📊 Consequences

- **긍정**: phase-21 의 정당한 거버넌스 확장을 수용하면서도 ~1100w 의 실제 bloat 제거. §11.3 같은 핵심 루프를 가이드로 빼는 friction 회피 + 법의 명료성 보존.
- **부정 (tradeoff 의 비용)**: anti-bloat 순수성 일부 양보 — "6000 고정" 의 상징적 압박이 약화. 항상 로딩 토큰이 ~500w 더 큼(6000 대비). spec-21-03 의 "6000 유지" 결정을 갱신(번복)함.
- **중립**: 상한은 측정 대상(constitution+agent.md)만 — CLAUDE.fragment / CLAUDE.md / 가이드(native-feature-usage·director-mode)는 비포함. 가이드 추출은 여전히 유효한 향후 레버.

## 🔀 Alternatives

- **§11 등 운영 절 추출 → 가이드 + stub (상한 6000 유지)**: anti-bloat 순수. — 비채택: §11.3 은 *매 spec 착수 시* 사용 → 가이드 read-friction 이 핵심 루프 비용. cross-ref(§11.x) 관리 부담.
- **법의 공격적 압축 (상한 6000 유지)**: extraction 없이 green. — 비채택: constitution 은 "invariant laws" — 규칙 prose 과압축은 명료성/enforcement 뉘앙스 손실 위험.
- **상한 8000 상향 (upstream)**: 다이어트 불요. — 비채택: anti-bloat 원칙 정면 충돌(spec-21-03 비채택 유지). 6500 은 실측 기반 최소 보정.
- **상한 6000 유지 + red 방치**: phase Done 불가. — 비채택.

## 📌 Status

Accepted (2026-06-08). 적용: `tests/test-governance-dedup.sh` Check 3 `LIMIT=6500` (spec-21-05). spec-21-03 의 "6000 유지" 결정을 실측 증거(안전 압축으로도 <6000 불가)에 근거해 갱신.

## 🔗 Related

- ADR-010 (context-orchestration) · ADR-011 (director-mode) — 본 상향을 유발한 정당한 거버넌스 추가
- spec-21-03 (§11.3 재검증서 "6000 유지 + 다이어트" 결정 — 본 ADR 가 실측 후 갱신)
- spec-21-05 (governance-diet — 안전 압축 ~1100w + 본 재보정)
- `backlog/queue.md` Icebox "거버넌스 단어 수 한계 초과 — 한계 재설정 또는 다이어트" (본 ADR 가 해소)
- 차기 후보: 분기별 governance prune protocol (Icebox)
