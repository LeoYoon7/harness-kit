# spec-x-review-b1-default: 코드 리뷰 기본 패턴을 B1(self-consistency + generalist 정독)로 업그레이드

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-review-b1-default` |
| **Phase** | 없음 (spec-x, Solo) |
| **Branch** | `spec-x-review-b1-default` |
| **상태** | Planning |
| **타입** | Refactor (리뷰 메커니즘 재구성) + Docs (ADR 2종) |
| **Integration Test Required** | no |
| **작성일** | 2026-06-09 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

`/hk-code-review` 는 **단일 Opus 서브에이전트**가 3 렌즈(spec 대비 구현 / 코드 품질 / 테스트 커버리지)로 리뷰하고 `code-review.md` 에 저장한다. ship pre-flight 게이트의 기본 리뷰 채널이다.

직전 연구 `spec-x-persona-hybrid-research`(#48, 2026-06-09)가 cross-model blind 채점(Gemini)으로 리뷰 패턴의 value 를 ≥2 표본 측정했다. 결론:

- **generalist 정독 1패스 = 깊이 lever** — 두 표본 모두에서 단일 리뷰어가 놓친 구체 버그(awk locale/byte-count, fence desync, UTF-8 절단)를 회복. 값싸고 항상 유효.
- **self-consistency(Opus×N) + generalist 정독 = B1 패턴** — 깊이 표본(S2)에서 페르소나 패널(H1)을 cheaperEqual 로 지배. 폭 표본(S1)에서도 baseline(B0) 대비 우위.
- 권고 A. **`hk-*-review` 기본을 B1 로 업그레이드**하고, 페르소나 패널은 폭 지배(설계/UX/거버넌스) 리뷰 한정 opt-in 으로 문서화.

### 문제점

1. **깊이 갭** — 단일 리뷰어는 비결정성 탓에 한 번의 패스로 구체 구현/locale/엣지 버그를 일관되게 잡지 못한다(phase-22·#48 실증). 정독 lever 부재.
2. **연구 결론이 코드에 미반영** — #48 의 측정된 win(B1)이 Icebox 권고로만 남아 실제 리뷰 품질에 기여하지 못함.
3. **리뷰 value 측정·독립성 원칙이 비형식화** — "다관점 리뷰는 baseline 대비 측정 후 채택", "측정 채점자는 피측정 모델과 독립" 이라는 #48 의 방법론적 교훈이 ADR 로 박히지 않아 향후 리뷰 변경 시 순환 평가가 재발할 위험.

### 해결 방안 (요약)

`/hk-code-review` 의 리뷰 메커니즘을 **B1 패턴**(독립 Opus 리뷰어 N=3 self-consistency + generalist 정독 1패스 → 디렉터 증류)으로 재구성하고, 페르소나 패널을 폭 지배 리뷰 한정 opt-in 으로 같은 커맨드에 문서화한다. 그 방법론적 불변식을 ADR 2종(`review-value-baseline`, `review-eval-independence`)으로 형식화한다.

> **깊이 회복 주역 = generalist**: #48 데이터에서 깊이 갭을 메운 것은 generalist 정독이며(B0→B1 차이), N=3 self-consistency 의 비용 증분은 분리 미측정. self-consistency 는 비결정성 보정 보조 lever 로 두되 N=3 은 약근거 기본값으로 표기한다(NFR4).
> **독립성 시스템 분담**: 동일-모델(Opus) self-consistency 는 PoLL 문헌상 correlated blind spot 을 공유해 *독립 채점자가 아니다* — Opus 가 구조적으로 못 보는 버그는 N회 모두 놓친다. 이 독립성 결핍은 본 spec 이 OOS 로 두는 cross-model 채널(`hk-gemini-review`)이 분담한다(ADR-014 가 이 분담을 포섭).

## 🎯 요구사항

### Functional Requirements

1. **B1 dispatch** — `/hk-code-review` 가 독립 서브에이전트 4개를 병렬 dispatch 한다. ① 기존 3-렌즈 리뷰어 Opus×3(self-consistency) + ② generalist 정독 Opus×1(렌즈 제약 없이 구체 구현/플랫폼/locale/엣지/테스트 갭 집중).
2. **결과 계약만 반환** — 각 서브에이전트는 `{issue, severity, rationale, source}` 구조의 결과만 반환한다(transcript 금지, ADR-010 정합). `source` enum = `spec대비` | `품질` | `테스트` | `정독`(=generalist). 리뷰어 R1~R3 는 `spec대비`/`품질`/`테스트` 중 해당값, generalist 는 `정독`.
3. **증류(distillation) — 조작적 정의 명문화** (재현성 필수 — 규칙 없으면 매 실행 디렉터 재량으로 표가 달라져 self-consistency 재현성이 깨짐):
   - **dedup**: 동일 이슈 판정 = `파일:라인` 근접 우선, 모호 시 의미 일치를 디렉터가 판단. dedup 후 단일 이슈로 병합.
   - **합의 수**: dedup 후 *그 이슈를 제기한 워커 수 ÷ 반환 워커 수*(예: 2/4). self-consistency 의 신호값.
   - **심각도 충돌**: 워커 간 심각도 상이 시 *최고 심각도 채택* + 이견을 별도 행/주석으로 보존.
   - **이견 보존(평탄화 금지)**: 1워커만 제기한 이슈도 표에서 제거 금지. generalist 고유 발견·심각도 이견 모두 남긴다.
   - 통합 산출 = 이슈별 머지표(이슈 / 제기 워커·source / 합의 수 / 심각도 / 근거).
4. **부분 실패 fallback** — 4 dispatch 중 일부 실패/빈 반환 시에도 *반환된 k개로 증류 진행*. 합의 분모 = 반환 워커 수(k), 미반환 워커는 `code-review.md` 에 명시. ship 게이트는 부분 결과로도 동작해야 한다.
5. **저장·보고** — 증류 결과를 `code-review.md` 에 저장(기존 경로 유지)하고, 요약을 보고한다. 요약 = 전체 평가 / Critical·Major·Minor 수 / **합의 분포**(텍스트, 예: `4/4: N건, 3/4: M건, 2/4: K건, 1/4: L건`) / 미반환 워커 수.
6. **페르소나 패널 opt-in 문서화** — 동일 커맨드 안에 "폭 지배(설계/UX/거버넌스 분기 큰) 리뷰 한정 opt-in" 섹션을 둔다. 언제 쓰는지 + 어떻게(페르소나 3 — 설계자/규제자/사용자 옹호자 수동 dispatch) + 미구현 명시 + #48 근거 링크.
7. **ADR 2종 작성**:
   - `ADR-013-review-value-baseline` (type: `invariant`) — 다관점 리뷰 도입은 baseline 대비 value 측정을 Go 전제로 한다. **baseline = 직전 채택된 리뷰 구성**(상대적 정의 — self-consistency 자체를 baseline 으로 고정하면 self-consistency 의 가치가 무엇 대비 측정되는지 순환).
   - `ADR-014-review-eval-independence` (type: `invariant`) — 리뷰 value 측정은 채점자/ground-truth 가 피측정 모델과 독립(cross-model/사람 blind)이어야 한다. **동일-모델 self-consistency 는 독립 채점자가 아님을 명시 포섭** — 그 독립성 결핍을 cross-model(`hk-gemini-review`) 채널이 분담한다.
8. **도그푸딩 미러 동기화** — `sources/commands/hk-code-review.md` 변경은 `.claude/commands/hk-code-review.md` 에 동일 반영(ADR-003).

### Non-Functional Requirements

1. **bash/마크다운만** — 커맨드는 `.md` 지시문. 실행 가능한 새 스크립트 도입 없음(검증은 grep 기반 구조 테스트).
2. **인터페이스 무변경** — ship pre-flight 게이트(`hk-ship.md`)·`code-review.md` 출력 경로는 유지(호출 측 코드 무변경). "무변경" 은 *인터페이스* 한정 — 비용·지연은 증가(NFR4)하므로 게이트 사용자에 체감 변화 있음.
3. **거버넌스 무변경** — constitution/agent.md 본문 미수정(단어 예산 ADR-012 압박 회피). 불변식은 ADR 로 외부화.
4. **비용 인지 + N 근거 정직화** — 기본 리뷰가 서브에이전트 1→4 로 증가(self-consistency N=3 + generalist 1). **#48 의 깊이 회복 주역은 generalist 이며, N=3 self-consistency 의 비용 3배 증분은 #48 로 분리 미측정 + 외부 문헌(arXiv 2511.00751)상 frontier 모델에서 증분 작음 — N=3 은 "moderate(3~10) 하단" 으로 합리적이나 *약근거 기본값*.** 적응형 N(diff 크기 게이팅)은 본 spec 에서 미구현, 문서상 옵션으로만 남긴다(별도 spec — `review-cost-adaptivity` 트레이드오프 흡수). 후속 B2 에서 N=1 vs N=3 분리 측정 권장.

## 🚫 Out of Scope

- **`hk-phase-review` B1 적용** — #48 POC 는 *코드 리뷰*(diff vs ground truth)만 검증. phase 회고(다파일 감사)의 self-consistency 는 미검증 + 비용 우려(Opus×N over many files). 본 spec 제외, 필요 시 별도 항목.
- **`hk-spec-critique` 변경** — 코드 리뷰가 아닌 사전 spec 비평(다른 단계). 제외.
- **`hk-gemini-review` 변경** — cross-model 채널 자체가 B1 의 "독립 채점" lever(동일-모델 self-consistency 의 correlated blind spot 을 분담, ADR-014 포섭). 변경 불요.
- **페르소나 패널 *구현*** — phase-22 No-Go 로 미구현 상태 유지. 본 spec 은 opt-in *문서화*만(코드 없음).
- **자동 라우팅(폭/깊이 판별) 및 적응형 N(diff 크기 게이팅)** — #48 권고 B(보류) + critique 대안 A. 미검증·경계값 임의성으로 본 spec 미착수. NFR4 에 문서상 옵션으로만 언급, 실제 구현은 후속 spec.
- **self-consistency N 의 설정값화(config)** — 기본 N=3 문서 명시로 충분. config 슬롯 신설은 over-engineering.

## 📑 ADR 후보 (Architecture Decision Records)

- [x] ADR 가치 있는 결정 있음 → 후보:
  - `review-value-baseline` (type: `invariant`) — ADR-013
  - `review-eval-independence` (type: `invariant`) — ADR-014
- [ ] 없음

> 두 ADR 은 #48 연구가 이미 *내린* 결론을 형식화한다(net-new 아키텍처 결정 아님 — spec-x 정합 근거).

## 🔍 Critique 결과 (선택)

Opus 서브에이전트 critique 실행 (전문: `specs/spec-x-review-b1-default/critique.md`). 외부 문헌(self-consistency 적정 N — arXiv 2511.00751 / AdamsReview·calimero·diffray 산업 사례 / PoLL·self-preference bias) 대조. 권장안 = **현 구조(B1/N=3/증류표) 유지 + 증류 알고리즘 명문화(blocking) + 부분실패 fallback + N=3 약근거 정직화**. 사용자 결정(`권장`)으로 A~F 반영, G(`review-cost-adaptivity` ADR)는 NFR4 흡수. 핵심 반영:
- 증류 조작적 정의(dedup/합의/심각도충돌/이견보존) → FR3 (재현성 blocking 갭 해소).
- 부분 실패 fallback → FR4.
- 동일-모델 self-consistency 비독립 → cross-model 분담 명시(배경·FR7 ADR-014).
- N=3 약근거 표기 + 적응형 N 문서 옵션화 → NFR4.
- NFR2 "인터페이스 무변경" 한정 + `source` enum spec↔plan 동기화.

## ✅ Definition of Done

- [ ] `tests/test-review-b1.sh` 작성 + 전 항목 PASS (B1 용어 / 증류 조작적 정의(dedup·합의·fallback) / opt-in 섹션 / ADR type / 미러 parity)
- [ ] 기존 `tests/test-governance-dedup.sh` PASS (회귀 없음 확인)
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-review-b1-default` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
