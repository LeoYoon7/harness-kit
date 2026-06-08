# Implementation Plan: spec-x-native-session-feature-verify

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-native-session-feature-verify` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> 본 Plan 을 Accept 하기 전에 사용자가 명시적으로 확인해야 할 항목들.

> [!IMPORTANT]
> - [ ] **검증 방법론 = 문서 조사 + 정적 분석 (라이브 자가 실행 아님)**. 본 에이전트는 백그라운드 잡으로 실행 중이라 `/background`·`/branch` 를 스스로 호출해 라이브 동작을 관측할 수 없다. 따라서 판정 근거는 ① Claude Code 공식 문서, ② harness-kit hook 배선 정적 분석, ③ `CLAUDE_CODE_FORK_SUBAGENT` 의미 분석이다. **라이브 실측은 선택적 사용자 체크리스트로만 제공하며 Done 조건이 아니다.**
> - [ ] **정책 반영은 판정 결과에 종속**. 조건부 Go 결론이면 agent.md §6.7 + ADR-007 을 amendment 로 갱신(3단계→2단계 승격), 보류 결론이면 report + Icebox 근거 기록에 그친다. 어느 쪽이 될지는 검증 후 확정된다.

> [!WARNING]
> - [ ] production 코드 변경 없음(거버넌스 문서 + report 만). 단위 테스트 없음 — Research/docs (constitution §9.1 justified).
> - [ ] `gh` 전제 기능 평가 시 두 시점(도그푸딩 GitHub / target Bitbucket) 중립성 유지.

## 🎯 핵심 전략 (Core Strategy)

### 검증 프레임

report §2 의 7개 충돌 축 중 본 spec 이 다루는 축만 발췌하여 두 기능을 판정한다.

| 기능 | 검증 축 | report 테스트 | 핵심 질문 |
|---|---|:---:|---|
| `/background` (`/bg`) | B(알림), E(세션/config) | test 1 | 백그라운드 세션의 input-wait 알림이 채널로 도달하는가? 추가 세션이 공유 config 제약에 걸리는가? |
| `/branch` (`/fork`) | A(게이트), F(hook), C(멀티모델) | test 4 | fork 세션이 텍스트 게이트·git hook·멀티모델 지정을 승계하는가? `CLAUDE_CODE_FORK_SUBAGENT` 유무별 차이는? |

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **검증 방법** | 문서 조사 + 정적 분석 (claude-code-guide 에이전트 / 공식 docs + hook 소스 Read·Grep) | 백그라운드 잡은 대화형 세션 명령 자가 실행 불가. 문서·배선 분석으로 판정 가능하며 자율 완료 보장 |
| **라이브 실측** | 선택적 사용자 체크리스트로 분리 (report 부록) | 라이브 확인이 *반드시* 필요한 잔여 claim 만 사용자에게 위임. Done 차단 안 함 |
| **판정 산출물** | `report.md` (본 spec 은 spec.md 도 함께 유지) | agent.md §9.2 Research Report. 기능별 ≥2 선택지 trade-off + Go/No-Go |
| **정책 반영** | 조건부 Go → ADR-007 amendment + agent.md §6.7 갱신 / 보류 → Icebox 기록 | 신규 ADR 미발급 (기존 정책의 확장). 결과 종속 |

### 📑 ADR 후보

- [x] ADR 가치 있는 결정 있음 → 후보 한 줄 요약: 기존 **ADR-007 (native-feature-adoption-policy)** 의 amendment 로 반영 (조건부 Go 결론 시). 신규 ADR 미발급.
- [ ] 없음

## 📂 Proposed Changes

### 검증 산출물

#### [NEW] `specs/spec-x-native-session-feature-verify/report.md`
- 검증 보고서. 구조: 메타 / 검증 프레임 / `/background` 판정 / `/branch` 판정 / Go·No-Go 종합 / 사용자 확인 체크리스트(선택) / 정책 반영 결론.
- 기능별로 ≥2 선택지(조건부 채택 vs 보류 유지)를 trade-off 비교하고 근거 명시 (§9.1).

### 정책 반영 (판정 결과 종속 — 조건부 Go 결론 시에만 편집)

#### [MODIFY] `sources/governance/agent.md` 및 `.harness-kit/agent/agent.md` §6.7
- 조건부 Go 결론 시: `/background`·`/branch` 를 게이트 보존 조건과 함께 추가. sources(원본) → .harness-kit(설치본) 단방향 동기화 (ADR-003).

#### [MODIFY] `docs/decisions/ADR-007-native-feature-adoption-policy.md`
- 조건부 Go 결론 시: Consequences/Amendment 절에 두 기능의 등급 승격 + 조건 기록.

#### [MODIFY] `backlog/queue.md`
- Icebox 의 "CC 네이티브 세션 기능 검증 spec" 항목(line 48)을 결과 반영하여 갱신/제거. 보류 결론 시 근거를 남겨 잔류.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)

```text
해당 없음 — Research/docs spec. production 코드 변경 없음 (constitution §9.1 justified).
```

```bash
# 거버넌스 문서를 편집한 경우에만 (정책 반영 task 후) 회귀 확인
bash tests/test-governance-dedup.sh   # sources ↔ .harness-kit 동기화(Check 2) 회귀 확인
```

### 통합 테스트 (Integration Test Required = no)

```text
없음.
```

### 수동 검증 시나리오 (선택 — 사용자 실행용 라이브 확인 체크리스트)

> report 부록에 동봉. 본 spec 의 Done 조건이 **아니다**. 사용자가 라이브 세션에서 실행해 판정을 경험적으로 보강할 때만 사용.

1. `/background` 로 세션 분리 → 에이전트가 입력 대기 진입 → Telegram/Discord 에 알림 도달 여부 확인. 기대: 도달(또는 누락 시 축 B 위험 실증).
2. `/branch` 로 fork → fork 세션에서 main 커밋 시도 → check-branch hook 차단 여부 확인. 기대: 차단(hook 승계 시).
3. `/branch` fork 세션에서 §8.5 선택지 제시 시 텍스트 게이트 정상 발화 확인.

## 🔁 Rollback Plan

- docs-only 변경이므로 해당 commit revert 로 즉시 원복.
- 정책(agent.md/ADR-007) 편집은 sources↔.harness-kit 쌍을 함께 revert.
- 상태 영향 없음 (코드/데이터 변경 없음).

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
