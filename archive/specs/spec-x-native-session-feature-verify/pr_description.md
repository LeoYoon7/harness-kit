# docs(spec-x-native-session-feature-verify): /background·/branch 게이트 보존 검증 + 조건부 Go

## 📋 Summary

### 배경 및 목적

직전 세션(`spec-x-cc-native-adoption` PR #25 → `spec-x-native-feature-adoption-policy` PR #26)에서 "검증 후(3단계)"로 보류했던 Claude Code 세션 기능 `/background`(`/bg`)·`/branch`(`/fork`) 2종을 실측하여 등급을 확정한다. report 부록 A 의 검증 테스트 **1·4** 해소가 목표.

본 에이전트는 백그라운드 잡으로 실행 중이라 대화형 세션 명령을 라이브 자가 실행할 수 없어, **공식 문서 조사 + harness-kit hook 배선 정적 분석 + `CLAUDE_CODE_FORK_SUBAGENT` 의미 분석**으로 판정했다. 라이브 실측이 *반드시* 필요한 잔여 항목은 선택적 사용자 체크리스트로 분리(Done 조건 아님).

### 주요 변경 사항

- [x] `report.md` — `/background`·`/branch` 의 7충돌축 발췌 판정 + Go/No-Go + 조건
- [x] **`/branch` → 조건부 Go** (3→2단계): settings(hook)·CLAUDE.md·모델·git 상태 승계 + 같은 working dir → 게이트(축 A/F/C) 보존 doc-확정
- [x] **`/background` → 조건부 Go (제한적)** (3→2단계): 게이트-free mechanical 구간 한정 + 계층 2 명시 알림 필수. 계층 1 자동 알림(test 1)은 라이브 확인 권장
- [x] ADR-007 Amendment + agent.md §6.7(sources/.harness-kit 동기화) + queue.md Icebox 반영

### Phase 컨텍스트
- **Phase**: 없음 (spec-x, Research)
- **본 SPEC 의 역할**: CC 네이티브 채택 로드맵 3단계(세션 기능 실측)를 doc+정적 분석으로 해소

## 🎯 Key Review Points

1. **검증 방법론의 한계 명시**: 라이브 자가 실행 불가 → 문서+정적 분석. 라이브 필요 항목(`/background` 계층 1 알림)을 ⚠️로 명확히 구분하고 사용자 체크리스트로 분리했는가.
2. **`/background` 조건부 Go 의 안전성**: 계층 1 미확정에도 "게이트-free 구간 한정 + 계층 2 필수"로 리스크가 실제로 한정되는가 (§9 비대칭 비용 관점).
3. **정책 반영 위치**: agent.md 는 요지 한 절, 상세는 ADR-007 Amendment — 거버넌스 단어 수 한계 정책(prior spec 선례) 일관성.
4. **worktree ↔ SDD 상호작용 발견(§2.4)**: 추가 검토/후속 spec 가치 판단.

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-governance-dedup.sh
```

**결과 요약**:
- ✅ Check 2 (sources ↔ .harness-kit 동기화): agent.md / constitution.md PASS
- ❌ Check 3 (단어 수 7021w > 6000w): **회귀 아님** — 기존 비대화(6994w), 본 spec +27w 는 정책 필수 최소. 별도 거버넌스 다이어트 Icebox 항목.
- 단위 테스트: 해당 없음 (Research/docs, constitution §9.1 justified)

### 수동 검증 시나리오
1. **방법론**: claude-code-guide + 공식 문서 → `/branch` 승계 확정, `/background` 계층 1 알림 라이브 필요 판정
2. **정적 분석**: `notify-on-input-wait.sh`(`Notification`/`Stop` 등록) + git hook(`PreToolUse`) 배선 → 판정 근거
3. **정책 회귀**: ADR/agent.md/queue 편집 후 동기화(Check 2) PASS

## 📦 Files Changed

### 🆕 New Files
- `specs/spec-x-native-session-feature-verify/spec.md` · `plan.md` · `task.md` · `report.md` · `walkthrough.md` · `pr_description.md`

### 🛠 Modified Files
- `sources/governance/agent.md` / `.harness-kit/agent/agent.md` §6.7: `/background`·`/branch` 게이트 보존 조건 요지 추가 (동기화)
- `docs/decisions/ADR-007-native-feature-adoption-policy.md`: Amendment 절 — 세션 기능 2종 조건부 Go 승격 + per-feature 조건
- `backlog/queue.md`: Icebox 검증 spec 항목 resolved 마킹

## ✅ Definition of Done

- [x] `report.md` — 기능별 ≥2 선택지 trade-off + Go/No-Go + 조건
- [x] 정책 반영 (agent.md §6.7 + ADR-007 Amendment + queue Icebox)
- [x] (Research/docs — 단위 테스트 해당 없음) 거버넌스 동기화(Check 2) PASS
- [x] `walkthrough.md` / `pr_description.md` ship commit
- [x] 브랜치 push
- [x] 사용자 검토 요청 알림

## 🔗 관련 자료

- 조사: `spec-x-cc-native-adoption` (PR #25), 정책: `spec-x-native-feature-adoption-policy` (PR #26)
- ADR: `docs/decisions/ADR-007-native-feature-adoption-policy.md` (Amendment)
- Report: `specs/spec-x-native-session-feature-verify/report.md`
