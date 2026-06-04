# Implementation Plan: spec-x-goal-verify-gate

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-goal-verify-gate` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] **검증 ≠ 승인 경계 확인** — code-review/critique 가 Plan Accept·scope 확장·merge 권한을 대체하지 않음(헌법 §1.2/§5.3, ADR-008). 이 경계에 동의하는가?
> - [ ] **1차 보수안(Q1-a)** — 가역 마이크로 A/B 도 hard-stop 유지 → 완전 무중단은 아님. Q1-b(§7 완화)는 추후 별도 spec. 이대로 진행하는가?
> - [ ] **dogfood sync 방식** — sources + installed 직접 동시 편집(권장) vs `update.sh` 전체 재sync (아래 주요 결정 표)

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **정책 위치** | ADR-007 **Amendment** (신규 ADR 아님) | `/goal` 조건 refinement — ADR-007 Amendment 패턴 일관, ADR 번호 인플레 회피 |
| **agent.md §6.7** | 요지 + ADR 포인터만 (최소 변경) | 거버넌스 단어수 한계(Icebox) — 상세는 ADR/플레이북으로 |
| **플레이북 §2·§3** | `/goal` 행에 검증 조건 추가 | 설치 대상의 자족 사용 지침 (ADR 미배포) |
| **dogfood sync** | sources + installed **직접 동시 편집** (update.sh 대신) | 2파일 소규모 변경 — surgical. `update.sh` 전체 재sync 의 부수 drift 유입 회피. ADR-003 의 drift-free 목적은 동일 달성 |
| **강제 범위** | §11.2 scope 임계 **재사용** | 새 임계값 도입 회피 — spec(6+ task)/phase 급만 강제 |

### 📑 ADR 후보

- [x] ADR-007 Amendment 로 기록 (type: convention 유지, 신규 번호 미발급)
- [ ] 없음

## 📂 Proposed Changes

### 정책 본문 (kit-repo)

#### [MODIFY] `docs/decisions/ADR-007-native-feature-adoption-policy.md`
`/goal` 검증 강제 정책 Amendment 절 추가. 내용: ① 진입 critique + ship code-review 강제(skip 불가, spec/phase 급 한정) ② 검증≠승인 경계 ③ 보존 hard-stop 2개(Plan Accept·계획밖 deviation) ④ launch-ritual 앵커링 ⑤ §11.2 임계 재사용 ⑥ Q1-a 채택 / Q1-b 는 Icebox 후속.

### 운영 규약 (sources → installed sync)

#### [MODIFY] `sources/governance/agent.md` · `.harness-kit/agent/agent.md`
§6.7 의 `/goal` 절에 요지 한 줄 추가 ("+ spec/phase 급일 때 진입 critique·ship code-review 강제 — ADR-007 Amendment") + ADR-007 참조 유지. 두 복사본 동일 편집.

#### [MODIFY] `sources/governance/native-feature-usage.md` · `.harness-kit/agent/native-feature-usage.md`
§2 상황별 표 + §3 2단계 조건 표의 `/goal` 행에 검증 강제 조건 추가. 두 복사본 동일 편집.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트
docs-only 변경 — 단위 테스트 미해당 (헌법 §9.1 문서 변경 예외).

### governance 일관성 테스트 (대체 검증)
```bash
bash tests/test-governance-dedup.sh
```
> 단어수 상한 테스트는 **사전 상태를 먼저 기록**하고, 본 변경이 *새로운* 회귀를 만들지 않는지 확인한다 (기존 초과는 별도 Icebox 항목). agent.md 변경은 요지 1줄로 최소화.

### 수동 검증 시나리오
1. ADR-007 Amendment ↔ `agent.md §6.7` ↔ 플레이북 `/goal` 행 3자 내용 일관성 육안 확인 — 기대: 모순 없음.
2. `git diff` 로 sources ↔ installed 의 agent.md / native-feature-usage.md 변경이 동일한지 확인 — 기대: 양쪽 동일.

## 🔁 Rollback Plan

- docs-only · 완전 가역. 문제 시 `git revert` 로 즉시 복구. 데이터/상태 영향 없음.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
