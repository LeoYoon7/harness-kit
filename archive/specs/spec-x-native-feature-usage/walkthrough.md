# Walkthrough: spec-x-native-feature-usage

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 산출물 위치 | docs/(미배포) / ADR-007 내부 / 배포(sources/) | **docs/native-feature-usage.md (미배포)** | governance 단어수(7021w 초과) 회피 + ADR-007 "상세 kit repo, 요지만 배포" 패턴 일관. ADR 은 decision-record라 playbook 과 안 맞음. 배포는 중립성 우려 |
| 구성 | 기능별 / tier별 / **상황별** | **상황(when) 우선** | "어떤 상황에 어떻게" 요청에 직접 부합 |
| 조건 출처 | 본 문서에 재작성 / ADR-007 발췌 참조 | **ADR-007 발췌 + 정본 명시** | 중복 표현 drift 방지 — 모순 시 ADR-007 우선 명문화 |
| discoverability | agent.md §6.7 편집 / ADR-007 Related만 | **ADR-007 Related만** | agent.md 편집 시 단어수 추가 악화. §6.7 → ADR-007 → 본 문서 체인으로 충분 |
| 1단계 6종 공식화 | 별도 FF 메모 / 본 spec 흡수 | **본 spec 흡수** | 지난 턴 후보(D2)를 별도 처리 없이 playbook 이 담음 |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — 신규 결정 없음(기존 ADR-007 합성). 본 문서는 reference playbook이며 ADR-007 이 정본.

## 💬 사용자 협의

- **주제**: 다음 작업 후보 중 CC 네이티브 도입
  - **사용자 의견**: "네이티브 기능을 어떤 상황에 어떻게 사용할 것인지 정리"
  - **합의**: 흩어진 사용 지침(report/ADR-007/agent.md §6.7)을 상황-우선 playbook 으로 통합. SDD-x, 위치 A(docs/), 상황-우선 구성. "진행" 승인 → Plan Accept

## 🧪 검증 결과

### 1. 자동화 테스트
- **명령**: 해당 없음 — docs-only spec (production 코드 변경 없음, constitution §9.1 justified). agent.md/constitution 미편집이라 `test-governance-dedup` 회귀 무관.

### 2. 수동 검증

1. **Action**: playbook 의 전 기능을 ADR-007 / report 등급·조건과 대조
   - **Result**: 1단계 6종 + 2단계 7종 + 3단계 2종(15종) + 보류(/batch) + N-A(/powerup·/radio) 전부 수록. 조건이 ADR-007 표·Amendment 와 일치. 모순 없음
2. **Action**: ADR-007 Related 포인터가 `docs/native-feature-usage.md` 를 정확히 가리키는지 확인
   - **Result**: ✅ 추가됨 (역방향: 본 문서 머리말이 ADR-007 을 정본으로 인용)

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | Skip |
| **결과 파일** | N/A |
| **요약** | N/A |
| **Skip 사유** | `docs-only` — 신규 reference 문서 1개 + ADR-007 포인터 1줄, 실행 코드 변경 없음 (agent.md §6.3.8) |

## 🔍 발견 사항

- **단일 출처 원칙의 실천**: 조건을 본 문서에 재작성하면 ADR-007 과 drift 한다. "정본=ADR-007, 모순 시 ADR-007 우선" 명시 + 발췌 참조로 해소.
- **상황-우선 구성의 가치**: 같은 기능도 "언제 쓰나"로 진입하면 tier/조건이 자연히 따라온다 — decision-record(ADR) 가 못 주는 사용성.
- **CC 네이티브 도입 arc 완결**: 조사(#25) → 정책(#26) → 검증(#27) → 사용 playbook(본 spec). 1단계 6종 공식화로 17종 전부 처리(보류 /batch 제외).

## 🚧 이월 항목

- **`/batch` Bitbucket 정합성** — 여전히 보류(Icebox). 조건(검증 2·3·5 + Bitbucket 중립성) 해소 시 별도 spec. playbook §4 각주에 경계만 표시.
- **거버넌스 다이어트** (7021w) — 본 spec 과 무관(agent.md 미편집)하나 별도 Icebox 항목으로 잔존.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-02 ~ 2026-06-02 |
| **최종 commit** | ship commit (push 직전) |
