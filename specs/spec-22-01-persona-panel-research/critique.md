# Spec Critique: spec-22-01

> 독립 시니어 아키텍트 비평. 대상: `specs/spec-22-01-persona-panel-research/{spec,plan}.md`, `backlog/phase-22.md`.
> 정합 점검: ADR-008(human-gate)·ADR-010(context-orchestration)·ADR-011(director-mode), agent.md §9 Research Spec Protocol.
> **연구 spec 임을 감안** — "과잉 설계" 비판은 연구 자체가 de-risking 이라는 점을 전제로 한 것.

## 1. 유사 기법 조사

### 발견된 패턴/도구

이 문제(다관점 리뷰 + 종합/중재 + 종료조건)는 학계·업계에서 활발히 연구된 영역이다. spec 이 다루는 5난점 대부분이 이미 알려진 해법을 가진다.

**(a) Multi-Agent Debate (MAD) — 종료조건/무한루프 핵심 시사**
- 다수 연구가 **3라운드 이하에서 수렴**한다고 보고 (Du et al. 계열, "Reaching Agreement Among Reasoning LLM Agents"). spec 의 "라운드 상한" 기본값에 직접적 근거를 준다.
- 종료조건은 **이중 방어(defense-in-depth)** 가 표준: ① 의미적 합의 신호(consensus reached) + ② 하드 라운드 상한. 둘 중 하나라도 trip 되면 종료.
- **debate collapse / endless conflicting arguments** 가 알려진 실패 모드 ("The Value of Variance: Mitigating Debate Collapse"). 즉 무한루프는 spec 이 발명한 가설적 위험이 아니라 *실증된 실패 패턴*이다 — 연구의 정당성을 강화.
- **의미적 루프 탐지**: 단순 turn counting 으로는 "같은 아이디어, 다른 표현" 순환을 못 막는다 → **hash 기반 / 의미 유사도 기반 중복 탐지** 가 권장됨. spec 의 "신규 이슈 동결" 보다 정밀한 메커니즘.

**(b) Mixture-of-Agents (MoA) — 증류/종합 아키텍처**
- proposers(=페르소나 워커) → aggregator(=중재/종합) 의 **레이어드 아키텍처**가 정확히 spec 의 패널 구조와 동형. AlpacaEval 2.0 SOTA 달성으로 검증된 패턴.
- **MoA-Lite (2 layer)** 가 비용 대비 효율 — spec 의 "라운드 상한" 설계에 "1라운드(fan-out → 1회 종합)로도 충분할 수 있다"는 baseline 을 제공.
- **결정적 반례 — Self-MoA**: "Rethinking Mixture-of-Agents"(arXiv 2502.00674)는 *단일 최고 성능 모델*만 여러 번 aggregate 하는 Self-MoA 가 다양한 모델 혼합보다 +3.8% 우수하다고 보고. **이것은 spec 의 핵심 전제("다양한 페르소나가 단일 Opus 보다 낫다")에 정면으로 도전한다.** 연구가 반드시 측정해야 할 null hypothesis.

**(c) LLM-as-Judge Ensemble / LLM-Jury — 증류 품질·disagreement 신호**
- **panel disagreement isn't noise, it's signal** — 페르소나 간 이견은 손실해서는 안 되는 신호이며, "rubric 이 깨끗이 결정 못하는 = 사람 리뷰가 필요한 지점"을 flag 한다. spec 의 "핵심 이견 보존" 요구를 강화하는 근거이자, distilled contract 가 *반드시* disagreement 를 surface 해야 한다는 설계 제약.
- **Self-Consistency / multi-run**: 동일 판정을 seed 바꿔 반복 후 집계. 만장일치 = 높은 신뢰. 이는 페르소나 패널의 *값싼 대안*(같은 Opus N회 + 투표)을 제시.
- **Agreeableness bias / familial bias**: 단일 모델 군에서 나온 판정은 서로 동조하는 편향(self-inconsistency, Krippendorff α 0.3~0.8). cross-model 다수결이 이를 완화. → fork 가 페르소나를 *같은 Opus* 로 돌리면 다양성 이득이 제한될 수 있음(Self-MoA 와 연결).

**(d) Role-based SE Multi-Agent (MAGIS, AGILECoder)**
- Manager/Developer/QA Engineer/Tester 등 역할 분업이 GitHub issue resolution 에서 검증됨. spec 의 페르소나(보안/성능/가독성 등) 설계에 참고 가능한 역할 taxonomy 존재.
- 다만 이들은 **production 시스템**이고 fork 의 POC 는 review 1건이므로, 역할 수는 최소(2~3)로 시작하는 것이 MoA-Lite 교훈과 일치.

### 시사점

