# Implementation Plan: spec-x-review-base-config

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-review-base-config` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] 설정 키 이름을 `defaultBranch` 로 확정 (GitHub "default branch" 용어 차용; 대안 `integrationBase` 는 phase `baseBranch` 와 혼동 위험이 더 큼)
> - [ ] 이번 spec 의 적용 범위는 **리뷰 게이트 2종 + 노출 (status JSON/doctor)** — hk-ship PR base / sdd 내부 main fallback / hk-cleanup 검사는 Icebox (spec.md Out of Scope 참조)
> - [ ] critique 반영으로 `sdd status --json` 스키마에 `defaultBranch` 필드 추가됨 (additive — 기존 파서 영향 없음)

> [!WARNING]
> - [ ] breaking change 없음 — `defaultBranch` 미설정 시 모든 경로가 현 동작과 동일 (main)

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **설정 저장소** | `installed.json` `.defaultBranch` | 기존 config 키 (uxMode/directorMode/models/precheck) 와 동일 위치·패턴 |
| **조회/설정 CLI** | `sdd config default-branch [<branch>]` | `_config_ux_mode` 패턴 답습 — 학습 비용 0 |
| **설정 검증** | `git check-ref-format --branch` (거부) + `git rev-parse --verify` (경고만) | 형식 오류 차단 + 오타 가시화, just-in-time 케이스는 경고로 통과 |
| **base 해석 체인** | phase `baseBranch` → `defaultBranch` → 리터럴 `main` (2단 종착) | phase base 우선순위 보존 + 미설정 시 기존 동작 100% 보존 + 무한 체인 없음 |
| **LLM 절차 단일 소스** | `sdd status --json` 에 `defaultBranch` 노출 → hk-code-review 는 jq 한 번으로 결정 | LLM 이 두 파일 (state/installed) 을 합성하는 비결정성 제거 (critique 핵심 반영) |
| **진단 가시성** | `sdd doctor` 에 defaultBranch 한 줄 | diff 범위가 조용히 바뀌는 키 — directorMode 노출 선례 답습 |

### 📑 ADR 후보

- [x] ADR 가치 있는 결정 있음 → 후보 한 줄 요약: `review-base-resolution-chain` (type: tradeoff) — **deferred**, Icebox 항목 착수 시 작성 (spec.md ADR 섹션 참조)
- [ ] 없음

## 📂 Proposed Changes

### sdd (config + 노출)

#### [MODIFY] `sources/bin/sdd`

1. `cmd_config()` 분기에 `default-branch) _config_default_branch "$@" ;;` 추가 + usage 도움말 한 줄.
2. `_config_default_branch()` 신설 (`_config_ux_mode` 패턴).

```text
_config_default_branch() {
  installed.json 존재 확인
  인자 없음 → jq -r '.defaultBranch // "main"' 출력
  인자 있음 → git check-ref-format --branch "$v" 검증 (실패 시 die)
            → git rev-parse --verify --quiet "$v^{commit}" 실패 시 ⚠ 경고 (계속 진행)
            → jq 로 .defaultBranch 갱신 → ok "defaultBranch = $v"
}
```

3. `cmd_status` `--json` 분기: `state_dump` 결과에 `defaultBranch` 주입 (installed.json 해석값, 부재 시 `"main"`). state 부재 fallback printf JSON 에도 `"defaultBranch":"..."` 포함.
4. `cmd_doctor` 에 defaultBranch 표기 한 줄 추가 (directorMode 노출부 인접).

### gemini-review.sh

#### [MODIFY] `sources/bin/gemini-review.sh`

base 결정부 (`:64-80`) 를 2단 fallback 종착 체인으로 교체 (spec.md FR 5).

```text
DEFAULT_BRANCH=$(jq -r '.defaultBranch // "main"' "$PROJECT_ROOT/.harness-kit/installed.json" 2>/dev/null) || DEFAULT_BRANCH="main"
[ -z "$DEFAULT_BRANCH" ] || [ "$DEFAULT_BRANCH" = "null" ] 시 DEFAULT_BRANCH="main"

BASE_BRANCH=$(echo "$STATUS_JSON" | jq -r '.baseBranch // empty')
[ -z "$BASE_BRANCH" ] || [ "$BASE_BRANCH" = "null" ] 시 BASE_BRANCH="$DEFAULT_BRANCH"

# 1단: phase base ref 부재 (첫 spec just-in-time) → defaultBranch 로
if ! ref_exists "$BASE_BRANCH" && [ "$BASE_BRANCH" != "$DEFAULT_BRANCH" ]; then
  ⚠ 경고; BASE_BRANCH="$DEFAULT_BRANCH"
