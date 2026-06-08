# spec-20-04: phase-FF 를 phase 내 1급 작업 모드로 거버넌스 반영 (upstream ADR-004 parity)

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-20-04` |
| **Phase** | `phase-20` |
| **Branch** | `spec-20-04-phase-ff-first-class` |
| **상태** | Planning |
| **타입** | Refactor (거버넌스) |
| **Integration Test Required** | no |
| **작성일** | 2026-06-04 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

upstream(Changsik00) ADR-004 가 phase-FF 를 **phase 내 1급 작업 모드**로 정의했다 — phase 안의 작고 명확하고 가역적인 1–2 commit 항목은 spec 산출물 없이 phase base 브랜치에 직접 커밋하며, 이는 재조정 fallback 이 아니라 **착수 시점의 1급 선택지**다.

fork(LeoYoon7)는 `0.13.6` 분기 이후 이 1급화를 반영하지 못했다. fork 는 phase-FF "용어"는 보유하지만(agent.md §11.4 재조정 옵션, CLAUDE.fragment Good Pattern) **착수 시점 1급 구도·constitution 명문·정식 ADR 이 빠져** 있다.

### 문제점 (Explore triage — fork↔upstream 대조)

| 항목 | upstream (ADR-004) | fork 현재 | 빠진 것 |
|---|---|---|---|
| 정식 ADR | ADR-004 phase-ff-first-class | 없음 (fork ADR-004 = notification, 번호 충돌) | **ADR-009 신규 필요** |
| constitution §3.1 | "In-Phase Work Sizing" 명문 (phase-FF + Spec 병렬) | "related **Specs**" 만 | phase-FF 정의 부재 |
| agent.md §11.4 | "first-class in-phase mode, **upfront** sizing" | "Re-Adjustment Options" (사후 **fallback**) | 착수 시점 1급 구도 |
| CLAUDE.fragment | 간략 정의 | 간략 (Good Pattern) | 1급 강도 + notify 정합 |
| pre-push gate | phase-FF 항목 개별 review → phase-ship 통합검증 이동 | §10.2 일괄 (모든 push 전 test) | phase-FF de-hardcode |

**구체적 통증**: fork 에이전트는 phase 안의 3줄 변경에도 spec ceremony(5 md + Plan Accept + PR + 리뷰, 약 6–8k 토큰)를 붙이는 편향이 남아 있다. phase-FF 가 1급으로 명문화되지 않아 "phase 안이면 무조건 spec" + "FF 회피용 bundle" 압력이 지속된다. (단 sdd 코드는 이미 `sdd spec new` 시 "1-2 commit 이면 phase FF 가 나은가?" 재검증 prompt 를 보유 → **코드 변경 불필요, 순수 docs-only**.)

### 해결 방안 (요약)

upstream ADR-004 의 phase-FF 1급화를 fork 거버넌스에 **간결하게** 반영한다. 신규 ADR-009 작성(번호 충돌 회피) + constitution §3.1 "In-Phase Work Sizing" 문단 + agent.md §11.4 를 "upfront 1급" 구도로 in-place 재구성 + CLAUDE.fragment 강화(notify 프로토콜 정합 포함) + pre-push gate 의 phase-FF 예외를 보수적으로 명문화. 모든 추가는 **간결**히 — constitution+agent.md 가 이미 word-count 상한 초과 상태(아래 NFR-1).

## 🎯 요구사항

### Functional Requirements

1. **FR-1 (ADR-009)**: `docs/decisions/ADR-009-phase-ff-first-class.md` 작성. frontmatter `type: decision`. upstream ADR-004 를 참조로 명시하되 fork 맥락(notify-heavy 거버넌스, ADR 번호 충돌 회피)에 맞춰 작성. Context/Decision/Consequences/Alternatives/Status/Related 구조(adr.md 템플릿 준수).
2. **FR-2 (constitution §3.1)**: `constitution.md` §3.1(Phase) 에 "In-Phase Work Sizing" 명문 추가 — phase 내 작고 가역적인 1–2 commit 항목은 phase-FF(spec 산출물 없이 phase 브랜치 직접 커밋, 항목별 재승인 불요)로 처리 가능. §2(Work Modes)의 phase-FF 위치도 정합.
3. **FR-3 (agent.md §11.4)**: §11.4 를 "사후 재조정 옵션"에서 **"착수 시점 upfront sizing + phase-FF 1급 선택"** 구도로 in-place 재구성(추가가 아닌 치환으로 word-count 중립 지향).
4. **FR-4 (CLAUDE.fragment)**: phase-FF 를 Good Pattern 수준에서 **1급 작업 모드**로 격상 + **notify 프로토콜 정합** 명시 — phase-FF 직접 커밋은 개별 의사결정 게이트(§5/§9 알림)를 발생시키지 않음(최소 알림).
5. **FR-5 (pre-push gate de-hardcode)**: constitution §10.2(Pre-Push Validation) / §9(Testing) 에 phase-FF 예외를 **보수적으로** 명문화 — phase-FF 도 testable 변경엔 테스트 유지하되, *개별 spec PR review* 는 phase-ship 통합검증으로 이동(per-item review 강제 해제).

### Non-Functional Requirements

1. **NFR-1 (governance bloat 억제)**: constitution+agent.md 는 이미 `test-governance-dedup.sh` Check 3 기준(6000w)을 초과(7073w, 기존). 본 spec 의 추가는 **간결**해야 하며 §11.4 는 in-place 재구성으로 word 증가 최소화. Check 3 의 완전 해소는 director mode 의 agent.md 축소 작업(별도)에 위임.
2. **NFR-2 (sources↔installed sync)**: `sources/governance/{constitution,agent}.md` ↔ `.harness-kit/agent/{constitution,agent}.md`, `sources/claude-fragments/CLAUDE.fragment.md` ↔ `.harness-kit/CLAUDE.fragment.md` 동기 유지(`test-governance-dedup.sh` Check 2).
3. **NFR-3 (무회귀)**: 기존 거버넌스 규칙(FF Mode C / spec-x / bundle 등) 의미 보존. phase-FF 는 FF(Mode C)와 구별 유지(state.json active spec 불변 + phase PR 포함).
4. **NFR-4 (docs-only)**: 코드/스크립트/테스트 변경 없음. sdd 의 기존 phase-FF prompt 동작 확인만.

## 🚫 Out of Scope

- director mode 재구현(별도 phase-20 후속) 및 그로 인한 agent.md 축소.
- 산출물 통합(5 md → 1 work.md) — upstream ADR-004 도 "보류(직교 레버)"로 분류. 본 spec 미포함.
- sdd 코드 변경 — 이미 phase-FF 재검증 prompt 보유.
- `test-governance-dedup.sh` Check 3(word count) 완전 해소 — 본 spec 은 *악화 최소화*만, 해소는 별도.

## 📑 ADR 후보 (Architecture Decision Records)

- [x] ADR 가치 있는 결정 있음 → `phase-ff-first-class` (type: **decision**) — 본 spec 의 핵심 산출물(FR-1). upstream ADR-004 parity, fork 번호 009.
- [ ] 없음

## ✅ Definition of Done

- [ ] FR-1~5 반영 완료 (ADR-009 + constitution + agent.md + fragment)
- [ ] `test-governance-dedup.sh` Check 1(중복)/2(sync)/5(섹션번호)/6(sdd경로) PASS — Check 3(word count)은 기존 FAIL(악화 최소 확인)
- [ ] `sources` ↔ `.harness-kit` 거버넌스 sync (`diff -q` 또는 Check 2)
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-20-04-phase-ff-first-class` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
