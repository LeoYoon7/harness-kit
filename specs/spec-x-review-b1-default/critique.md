# Spec Critique: spec-x-review-b1-default

> 독립 시니어 아키텍트 검토. 검토 대상 `specs/spec-x-review-b1-default/spec.md`. 배경 연구 `spec-x-persona-hybrid-research/report.md`. 작성 2026-06-09.

## 1. 유사 기법 조사

### 발견된 패턴/도구

- **Self-Consistency (Wang et al., 원 CoT 디코딩)**: 동일 프롬프트를 N회 독립 샘플링 후 majority vote 로 신뢰도 향상. 본 spec 의 "Opus×3 self-consistency" 가 정확히 이 계열 — 본 spec(B1)과의 비교: **지지**. 다만 원 기법은 *답이 하나*인 추론 과제(정답 majority vote)에 정의된 것이고, 코드 리뷰는 *열린 생성*(이슈 집합)이라 단순 vote 가 안 된다. 그래서 본 spec 은 vote 대신 "이견 보존 + 합의 수 표기" 로 변형했는데, 이 변형은 학계에서 **Universal Self-Consistency(USC)** / **Integrative Decoding(ID)** 로 별도 명명될 만큼 비자명한 적응이다. spec 이 이 점(열린 생성에서 vote 불가 → 합의 수 집계로 대체)을 명시하지 않아 §2 모호함으로 이어진다.

- **AdamsReview (Claude Code 다중 에이전트 PR 리뷰, 오픈소스)**: 본 spec 과 *가장 직접적인 산업 유사물* — Claude Code 위에서 워커를 병렬 dispatch 후 한 코멘트로 머지. 본 spec(B1)과의 비교: **부분 반박/보강**. AdamsReview 는 self-consistency(동일 프롬프트 N회)가 *아니라* 렌즈별 특화(correctness/security/test/perf) 워커를 쓴다. 즉 본 spec 의 generalist 1패스 + 3렌즈 묶음 쪽에 가깝고 self-consistency 축은 채택 안 함. 주목할 두 경고: ① **"5 focused agents over 200-line diff 는 single agent 보다 비싸다 → PR 크기(~200줄)로 실행 게이팅"** ② **"multi-agent review 는 프롬프트 scaffolding 의 bias 를 증폭한다"**(동일 프롬프트 N회면 bias 도 N회 상관 증폭). 본 spec 의 N=3 동일 프롬프트는 이 bias 상관 증폭에 *가장 취약한 구성*이다(아래 §1 시사점).

- **calimero ai-code-reviewer / diffray (오픈소스 다중 에이전트 리뷰)**: 2~10+ 특화 에이전트 병렬 + **합의 가중 스코어링**(findings 를 동의 에이전트 수로 가중). 본 spec(B1)과의 비교: **지지**. 본 spec 의 "합의 수(N/3)" 표기와 동형. diffray 는 "87% fewer false positives, 3x more real bugs" 를 주장하나 — AdamsReview 기사가 지적하듯 **공개 테스트셋 없는 마케팅 수치**라 근거로 인용 불가.

- **"Self-Consistency Is Losing Its Edge" (arXiv 2511.00751, 2025)**: 현대 frontier 모델에서 self-consistency 의 한계효용 측정. 본 spec(B1)과의 비교: **N=3 선택을 지지, 단 효용 기대치는 하향**. 핵심 수치 — Math-500/Gemini-2.5-Pro 에서 baseline 98% → 3 agents 99.2% → 15 agents 99.6%(15개로 늘려도 +0.4%p). 결론: "**moderate sampling(대략 3~10) 이 정확도/비용 최적, high-sample 은 비용 대비 무의미**". → 본 spec 의 N=3 은 이 "moderate" 하단에 정확히 위치해 **합리적 기본값**. 단 이 논문은 frontier 모델일수록 self-consistency *증분 자체가 작아진다*고 경고 — Opus 같은 고성능 모델에서 N=3 의 win 이 비용 3배를 정당화하는지는 본 spec 의 #48 표본(n=2)이 유일 근거이고, 외부 문헌은 "증분 작음" 쪽을 시사한다.

