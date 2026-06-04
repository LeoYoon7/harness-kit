# Implementation Plan: spec-20-03

## 📋 Branch Strategy

- 신규 브랜치: `spec-20-03-harness-footguns` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `phase-20-upstream-parity` (phase-20 base 모드 — PR target 도 동일 base)
- 첫 task 가 브랜치 생성을 수행함
- 선행 spec(spec-20-02)은 base 브랜치에 Merged 확인됨 → §5.1 base 분기 규칙 충족

## 🛑 사용자 검토 필요 (User Review Required)

> 본 Plan 을 Accept 하기 전에 사용자가 명시적으로 확인해야 할 항목들.

> [!IMPORTANT]
> - [ ] **#2 병렬 진화 머지 방식**: fork 의 `.md` 제외(`staged_diff_no_md`)를 **유지한 채** upstream 의 보간/placeholder 필터(`_var_re`/`_ph_re`/`_op_re`)를 추가로 적용한다. 즉 두 오탐 예외를 모두 거친다. (대안: upstream 방식으로 전면 교체 → fork 의 `.md` 제외 손실, 비채택)
> - [ ] **#1b 채택 결정**: fork 의 `sdd status` drift 탐지와 별개로 `_warn_install_drift` 를 `spec new`/`specx new` 시점에 추가한다(능동 경고). 중복이 아니라 보완 — status 는 수동 조회, spec new 경고는 브랜치 생성 직전 능동 발화.

> [!WARNING]
> - [ ] **#3 state 시맨틱 변경**: 같은 phase 재활성 시 active spec 보존(기존엔 가드 die 또는 `--force` 리셋). 미세한 행동 변경 — `test-sdd-phase-activate.sh` 기존 Check 회귀 보존으로 검증.
> - [ ] 모든 변경은 sources↔installed **양쪽** 반영(NFR-2). 한쪽만 수정 시 sync drift 발생.

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **#2 check-secrets** | fork `.md` 제외 파이프라인에 upstream 보간/placeholder 필터 **append** | 두 오탐 원인(문서 리터럴 + env 보간)이 직교 — 둘 다 필요 |
| **#1a update.sh** | 종료 직전 안내 블록 additive 포팅 | fork update.sh 와 충돌 없음(말미 추가). 자동 커밋 금지 |
| **#1b _warn_install_drift** | upstream 헬퍼 그대로 포팅 + `spec new`/`specx new` 2곳 호출 | fork 헬퍼·호출자 구조 동일 → 매끄러운 이식 |
| **#3 phase activate** | upstream 로직 재구현 + `_set_phase_base_meta` 헬퍼 신규 포팅 | fork phase_new 는 인라인 sed(placeholder 전용) — 범용 헬퍼가 재활성 케이스에 필요 |

### 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — spec.md ADR 섹션과 동일. footgun fix 는 ADR 비대상(phase-20 plan 명시).

## 📂 Proposed Changes

### #2 시크릿 가드 (FR-1)

#### [MODIFY] `sources/hooks/check-secrets.sh` + `.harness-kit/hooks/check-secrets.sh`
fork 의 "일반 시크릿" 검사 블록(현재 line 63-66)에서 `staged_diff_no_md` 파이프라인은 유지하되, upstream 의 필터를 추가한다.

```bash
# 일반 시크릿 (추가된 줄만, 값이 있는 경우) — .md 제외 + shell 보간/placeholder 제외
# fork: .md 본문 제외(staged_diff_no_md) / upstream(#158): 값이 ${..}/$(..)/$VAR/placeholder 면 제외
_keys='(password|secret|api_key|api_secret|access_token|private_key)'
_q='["'"'"']?'                                   # 선택적 따옴표
_var_re="[=:][[:space:]]*${_q}[$][{(A-Za-z_]"    # 값 = $VAR / ${..} / $(..)
_ph_re="[=:][[:space:]]*${_q}(changeme|change-me|placeholder|example|sample|your[_-]|xxx+|dummy|todo|<[^>]+>|[.]{3})"
_op_re="${_keys}[[:space:]]*:[-=?+]"             # ${VAR:-default} 등 파라미터 확장
if echo "$staged_diff_no_md" | grep -E '^\+' \
     | grep -iE "${_keys}[[:space:]]*[=:][[:space:]]*[^[:space:]]+" \
     | grep -vE "$_var_re" | grep -viE "$_ph_re" | grep -viE "$_op_re" \
     | grep -q .; then
  violations="${violations}  시크릿 할당 패턴 발견 (password=, secret=, api_key= 등)\n"
fi
```

