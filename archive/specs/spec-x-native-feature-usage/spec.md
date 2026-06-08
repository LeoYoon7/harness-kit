# spec-x-native-feature-usage: Claude Code 네이티브 기능 사용 playbook (상황→기능→조건)

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-native-feature-usage` |
| **Phase** | `phase-x` |
| **Branch** | `spec-x-native-feature-usage` |
| **상태** | Planning |
| **타입** | Feature (docs) |
| **Integration Test Required** | no |
| **작성일** | 2026-06-02 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

Claude Code 네이티브 기능의 도입 판단·조건은 세 차례 작업으로 확정됐다.
- `spec-x-cc-native-adoption` (PR #25) — 17종 8충돌축 매트릭스 + Go/No-Go (`report.md`)
- `spec-x-native-feature-adoption-policy` (PR #26) — 조건부 Go 7종 정책 (ADR-007 + agent.md §6.7)
- `spec-x-native-session-feature-verify` (PR #27) — `/background`·`/branch` 검증 → 조건부 Go (ADR-007 Amendment)

### 문제점

그 결과 "어떤 기능을, 어떤 상황에, 어떤 조건으로 쓰는가"의 정보가 **세 곳에 분산**되어 있다.
- `report.md` — 곧 archive 될 조사 산출물(매트릭스·등급).
- `ADR-007` — decision-record 형식(조건부 7종 표 + amendment). *왜* 그 조건인지에 최적화돼 있어 *지금 뭘 쓸지*를 빠르게 찾기 어렵다.
- `agent.md §6.7` — 한 줄 요지 + 포인터.

운영자/미래 세션이 **"지금 이 상황엔 어떤 네이티브 기능을 쓰지?"** 를 한눈에 볼 *상황-중심 사용 playbook* 이 없다. 또한 1단계 즉시 채택 6종(`/deep-research` 등)은 "spec 불필요, 사용 가능"으로만 남아 *공식 기록*이 없다.

### 해결 방안 (요약)

`docs/native-feature-usage.md` 한 문서로 **상황(when) → 기능(what) → tier/조건(how)** playbook 을 통합한다. 채택된 1·2·3단계 전 기능을 담고, 1단계 6종 채택을 이 문서로 공식화하며, ADR-007 이 본 문서를 참조하게 한다. 정책·조건 자체는 변경하지 않고 *합성·재배치*만 한다.

## 🎯 요구사항

### Functional Requirements

1. **사용 playbook 신설** — `docs/native-feature-usage.md` 작성. 핵심은 **상황-우선 표**(상황 → 권장 기능 → tier → 조건 요약). tier = 1단계(무조건)/2단계(조건부)/3단계(검증완료 조건부).
2. **전 채택 기능 수록** — 1단계 6종(`/deep-research`·`/workflows`·`/copy`·`/rewind`·`/team-onboarding`·`/btw`) + 2단계 7종 + 3단계 2종(`/background`·`/branch`). 보류(`/batch`)·거버넌스무관(`/powerup`·`/radio`)은 각주로 경계만 명시.
3. **1단계 6종 공식화** — 본 문서에 "1단계 = 무조건 사용 가능(거버넌스 직교)"로 명문화하여 지난 턴의 별도 FF 메모를 흡수.
4. **discoverability 링크** — `ADR-007` 의 Related 절에서 본 문서를 참조(역방향: 본 문서는 ADR-007/report 를 근거로 인용). agent.md §6.7 은 *변경하지 않음*(이미 ADR-007 포인터 보유 → 단어수 한계 회피).

### Non-Functional Requirements

1. **단일 출처 원칙** — 조건의 *정본*은 ADR-007. 본 문서는 *사용 관점 합성*이며 ADR-007 과 모순되면 ADR-007 이 우선임을 명시(중복 표현 drift 방지).
2. **미배포(kit repo 전용)** — 본 문서는 `docs/` 에 두고 install 로 target 에 배포하지 않는다(ADR-007 "상세는 kit repo, 요지만 배포" 패턴, 배포 중립성).

## 🚫 Out of Scope

- **정책/조건 변경** — 기존 ADR-007 조건을 *합성*만 한다. 새 조건 추가·기존 조건 수정 금지(그건 별도 spec).
- **`/batch` 채택** — 보류(report §7-4). 각주로 경계만 표시.
- **target 배포(sources/)** — kit repo 전용 문서.
- **agent.md §6.7 / constitution 편집** — governance 단어수 한계 회피(이미 7021w 초과). discoverability 는 ADR-007 경유.

## 📑 ADR 후보 (Architecture Decision Records)

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — 신규 결정 없음(기존 ADR-007 합성). 본 문서는 reference playbook.

## ✅ Definition of Done

- [ ] `docs/native-feature-usage.md` 작성 — 상황-우선 표 + 전 채택 기능 + 보류/N-A 각주
- [ ] `ADR-007` Related 에 본 문서 포인터 추가
- [ ] 단위 테스트: **해당 없음** — docs-only (constitution §9.1 justified). agent.md 미편집이므로 governance 테스트 회귀 무관
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-native-feature-usage` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