- **Panel of LLMs (PoLL) / "Jury" + 자기선호(self-preference) bias 문헌**: 다중 *모델 패밀리* 패널이 단일 모델 판정보다 신뢰. "동일 패밀리/동일 모델은 correlated blind spot 공유, 서로 다른 패밀리라야 bias 가 상쇄". 본 spec(B1)과의 비교: **반박 신호**. 본 spec 의 self-consistency 는 *동일 모델(Opus) 동일 프롬프트* — 문헌이 말하는 "correlated blind spot" 의 정의에 정면으로 해당한다. 즉 Opus 가 구조적으로 못 보는 버그는 3회 돌려도 3회 다 놓친다. 이 갭은 본 spec 이 OOS 로 둔 `hk-gemini-review`(cross-model)가 메우게 설계돼 있으나, spec 본문이 "self-consistency 의 독립성 한계는 cross-model 채널이 보완" 이라는 **시스템 수준 분담**을 명시하지 않는다(§2 누락).

### 시사점

1. **외부 근거는 N=3 을 "합리적 하단"으로 지지하되, 효용 기대치는 낮춰야 한다.** frontier 모델에서 self-consistency 증분은 작다(2511.00751). 본 spec 의 비용 1→4 는 self-consistency(3) 보다 **generalist 1패스가 진짜 win**(#48 두 표본 모두 PASS)이라는 점을 더 강조해야 정당화가 단단하다. 실제로 #48 데이터에서도 깊이 회복의 주역은 generalist 이지 self-consistency 의 majority 가 아니었다.

2. **동일-모델 self-consistency 의 correlated-bias 한계를 명문화하라.** PoLL 문헌상 동일 모델 N회는 독립 채점자가 아니다. 본 spec 은 이 한계를 cross-model(`hk-gemini-review`)이 분담한다고 *시스템 차원에서* 적어야 한다 — 안 그러면 "N=3 이면 충분히 독립적" 이라는 오해 위에 후속 결정이 쌓인다.

3. **AdamsReview 의 두 운영 교훈(크기 게이팅 / bias 증폭)을 도입하라.** 특히 "diff 크기 무관 항상 4 dispatch" 는 trivial diff 에서 비용 낭비 — #48 권고 B(자동 라우팅)를 OOS 로 둔 것은 타당하나, *최소한* "작은 diff 는 N 축소" 같은 문서상 가이드는 값싸다(§3 대안 A).

## 2. 요구사항 비판

### 누락

- **서브에이전트 부분 실패/타임아웃 처리**: 4 병렬 dispatch 중 1~2개가 실패/빈 반환하면 증류를 어떻게 하나? "3/3 합의" 의 분모가 가변이 되는데 정의가 없다. → 최소 "k/4 반환 시에도 증류 진행, 미반환 워커는 합의 분모에서 제외 + 보고에 명시" 같은 fallback 이 필요. `code-review.md` 는 ship 게이트라 *부분 결과로도 게이트가 굴러가야* 한다.
- **합의 수(N/3)의 의미·임계 정의**: 요구사항 3·4 가 "합의 수" 를 표기하라 하지만 *그것으로 무엇을 하는지*(예: 1/3 만 제기한 이슈는 Minor 강등? 3/3 은 Critical 승격?)가 없다. self-consistency 의 신호가 "합의 분포" 인데 그 분포를 *해석하는 규칙*이 비어 있어 표기만 하고 의사결정엔 안 쓰는 장식이 될 위험.
- **이슈 dedup 기준**: 4 워커가 "같은 버그를 다른 문장으로" 제기할 때 *동일 이슈 판정 기준*이 없다. 증류표의 "합의 N/3" 정확도는 dedup 품질에 전적으로 의존하는데, .md 지시문에 dedup 휴리스틱(파일:라인 일치? 의미 일치?)이 없으면 합의 수 자체가 부정확해진다. **이것이 B1 의 핵심 신호를 좌우하는 단일 최대 갭이다.**
- **generalist vs 3렌즈 중복 처리**: generalist 가 "렌즈 제약 없음" 이라 3렌즈 영역과 필연 겹친다. 같은 이슈를 렌즈 리뷰어 2명 + generalist 가 제기하면 "합의 3/3 + generalist" 인가, 아니면 별개 source 인가? source 필드(`spec대비|품질|테스트|정독`)와 합의 카운트의 관계가 미정의.
- **결과 계약 스키마의 source enum 불일치**: 요구사항 2는 `source` 를 자유 텍스트처럼 두지만 plan.md:74 는 `spec대비|품질|테스트|정독` enum 으로 고정. spec 본문엔 이 enum 이 없다 — spec↔plan drift. 또한 generalist 가 테스트 갭을 발견하면 source 가 `테스트`인가 `정독`인가 모호.
- **`hk-gemini-review` 와의 시스템 분담 명시**: §1 시사점 2 참조. self-consistency 의 동일-모델 한계를 cross-model 채널이 메운다는 설계 의도가 spec 의 OOS 항목(63줄)에 *한 줄 사실*로만 있고 *왜 이 분담이 self-consistency 의 독립성 결핍을 보완하는지* 근거가 없다.

### 모순

- **"호출 측 무변경"(NFR2) vs 비용 4배(NFR4)**: 출력 경로·요약 포맷은 유지하나, ship 마다 도는 게이트의 *지연·비용*이 4배가 되는 것은 호출 측(`hk-ship` 게이트 사용자)에 체감되는 변화다. "무변경" 은 *인터페이스* 무변경으로 한정해 표현해야 정확. 현재 문구는 비용 인지(NFR4)와 긴장.
- (그 외 직접 모순 없음.)

### 과잉 설계

- **N=3 self-consistency 자체가 본 spec 범위에선 과할 수 있음**: #48 데이터(report.md S1/S2 표)를 다시 보면 *깊이 회복의 주역은 generalist*였고, B1 이 H1 을 이긴 것도 generalist 덕이다. self-consistency 의 3회 반복이 단독으로 기여한 증분은 #48 표에서 분리 측정되지 않았다(B0 vs B1 차이 = generalist 추가분이지 N 증가분이 아님). 즉 **"N=3" 의 비용 3배는 #48 로 직접 검증된 바 없고**, 외부 문헌은 frontier 모델에서 그 증분이 작다고 본다. generalist 는 강한 근거, self-consistency N=3 은 약한 근거 — 둘을 한 묶음으로 "검증됨" 처리하는 것은 과대 일반화. (→ 권장안에서 N 기본값 재고.)
- **증류표 4컬럼 구조는 적정**(과잉 아님): 제기자/합의수/심각도/근거는 최소 필수. 단 위 dedup 누락 탓에 "합의수" 컬럼이 신뢰 못 할 수 있음 — 구조가 과한 게 아니라 *채울 데이터의 정의*가 빈 것.

### 모호함

- **"증류(distillation)" 의 .md 재현성**: 요구사항 3은 "이슈별 구조화 머지표로 통합, 이견 보존, 평탄화 금지" 라 하지만, 에이전트가 *재현 가능하게* 실행하려면 (a) 동일 이슈 판정(dedup) 알고리즘, (b) 심각도 충돌 시(리뷰어마다 Critical/Major 다름) 결정 규칙, (c) 합의 카운트 산출법이 필요. 셋 다 .md 에 없으면 매 실행마다 디렉터 재량으로 표가 달라져 self-consistency 의 *재현성* 자체가 깨진다(아이러니).
- **"이견 보존(평탄화 금지)"**: 의도는 명확하나 *조작적 정의*가 없다. "1/3 만 제기한 이슈도 표에 남긴다" 인지, "심각도 이견도 별도 행으로 남긴다" 인지 해석이 갈린다. 테스트(C1)가 "이견 보존" *단어*만 grep 하므로 구현 충실도는 검증 못 함.
- **"self-consistency 합의 분포" 보고(요구사항 4)**: "분포" 의 형식 미정 — 히스토그램? "3/3: N건, 2/3: M건, 1/3: K건" 텍스트? 보고 포맷이 `code-review.md` 요약에 들어가는데 형식이 비어 있어 호환성(NFR2 "요약 포맷 그대로") 주장과 충돌 가능.
- **"N 은 문서상 조정 가능 기본값"(NFR4)**: config 슬롯은 OOS(66줄)인데 "조정 가능" 이 *무엇을* 뜻하는지 모호 — 사용자가 .md 를 직접 편집? 런타임 인자? "기본 N=3, 변경하려면 .md 의 dispatch 횟수를 수동 편집" 정도로 조작적 정의 필요.

## 3. 대안 제안

### 대안 A: 비용 적응형 N (diff 크기 게이팅)

- **아이디어**: generalist 1패스는 항상, self-consistency N 은 diff 크기로 적응(예: <100줄 N=1, <300줄 N=2, 그 이상 N=3). AdamsReview 의 "~200줄 게이팅" 산업 관행 + 2511.00751 의 "small diff 엔 self-consistency 증분 무의미" 를 반영.
- **장점**: trivial ship 의 비용 낭비 제거(대부분의 spec-x diff 는 작음). #48 의 generalist win(항상 유효)은 보존. 비용 1→4 의 *평균* 을 크게 낮춤. .md 지시문에 분기 한 줄로 표현 가능(스크립트 불요).
- **단점**: 분기 규칙이 또 하나의 결정 — "100/300 경계" 의 근거 박약(임의). #48 은 적응형을 측정 안 함(검증 공백). spec 의 "단순 기본값" 철학과 약간 긴장.

### 대안 B: generalist 정독 단독(N=1) + self-consistency 생략

- **아이디어**: B1 에서 self-consistency 를 빼고 generalist 정독 1패스 + 기존 3렌즈 1회만(총 워커 2). #48 이 검증한 *진짜 win(깊이 회복)*만 채택, 약한 근거의 N=3 은 포기.
- **장점**: 비용 1→2 로 최소. #48 데이터로 직접 정당화되는 부분만(generalist) 채택 — 과대 일반화 회피. correlated-bias 문제(동일 모델 N회)도 자연 소거. 외부 문헌(frontier self-consistency 증분 작음)과 가장 정합.
- **단점**: self-consistency 의 비결정성 보정 효과를 *완전히* 포기 — #48 S1 에서 B0(self-consistency)도 단독으로 일부 GT 회복했으므로 N=1 은 그만큼 손실. spec 의 명시 목표("self-consistency + generalist = B1")와 다른 패턴이라 #48 권고 A 의 *문자적* 구현이 아님.

### 대안 C: 합의 집계를 별도 judge 서브에이전트로 분리

- **아이디어**: 디렉터가 직접 증류하는 대신, 4 계약을 받아 dedup·합의카운트·심각도조정을 수행하는 *전용 judge 서브에이전트*(1개 추가)에 위임. 디렉터는 judge 의 증류 결과만 받음(ADR-010 정합).
- **장점**: 증류 로직(dedup/충돌해소)을 한 곳에 격리 → 재현성↑(모호함 해소). 디렉터 메인 context 가 4 계약 raw 로 오염 안 됨(ADR-010 ②③축 강화). LLM-as-judge 문헌의 "aggregation 은 별도 판정자" 권고와 정합.
- **단점**: 워커 1개 추가(비용 4→5). judge 자신이 동일 Opus 면 self-preference bias(문헌 경고) 유입 — cross-model judge 라야 이상적이나 그건 `hk-gemini-review` 영역. 증류가 단순한 현 규모(이슈 수십 개)엔 over-engineering 일 수 있음.

## 권장안

**현재 spec 유지를 기반으로 하되, 두 가지 보정을 Plan Accept 전에 반영할 것을 권장한다(대안 A 의 부분 채택 + 누락 보강).**

1. **dedup·합의·증류 알고리즘의 조작적 정의를 spec/커맨드에 명문화**(§2 모호함의 핵심). 이것 없이는 B1 의 핵심 신호(합의 분포)가 재현 불가 — 이는 *대안 선택 이전에* 반드시 메워야 할 **blocking 갭**이다. 최소: (a) dedup = `파일:라인` 근접 + 의미 일치 디렉터 판단, (b) 심각도 충돌 = 최고 심각도 채택 + 이견 행 보존, (c) 합의 = dedup 후 동일 이슈를 제기한 워커 수 / 반환 워커 수.

2. **N=3 의 근거 약함을 인지한 안전장치** — 현 spec 의 N=3 유지는 #48 권고 A 의 문자적 구현이라 정당하나, 외부 문헌(2511.00751)과 #48 의 *분리 미측정* 을 감안해 **NFR4 에 "N 은 약근거 기본값, B2 후속에서 N=1 vs 3 분리 측정 권장" 한 줄 추가**. 대안 B(N=1) 로 *지금* 바꾸는 것은 #48 권고 A 와 어긋나므로 비권장 — 대신 후속 측정 hook 만 남긴다.

> 대안 A(적응형 N)는 매력적이나 #48 미검증 + 경계값 임의성 탓에 *지금* 도입은 비권장. NFR4 의 "조정 가능" 문구를 살려 **문서상 옵션**으로만 남기고, 실제 적응형은 B(라우팅, #48 권고 B)과 함께 별도 spec 으로 미룬다.

요약 — **현 spec 의 구조(B1, N=3, 증류표)는 유지하되, "증류 알고리즘 명문화"(blocking)와 "부분 실패 fallback"(누락)을 요구사항에 추가**한 뒤 Accept.

## 4. ADR 후보 추출

- [x] **계획된 ADR 적절성 (ADR-013/014)**: **둘 다 범위·type 적절.**
  - `ADR-013-review-value-baseline` (invariant): "다관점 리뷰 도입은 baseline 대비 value 측정이 Go 전제" — 본 spec 자신이 이 불변식의 *적용 사례*(self-consistency baseline 위에 generalist 추가를 #48 로 측정)라 자기정합. type `invariant` 적절(향후 모든 리뷰 변경에 강제되는 절차 규약, 1회성 결정 아님). **단 보강 제안**: "baseline" 의 정의를 ADR 본문에 못박을 것 — 본 spec 에서 baseline 은 self-consistency(B0)이지만, ADR-013 이 "self-consistency 가 baseline" 으로 고정하면 *self-consistency 자체의 가치 미측정* 이라는 순환이 생긴다(N=3 의 가치는 무엇 대비 측정?). ADR-013 은 "baseline = *직전 채택된 리뷰 구성*" 같은 상대적 정의가 안전.
  - `ADR-014-review-eval-independence` (invariant): "채점자/GT 가 피측정 모델과 독립" — PoLL/self-preference 문헌이 강하게 지지(§1). type `invariant` 적절. **보강**: §1 의 "동일-모델 self-consistency 는 독립 채점자가 아니다" 를 ADR-014 가 *명시적으로 포섭*하면, 본 spec 의 self-consistency 가 왜 cross-model(`hk-gemini-review`) 채널과 분담해야 하는지의 근거가 ADR 레벨에서 확보된다.

- [ ] **추가 후보**: `review-cost-adaptivity` — type: `tradeoff` — **있음(약한 권장)**. 이유: 본 spec 이 "비용 1→4, N=3, 적응형 보류" 라는 *비용-효용 트레이드오프 결정*을 내리는데, 이는 invariant(불변 규약)도 convention(관행)도 아닌 *현 시점의 비용 균형 선택*이다. 외부 문헌(2511.00751 frontier 증분 작음 / AdamsReview 크기 게이팅)이 "더 적은 N + 크기 게이팅" 을 시사하는 상황에서, "왜 지금은 블랭킷 N=3 인가(= #48 권고 A 충실 + 적응형 미검증)" 를 tradeoff ADR 로 박으면 후속 B2/라우팅 spec 이 이 결정을 *근거와 함께* 뒤집을 수 있다. — **단 강제는 아님**: spec 의 NFR4 + 본 critique 권장안 2(NFR4 한 줄 추가)로도 흡수 가능하므로, ADR 신설이 부담이면 NFR4 보강으로 대체 가능. 나머지(N 기본값 정책, 비용 상한)는 이 한 ADR 또는 NFR4 로 충분 — **그 외 추가 없음.**
