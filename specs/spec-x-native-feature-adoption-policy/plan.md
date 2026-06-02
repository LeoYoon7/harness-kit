# Implementation Plan: spec-x-native-feature-adoption-policy

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-native-feature-adoption-policy` (브랜치 이름 = spec 디렉토리 이름)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> 본 Plan 을 Accept 하기 전에 사용자가 명시적으로 확인해야 할 항목들.

> [!IMPORTANT]
> - [ ] **전파 범위 결정** — 정책을 어디까지 적용할지:
>   - **안 A (전파, 권장)**: `sources/governance/agent.md` 에 자족 요지 추가 → install/update 로 *모든 설치 대상*에 전파. 네이티브 기능 사용 조건은 harness-kit 사용자 일반에 유효하므로.
>   - **안 B (키트 한정)**: 키트 repo 거버넌스에만 적용, sources 미수정. 정책이 harness-kit *자체 개발*에만 유효.
> - [ ] **dangling 참조 회피** — ADR-007 은 키트 repo 에만 존재(설치 대상 미전파). 따라서 전파되는 agent.md 요지는 ADR 없이도 의미가 통하는 *자족 문장* + "(근거: 키트 ADR-007)" 형태. 설치 대상에선 ADR 링크가 끊겨도 요지로 작동.
> - [ ] **agent.md 삽입 위치/분량** — `§6.7 Workflow Patterns` 에 항목 1개(요지 3~5줄). 거버넌스 단어 수 한계(6418w>6000w) 악화 최소화.

> [!WARNING]
> - [ ] 거버넌스 변경이므로 도그푸딩 동기화(`.harness-kit/agent/agent.md`) 필요 — 미동기화 시 본 프로젝트 자체 규약과 drift

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **정책 상세** | ADR-007 (docs/decisions/, 키트 repo) | 7종 조건·근거·대안의 전문. 키트 개발 자산이라 전파 불요 |
| **실행 요지** | `sources/governance/agent.md` §6.7 항목 1개 (안 A) | 전파되는 강제 규약. 자족적 요지 + ADR 근거 참조 |
| **거버넌스 슬림** | 상세는 ADR, 요지만 agent.md | 단어 수 한계(6000w) 악화 최소화 |
| **도그푸딩 동기화** | `sources/governance/agent.md` → `.harness-kit/agent/agent.md` 직접 cp | 단일 파일이라 update.sh(전체 재설치)는 과함. ADR-003 SSOT 정신은 유지(원본→설치본 단방향) |

### 📑 ADR 후보

- [x] ADR 가치 있는 결정 있음 → 후보 한 줄 요약: `native-feature-adoption-policy` (type: **convention**) — 본 spec 핵심 산출물 ADR-007
- [ ] 없음

## 📂 Proposed Changes

### ADR

#### [NEW] `docs/decisions/ADR-007-native-feature-adoption-policy.md`
- type: convention, status: accepted
- Context: spec-x-cc-native-adoption 조사가 7종을 조건부 Go 로 분류, 조건이 거버넌스 미반영
- Decision: 7종 각 게이트 보존 조건을 규약화 (goal/ultracode/fewer-perm/code-review[ultra·기본형]/ultraplan/스킬)
- Consequences / Alternatives / Status / Related (spec-x-cc-native-adoption, ADR-006)

### 거버넌스 (안 A 채택 시)

#### [MODIFY] `sources/governance/agent.md`
- §6.7 Workflow Patterns 에 "네이티브 기능 게이트 보존" 항목 1개 추가 (자족 요지 3~5줄 + ADR-007 근거 참조)

#### [MODIFY] `.harness-kit/agent/agent.md`
- 위 변경을 도그푸딩 설치본에 동기화 (직접 cp)

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
# 거버넌스 단어 수 한계 테스트 영향 확인 (이미 초과 상태이므로 악화 여부)
bash tests/test-governance-dedup.sh
```

### 수동 검증 시나리오
1. ADR-007 이 7종 조건을 모두 담는가 — 기대: 각 기능에 조건 + 근거 명시
2. agent.md 요지가 자족적인가(ADR 링크 없이 의미 통함) — 기대: "게이트 보존 조건 하에서만" 규약이 단독으로 읽힘
3. `sources/governance/agent.md` 와 `.harness-kit/agent/agent.md` 가 일치하는가 — 기대: diff 없음
4. 거버넌스 단어 수가 크게 늘지 않았는가 — 기대: 요지 추가분만(수십 단어)

## 🔁 Rollback Plan

- 거버넌스 문서 + ADR 추가만이므로 시스템 영향 없음. 브랜치 폐기로 완전 롤백.
- agent.md 변경은 git revert 로 원복 가능, 동기화도 재실행으로 복구.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음 (전파 범위 안 A/B 포함)
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
