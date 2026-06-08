# spec-22-01: 페르소나 리뷰 패널 연구

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-22-01` |
| **Phase** | `phase-22` |
| **Branch** | `spec-22-01-persona-panel-research` |
| **상태** | Planning |
| **타입** | Research |
| **Integration Test Required** | no (research DoD §9.1 적용 — POC 실증이 검증) |
| **작성일** | 2026-06-08 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

review 커맨드(`hk-code-review` / `hk-spec-critique` / `hk-phase-review`)는 현재 **단일 Opus 서브에이전트**로 리뷰한다. 단일 관점이라 자기평가 편향·관점 누락이 가능하다. upstream 은 "페르소나 패널"(여러 페르소나 워커가 병렬 리뷰 후 종합/중재) 아이디어를 냈으나, **구현 명세 없이 테스트(T13 텍스트 문구 / T14 미러 parity)만** 남기고 Icebox 로 유보했다. fork 도 phase-21 에서 같은 이유로 defer 했다.

### 문제점

페르소나 패널은 단순 기능 추가가 아니라 **미검증 설계 문제**다. 구현부터 들어가면 다음 5난점이 그대로 리스크가 된다.

1. **종료 조건** — 패널·중재가 언제 수렴·종료하는가 (무한 협의 위험).
2. **증류 (distillation)** — 페르소나별 의견을 어떻게 한 장으로 압축하는가 (정보 손실 vs 일관성).
3. **무한 루프** — 중재가 새 이슈 제기 → 워커 재실행 → 재중재 순환 차단.
4. **검증 불변식 양립** — ADR-010 "워커 transcript 전문 재흡수 금지" 와 "중재자는 워커 의견을 이해해야 함" 의 균형.
5. **context 오염** — 패널 전문이 메인 세션 context 를 오염시키지 않는 격리.

그리고 critique(2026-06-08)가 짚은 **6번째이자 가장 중요한 함정**: 위 5난점은 모두 *liveness*(패널이 돌아가고 수렴하는가)에 관한 것이다. 정작 **value**(페르소나 패널이 단일 Opus 보다 *실제로 나은가*)를 측정하지 않으면 "가치 없어도 수렴하면 Go" 가 되어 Go/No-Go 가 공허해진다. Self-MoA 연구(arXiv 2502.00674)는 다양성 혼합이 단일 최고 모델 반복보다 *나쁠 수도* 있음을 실증했다.

### 해결 방안 (요약)

구현 전에 **연구로 5난점을 설계로 해소**하고, review 커맨드 1개(`hk-spec-critique`)에 **POC** 를 적용해 실제 실행으로 ① 수렴·증류(liveness)와 ② **단일-Opus baseline 대비 우위(value)** 를 함께 실증한 뒤 **Go/No-Go** 를 권고한다 (§9 Research Spec Protocol). 산출물은 `report.md`(spec.md 대체, §9.2) + POC 자산.

## 🎯 요구사항

### Functional Requirements (연구 질문 — 각각 답을 내야 함)

**A. 5난점 설계 (각 ≥2안 트레이드오프 비교)**
1. **종료 조건** — consensus 수렴 신호 + **하드 라운드 상한(≤3) 이중 방어**. ≥2안 비교.
2. **증류** — 페르소나 의견 → distilled contract 압축 방식. **이견(disagreement) 보존이 핵심** (LLM-jury 관점: 이견은 노이즈 아닌 신호). ≥2안 비교.
3. **무한 루프 방지** — 라운드 상한 + **의미적 중복 탐지(해시/유사도)** 로 "신규 이슈로 가장한 재실행" 차단 (turn count 만으론 불충분).
4. **불변식 양립** — 중재자가 워커 *결과 계약* 만으로 종합 (전문 재흡수 없이) — ADR-010/011 정합.
5. **context 격리** — 패널 워커 전문이 메인에 유입되지 않는 dispatch 패턴.

**B. 측정 (value 를 반증 가능하게 — critique 반영)**
6. **value 측정** — 패널 산출물이 baseline 대비 *더 나은가* 를 측정 축으로 정의 (놓친 이슈 수 / 거짓 양성 / 실행자 평가). liveness 와 분리.
7. **증류 품질 proxy** — **issue retention rate** = 페르소나 distinct issue 수 대비 distilled contract 잔존 수 (이견 보존율).
8. **비용/지연 측정** — 패널의 토큰·시간 비용. Go/No-Go 는 본질상 ROI 결정.

**C. POC + 결론**
9. **POC** — `hk-spec-critique` 페르소나 패널 프로토타입 + 실제 archived spec 1건 실행. **baseline = 단일 Opus N회 투표(self-consistency)** 와 비교 → 앙상블 기여와 페르소나 다양성 기여를 분리.
10. **연구 파라미터 명시** — 페르소나 수·구성 + archived spec 표본 선정 기준 (*의도적으로 이견 갈리는* spec).
11. **Go/No-Go** — §9.1 결론 + 근거. **value > baseline 입증이 Go 전제** (수렴만으론 Go 불가).

### Non-Functional Requirements

1. fork 거버넌스 정합 — ADR-008(human-gate)·ADR-010(orchestration)·ADR-011(director) 불변식 위반 금지. 디렉터 게이트(Plan Accept/Ship)는 패널에 위임 불가.
2. POC 는 기존 단일-Opus 리뷰 경로를 *변경하지 않는다* (프로토타입은 별도 — production 무영향).
3. 키트 1차 타깃(NestJS install 대상)에서도 의미 있는 결론 — 도그푸딩 가능성 유지.

## 🚫 Out of Scope

- 3개 review 커맨드 production 적용 (= spec-22-02, research Go 전제).
- `hk-spec-critique` 외 커맨드 POC (1개로 충분히 수렴·value 실증).
- 새 슬래시 커맨드/도구 신설 (POC 는 프로토타입 프롬프트/스크립트 수준).
- 단일-Opus 리뷰 경로의 변경/제거.

## 📑 ADR 후보 (Architecture Decision Records)

- [x] ADR 가치 있는 결정 있음 → 후보:
  - `persona-panel-orchestration` (type: decision) — research Go + 설계 확정 시 spec-22-02 머지 시점 작성.
  - `review-value-baseline` (type: invariant/convention 후보) — "다관점 리뷰 도입은 baseline 대비 value 측정을 Go 전제로 한다" (critique 반영) — research 결과 후 트리거.
  - No-Go 면 "왜 안 하는가" 근거 기록으로 대체 검토.
- [ ] 없음

## 🔍 Critique 결과 (2026-06-08, Opus)

전문: `specs/spec-22-01-persona-panel-research/critique.md`. 권장안 = **현재 구조 유지 + value 측정 축 보강**. 핵심 우려(liveness만 측정, value 미측정)를 위 FR B·C 와 DoD 에 반영(6항목 all). 유사기법 시사: MAD(라운드 상한), LLM-jury(이견 보존), Self-MoA(다양성이 항상 우위는 아님 → 반증가능 측정).

## ✅ Definition of Done (Research — §9.1)

- [ ] **트레이드오프 분석**: 5난점 각각 ≥2안 비교 (정성/정량 근거) → `report.md`
- [ ] **측정 설계**: value 축 + issue retention rate + 비용/지연 + baseline(단일 Opus N회 투표) 정의 → `report.md`
- [ ] **POC + baseline 비교**: `hk-spec-critique` 패널 프로토타입 + baseline 을 동일 archived spec 에 실행 → `report.md` + `scripts/research/`
- [ ] **liveness 실증**: 유한 라운드(≤상한) 종료 + 증류 산출물 생성 + 워커 전문 미재흡수
- [ ] **value 실증**: 패널 vs baseline (놓친 이슈 / 거짓 양성 / issue retention rate / 비용·지연) — 패널 우위를 *반증 가능하게* 측정
- [ ] **Go/No-Go 권고**: value > baseline 입증 여부 기반 명시적 결론 + 근거 → `report.md`
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-22-01-persona-panel-research` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