1. **종료조건은 이미 풀린 문제에 가깝다** — "consensus 신호 + 하드 라운드 상한(≤3)" 이중 방어가 업계 표준. spec 의 "최소 2안 비교" 는 이 표준 위에서 진행하면 빠르게 수렴.
2. **무한루프는 turn count 만으로 못 막는다** — 의미적 중복 탐지(hash/유사도)가 필요. spec 의 FR3("신규 이슈 동결")은 이 정밀도까지 명세해야 robust.
3. **증류는 disagreement 를 보존해야 가치** — distilled contract 의 품질 기준 = "이견을 압축하되 surface 한다". 이견을 평균내 지우면 패널 가치가 단일 Opus 이하로 떨어진다(LLM-jury 교훈).
4. **가장 큰 시사 — Self-MoA 반례**: 연구는 "페르소나 다양성이 정말 단일 Opus 보다 나은가"를 **반증 가능한 형태로** 측정해야 한다. 이게 빠지면 연구가 "패널이 돌아간다"만 보이고 "패널이 더 낫다"는 못 보인 채 Go 를 권고할 위험.

## 2. 요구사항 비판

### 누락

- **[누락-핵심] POC 성공/Go 판정 기준이 측정 불가능.** spec 의 DoD 와 phase 성공기준 2번은 "유한 라운드 수렴 + 증류 산출물 생성 + 워커 전문 미재흡수"를 요구하는데, 이는 **프로세스가 돌아갔다(liveness)** 는 증명일 뿐 **패널이 단일 Opus 보다 낫다(value)** 는 증명이 아니다. 현재 기준대로면 "패널이 가치 없어도 돌아가기만 하면 Go" 가 가능 — 연구의 핵심 질문(왜 단일 Opus 를 버리는가)에 답하지 못한다. **단일-Opus baseline 대비 비교 측정이 누락됨** (위 Self-MoA 반례가 이를 강제).
- **[누락] 증류 품질 평가 기준 부재.** "핵심 이견 보존"(plan 수동검증 3)이 유일한 정성 기준인데, *누가/어떻게* 보존 여부를 판정하는지 없음. 측정 가능한 proxy 필요(예: 페르소나가 제기한 distinct issue 개수 vs distilled contract 에 살아남은 개수 = issue retention rate).
- **[누락] 비용/지연 측정 부재.** 패널은 단일 Opus 대비 N배 토큰·시간. Go/No-Go 는 본질적으로 ROI 결정인데(phase 위험표도 "패널 가치 < 단일 Opus" 를 위험으로 명시) **비용 축이 DoD 에 없다.** MoA-Lite/Self-MoA 가 비용을 1급 변수로 다루는 이유.
- **[누락] 페르소나 수·구성 결정 근거 없음.** 몇 개 페르소나로 POC 하는지, 어떤 페르소나인지가 spec/plan 어디에도 없음. MoA 교훈상 이건 결과를 좌우하는 1급 변수(2 layer vs N layer, diverse vs self).

### 모순

- **[모순] Integration Test "no" 와 phase 통합테스트 시나리오 1 의 긴장.** spec 메타는 "Integration Test Required: no"인데 phase-22.md 통합 시나리오 1 은 POC 수렴을 "phase Done 조건 중 하나"로 통합테스트화. 둘이 정면 충돌은 아니나(research DoD 가 대체), spec 이 "no" 라 적은 게 오해 소지. **"POC 수렴 실증이 통합테스트를 대체"** 라고 명시하면 해소.

### 과잉 설계 (research 감안)

- **[과잉?] 5난점 중 3개(무한루프/불변식양립/context격리)는 이미 ADR-010/011 이 사실상 답을 줬다.** 무한루프=라운드 상한, 불변식양립=distilled contract 만 반납(ADR-011 규칙3/4), context격리=sub-agent fan-out 결과만 반환(ADR-010 ②③⑤). 이 셋은 "최소 2안 비교"가 ceremony 가 될 수 있음 — **연구 에너지를 종료조건+증류+(누락된)value 측정에 집중**하고, 나머지 3개는 "기존 ADR 적용 확인"으로 경량 처리하는 게 ROI 적합. (research 라 2안 비교 자체가 무의미하진 않으나, 동등 무게 배분은 과함.)

### 모호함

- **[모호] "수렴 신호" 정의가 spec 에 없음.** FR1 은 "수렴 신호 정의"를 *산출물로* 요구하나 spec 자체엔 후보가 없음. 연구의 입력으로 최소 후보(예: ① 신규 이슈 0건 라운드, ② 페르소나 간 합의율 임계, ③ aggregator 의 "충분" 자기판정)를 제시하면 연구가 빈 페이지에서 시작 안 함.
- **[모호] "archived spec 1건" 표본 선정 기준 없음.** 어떤 성격의 spec(논쟁적/단순)을 고르냐가 수렴 관찰 결과를 좌우. 의도적으로 *이견이 갈릴 만한* spec 을 골라야 패널 효용이 드러남(쉬운 spec 은 단일 Opus 로도 충분 → 패널 이득 안 보임).

