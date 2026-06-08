# Research Report: spec-22-01 페르소나 리뷰 패널

> §9.2 Research Report — 본 문서가 spec.md 를 대체하는 핵심 산출물이다.
> 연구 진행에 따라 각 섹션을 채운다. Definition of Done = spec.md §DoD (Research §9.1).

## 0. 요약 (Executive Summary)

<!-- Task 5 에서 최종 작성: 한 문단 결론 + Go/No-Go -->
_(연구 완료 후 작성)_

## 1. 문제 정의

review 커맨드(`hk-code-review`/`hk-spec-critique`/`hk-phase-review`)의 단일 Opus 리뷰를 **페르소나 패널**(다관점 워커 + 종합/중재)로 바꿀지·어떻게 할지 결정한다. 핵심은 5난점(종료조건/증류/무한루프/검증불변식/context오염) 해소 + **value(단일 Opus 대비 우위) 반증가능 측정**.

## 2. 5난점 설계 (각 ≥2안 트레이드오프)

### 2.1 종료 조건 (consensus + 라운드 상한 ≤3)

| 안 | 메커니즘 | 장점 | 단점 |
|---|---|---|---|
| A. 고정 1라운드 | 병렬 리뷰 1회 → 종합 1회, 중재 없음 | 무한루프 불가·비용 예측가능·최단 | 이견 미해소(평탄화) |
| B. consensus + 하드 상한 | 매 라운드 중재자가 "수렴?" 판정, 미수렴 시 +1라운드, **≤3** | 이견 해소 기회 + 상한 안전망 | 판정 비용, consensus 판정 주관성 |
| C. 이견-한정 2차 | 1차 병렬 → *충돌 이슈만* 2차 미니 토론 → 종합 | 비용 효율(전체 재실행 X) + 이견 집중 | "충돌 이슈" 식별 로직 필요 |

**권장**: **C 우선, B 를 fallback** — MAD(Multi-Agent Debate) 연구가 "전체 재토론"의 비용·수렴 난점을 지적하므로, 이견만 2차로 좁히는 C 가 ROI·종료성에서 유리. 상한(≤3)은 어느 안이든 하드 안전망으로 강제. POC 에서 C 의 "충돌 이슈 식별"이 실제 동작하는지 검증.

### 2.2 증류 (이견 보존)

| 안 | 메커니즘 | 장점 | 단점 |
|---|---|---|---|
| A. 자유서술 종합 | 중재자 LLM 이 결과 계약을 받아 산문 1장 | 자연스러운 종합·읽기 쉬움 | 중재자가 이견을 *평탄화*할 위험(측정 불가) |
| B. 구조화 머지 | 이슈별 표(이슈 / 제기 페르소나 / 합의여부 / 심각도 / 근거) | 이견 명시 보존 + **issue retention 측정 가능** | 형식 경직, 표 비대 가능 |

**권장**: **B (구조화 머지)** — critique 핵심(이견은 노이즈 아닌 신호, LLM-jury)을 살리려면 평탄화를 막아야 하고, issue retention rate(§3.2) 측정도 B 라야 가능. 산문 요약은 표 위에 *선택적* 1문단으로 덧붙임.

### 2.3 무한 루프 방지 (의미적 중복 탐지)

| 안 | 메커니즘 | 장점 | 단점 |
|---|---|---|---|
| A. turn count 상한만 | 라운드 ≤ N | 단순 | 같은 이슈 반복하며 상한까지 비용 소모 |
| B. 신규-이슈-비율 종료 | 새 라운드가 신규 distinct 이슈를 임계% 미만 추가하면 종료 (정규화/유사도 매칭으로 의미적 중복 판정) | 진전 없으면 *조기* 종료 | 유사도 임계 튜닝 필요 |

**권장**: **A + B 결합** — 하드 상한(A, ≤3)은 최악 방어, 신규-이슈-비율(B)은 정상 조기종료. turn count 만으론 "신규로 가장한 재실행"을 못 막는다(critique 지적). 임계는 POC 에서 보수적으로 시작(예: 신규 distinct 이슈 0건이면 종료).

### 2.4 검증 불변식 양립 (ADR-010/011)

**긴장**: 중재자가 종합하려면 페르소나 의견을 "이해"해야 하는데, ADR-010 은 *워커 transcript 전문 재흡수 금지*.

