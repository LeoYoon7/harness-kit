# Walkthrough: spec-x-persona-hybrid-research

> 작업 기록 — phase-22 No-Go 후속 하이브리드(페르소나 패널 + generalist 정독) research.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 작업 모드 | spec-x research / 새 phase | **spec-x research** | 결과 불확실(또 No-Go 가능), 산출물 report 1개. Go 시 구현 phase 승격 |
| Critique 반영 | 대안 A(현행) / B(범위축소+엄밀화) / C | **대안 B** (사용자 A) | 진짜 리스크는 측정 신뢰도(순환평가·표집편향·임계부재). H1 단일+채점분리+사전등록 |
| 채점 독립성 | 동일 Opus 자기채점 / cross-model blind | **Gemini blind** | self-preference bias 차단(critique 핵심). 라벨 익명화 A/B/C |
| baseline | B0만 / B0+B1(정독변형) | **B0+B1** | 페르소나 vs 정독 기여 분리(대안 C 흡수) |
| POC 안 | H1~H3 / H1 단일 | **H1 단일** | H1 이 유일 신규 가설. H2≈baseline, H3 문헌상 위험(앵커링/echo) |
| 표본 | 폭만 / 폭+깊이 균형 | **S1 폭 + S2 깊이** | 표집 편향 완화 — 깊이 대조 표본이 결정적 시험대 |
| 실행 방식 | 풀 일괄 / 증분 | **증분(S1→보고→S2)** | 비용 관리 + 조기 신호(사용자 결정) |
| Go/No-Go | Go / No-Go / Conditional | **Conditional No-Go** | 블랭킷 패널 ROI 실패(S2). 단 정독(B1) win 발견 → 라우팅 권고 |

### ADR 승격 가이드

- [x] **트리거 대기**: `review-value-baseline` (invariant) — 다관점 리뷰는 baseline 대비 value 측정을 Go 전제로. 본 연구가 그 틀로 블랭킷 패널 기각한 실증.
- [x] **트리거 대기**: `review-eval-independence` (invariant) — 리뷰 value 측정은 채점자/GT 가 피측정 모델과 독립. 본 연구가 Gemini blind 로 적용.
- [ ] 본 spec 머지 시점 ADR 작성 없음 (결론 확정·후속 spec 트리거 시 — phase-22 의 문제-실증 기반 원칙).

## 💬 사용자 협의

- **작업 선택**: 채널(Telegram) "3" → persona-hybrid research.
- **작업 모드**: spec-x research (1).
- **Plan Accept #1**: "2" → Critique 먼저.
- **Critique 반영**: "A" → 대안 B 전면 채택.
- **Plan Accept #2**: "1" → 실행.
- **Task 4 실행 방식**: "1" → S1 증분.
- **S2 진행**: "1" → S2 실행.
- 다수 결정이 **원격 채널(Telegram) 답장**으로 이뤄짐 (§10 양방향 — multi-device).

## 🧪 검증 결과 (Research §9.1 — POC 실증)

### POC 실행 (전문: `scripts/research/persona-hybrid-poc-run.md`)
- **방법**: H1(P1/P2/P3 페르소나 + G generalist) vs B0(Opus×3 self-consistency) vs B1(B0+G). 모두 Opus sub-agent, 결과 계약만(ADR-010 격리 ✅).
- **채점**: Gemini v0.45.2 cross-model blind (라벨 익명화) — 순환 평가 차단.
- **표본 2 (균형)**: S1 `notify-channel-formatter`(폭) / S2 `notify-chunk-line-aware`(깊이).

| 표본 | H1 GT | B1 GT | 페르소나 순기여 | ROI(H1/B0) | 사전등록 |
|---|---|---|---|---|---|
| S1 폭 | 4/4 | 3/4(GT1 폭 놓침) | 양(+) | 1.25 | PASS |
| S2 깊이 | 5/5 | 5/5(동급) | ≈0 | 0.83 | FAIL |

### liveness
- 격리 ✅ (14 워커 전원 계약만, 메인 transcript 미유입) · 종료 ✅ (라운드 1) · 증류 ✅.

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | Skip |
| **Skip 사유** | `docs-only` (research 산출물 — report/scripts/md 만, production 코드 0). 또한 본 연구가 *내부적으로* Gemini cross-model blind 채점을 이미 수행(독립 검증 내재). |

## 🔍 발견 사항

- **두 lever 분리**: generalist 정독 = 깊이 lever(싸고 항상 유효), 페르소나 = 폭 lever(폭 지배 리뷰 한정). phase-22 의 "패널은 깊이 놓침"을 정독으로 해소.
- **B1(self-consistency + 정독)이 값싼 win** — 블랭킷 패널보다 ROI 우위. 후속 spec 후보.
- **측정틀 재사용·확장 성공** — phase-22 §3 + 독립 채점 추가가 결론 신뢰도 결정.

## 🚧 이월 항목

- **후속 spec 후보**: `hk-*-review` 기본을 B1 패턴(Opus×N + generalist 정독)으로 업그레이드 + 페르소나 패널 폭-리뷰 opt-in 문서화 → `backlog/queue.md` Icebox.
- ADR `review-value-baseline` / `review-eval-independence` (invariant) — 후속 spec 트리거 시 작성.
- 혼합형(폭+깊이 동시 지배) 경계 표본 미검증 (n=2 한계).

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent(Opus orchestrator) + 14 Opus 워커 + Gemini blind judge + Leo |
| **작성 기간** | 2026-06-09 |
| **최종 commit** | `89ec32b` (go/no-go, ship 직전) |
