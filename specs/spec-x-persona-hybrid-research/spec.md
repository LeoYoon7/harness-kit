# spec-x-persona-hybrid-research: 하이브리드 리뷰(페르소나 패널 + generalist 정독) 연구

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-persona-hybrid-research` |
| **Phase** | `phase-x` (spec-x — 비소속, 연구 단발) |
| **Branch** | `spec-x-persona-hybrid-research` |
| **상태** | Planning |
| **타입** | Research |
| **Integration Test Required** | no (research DoD §9.1 적용 — POC 실증이 검증) |
| **작성일** | 2026-06-09 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

phase-22(`spec-22-01`)는 review 커맨드의 단일 Opus 리뷰를 **페르소나 패널**로 바꿀지 연구해 **Conditional No-Go** 로 결론냈다. POC(n=1, `spec-x-notify-channel-formatter`) 결과:
- 패널은 *framing 폭*(설계·UX, 이 spec 의 실제 핵심 모바일→embed 이슈)에서 우위.
- baseline(단일 Opus×3, self-consistency)은 *구체 구현 버그*(awk locale 의존)를 3/3 으로 잡았으나 **패널은 전원 놓침**.
- 비용 동급. → 둘은 **상보적**, 패널이 baseline 을 지배하지 못함.

phase-22 §6 은 다음 단계로 **A. 하이브리드 재설계(권장)** — 페르소나 패널(폭) + generalist 정독 1패스(깊이) 결합 — 을 권고했다. 측정틀(value/retention/cost + self-consistency baseline)은 `specs/spec-22-01-persona-panel-research/report.md §3` 에 자산화돼 있다.

### 문제점

1. **깊이 손실의 원인 미해소** — 페르소나의 "렌즈 제약"(각자 한 관점만)이 구체 구현 버그 정독을 희생시켰다. 패널 단독으로는 baseline 의 깊이를 못 따라간다.
2. **n=1 일반화 불가** — phase-22 결론은 표본 1건. 하이브리드든 패널이든 ≥2 표본 없이는 방향 확정 불가.
3. **비용 비대칭 심화 위험** — 하이브리드 = 패널 + generalist 이므로 baseline 보다 *비싸다*(패널만으로도 이미 비용 동급). 따라서 value 우위 입증의 ROI 바가 더 높다 — "조금 나음"으로는 Go 불가.

### 해결 방안 (요약)

하이브리드 설계안 ≥2개를 트레이드오프 비교하고, phase-22 측정틀을 재사용해 **≥2 표본**에 **하이브리드 vs baseline(self-consistency) vs pure-panel(phase-22 데이터 재사용)** 3자 비교 POC 를 돌린 뒤, "하이브리드가 baseline 대비 *상보 손실(깊이)을 회복하면서 폭 우위를 유지*하고, 추가 비용을 정당화하는가" 를 기준으로 **Go/No-Go** 를 권고한다 (§9 Research Spec Protocol). 산출물은 `report.md`(spec 대체, §9.2) + POC 자산(`scripts/research/`).

## 🎯 요구사항

### Functional Requirements (연구 질문 — 각각 답을 내야 함)

> **대안 B 채택 (critique 2026-06-09, 사용자 A)**: 진짜 리스크는 "하이브리드 안의 수"가 아니라 *측정 신뢰도*(순환 평가·표집 편향·임계 부재). POC 를 H1 단일로 좁히고 절감분을 측정 엄밀화에 재투자.

**A. 하이브리드 설계 (POC 대상 = H1 단일, H2/H3 는 문서 트레이드오프만)**
1. **H1 (POC 대상): 패널 + generalist 정독 병렬** — 3 페르소나(렌즈 제약) + generalist 1 정독 패스 병렬 팬아웃 후 통합 증류. *본 연구의 유일한 신규 가설* — "정독 추가가 패널이 놓친 깊이를 회복하는가".
2. **H2/H3 (문서 비교만, POC 제외)** — H2(페르소나=렌즈 비제약 정독자)는 self-consistency 에 라벨만 붙은 형태로 baseline 과 차별성 약함; H3(generalist-first→페르소나)는 문헌상 앵커링·오류상관(echo chamber) 위험. → report §2 트레이드오프 표로만 남기고 POC 비대상.

**B. 측정 (phase-22 §3 재사용 + 엄밀화)**
3. **평가 독립성(신규·필수)** — 채점(recall/precision/고유관점 유효성 판정)은 피측정 모델(Opus)과 *독립*: cross-model(Gemini, `hk-gemini-review` 자산) blind 채점. 산출물 라벨 제거 후 채점.
4. value 축(recall proxy / precision proxy / 고유 유효 관점 수) — phase-22 §3.1 재사용 (단 채점자만 분리).
5. **깊이 회복 / 폭 유지 (정량 임계)** — 깊이: phase-22 에서 baseline 이 3/3, 패널이 0/3 이던 *구체 버그 부류*를 하이브리드가 회복(임계 예: ≥2/3). 폭: 패널 고유 framing 이슈 보존(retention 예: ≥0.8). 임계는 §사전등록에 박제.
6. issue retention rate (증류 평탄화 여부) — §3.2 재사용.
7. **ROI 바(정량)** — 하이브리드는 baseline 보다 비쌈(워커 4 vs 3) → `value 증분 / 비용 증분` 합격 배수를 사전 고정.
8. **baseline 2변형** — (a) 순수 Opus×3 self-consistency, (b) **Opus×3 + 정독 1패스**(대안 C 흡수) — 페르소나 기여 vs 정독 기여를 거의 공짜로 분리.

**C. POC + 결론 (2자 비교)**
9. **표본 ≥2 (균형 표집)** — ① phase-22 표본(`spec-x-notify-channel-formatter`, 설계 갈림) + ② **깊이-중심 대조 표본 1건**(구체 구현 버그가 핵심이던 spec) — 표집 편향 완화.
10. **2자 비교** — 하이브리드(H1) vs baseline(2변형). pure-panel 은 phase-22 데이터 *서술 참조*(재실행 안 함, 한계효용 낮음).
11. **사전 등록 (Go/No-Go 규칙)** — POC 착수 *전* report §3 에 정량 임계 + 판정 규칙 박제(사후 합리화 차단). 예: "(깊이회복≥2/3) AND (폭 retention≥0.8) AND (ROI≥X) 를 표본 2건 모두 충족 → Go; 1건 → 표본 확대; 0건 → No-Go".
12. **Go/No-Go** — 사전등록 규칙에 따른 명시적 결론. **"일반화" 금지** — n=2 는 표본별 *방향 일치* 만 보고.

### Non-Functional Requirements

1. fork 거버넌스 정합 — ADR-008(human-gate)·ADR-010(orchestration, 워커 결과 계약만)·ADR-011(director) 불변식 위반 금지.
2. POC 는 기존 단일-Opus 리뷰 경로를 변경하지 않는다 (프로토타입 별도 — production 무영향).
3. phase-22 측정틀·POC 자산을 *재사용*(중복 설계 금지) — 동일 지표로 비교 가능해야 결론이 누적된다.

## 🚫 Out of Scope

- review 커맨드 production 적용 (= Go 전제의 후속 구현 phase).
- `hk-spec-critique` 외 커맨드 POC (1개 커맨드 맥락으로 충분).
- 새 슬래시 커맨드/도구 신설 (POC = 프로토타입 프롬프트/스크립트).
- 단일-Opus 리뷰 경로 변경/제거.
- 표본 3건 이상으로의 대규모 확장 (≥2 로 방향 판정; 정밀화는 Go 후).
- **pure-panel 재실행** (phase-22 데이터 서술 참조로 대체 — 한계효용 낮음).
- **H2/H3 POC** (문서 트레이드오프만 — H1 이 유일 신규 가설).
- **cross-model 다양성 lever**(다른 모델 패밀리 패널) — 문헌상 더 강한 lever 이나 본 연구 범위 밖. report §6 "다음 단계"로 메모.

## 📑 ADR 후보 (Architecture Decision Records)

- [x] ADR 가치 있는 결정 있음 → 후보:
  - `review-value-baseline` (type: **invariant**) — "다관점 리뷰 도입은 baseline(self-consistency) 대비 value 측정을 Go 전제로 한다." phase-22 에서 트리거 대기로 남긴 항목 — 본 연구 결론 시 작성.
  - `review-eval-independence` (type: **invariant**, critique 신규 권장) — "리뷰 기법 value 측정은 채점자/ground-truth 가 피측정 모델과 *독립*(cross-model 또는 사람 blind)이어야 한다." 횡단 불변식 — 본 연구 결론 시 작성.
  - Go 시 `review-hybrid-orchestration` (type: decision) 후속 구현 spec 에서.
- [ ] 없음

## 🔍 Critique 결과 (2026-06-09, Opus + 웹 문헌)

전문: `specs/spec-x-persona-hybrid-research/critique.md`. 권장안 = **대안 B** (사용자 A 채택).
- **문헌**: Self-MoA(2502.00674)·PoLL(2404.18796)·Self-Preference Bias(2410.21819) — 페르소나(프롬프트) 다양성은 약한 lever, 강한 건 cross-model. persona 는 alignment 개선·정확도 손상(2603.18507) → phase-22 상보성과 동형.
- **반영(7건, FR/Scope/ADR 갱신)**: ① POC H1 단일(H2/H3 문서만) ② 채점 cross-model blind 분리(순환 평가 차단) ③ Go/No-Go 정량 임계 사전등록 ④ 깊이-중심 대조 표본 추가(표집 편향 완화) ⑤ baseline 정독변형(대안C 흡수) ⑥ "일반화" 제거(n=2=방향일치) ⑦ ADR `review-eval-independence` 추가.

## ✅ Definition of Done (Research — §9.1)

- [ ] **트레이드오프 분석**: 하이브리드 H1 (+ H2/H3 문서 비교) → `report.md`
- [ ] **측정 설계 + 사전등록**: phase-22 §3 재사용 + 깊이회복/폭유지/ROI 정량 임계 + Go/No-Go 규칙을 POC 착수 전 `report.md` §3 에 박제
- [ ] **평가 독립성**: 채점 cross-model(Gemini) blind + 산출물 라벨 제거
- [ ] **POC (표본 ≥2, 균형)**: 하이브리드(H1) vs baseline(2변형) 2자 비교 + 깊이-대조 표본 포함 → `report.md` + `scripts/research/`
- [ ] **value/깊이/폭 실증**: 사전등록 임계 대비 반증 가능하게 측정 (n=2 → 방향 일치만, "일반화" 금지)
- [ ] **Go/No-Go 권고**: 사전등록 규칙 기반 명시적 결론 + 근거 → `report.md`
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-persona-hybrid-research` 브랜치 push 완료 (PR base=main)
- [ ] 사용자 검토 요청 알림 완료