**해소**: 페르소나 워커는 transcript 가 아니라 **구조화된 결과 계약**(이슈 목록 + 심각도 + 근거 1줄)만 반환한다. 중재자는 *계약만으로* 종합하므로 전문 재흡수가 아니다 — "이해"는 계약 수준에서 충분하다. 즉 결과 계약 자체가 이미 distilled. **ADR-010 이 그대로 커버 → 신규 ADR 불요.** (불변식 위반 아님을 POC §5.1 격리 확인으로 실증.)

### 2.5 context 격리

페르소나 워커 = **sub-agent(별도 context)**. 메인 세션은 결과 계약만 수신하고, 워커 transcript 는 sub-agent 안에서 소멸. 패널·중재 전 과정이 sub-agent 경계 안에서 일어나고 메인엔 최종 distilled contract 1건만 올라온다. POC §5.1 에서 "메인 context 에 워커 전문 미유입"을 확인한다.

## 3. 측정 설계 (value 를 반증가능하게)

### 3.1 value 축 (놓친 이슈 / 거짓 양성 / 실행자 평가)

동일 spec 에 **패널 vs baseline** 을 돌리고 비교:
- **recall proxy**: 진짜 이슈 발견 수 (ground truth = 사후 사람 판정 또는 해당 spec 의 실제 walkthrough/critique 가 잡았던 이슈).
- **precision proxy**: 거짓 양성(무효·과잉) 이슈 수.
- **고유 관점 수**: baseline 이 못 낸 *유효* 신규 관점 수 (페르소나 다양성의 직접 증거).

### 3.2 증류 품질 proxy (issue retention rate)

`retention = distilled contract 잔존 distinct 이슈 수 / 페르소나 합집합 distinct 이슈 수`. 너무 낮으면 이견 손실(평탄화), 너무 높으면 노이즈 미정제. 적정 밴드를 POC 관찰로 제시(절대 정답값보다 *평탄화 여부* 판정이 목적).

### 3.3 비용/지연 (ROI)

- **토큰**: 패널(페르소나 sub-agent 합 + 중재) vs baseline(단일 Opus N회) 총 출력 토큰.
- **지연**: wall-clock (팬아웃 병렬성 반영).
- value 증분 대비 비용 배수로 ROI 판정 — Go/No-Go 의 핵심 입력.

### 3.4 baseline 정의 (단일 Opus N회 투표 — self-consistency)

baseline = **동일 리뷰 프롬프트를 단일 Opus 로 N회(기본 3회) 실행 후 이슈 합집합/다수결**. 페르소나 *없는* 앙상블이라, "패널이 단일 Opus 보다 나음"이 ① 앙상블(여러 번) 효과인지 ② 페르소나 다양성 효과인지를 분리한다 (critique·Self-MoA 반영). 패널이 self-consistency baseline 도 못 이기면 페르소나 부여의 가치 미입증.

### 3.5 연구 파라미터 (페르소나 수·구성 / 표본 선정)

- **페르소나 수**: **3** (비용·다양성 균형; MoA/패널 연구의 통상 소수 패널). `hk-spec-critique` 맥락 페르소나 후보: ① 설계자(아키텍처·단순성), ② 규제자(거버넌스·불변식·리스크), ③ 사용자 옹호자(DX·도그푸딩·모바일 UX).
- **표본 선정 기준**: archived spec 중 **설계 선택지가 실제로 갈렸던**(critique.md 존재 + 대안 비교가 컸던) 1건. 후보: `archive/specs/spec-x-notify-channel-formatter`(대안 B embed 와 갈림) 또는 `archive/specs/spec-x-install-ignore-coverage`(루트 침입 .gitignore 대안 분석). Task 4 에서 1건 확정.

### 3.6 ADR 정합 점검

- ADR-008(human-gate): 패널은 *리뷰 의견*만 생성, Plan Accept/Ship 게이트 미위임 — 정합.
- ADR-010(orchestration): 결과 계약만 반환(§2.4) — 정합.
- ADR-011(director): 디렉터가 패널 dispatch·검증 보유 — 정합.

## 4. POC 설계

<!-- Task 3 — scripts/research/persona-panel-poc.md 요약 -->
_(미작성)_

## 5. POC 실행 결과

<!-- Task 4 — scripts/research/persona-panel-poc-run.md 증빙 -->
### 5.1 liveness (수렴 / 증류 / 격리)
_(미작성)_

### 5.2 value (패널 vs baseline 비교표)
_(미작성)_

## 6. Go / No-Go 권고

<!-- Task 5 — value > baseline 입증 여부 기반 명시 결론 + 근거 -->
_(미작성)_
