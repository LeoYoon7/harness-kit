# Spec Critique: spec-x-persona-hybrid-research

## 1. 유사 기법 조사

### 발견된 패턴/도구

- **Self-MoA (arXiv 2502.00674)**: 단일 최강 모델 출력만 앙상블. 다양성보다 *품질*이 지배 변수 — proposer 품질 격차가 크면 Mixed-MoA 열등. 본 연구 baseline(Opus×3)이 정확히 "Self" 형태. H1/H2 페르소나는 같은 Opus 에 렌즈만 다르게 입힌 *프롬프트 다양성* → 깎인 개별 품질 < 정독 품질일 수 있음(phase-22 awk locale 누락과 일치).
- **Multi-Agent Debate vs Self-Consistency**: 동일 agent 수 기준 MAD 가 self-consistency 다수결을 하회. 같은 모델이면 오류 상관(echo chamber). H3(generalist-first→페르소나)은 앵커링·problem drift 위험에 정면 노출.
- **LLM Jury / PoLL (arXiv 2404.18796)**: 다양성 이득의 대부분은 *모델 패밀리 다양성*(Anthropic+OpenAI+Google), 같은 패밀리 내부는 bias 미상쇄. 본 연구는 페르소나·baseline·증류·채점 전부 동일 Opus → 약한 lever(페르소나)만 비싸게 재확인 위험.
- **Self-Preference Bias (arXiv 2410.21819) / Expert Personas Improve Alignment but Damage Accuracy (arXiv 2603.18507)**: persona 프롬프트는 alignment/preference 과제는 개선하나 *지식·정확도 과제는 손상*. 페르소나=폭(framing) 증가·깊이(구체버그) 감소가 *문헌상 예측된 결과* — phase-22 상보성과 동형.

### 시사점

1. 다양성이 항상 우위는 아니라는 결론이 직접 적용 — 본 연구는 사실상 문헌이 부정적으로 답한 lever 검증. No-Go 확률을 사전 높게 잡는 게 정직.
2. 가장 강한 lever(cross-model)는 OOS — 결론이 No-Go 여도 "cross-model 은?" 미해소. report §6 다음 단계에 명시 권장.
3. H3 가 문헌상 가장 위험(순차+앵커링+오류상관) → POC 1순위 배제 근거.

## 2. 요구사항/방법론 비판

### 누락

- **순환 평가 (치명)**: 동일 Opus 가 페르소나·baseline·증류·채점 모두 수행. Self-Preference Bias 상 결과 무효화 가능. 채점 단계만이라도 cross-model(Gemini, `hk-gemini-review` 자산) 또는 사람 blind 분리 필요.
- **Ground truth 순환성**: phase-22 ground truth = 과거 Opus 가 만든 walkthrough/critique. 독립 판정자 부재. 사람/cross-model 판정 강화 필요.
- **blind 비교 부재**: 3자 산출물 채점 시 라벨 보이면 확증편향. 라벨 제거 후 blind 채점 절차 없음.
- **표본 선정 편향**: "설계 갈린 spec"만 표집 = 페르소나에 구조적 유리. 깊이가 핵심인 대조 표본 1건 포함 필요.
- **사전 등록 부재**: Go/No-Go 임계 숫자 미고정 → 사후 합리화 여지.
- **n=2 정직성**: n=2 는 일반화 불가(우연과 구별 불가). 결론에서 "일반화" 금지, 표본별 방향-일치만 보고.

### 모순/과잉 (YAGNI)

- **3자 × ≥2표본 × H1~2안 = 조합 폭증** (plan 도 수백k 토큰 인정). phase-22 가 pure-panel 끝냈으므로 순증 질문은 "정독 추가가 깊이 회복하나" 뿐 → 하이브리드 1안 vs baseline 2자로 충분.
- **H1~H3 3안 탐색 과잉**: H3 위험, H2 는 self-consistency 에 라벨만(차별성 약). 실질 신규는 H1 뿐 → POC 는 H1 단일로 좁힘이 YAGNI 정합.
- **"일반화" 과잉 약속** (plan.md).

### 모호함

- **정량 임계 미정의 (핵심 결함)**: "깊이 회복"·"폭 유지"·"ROI 바" 모두 정성. 예: 깊이회복 ≥2/3, 폭 retention ≥0.8, ROI 합격배수 미정.
- **Go/No-Go 규칙 미사전등록**: POC 후 임계 정하면 사후 합리화. 착수 전 report §3 에 박제 필요.
- **"고유 유효 관점"의 유효 판정자 불명** (순환 평가 연결).

## 3. 대안 제안

### 대안 A — 현 spec 유지 (3자 × ≥2표본 × H1~H3)
- 장점: 설계 공간 탐색 + 3분할 기여 분리 완전. 단점: 비용 최대, 순환평가·표집편향·임계미정의 상속 → 비싼데 신뢰도 낮음.

### 대안 B — H1 단일 2자 + 채점 분리 + 임계 사전등록 (권장)
- 아이디어: POC 를 H1 1안 vs baseline 2자로 좁히고(pure-panel 은 phase-22 서술 참조), 절감분을 (a) 채점 cross-model 분리(Gemini blind), (b) 정량 임계 사전등록, (c) 깊이-중심 대조 표본 1건 추가에 재투자.
- 장점: 비용↓ + 순환평가·표집편향 동시 완화(진짜 약점을 돈으로 삼). 답 해상도↑.
- 단점: 3분할 기여 분리 약화, H2/H3 는 문서 트레이드오프로만.

### 대안 C — 하이브리드 전 "강화 baseline" 먼저 (Opus×3 + 정독 1패스)
- 아이디어: 더 싼 비교군 먼저 — 페르소나 없이 정독만으로 깊이 회복되나. 장점: 최저가, YAGNI 최강. 단점: 폭(framing) 이득 포기.

## 권장안

**대안 B** — 본 연구의 진짜 리스크는 "하이브리드 안의 수"가 아니라 *측정 신뢰도*(순환 평가·표집 편향·임계 부재). 약한 신호(페르소나)를 오염된 자채점으로 재면 결론을 못 믿는다. phase-22 가 pure-panel 끝냈으므로 3자 재실행은 한계효용 낮음 → 절감분을 채점 분리에. **대안 C 의 "강화 baseline"은 대안 B 의 baseline 정의에 흡수** 권장(baseline 에 "Opus×3 + 정독 1패스" 변형 셀 추가 → 페르소나 vs 정독 기여를 거의 공짜로 분리).

## 4. ADR 후보

- [x] 유지: `review-value-baseline` (invariant) — 기존 후보 타당.
- [x] 신규 권장: `review-eval-independence` (invariant) — "리뷰 기법 value 측정은 채점자/ground-truth 가 피측정 모델과 독립(cross-model/사람 blind)이어야 한다." 횡단 불변식, 가치 높음.
- [ ] 선택(우선순위 낮음): `research-pre-registration` (decision/process) — Research Go/No-Go 임계 사전 등록. §9 본문 보강으로 대체 가능.

---

Sources: Self-MoA (2502.00674) · PoLL (2404.18796) · Self-Preference Bias (2410.21819) · Problem Drift in MAD (2502.19559) · Expert Personas (2603.18507)