fi
# 2단: defaultBranch ref 도 부재 → 리터럴 main 으로 (종착)
if ! ref_exists "$BASE_BRANCH" && [ "$BASE_BRANCH" != "main" ]; then
  ⚠ 경고; BASE_BRANCH="main"
fi
# main 도 부재 → 기존과 동일: 빈 diff → "리뷰할 변경이 없습니다" exit
```

주석의 "main 은 캐논 base 전제" 문구를 "defaultBranch (기본 main) 는 캐논 base 전제" 로 갱신.

### 명령 문서

#### [MODIFY] `sources/commands/hk-code-review.md`

도입부에 base 결정 단계 1회 추가, 이후 `git diff main...HEAD` 3곳 (`:22,53,83`) 을 `git diff ${REVIEW_BASE}...HEAD` 로 교체.

```text
REVIEW_BASE=$(bash .harness-kit/bin/sdd status --json | jq -r '.baseBranch // .defaultBranch // "main"')
# REVIEW_BASE ref 부재 시 (첫 spec 등): defaultBranch → main 순 fallback (gemini-review.sh 와 동일 체인)
```

#### [MODIFY] `sources/commands/hk-gemini-review.md`

base 서술 2곳 (`:13` "phase base 또는 main", `:24` "base branch 식별") 을 새 체인 (`phase base → defaultBranch → main`) 반영으로 갱신 — 문서 drift 방지.

### 도그푸딩 동기화

#### [MODIFY] `.harness-kit/bin/sdd`, `.harness-kit/bin/gemini-review.sh`, `.claude/commands/hk-code-review.md`, `.claude/commands/hk-gemini-review.md`

sources/ 변경분을 install 결과 위치에 동일 반영 (각 구현 task 의 같은 commit 에 포함).

### 테스트

#### [MODIFY] `tests/test-sdd-config.sh`

default-branch 케이스 4종 추가:
1. 미설정 조회 = `main`
2. 설정 후 조회 = 설정값 (실재 브랜치)
3. 부적합 이름 (`"bad branch"` 공백 포함) 거부 (exit≠0)
4. `sdd status --json` 출력에 `.defaultBranch` 반영 확인 (설정값/미설정 main)

#### [MODIFY] `tests/test-gemini-review-guard.sh`

- **T8** (defaultBranch 반영): fixture 에 `git branch develop main` + installed.json `defaultBranch=develop` → capture stub stdin 에 `Diff (develop...HEAD)` 포함 확인 (exit 0).
- **T9** (2단 fallback 종착): installed.json `defaultBranch=no-such-branch` (형식 합법·실재 안 함, phase base 없음) → 1단 스킵 (BASE==DEFAULT), 2단 fallback 으로 `main` 진행 → exit 0 + stdin 에 `Diff (main...HEAD)` 포함 확인.

### 백로그

#### [MODIFY] `backlog/queue.md`

Icebox 에 4건 등록:
1. 멀티레포 리뷰 지원 (2-repo diff)
2. sdd 내부 main fallback (`:515,1908`) 설정화 — 착수 시 ADR `review-base-resolution-chain` (tradeoff) 작성
3. hk-ship PR_BASE·governance main 전제 재검토
4. hk-cleanup 의 defaultBranch 실재 검사 추가 여부

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
bash tests/test-sdd-config.sh
bash tests/test-gemini-review-guard.sh
```

### 회귀 (관련 suite)
```bash
bash tests/test-sdd-base-branch.sh
bash tests/test-review-b1.sh
bash tests/test-install-manifest-sync.sh
bash tests/test-hk-doctor.sh
```

### 수동 검증 시나리오
1. 본 repo (defaultBranch 미설정) 에서 `bash .harness-kit/bin/sdd config default-branch` — 기대: `main` 출력.
2. `sdd config default-branch develop` (본 repo 에 develop 없음) — 기대: 실재 경고 + 설정은 성공. 조회 = `develop`. 이후 `sdd config default-branch main` 으로 원복.
3. `sdd config default-branch "bad name"` — 기대: 거부 (die).
4. `bash .harness-kit/bin/sdd doctor` — 기대: defaultBranch 현재값 한 줄 표기.

## 🔁 Rollback Plan

- 커밋 단위 revert 로 충분 — 설정 키·status JSON 필드는 additive 이고 미설정 시 기존 경로와 동일하므로 부분 revert 도 안전.
- installed.json 에 키가 남아도 구버전 스크립트는 해당 키를 읽지 않아 무해.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
