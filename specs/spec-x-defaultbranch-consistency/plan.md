# Implementation Plan: spec-x-defaultbranch-consistency

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-defaultbranch-consistency` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] **base 해석 체인 확정**: `phase baseBranch → defaultBranch → main` (ADR-015 로 자산화)
> - [ ] **constitution §3.3 수정**: "spec-x PR Target: always main" → "defaultBranch (기본 main)" — 거버넌스 텍스트 정합 (정책 변경 아님)

> [!WARNING]
> - [ ] **동작 변경 지점**: phase baseBranch 미설정 + defaultBranch≠main 인 환경에서 머지 감지/PR 타깃이 main → defaultBranch 로 바뀜. defaultBranch 미설정 시 기존과 동일(main 폴백) — 본 dogfood 는 defaultBranch=main 이라 무영향.

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **sdd base 해석** | `_resolve_base_branch()` 헬퍼 1개로 통일 | 하드코딩 2곳(517,1941) 중복 제거 + 체인 단일화 |
| **해석 체인** | `state.baseBranch → installed.json defaultBranch → "main"` | 기존 review gate(sdd:671) 패턴과 동일, 하위호환(폴백 main) |
| **hk-ship/hk-cleanup** | 커맨드 문서를 헬퍼/defaultBranch 기준으로 정합 | 실행은 에이전트가 수행 — 문서 지침이 SSOT |
| **constitution §3.3** | 1줄 정합 (always main → defaultBranch) | 정책 변경 아닌 텍스트 일치 |
| **origin/HEAD 자동추론** | **비채택** (ADR-015 기록) | 명시 설정 우선 원칙 + 추론 모호성 (review-base-config critique) |

### 📑 ADR 후보

- [x] ADR 가치 있는 결정 있음 → `ADR-015-review-base-resolution-chain` (type: tradeoff)
- [ ] 없음

## 📂 Proposed Changes

### [MODIFY] `sources/bin/sdd`
- `_resolve_base_branch()` 신설: `SDD_STATE` 의 `.baseBranch` → `installed.json` 의 `.defaultBranch` → `"main"` 순 폴백, 해석 결과 echo. **각 후보는 `git rev-parse --verify --quiet` 로 실재 확인 후 미존재면 다음 단계로 fallback** (gemini-review.sh:78-92 패턴). installed.json/jq 부재·`null`·빈 문자열은 `main` 가드 (sdd:673-674 동일).
- 517, 1941 의 `base_branch="main"` + state.baseBranch override 블록을 `base_branch="$(_resolve_base_branch)"` 호출로 대체.

### [MODIFY] `sources/commands/hk-ship.md`
- line 139 추출 체인 `jq -r '.baseBranch // "null"'` → `jq -r '.baseBranch // .defaultBranch // "null"'`.
- line 144 `git checkout -b "$base_branch" main` → `... <defaultBranch>`; line 150 `PR_BASE="main"` → defaultBranch 폴백.

### [MODIFY] `sources/commands/hk-cleanup.md`
- 점검 목록에 "`defaultBranch` 가 `git rev-parse --verify --quiet` 로 실재하지 않음(오타 등)" 감지 항목 추가 (local 기준).

### [MODIFY] `sources/governance/constitution.md` §3.3 + §3.2
- §3.3 "PR Target: always `main`" → "`defaultBranch` (기본 `main`)".
- §3.2(line 67) `... (base mode) else main` → `else defaultBranch` (일관성).

### [NEW] `docs/decisions/ADR-015-review-base-resolution-chain.md`
- frontmatter `type: tradeoff`. (a) 체인 정의 (b) origin/HEAD 비채택 근거(symbolic-ref 부재 함정 + claude-code #31614) (c) `init.defaultBranch` vs `defaultBranch` 구분 (d) 동일 패턴 3벌(헬퍼·gemini-review·sdd:673) 부채 가시화 + lib 단일화 다음 트리거 재평가.

### [MODIFY] `tests/test-sdd-base-branch.sh` (또는 신규 회귀 테스트)
- fixture 확장: `installed.json`(defaultBranch="develop") **생성** + `develop` 브랜치 **실제 생성**(ref 실재 통과용). 검증: baseBranch 우선 / defaultBranch 선택 / 둘 다 없으면 main / installed.json 부재 시 main.

### 설치본 동기화 (dogfood)
- `.harness-kit/bin/sdd`, `.claude/commands/hk-ship.md`, `.claude/commands/hk-cleanup.md`, `.harness-kit/agent/constitution.md`.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
bash tests/test-sdd-base-branch.sh        # 신규 체인 검증 포함
bash tests/test-governance-dedup.sh       # §3.3 수정 후 sync + 예산
bash tests/test-sdd-phase-done-accuracy.sh
```

### 수동 검증 시나리오
1. fixture defaultBranch="develop", baseBranch 없음 → `_resolve_base_branch` = develop.
2. baseBranch="phase-1-x" 설정 → 우선순위로 phase-1-x.
3. 둘 다 없음 → main 폴백 (하위호환).

## 🔁 Rollback Plan

- 단일 브랜치. `git revert` 또는 브랜치 폐기로 즉시 원복. 상태/데이터 영향 없음.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
