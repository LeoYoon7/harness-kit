# Implementation Plan: spec-x-native-feature-usage

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-native-feature-usage` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> 본 Plan 을 Accept 하기 전에 사용자가 명시적으로 확인해야 할 항목들.

> [!IMPORTANT]
> - [ ] **산출물 위치 = `docs/native-feature-usage.md` (kit repo 전용, 미배포)**. ADR-007 패턴(상세는 kit repo, 요지만 배포) 일관. agent.md §6.7 은 변경 안 함 → governance 단어수(이미 7021w 초과) 회피.
> - [ ] **정책 무변경**. 기존 ADR-007 조건의 *사용 관점 합성*만. 조건의 정본은 ADR-007 — 모순 시 ADR-007 우선을 문서에 명시(drift 방지).

> [!WARNING]
> - [ ] production 코드 변경 없음(신규 docs 1개 + ADR-007 포인터 1줄). 단위 테스트 없음 — docs-only.

## 🎯 핵심 전략 (Core Strategy)

### 문서 구조 (상황-우선)

```text
docs/native-feature-usage.md
├─ 1. 개요 + tier 정의 (1/2/3단계, N-A, 보류) + 단일출처 원칙(정본=ADR-007)
├─ 2. 상황별 사용 가이드 (★ 핵심 — 상황 → 권장 기능 → tier → 조건 요약 표)
├─ 3. 기능별 조건 요약 (tier 2·3 의 게이트 보존 조건 — ADR-007 발췌)
└─ 4. 경계 (보류 /batch, 거버넌스무관 /powerup·/radio) 각주
```

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **위치** | `docs/native-feature-usage.md` (미배포) | governance 단어수 무관 + ADR-007 패턴 일관 |
| **구성** | 상황(when) 우선 표 | "어떤 상황에 어떻게" 요청에 직접 부합 |
| **조건 출처** | ADR-007 발췌(정본 참조), 모순 시 ADR-007 우선 명시 | 중복 표현 drift 방지(단일 출처) |
| **discoverability** | ADR-007 Related → 본 문서 (agent.md 미편집) | 단어수 한계 회피 |
| **1단계 6종** | 본 문서로 채택 공식화 | 지난 턴 별도 FF 흡수 |

### 📑 ADR 후보

- [x] 없음 — 신규 결정 없음(ADR-007 합성). reference playbook.

## 📂 Proposed Changes

### 사용 playbook

#### [NEW] `docs/native-feature-usage.md`
- 상황-우선 사용 가이드. §2 핵심 표: 상황(근거 수집 / 긴 mechanical 실행 / 대안 탐색 / 리뷰 / 롤백 / 산출물 이관 / 계획 / 권한 정리 / 온보딩 등) → 권장 기능 → tier → 조건 요약.
- §3 기능별 조건 요약(tier 2·3) — ADR-007 발췌. §4 경계 각주.
- 머리말에 "정본=ADR-007, 모순 시 ADR-007 우선" 명시.

#### [MODIFY] `docs/decisions/ADR-007-native-feature-adoption-policy.md`
- Related 절에 `docs/native-feature-usage.md`(사용 playbook) 포인터 한 줄 추가.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)

```text
해당 없음 — docs-only spec. production 코드 변경 없음 (constitution §9.1 justified).
agent.md/constitution 미편집이므로 test-governance-dedup 회귀 무관.
```

### 통합 테스트 (Integration Test Required = no)

```text
없음.
```

### 수동 검증 시나리오

1. `docs/native-feature-usage.md` 의 모든 기능이 ADR-007 / report 의 등급·조건과 **일치**하는가 (정본 대조). — 기대: 모순 없음.
2. 1·2·3단계 + 보류 + N-A 의 전 기능이 빠짐없이 수록됐는가. — 기대: 17종 커버.
3. ADR-007 Related 포인터가 본 문서를 정확히 가리키는가.

## 🔁 Rollback Plan

- docs-only 변경이므로 해당 commit revert 로 즉시 원복.
- 상태 영향 없음(코드/데이터 변경 없음).

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