## 3. 대안 제안

### 대안 A — 현재 spec 유지 + value 측정 축 보강 (최소 수정)
- **아이디어**: 현재 1-커맨드 POC 구조를 유지하되, DoD 에 "단일-Opus baseline 대비 비교"와 "비용/이견보존 정량 지표"를 추가. 같은 archived spec 을 ① 단일 Opus ② 페르소나 패널 둘 다 돌려 산출물을 나란히 비교.
- **장점**: 현재 구조 최소 변경. liveness 만 보던 연구가 value 까지 측정 → Go/No-Go 가 ROI 근거를 가짐. Self-MoA 반례에 대응.
- **단점**: 측정 작업 추가로 POC 부피 소폭 증가. "낫다"의 정성 판정에 여전히 주관 개입.

### 대안 B — N-vote ensemble baseline 을 먼저 (페르소나 전에 단순 앙상블)
- **아이디어**: 페르소나 부여 전에, *같은 Opus 를 N회* 돌려 self-consistency 투표(Self-MoA/self-consistency 패턴)부터 POC. 그 다음 페르소나 다양성이 N-vote 대비 추가 이득이 있는지 비교.
- **장점**: 가장 값싼 개입(페르소나 설계 불요)부터 검증 → 만약 N-vote 만으로 단일 Opus 를 이기면 페르소나 패널 자체가 over-engineering 일 수 있음을 조기 발견. "더 단순한 것부터" 원칙(CLAUDE.md §2)과 정합.
- **단점**: 연구 범위가 2층(N-vote → persona)으로 늘어 1 spec 에 과부하 가능. phase 의 "페르소나 패널" 프레이밍과 살짝 어긋남(but 그게 연구의 정직함).

### 대안 C — 설계-only 연구 (POC 제거)
- **아이디어**: §9.1 의 prototype 을 "if applicable" 로 해석, POC 없이 5난점 설계서 + Go/No-Go 만.
- **장점**: 가장 빠름·값쌈.
- **단점**: spec 의 핵심 논거("종료조건/증류는 *돌려봐야* 안다")를 스스로 부정. 수렴은 실증 없이 설계만으론 신뢰 못 함(debate collapse 가 실증 실패 패턴인 이유). **비권장.**

### 권장안

**대안 A (현재 spec 유지 + value 측정 축 보강) + 대안 B 의 baseline 아이디어 1줄 흡수.**

근거: 현재 spec 의 1-커맨드 POC·context 격리·연구-우선 프레임은 ADR-010/011 과 정합하고 잘 설계됨 — 구조를 바꿀 이유 없음. **단, 현 DoD 는 liveness 만 측정하고 value(단일 Opus 대비 우위)를 측정 안 해 Go 판정이 공허해질 위험이 가장 크다.** Self-MoA 반례가 이를 학술적으로 입증. 따라서 POC 를 "단일 Opus baseline 과 나란히 실행 + 이견보존율/비용 정량화"로 보강하는 최소 수정이 최고 ROI. 대안 B 는 별도 spec 으로 분리하기엔 무겁지만, POC 의 baseline 을 "단일 Opus 1회" 대신 "단일 Opus N회 투표"로 두면 한 줄로 흡수 가능(앙상블 자체의 기여를 페르소나 기여와 분리).

## 4. ADR 후보 추출

- **`persona-panel-orchestration`** (type: **decision**) — spec 이 이미 식별. research Go + 설계 확정 시 spec-22-02 머지 시점 작성. **유지.** (No-Go 면 "왜 안 하는가" 근거 자산화로 대체 — spec 이 이미 명시.)
- **[신규 후보] `review-value-baseline`** (type: **convention** 또는 **invariant**) — "모든 다관점/앙상블 리뷰 도입은 단일-모델 baseline 대비 value 측정을 Go 전제로 한다"는 결정. Self-MoA 반례가 보여주듯 "다양성이 항상 낫다"는 거짓일 수 있으므로, 이를 *불변식*으로 박으면 향후 유사 기능(cross-model review 등)에도 자동 적용. 단, research 결과가 나오기 전이라 **트리거 대기** 상태로 두는 게 적절(현재 작성은 시기상조).
- 그 외 ADR 가치 결정: **해당 없음** (무한루프/격리/불변식양립은 ADR-010/011 이 이미 커버 — 신규 ADR 불요).
