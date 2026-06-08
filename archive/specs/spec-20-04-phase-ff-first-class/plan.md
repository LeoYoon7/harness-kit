# Implementation Plan: spec-20-04

## 📋 Branch Strategy

- 신규 브랜치: `spec-20-04-phase-ff-first-class` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `phase-20-upstream-parity` (phase-20 base 모드 — PR target 동일)
- 첫 task 가 브랜치 생성을 수행함
- 선행 spec(spec-20-03)은 base 브랜치에 Merged 확인 → §5.1 base 분기 규칙 충족

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] **ADR 번호 = 009**: fork ADR-004 가 notification 이라 upstream ADR-004(phase-FF)와 번호 충돌. fork 신규 번호 **ADR-009** 부여(phase-20 plan 의 "009+" 명시와 일치).
> - [ ] **pre-push gate de-hardcode 의 보수적 해석**: phase-FF 도 testable 변경엔 **테스트 유지**. 해제되는 건 *개별 spec PR review* 강제뿐(→ phase-ship 통합검증). 테스트 면제가 아님.

> [!WARNING]
> - [ ] **governance word-count**: constitution+agent.md 가 이미 7073w>6000w(Check 3 FAIL). 본 spec 은 추가를 간결히·§11.4 in-place 재구성으로 **악화 최소화**만 보장. 완전 해소는 OOS(director mode 작업).
> - [ ] 모든 거버넌스 변경은 sources↔installed **양쪽** 반영(NFR-2).

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **ADR-009** | upstream ADR-004 참조·재작성(cherry-pick 아님) | 번호 충돌 회피 + fork notify 정합 기술 |
| **agent.md §11.4** | in-place 재구성(추가 아닌 치환) | word-count 중립 지향(NFR-1) |
| **fragment notify 정합** | phase-FF = 개별 게이트 미발생 명시 | fork notify-heavy 프로토콜과 충돌 방지 |
| **pre-push gate** | 보수적 — review 강제만 해제, 테스트 유지 | testing 계약 급변 회피(NFR-3) |

### 📑 ADR 후보
- [x] ADR 가치 있는 결정 있음 → `phase-ff-first-class` (type: **decision**) — FR-1, 본 spec 핵심 산출물. 머지 전 작성(Task 1).
- [ ] 없음

## 📂 Proposed Changes

### ADR (FR-1)
#### [NEW] `docs/decisions/ADR-009-phase-ff-first-class.md`
adr.md 템플릿 준수. frontmatter `type: decision`. Context(ceremony 고정비 + phase 브랜치 안전성) / Decision(phase-FF 1급, upfront, 항목별 재승인 불요) / Consequences(긍정·부정·중립 — FF Mode C 구별 포함) / Alternatives / Status(Accepted, 규약 반영 위치 명시) / Related(upstream ADR-004 참조, fork ADR-002 Planning Economy).

### constitution (FR-2, FR-5) — sources/governance + .harness-kit/agent
#### [MODIFY] `constitution.md`
- §3.1(Phase): "In-Phase Work Sizing" 문단 추가 — phase 내 1–2 commit 가역 항목 = phase-FF(산출물 없음, 재승인 불요, → agent.md §11.4). 간결.
- §2(Work Modes) / §10.2(Pre-Push Validation): phase-FF 가 per-item PR review 대신 phase-ship 통합검증을 받는다는 보수적 예외 한 줄(테스트 요건 유지).

### agent.md (FR-3) — sources/governance + .harness-kit/agent
#### [MODIFY] `agent.md`
- §11.4 제목/본문을 "In-Phase Work Sizing & Re-Adjustment"로 in-place 재구성 — 착수 시점 upfront sizing(substantial→Spec / small·reversible 1–2 commit→phase-FF 1급) 강조. 기존 재조정 표는 보존하되 "1급 선택" 프레이밍 추가. word 증가 최소화.

### CLAUDE.fragment (FR-4) — sources/claude-fragments + .harness-kit
#### [MODIFY] `CLAUDE.fragment.md`
- 기존 phase-FF 항목(Good Pattern)을 **1급 작업 모드**로 격상 + notify 정합 한 줄(phase-FF 직접 커밋은 §5/§9 개별 게이트 미발생 → 최소 알림).

## 🧪 검증 계획 (Verification Plan)

### 거버넌스 일관성 (단위 테스트 대체 — docs-only)
```bash
bash tests/test-governance-dedup.sh
# 기대: Check 1(중복 0) / 2(sync) / 5(섹션번호) / 6(sdd경로) PASS
#       Check 3(word count) 은 기존 FAIL — 본 spec 후 증가폭 확인(악화 최소)
diff -q sources/governance/constitution.md .harness-kit/agent/constitution.md
diff -q sources/governance/agent.md .harness-kit/agent/agent.md
diff -q sources/claude-fragments/CLAUDE.fragment.md .harness-kit/CLAUDE.fragment.md
```

### 수동 검증 시나리오
1. constitution §3.1 + agent.md §11.4 + fragment 를 통독 — phase-FF 가 "착수 시점 1급 선택"으로 일관 기술되는지.
2. ADR-009 frontmatter `type: decision` + §6.4 어휘 준수 확인.
3. word-count 증가폭 측정(`wc -w`) — Check 3 상한 대비 악화 정도 기록.

## 🔁 Rollback Plan

- 모든 변경이 docs(추가/치환) → 문제 시 해당 commit revert. 코드/상태 영향 없음.
- ADR-009 는 신규 파일 → 삭제로 즉시 롤백.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
