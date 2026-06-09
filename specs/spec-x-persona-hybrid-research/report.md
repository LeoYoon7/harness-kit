# Research Report: spec-x-persona-hybrid-research 하이브리드 리뷰

> §9.2 Research Report — 본 문서가 spec.md 를 대체하는 핵심 산출물이다.
> 연구 진행에 따라 각 섹션을 채운다. Definition of Done = spec.md §DoD (Research §9.1).
> phase-22 측정틀(`specs/spec-22-01-persona-panel-research/report.md §3`)을 재사용한다.

## 0. 요약 (Executive Summary)

<!-- 연구 종료 시 작성 — 하이브리드가 baseline 대비 깊이 회복 + 폭 유지 + ROI 정당화 여부 결론 -->
_(POC 후 작성)_

## 1. 문제 정의

phase-22 결론: 단순 페르소나 패널은 self-consistency baseline(Opus×3)을 지배하지 못함 — 패널=framing 폭, baseline=구체 버그 깊이로 **상보적**, 비용 동급, n=1. 패널은 렌즈 제약 탓에 구체 구현 버그(awk locale)를 전원 놓쳤다. 본 연구는 **하이브리드(패널 + generalist 정독)** 가 그 깊이 손실을 회복하면서 폭 우위를 유지하고, *추가 비용을 정당화하는가* 를 ≥2 표본으로 판정한다.

## 2. 하이브리드 설계 (≥2안 트레이드오프)

### 2.1 설계안 비교

| 안 | 메커니즘 | 장점 | 단점 |
|---|---|---|---|
| H1. 패널 + generalist 병렬 | 3 페르소나(렌즈 제약) + generalist 1 정독 패스 병렬 → 통합 증류 | 폭(페르소나) + 깊이(정독) 명시 결합 | 비용 최대(4 워커), 증류 복잡 |
| H2. 페르소나=추가 정독자 | 페르소나에 렌즈 제약 없이 각자 전반 정독 + 관점 강조 | 깊이·폭 동시, 워커 수 동일(3) | 페르소나 차별성 약화 위험 |
| H3. generalist-first → 페르소나 확장 | 정독 1패스 → 페르소나가 비평·보강 | 깊이 선확보 후 폭, 순차라 증류 단순 | 순차→지연↑, 페르소나가 정독에 앵커링될 위험 |

**결정 (대안 B)**: **POC 대상 = H1 단일.** H2 는 self-consistency 에 라벨만 붙은 형태(baseline 과 차별성 약), H3 는 문헌상 앵커링·오류상관(echo chamber) 위험 — 둘은 본 표(문서 트레이드오프)로만 남기고 POC 비대상. 본 연구의 유일 신규 가설은 "generalist 정독 추가가 패널이 놓친 깊이를 회복하는가"(H1).

### 2.2 거버넌스 정합 (ADR-008/010/011)

<!-- 워커 결과 계약만 반환(ADR-010), 게이트 미위임(ADR-008), 디렉터 dispatch·검증 보유(ADR-011) -->
_(작성 예정)_

## 3. 측정 설계 (phase-22 §3 재사용 + 엄밀화)

### 3.1 재사용 (phase-22 §3.1~3.4)
value 축(recall proxy / precision proxy / 고유 유효 관점 수) · issue retention rate · 비용/지연.

### 3.2 평가 독립성 (신규·필수 — 순환 평가 차단)
phase-22 는 동일 Opus 가 패널·baseline·채점을 모두 수행 → self-preference bias 위험. 본 연구는 **채점자를 분리**한다: 산출물(하이브리드/baseline) **라벨 제거 후 cross-model(Gemini, `hk-gemini-review` 자산) blind 채점**. recall/precision/고유관점 *유효성* 판정을 Opus 가 아닌 Gemini 가 수행. ground truth 는 phase-22 의 walkthrough/critique 기반이되 한계(과거 Opus 산출)를 §5 에 명시.

### 3.3 baseline 2변형 (페르소나 vs 정독 기여 분리)
- **B0**: 순수 Opus×3 self-consistency (phase-22 baseline).
- **B1**: **Opus×3 + 정독 1패스** (대안 C 흡수) — 페르소나 *없이* 정독만으로 깊이가 회복되는지. H1(패널+정독)이 B1 을 못 이기면 페르소나의 순 기여 미입증.

### 3.4 정량 임계 + 사전 등록 (Go/No-Go 규칙 — POC 착수 전 박제)
> **사후 합리화 차단**: 아래 임계·규칙은 POC 실행 *전* 확정한다. 표본별로 PASS/FAIL 만 채운다.

- **깊이 회복**: phase-22 에서 baseline 이 3/3·패널이 0/3 이던 *구체 버그 부류*를 H1 이 회복 → 임계 **≥2/3**.
- **폭 유지**: phase-22 패널 고유 framing 이슈 대비 H1 보존율 → **retention ≥0.8**.
- **ROI**: H1 은 워커 4(페르소나3+정독1) vs baseline 3 → 비용 ~1.3배. `value 증분 / 비용 증분 ≥ 1.0` (Task 2 에서 최종 확정).
- **판정 규칙(초안, Task 2 확정)**: H1 이 **B1 대비** (깊이회복≥2/3) AND (폭 retention≥0.8) AND (ROI≥임계) 를 **표본 2건 모두** 충족 → **Go**; 1건 → 표본 확대; 0건 → **No-Go**. (B1 이 H1 과 동급이면 → 페르소나 불요, No-Go 쪽.)

## 4. POC 설계 (2자 비교)

- **표본 ≥2 (균형 표집)**: ① `spec-x-notify-channel-formatter`(phase-22 표본 — 설계 갈림, 폭 우위 표본) ② **깊이-중심 대조 표본 1건**(구체 구현/플랫폼 버그가 핵심이던 archived spec — 표집 편향 완화) — Task 3 확정.
- **2자 비교**: 하이브리드(H1) vs baseline(B0, B1). **pure-panel 은 phase-22 데이터 서술 참조**(재실행 안 함 — 한계효용 낮음).
- **dispatch**: sub-agent 팬아웃, 결과 계약(`issue/severity/rationale`)만 반환(ADR-010), 메인 context 격리. 채점은 별도 Gemini blind 패스(§3.2).
- **재사용**: phase-22 의 `scripts/research/persona-panel-poc.md` 프로토콜 확장 → `persona-hybrid-poc.md`.

## 5. POC 실행 결과

<!-- liveness(격리/종료/증류) + 2자 비교표 H1 vs B0/B1 (깊이회복/폭유지/비용/ROI), Gemini blind 채점 결과, 표본별 PASS/FAIL -->
_(POC 후 작성)_

## 6. Go / No-Go 권고

<!-- value 우위 + ROI 정당화 여부 기반 명시적 결론. n 한계 명시. 최종 결정권=사용자 -->
_(POC 후 작성)_
