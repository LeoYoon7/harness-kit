# spec-x-defaultbranch-consistency: base 브랜치 해석을 defaultBranch 로 통일

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-defaultbranch-consistency` |
| **Phase** | `phase-x` (Phase 비소속) |
| **Branch** | `spec-x-defaultbranch-consistency` |
| **상태** | Planning |
| **타입** | Refactor |
| **Integration Test Required** | no |
| **작성일** | 2026-06-16 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

harness-kit 은 통합 base 브랜치를 `defaultBranch` 설정(`installed.json`, `sdd config default-branch`)으로 관리한다. 이미 **리뷰 게이트**(`sdd:671-678` state_dump)와 **doctor**(`sdd:2429`)는 이 값을 읽는다. spec-x-review-base-config 에서 도입된 인프라다.

### 문제점

`defaultBranch` 를 **반영하지 않고 `main` 을 하드코딩**하는 경로가 남아 있다.

| 위치 | 현재 동작 | 문제 |
|---|---|---|
| `sources/bin/sdd:517` | `base_branch="main"` → state.baseBranch 로만 override | 머지 감지(git log cache)가 `defaultBranch` 무시 |
| `sources/bin/sdd:1941` | 동일 패턴 | phase-done 정확도 cross-check 가 `defaultBranch` 무시 |
| `sources/commands/hk-ship.md:144,150` | `git checkout -b ... main` / `PR_BASE="main"` | 비-main 기본 브랜치 환경에서 PR 타깃·base 생성 오류 |
| `constitution §3.3` | "spec-x PR Target: always main" | `defaultBranch` 비반영 (텍스트 불일치) |
| `sources/commands/hk-cleanup.md` | `baseBranch` remote 부재만 점검 | `defaultBranch` 오설정(오타 등) 미감지 |

`defaultBranch` 가 `main` 이 아닌 형상(예: nextmarket 라이브 실증, fork 운영)에서 머지 감지·PR 타깃·정리 점검이 어긋난다. base 해석 체인이 경로마다 제각각(`baseBranch → main`)이고, 의도된 체인(`baseBranch → defaultBranch → main`)이 공식 기록(ADR)으로 자산화되어 있지 않다.

### 해결 방안 (요약)

base 해석을 **단일 체인 `phase baseBranch → defaultBranch → main`** 으로 통일한다. sdd 의 하드코딩 2곳을 `_resolve_base_branch()` 헬퍼로 대체하고, hk-ship/hk-cleanup 커맨드 문서와 constitution §3.3 을 같은 체인에 정합시킨다. 체인과 비채택안(origin/HEAD 자동추론)을 `ADR-015-review-base-resolution-chain` 으로 기록한다.

## 🎯 요구사항

### Functional Requirements

1. `sources/bin/sdd` 에 `_resolve_base_branch()` 헬퍼 도입 — 우선순위 `state.baseBranch(phase) → installed.json defaultBranch → "main"`. **각 단계는 ref 로 실재하지 않으면 다음 단계로 fallback** (gemini-review.sh:78-92 동일 패턴 — base-branch 모드 phase 의 첫 spec 은 base 브랜치가 JIT 생성이라 작업 중 미존재 → 값-체인만 만들면 `git log <미존재>` 무음 실패로 머지 감지 회귀). installed.json 부재 / jq 부재 / `null`·빈 문자열은 `main` 으로 graceful 폴백 (sdd:673-674 가드와 동일 패턴). 기존 하드코딩 `base_branch="main"` 패턴(517, 1941)을 헬퍼 호출로 대체. (critique #1, #4)
2. `sources/commands/hk-ship.md` — base/PR_BASE 결정이 `defaultBranch` 반영: **line 139 추출 체인 `.baseBranch // "null"` → `.baseBranch // .defaultBranch // "null"`** (hk-code-review.md:22 레퍼런스) + line 144 `git checkout -b ... <defaultBranch>` + line 150 `PR_BASE` 폴백 `defaultBranch`. (critique #2)
3. `constitution §3.3` **와 §3.2** 정합 — §3.3 "PR Target: always `main`" → "`defaultBranch` (기본 `main`)"; §3.2(line 67) `... (base mode) else main` → `else defaultBranch` (동일 일관성). (critique #3)
4. `sources/commands/hk-cleanup.md` — `installed.json` 의 `defaultBranch` 를 `git rev-parse --verify --quiet` 로 **실재 확인**하는 점검 추가 (오타 등 오설정 감지). 통합 base 라 local 존재 전제로 검사. (critique #5)
5. `docs/decisions/ADR-015-review-base-resolution-chain.md` (type: `tradeoff`) — (a) 해석 체인 (b) origin/HEAD 자동추론 비채택 근거(symbolic-ref 부재 함정 + `anthropics/claude-code` #31614) (c) `init.defaultBranch`(신규 repo 생성) vs `defaultBranch`(리뷰/PR base) 의미 구분 (d) **동일 패턴이 헬퍼·gemini-review.sh·sdd:673 물리 3벌 — lib 단일화는 다음 트리거(origin/HEAD 재고 등) 시 재평가** 부채 가시화. (critique #6)
6. base 해석 체인 회귀 테스트 — fixture 에 `installed.json`(defaultBranch="develop") 생성 + `develop` 브랜치 **실제 생성**(ref 실재 통과). 검증: baseBranch 우선 / defaultBranch 선택 / 둘 다 없으면 main / installed.json 부재 시 main. (critique #4)
7. 도그푸딩 설치본 동기화 (`.harness-kit/bin/sdd`, `.claude/commands/hk-ship.md`·`hk-cleanup.md`, `.harness-kit/agent/constitution.md`).

### Non-Functional Requirements

1. **회귀 안전**: 기존 테스트(`test-sdd-base-branch.sh`, `test-governance-dedup.sh`, `test-sdd-phase-done-accuracy.sh` 등) 전부 PASS.
2. **bash 3.2 호환**: 헬퍼는 bash 3.2 기능만 사용 (CLAUDE.md 작업 원칙 §3).
3. **하위호환**: `defaultBranch` 미설정 시 기존과 동일하게 `main` 으로 폴백 — 기존 사용자 무영향.
4. **소급 안전**: 동작 변경(base `main` → `defaultBranch`)이 영향을 주는 지점은 머지 감지·PR base 결정 등 **read-only 판정**뿐 — 기존 phase 진행 중 환경에서도 부작용 없음. (critique #7)

## 🚫 Out of Scope

- **멀티레포 리뷰 지원 (2-repo diff)** — 별도 feature 급 (Icebox 유지).
- **origin/HEAD 자동추론** — ADR-015 에서 *비채택* 근거만 기록 (구현 안 함).
- 이미 `defaultBranch` 를 올바로 읽는 경로(`sdd:671`, `sdd:2429`, `_config_default_branch`)의 DRY 리팩터 — 버그가 아니므로 surgical 하게 두되, 헬퍼로 자연스럽게 흡수 가능하면 한해서만.
- `hk-ship PR_BASE` 와 constitution §3.3 의 *정책 자체* 재설계 — 본 spec 은 defaultBranch 정합만, 정책 변경 아님.

## 📑 ADR 후보

- [x] ADR 가치 있는 결정 있음 → `review-base-resolution-chain` (type: **tradeoff**) — base 해석 체인 확정 + origin/HEAD 자동추론 비채택. cross-spec(review gate/ship/cleanup 공통 기준)·long-lived → ADR 적격.
- [ ] 없음

## ✅ Definition of Done

- [ ] `_resolve_base_branch()` 헬퍼 도입 + 하드코딩 2곳 대체
- [ ] hk-ship / hk-cleanup / constitution §3.3 defaultBranch 정합
- [ ] ADR-015 작성 (type: tradeoff)
- [ ] base 해석 체인 회귀 테스트 PASS + 기존 테스트 전부 PASS
- [ ] 설치본 동기화 → drift 깔끔
- [ ] `walkthrough.md` / `pr_description.md` ship commit
- [ ] 브랜치 push + 사용자 검토 요청 알림