### #1a update 안내 (FR-2)

#### [MODIFY] `update.sh` (루트 단일 파일)
종료 메시지 직후 미커밋 install 산물 감지 블록 추가(upstream 동일). `warn`/`$C_YLW`/`$C_CYN`/`$C_RST`/`$TARGET`/`$NEW_VER` 사용 — fork update.sh 에 존재 확인 필요(구현 시).

### #1b 브랜치 drift 경고 (FR-3)

#### [NEW helper] `sources/bin/sdd` + `.harness-kit/bin/sdd` — `_warn_install_drift()`
upstream 함수 그대로 포팅(`.harness-kit`/`.claude` porcelain 검사 → `warn` + 예시, rc 0).

#### [MODIFY] `spec_new()` / `specx_new()`
`die_if_active_spec` 직후 `_warn_install_drift` 호출 1줄씩 추가.

### #3 phase activate (FR-4)

#### [NEW helper] `sources/bin/sdd` + `.harness-kit/bin/sdd` — `_set_phase_base_meta()`
upstream 헬퍼 포팅 — Base Branch 메타 행 값을 sed 로 치환.

#### [MODIFY] `phase_activate()`
`--base=<branch>` 인자 파싱 + `same_phase` 판별(가드/리셋 생략) + base 결정 우선순위(arg > meta) + `_set_phase_base_meta` 호출.

### 테스트

#### [MODIFY] `tests/test-check-secrets-dual-mode.sh`
env 보간(`${VAR:-default}`)·placeholder 비-`.md` 케이스 추가 + 실제 시크릿 계속 차단 회귀.

#### [MODIFY] `tests/test-update.sh`
update 후 dirty `.harness-kit/` 상태 → 안내 출력 케이스 추가.

#### [NEW] `tests/test-sdd-spec-new-drift-warn.sh`
dirty install 상태 → `sdd spec new`/`specx new` 경고 출력 + rc=0 + 정상 생성.

#### [MODIFY] `tests/test-sdd-phase-activate.sh`
`--base=<branch>` 인자 + 같은 phase 재활성 시 active spec 보존 케이스 추가.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
bash tests/test-check-secrets-dual-mode.sh
bash tests/test-update.sh
bash tests/test-sdd-spec-new-drift-warn.sh
bash tests/test-sdd-phase-activate.sh
```

### 회귀 / sync 검증
```bash
bash tests/test-governance-dedup.sh
diff -q sources/bin/sdd .harness-kit/bin/sdd
diff -q sources/hooks/check-secrets.sh .harness-kit/hooks/check-secrets.sh
```

### 수동 검증 시나리오
1. 비-`.md` 파일에 `DB_PASSWORD=${PG_PW:-changeme}` staged → commit 시도 — 기대: 통과(오탐 없음).
2. 비-`.md` 파일에 `password=hunter2` staged → commit 시도 — 기대: 차단(실제 시크릿).
3. dirty `.harness-kit/` 상태 → `sdd specx new foo` — 기대: 경고 + rc=0 + 정상 생성.
4. `sdd phase activate phase-20 --base=phase-20-upstream-parity` (active spec 있는 상태) — 기대: active spec 보존 + 메타 자동 기입.

## 🔁 Rollback Plan

- 각 footgun 이 독립 commit → 문제 시 해당 commit 만 revert.
- 모든 변경이 비차단·additive → 롤백 시 데이터/상태 영향 없음(state.json 스키마 불변).
- check-secrets 오탐 우려 시 hook 비활성(`HARNESS_SECRETS_MODE=off`)로 즉시 우회 가능.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
