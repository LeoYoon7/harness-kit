# Implementation Plan: spec-21-04

## 📋 Branch Strategy

- 신규 브랜치: `spec-21-04-role-model-config` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: **`phase-21-director-mode`** (phase base 모드). 직전 spec(21-03) PR 머지 완료(constitution §5.1 충족).
- 첫 task 가 브랜치 생성을 수행함. PR target = `phase-21-director-mode`.

## 🛑 사용자 검토 필요 (User Review Required)

> 본 Plan 을 Accept 하기 전에 사용자가 명시적으로 확인해야 할 항목들.

> [!IMPORTANT]
> - [ ] **역할 taxonomy = director / worker / scout** (3역할): §6.6 의 기존 4역할을 매핑 — authoring·judgment·**review/critique** → `director`, task execution → `worker`, code analysis·broad search → `scout`. (phase draft 도 director/worker/scout. "scout" 에 code-analysis referent 부여로 over-engineering 회피.)
> - [ ] **기본값 = 현 동작 보존**: `director: opus`, `worker: sonnet`, `scout: opus`. (scout 가 opus 인 건 현재 code analysis 가 Opus 였기 때문.)
> - [ ] **신규 ADR 불요**: de-hardcode 근거는 ADR-011 에 귀속.

> [!WARNING]
> - [ ] **거버넌스 + install.sh 동시 변경**: agent.md §6.6(모든 세션 로딩) + install.sh installed.json 시드. `update.sh` 로 설치 대상 전파.
> - [ ] **backward compat**: 기존 설치 환경(`.models` 미존재)은 `_config_models` fallback 기본값으로 동작 — 깨지지 않음.

## 🎯 핵심 전략 (Core Strategy)

### 아키텍처 컨텍스트

```text
installed.json .models = { director, worker, scout }   ← 단일 소스 (config)
   │  fallback: _config_models 가 // "opus"/"sonnet" 으로 미존재 대비
   ▼
sdd config models           → 매핑 출력
sdd config models <role> <m> → 단일 역할 갱신
   │
agent.md §6.6 표 = 역할 → `models.*` 참조 (모델명 부재)   ← 거버넌스 = 정책
   │  근거 → ADR-011
install.sh heredoc = .models 기본 시드   ← 신규 설치도 명시 보유
```

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **role taxonomy** | director / worker / scout (3) | phase draft 정합 + §6.6 4역할 매핑. reviewer 별도 분리는 over-engineering(review=director 티어) |
| **config 저장** | `installed.json` `.models` (jq) | 기존 uxMode/directorMode 와 동일 위치. bash3.2 — 연관배열 미사용, jq 로 다룸 |
| **명령 표면** | `models` (list) + `models <role> <model>` (set) | `_config_director_mode`/`_config_precheck` 패턴 미러. reset 등 과잉 표면 미추가(No over-engineering) |
| **기본값 시드** | install.sh heredoc + `_config_models` fallback | 신규 설치 명시 보유 + 기존 설치 backward compat (directorMode 가 fallback-only 였던 것보다 한 단계 견고) |
| **§6.6 변경 범위** | 표(모델명→역할참조) + prose 1줄만 | orchestration 단락(21-01)은 이미 역할 언어 — 무변경. §6.7 예시 문자열 무변경(Out of Scope) |
| **구현 주체** | 메인 직접 | sdd 분기 + 거버넌스 정합 — 판단 중심, 소규모. (director mode off — §6.6 always-on 정책상 위임 ROI 낮음) |

### 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — ADR-011 에 귀속.

## 📂 Proposed Changes

### config 표면 (sdd)

#### [MODIFY] `sources/bin/sdd` + `.harness-kit/bin/sdd` (미러)
- `cmd_config` 에 `models)  _config_models "$@" ;;` 분기 추가.
- `_config_models` 신규: 인수 없으면 list(jq 로 `.models` 출력, fallback 기본값), `<role> <model>` 이면 set(installed.json 갱신, 미지원 role 에러). `_config_director_mode` 의 jq+mv 패턴 재사용.
- `cmd_help` 의 config 사용법에 `config models [<role> <model>]` 한 줄 추가.

```text
_config_models() {
  installed_json = $SDD_ROOT/.harness-kit/installed.json
  role="${1:-}"; model="${2:-}"
  defaults: director=opus worker=sonnet scout=opus
  if no role: print 3 roles (jq '.models.<r> // "<default>"')
  else: validate role ∈ {director,worker,scout}; jq set .models.<role>=model; mv
}
```

#### [MODIFY] `install.sh`
- installed.json heredoc(현 `uxMode` 라인 부근)에 `.models` 기본값 추가:
```text
"models": { "director": "opus", "worker": "sonnet", "scout": "opus" },
```

#### [MODIFY] `.harness-kit/installed.json` (로컬 — dogfood)
- `.models` 3역할 기본값 추가(추적 여부는 실행 시 `git ls-files` 로 확인; 추적이면 커밋, untracked 면 로컬만).

### 거버넌스

#### [MODIFY] `sources/governance/agent.md` + `.harness-kit/agent/agent.md` (미러)
- §6.6 prose "runs on **Opus**" → "runs as **director** (`models.director`)".
- §6.6 표: Model 열의 Opus/Sonnet → 역할(director/worker/scout) + `models.*` 참조. 4행 → 3행(review/critique 를 director 로 흡수). 모델 티어가 config(`sdd config models`)임을 1줄 명시(→ ADR-011).

### 테스트

#### [NEW] `tests/test-role-model-config.sh`
- C1: installed.json `.models` 3역할(director/worker/scout) 존재(또는 fallback 동작).
- C2: `sdd config models` list 출력에 3역할 포함.
- C3: `sdd config models worker <x>` set → installed.json 반영(fixture 사용, 원복).
- C4: §6.6 에 `models.director`/`models.worker`/`models.scout` 참조 존재 + 표에 모델명 하드코딩 부재.
- C5: 이중 미러 parity (agent.md + sdd).

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
bash tests/test-role-model-config.sh
```

### 회귀
```bash
bash tests/test-governance-dedup.sh   # 무 NEW 회귀, Check 3 red 유지(21-06)
bash tests/test-director-mode.sh
bash tests/test-director-protocol.sh
```

### 수동 검증 시나리오
1. `sdd config models` — 기대: director/worker/scout → 모델 매핑 출력.
2. `sdd config models scout haiku` 후 `sdd config models` — 기대: scout=haiku 반영(검증 후 원복).
3. `grep -A6 "6.6 Model" sources/governance/agent.md` — 기대: `models.*` 참조 존재, Opus/Sonnet 표 셀 부재.
4. `diff -q sources/bin/sdd .harness-kit/bin/sdd` / agent.md 미러 — 기대: 차이 없음.

## 🔁 Rollback Plan

- config 추가는 신규 분기(`models)`) + 신규 함수 — 기존 로직 무변경. installed.json `.models` 미존재 시 fallback 으로 안전.
- §6.6 변경은 문서 표현 전환(의미 동일). 브랜치 폐기/revert 로 즉시 원복. 상태/데이터 영향 없음.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
