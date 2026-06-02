# spec-x-native-feature-adoption-policy: 네이티브 기능 게이트 보존 정책 명문화

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-native-feature-adoption-policy` |
| **Phase** | 없음 (spec-x, Solo) |
| **Branch** | `spec-x-native-feature-adoption-policy` |
| **상태** | Planning |
| **타입** | docs (거버넌스 정책 + ADR) |
| **Integration Test Required** | no |
| **작성일** | 2026-06-02 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

선행 조사 `spec-x-cc-native-adoption`(PR #25 머지)이 Claude Code 네이티브 기능 7종을 **"조건부 Go"** 로 분류했다. 각 기능은 게이트(Plan Accept / §8.5 Choice Presentation)·멀티모델 전략·권한 자세를 건드릴 수 있어, *특정 조건 하에서만* 도입 가능하다.

- `/goal` — 단일 spec/phase 의 acceptance criteria + "각 게이트에서 멈추고 보고" 조건
- `/effort ultracode` — 구현 phase 내부 한정
- `/fewer-permission-prompts` — 생성 allowlist 커밋 전 검토
- `/code-review ultra` — ship 직전 보강 (크레딧 제한)
- `/code-review` 기본형 — 보조(effort/`--fix`/`--comment`)
- `/ultraplan` — 복귀 플랜 `/hk-plan-accept` 재게이팅
- 스킬 시스템 — `/hk-*` 와 중복 안 되는 작업, 컨텍스트 비용 인지

### 문제점

이 조건들이 **조사 기록(report.md)에만 존재**하고 거버넌스(강제 규약)에 반영되지 않았다. report 는 조사 산출물이라 강제력이 없으므로, 실제로 누군가 `/goal`·`/effort ultracode` 등을 쓸 때 §8.5 결정 지점·Plan Accept·phase별 모델 지정을 *조용히 건너뛸* 위험이 남는다. "조건부 Go"가 실효를 가지려면 조건이 거버넌스에 명문화되어야 한다.

### 해결 방안 (요약)

7종의 게이트 보존 조건을 **ADR-007 `native-feature-adoption-policy`(type: convention)** 에 전문으로 박고, `agent.md` 에는 자족적 요지 + ADR 참조를 둔다. 거버넌스 본문 비대화(단어 수 한계 이슈)를 피하기 위해 상세·근거는 ADR 에, 실행 규약 요지는 agent.md 에 분리한다. 본 spec 은 **정책 문서화**이며 기능 사용을 자동화하거나 hook 으로 강제하지 않는다.

## 🎯 요구사항

### Functional Requirements

1. **ADR-007 작성** — 7종 각각의 게이트 보존 조건 + 근거(어떤 축 충돌을 어떻게 막는가) + 대안을 `docs/decisions/ADR-007-native-feature-adoption-policy.md` 에 작성 (type: convention).
2. **agent.md 정책 요지** — 네이티브 기능은 "게이트 보존 조건 하에서만" 사용한다는 자족적 요지 + ADR-007 참조를 추가. *분량과 전파 범위는 plan 에서 결정*.
3. **도그푸딩 동기화** — 키트 원본(`sources/governance/`) 수정 시 설치본(`.harness-kit/agent/`)을 ADR-003(dogfood-sync) 정책에 따라 동기화.

### Non-Functional Requirements

1. **거버넌스 단어 수 한계 보호** — agent.md 추가는 요지만(상세는 ADR). 현재 6418w > 상한 6000w(Icebox 기록)를 더 악화시키지 않도록 최소화.
2. **dangling 참조 회피** — ADR 은 키트 repo 에만 있고 설치 대상에 전파되지 않으므로, 전파되는 agent.md 요지는 ADR 없이도 의미가 통하는 *자족적* 문장이어야 한다.
3. 모든 산출물 한국어.

## 🚫 Out of Scope

- 네이티브 기능의 실제 사용 자동화 / 래핑 / `/hk-*` 신규 커맨드 생성
- hook 을 통한 강제(차단) — 본 spec 은 *규약 명문화*까지. hook 화는 별도 검토
- 검증 spec 대상(`/background`·`/branch` 실측), 1단계 9종 즉시 채택 — 별도 Icebox 항목
- 거버넌스 단어 수 한계 자체의 재조정(별도 Icebox 항목)

## 📑 ADR 후보 (Architecture Decision Records)

- [x] ADR 가치 있는 결정 있음 → 후보 한 줄 요약: `native-feature-adoption-policy` (type: **convention**) — 본 spec 의 핵심 산출물 (ADR-007)
- [ ] 없음

## ✅ Definition of Done

- [ ] `docs/decisions/ADR-007-native-feature-adoption-policy.md` 작성 (7종 조건 + 근거 + 대안)
- [ ] `sources/governance/agent.md` (또는 plan 결정 위치)에 자족 요지 + ADR 참조 추가
- [ ] 도그푸딩 동기화 (`.harness-kit/agent/agent.md`)
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-native-feature-adoption-policy` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
- [-] 단위 테스트 — docs-only(거버넌스 문서)이므로 면제 (constitution §9.1). 단 거버넌스 단어 수 테스트(`test-governance-dedup.sh`) 영향은 검증
