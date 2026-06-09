# Implementation Plan: spec-x-persona-hybrid-research (Research)

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-persona-hybrid-research` (브랜치 이름 = spec 디렉토리 이름)
- 시작 지점: `main` 사전 분기 (spec-x → PR base=main)
- 첫 task 가 브랜치 생성 + 계획 산출물 커밋 수행
- 본 spec 은 **Research** — production 코드 없음. 검증 = POC 실증(§9.1). commit type 은 주로 `docs`.

## 🛑 사용자 검토 필요 (User Review Required)

> **대안 B 채택(critique 2026-06-09, 사용자 A)** — 범위 축소 + 측정 엄밀화.

> [!IMPORTANT]
> - [ ] **POC 범위**: H1 단일 vs baseline 2변형(B0 순수 Opus×3, B1 Opus×3+정독1패스). H2/H3·pure-panel 은 문서/참조만 — 동의 여부.
> - [ ] **평가 독립성**: 채점을 cross-model(Gemini) blind 로 분리(순환 평가 차단). Gemini CLI 가용 전제 — 동의 여부.
> - [ ] **사전 등록**: Go/No-Go 정량 임계(깊이회복≥2/3·폭retention≥0.8·ROI배수)를 POC 착수 전 report §3 에 박제 — 동의 여부.
> - [ ] **표본**: ≥2 균형(설계갈림 1 + 깊이중심 1). n=2 는 방향 일치만 보고("일반화" 금지).

> [!WARNING]
> - [ ] production 무영향 — 단일-Opus 리뷰 경로 미변경. 산출물은 report + scripts/research 한정.
> - [ ] 결론이 또 No-Go 일 수 있음 (정상 — 문헌상 페르소나는 약한 lever, B1 이 H1 과 동급이면 페르소나 불요).

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **측정틀** | phase-22 §3 재사용 + 깊이회복/폭유지/ROI **정량 임계 사전등록** | 동일 지표 누적 + 사후 합리화 차단 |
| **평가 독립성** | 채점을 cross-model(Gemini) blind 분리, 라벨 제거 | 순환 평가(self-preference bias) 차단 — critique 핵심 |
| **baseline** | B0 순수 Opus×3 + **B1 Opus×3+정독1패스** | 페르소나 기여 vs 정독 기여 분리(대안C 흡수) |
| **하이브리드 안** | **H1 단일** POC (H2/H3 문서만) | H1 이 유일 신규 가설; H2≈baseline, H3 문헌상 위험 |
| **비교 구조** | 2자 (H1 vs B0/B1), pure-panel=phase-22 참조 | 재실행 한계효용 낮음 → 절감분을 채점 분리에 |
| **표본** | ≥2 균형 (설계갈림 1 + 깊이중심 1) | 표집 편향 완화; n=2=방향일치(일반화 X) |

### 📑 ADR 후보

- [x] ADR 가치 있는 결정 있음 →
  - `review-value-baseline` (type: invariant) — 연구 결론 시 작성 (phase-22 트리거 대기분).
  - `review-eval-independence` (type: invariant, critique 신규) — "리뷰 value 측정은 채점자/ground-truth 가 피측정 모델과 독립" — 연구 결론 시 작성.
- [ ] 없음

## 📂 Proposed Changes

### 연구 산출물 (production 코드 없음)

#### [MODIFY] `specs/spec-x-persona-hybrid-research/report.md`
하이브리드 설계 비교 / 측정 설계 / POC 결과 / Go-No-Go 채움 (§9.2 핵심 산출물).

#### [NEW] `scripts/research/persona-hybrid-poc.md`
하이브리드 POC 프로토콜 (H1 dispatch=페르소나3+generalist1, 결과 계약, baseline B0/B1, **Gemini blind 채점** 절차, 사전등록 임계). phase-22 `persona-panel-poc.md` 확장.

#### [NEW] `scripts/research/persona-hybrid-poc-run.md`
표본 ≥2 실행 로그 (격리/종료/증류 + 2자 H1 vs B0/B1 value/깊이/폭/비용 비교표 + Gemini blind 채점 결과 + 표본별 PASS/FAIL).

## 🧪 검증 계획 (Verification Plan)

> Research — 단위 테스트 아님. §9.1 DoD 가 검증 기준.

### POC 실증 (단위 테스트 대체)
- H1 ≥2 표본 실행 → liveness(격리/종료/증류) 확인.
- 동일 표본에 baseline B0/B1 실행 → Gemini blind 채점으로 value/깊이/폭/비용 2자 비교.

### 수동 검증 시나리오
1. 표본 1(`spec-x-notify-channel-formatter`, 폭 표본) H1 vs B0/B1 → 기대: H1 이 패널이 놓쳤던 구체 버그(awk locale 류) 회복 + framing 폭 유지. B1 과의 차이로 페르소나 순기여 확인.
2. 표본 2(깊이중심 대조) H1 vs B0/B1 → 기대: 표본별 방향 일치 여부(일반화 아님).
3. Gemini blind 채점 + 비용 집계 → 기대: 사전등록 임계 대비 PASS/FAIL + ROI 배수 → Go/No-Go 입력.

## 🔁 Rollback Plan

- 연구 산출물(docs/scripts)만 추가 — production 무영향. 브랜치 폐기로 완전 원복.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
