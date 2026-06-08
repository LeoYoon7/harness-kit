# Implementation Plan: spec-22-01 (Research)

## 📋 Branch Strategy

- 신규 브랜치: `spec-22-01-persona-panel-research` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] 이 spec 은 **Research** — 산출물은 production 코드가 아니라 `report.md`(설계 + 측정 + Go/No-Go) + POC. 커맨드 production 변경은 spec-22-02(조건부)로 분리됨.
> - [ ] POC 검증 대상 커맨드 = `hk-spec-critique` 1개 (의견 발산형이라 패널 효용 판단에 적합). 다른 커맨드 POC 는 Out of Scope.
> - [ ] POC 는 **패널 + baseline(단일 Opus N회 투표)** 을 동일 archived spec 1건에 실행해 *value 를 반증 가능하게* 비교 (critique 반영).

> [!WARNING]
> - [ ] research 결론이 **No-Go** 일 수 있음 — 그 경우 spec-22-02 는 drop 되고 phase-22 는 근거 자산화로 종료. (No-Go 도 유효 결과)

## 🎯 핵심 전략 (Core Strategy)

### 연구 흐름

```mermaid
flowchart LR
  A[5난점 설계 ≥2안<br/>+ 측정 설계] --> B[POC 프로토타입<br/>hk-spec-critique]
  B --> C[패널 + baseline<br/>동일 spec 실행]
  C --> D[liveness + value 관찰<br/>수렴/증류/격리 + 패널vs baseline]
  D --> E[Go/No-Go 권고<br/>value > baseline 전제]
```

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **검증 방식** | POC 실증 (설계만 X) | 종료조건/증류/value 는 *돌려봐야* 안다. §9.1 prototype 요구 |
| **POC 대상** | `hk-spec-critique` 1개 | 의견 발산이 가장 큰 커맨드 → 패널 효용/수렴 난점이 가장 선명 |
| **실행 표본** | archived spec 1건 (이견 갈리는 표본) | 실제 텍스트로 현실적 수렴·value 관찰. production 무영향 |
| **패널 dispatch** | sub-agent fan-out, 결과 계약만 반환 | ADR-010 불변식(전문 재흡수 금지) 준수 + context 격리 |
| **종료 모델** | consensus 신호 + 라운드 상한(≤3) + 의미중복 탐지 | 무한 루프 차단. turn count 만으론 불충분 (MAD 표준) |
| **value 측정** | baseline = 단일 Opus N회 투표 + 패널 비교 | liveness 만으론 가치 판단 불가. self-consistency 분리로 페르소나 기여 식별 (critique) |

### 📑 ADR 후보

- [x] ADR 가치 있는 결정 있음 → `persona-panel-orchestration` (decision) + `review-value-baseline` (invariant/convention) — research Go/설계 확정 시 작성.
- [ ] 없음

## 📂 Proposed Changes

### 연구 산출물 (production 코드 아님)

#### [NEW] `specs/spec-22-01-persona-panel-research/report.md`
§9.2 Research Report. 섹션: 5난점별 설계(≥2안) / **측정 설계(value·retention·비용·baseline)** / POC 설계 / POC 실행 결과(liveness + **패널 vs baseline value**) / Go-No-Go 권고. spec.md 를 대체하는 핵심 산출물.

#### [NEW] `scripts/research/persona-panel-poc.md`
POC 프로토타입 — 페르소나 정의(수·구성), dispatch(fan-out·결과 계약만), 종료조건(consensus+라운드상한+의미중복), 증류 단계, **baseline(단일 Opus N회 투표) 프로토콜**.

#### [NEW] `scripts/research/persona-panel-poc-run.md`
POC 1회 실행 로그 — 대상 spec, 페르소나별 결과 계약(요약), 라운드 수, 최종 증류 산출물, 격리 확인, **baseline 결과 + value 비교표**.

> production 커맨드(`sources/commands/hk-*.md`)·`.claude/` 미러·`sources/bin/sdd` 등은 **본 spec 에서 변경하지 않는다** (Out of Scope).

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트

본 spec 은 Research 라 표준 단위 테스트가 없다 (production 코드 미변경). 검증은 POC 실증(아래)으로 대체 — §9.1 DoD.

### 수동 검증 시나리오 (POC 실증 — liveness + value)

1. POC 프로토타입대로 `hk-spec-critique` 페르소나 패널을 archived spec 1건(이견 갈리는 표본)에 실행 — 기대: 페르소나 N개가 각자 결과 계약 반환.
2. 종료조건 동작 — 기대: 라운드 상한(≤3) 내 수렴 + 의미적 중복 탐지로 재중재 순환 차단.
3. 증류 산출물 — 기대: 한 장 distilled contract, 핵심 이견 보존(issue retention rate 측정).
4. context 격리 — 기대: 메인 세션에 워커 transcript 전문 미유입(결과 계약만).
5. **baseline 비교** — 동일 spec 에 단일 Opus N회 투표 실행 → 패널 vs baseline 의 놓친 이슈/거짓 양성/retention/비용·지연 비교.
6. Go/No-Go — 기대: liveness(1~4) + **value(5: 패널 > baseline 입증 여부)** 로 명시적 결론.

## 🔁 Rollback Plan

- research 산출물(report.md, scripts/research/)은 격리된 신규 파일이라 영향 없음 — 브랜치 폐기로 즉시 롤백.
- POC 는 production 리뷰 경로를 변경하지 않으므로 운영 롤백 대상 없음.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
