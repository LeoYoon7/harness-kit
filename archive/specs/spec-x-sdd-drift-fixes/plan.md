# Implementation Plan: spec-x-sdd-drift-fixes

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-sdd-drift-fixes` (브랜치 이름 = spec 디렉토리 이름)
- 시작 지점: `main` (현재 HEAD: `487e637`)
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [x] **SSOT**: 본 fix 는 `sources/bin/sdd` (키트 원본) 에 적용. `.harness-kit/bin/sdd` (설치본) 는 `update.sh` 가 동기화 — ADR-003 정책.
> - [x] **dogfood-sync 자체를 패치** — 본 spec 작업 자체가 *자기 fix 를 dogfooding* 하는 구조. Task 4 에서 `update.sh` 호출이 *예상된* 단계 (예측 가능한 deviation 아님).

> [!WARNING]
> - [x] **외부 target 호환**: 새 `_drift_dogfood_sync` 는 `sources/` 디렉토리 *존재 시에만* 동작. 외부 사용자 (sources/ 없음) 환경에서 무영향 — Test C 가 자동 검증.
> - [x] **성능**: 매 `sdd status` 호출마다 ~30 파일 `diff -q` 추가. 미체감 수준이지만 본 spec 의 Verification 에서 1회 확인.

## 🎯 핵심 전략 (Core Strategy)

### 아키텍처 컨텍스트

```text
sources/bin/sdd  (SSOT — 패치 대상)
   ├─ _drift_stale_adr         ← 보강 (../ 시작 token 제외 1줄)
   ├─ _drift_dogfood_sync      ← NEW (sources/ vs .harness-kit/ tracked mismatch)
   └─ _status_drift            ← _drift_dogfood_sync 호출 추가

update.sh (Task 4-0 의 dogfood-sync 단계)
   └─ sources/bin/sdd → .harness-kit/bin/sdd 복사
```

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **dogfood-sync 검출 위치** | sdd 의 `_drift_dogfood_sync` 새 함수 추가 | `_drift_install` 은 *untracked* 만, 본 spec 은 *tracked* 비동기. 의도 분리 명확 + 기존 함수 보존. |
| **검사 대상 디렉토리** | `.harness-kit/hooks/*` + `.harness-kit/agent/templates/*` + `.claude/commands/*` | `_drift_install` 과 동일 범위 (install 대상). 일관성. `bin/` 도 후보지만 `_drift_install` 도 제외했으므로 **본 spec 도 제외** — scope 한정. |
| **외부 target 가드** | `[ -d "$SDD_ROOT/sources" ] \|\| return 1` | sources/ 없으면 dogfood 환경 아니므로 검사 자체 skip. |
| **메시지 형식** | `도그푸딩 sync: N 파일 sources/와 비동기 — bash update.sh --yes 권장` | 기존 drift 줄 (예: `워킹트리: ...`, `install 부산물: ...`) 의 1줄 패턴 일관 유지. |
| **ADR `../` 제외 위치** | token 필터 4 단계 직후, 존재 검사 직전 | 기존 필터 체인 보존 + 한 줄 추가. |

### 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — sdd 의 drift 검사 정확도 보강. 단발 fix.

## 📂 Proposed Changes

### sdd 패치

#### [MODIFY] `sources/bin/sdd`

**1. `_drift_stale_adr` 보강** (`../` token 제외)

기존 token 필터 체인 (`# 1) 슬래시 포함` ~ `# 4) 존재 검사`) 직전, 4) 검사 *바로 앞* 에 한 줄 추가:

```bash
# 5) 상대경로 토큰 (../) 은 ADR 본문의 가설/예시 인용 — 진단 제외
echo "$token" | grep -qE '^\.\./' && continue
```

**2. `_drift_dogfood_sync` 신규 함수**

```bash
# tracked .harness-kit/* 와 sources/* mismatch 검출 (dogfood 환경 한정)
_drift_dogfood_sync() {
  [ -d "$SDD_ROOT/sources" ] || return 1

  local mismatch=0
  local check_pairs="\
.harness-kit/hooks|sources/hooks
.harness-kit/agent/templates|sources/templates
.claude/commands|sources/commands"

  local pair installed_dir source_dir f source_path
  while IFS='|' read -r installed_dir source_dir; do
    [ -z "$installed_dir" ] && continue
    [ -d "$SDD_ROOT/$installed_dir" ] || continue
    [ -d "$SDD_ROOT/$source_dir" ] || continue
    for f in "$SDD_ROOT/$installed_dir"/*; do
      [ -f "$f" ] || continue
      source_path="$SDD_ROOT/$source_dir/$(basename "$f")"
      [ -f "$source_path" ] || continue
      diff -q "$f" "$source_path" >/dev/null 2>&1 || mismatch=$((mismatch + 1))
    done
  done <<EOF
$check_pairs
EOF

  [ "$mismatch" -eq 0 ] && return 1
  printf "  ${C_YLW}도그푸딩 sync: %d 파일 sources/와 비동기 — bash update.sh --yes 권장${C_RST}\n" \
    "$mismatch"
  return 0
}
```

> bash 3.2 호환을 위해 `declare -a` 사용 안 함 — heredoc + while read 패턴 (기존 `_drift_install` 과 같은 기법).

**3. `_status_drift` 등록**

기존 호출 체인에서 `_drift_install` 다음 줄에 추가:

```bash
_drift_dogfood_sync && has_drift=1
```

### 테스트 보강

#### [MODIFY] `tests/test-drift-stale-adr.sh`

ADR 본문에 `../` token 만 있는 fixture 추가 — `_drift_stale_adr` 가 stale 카운트 0 으로 보고하는지 검증 (Test D).

#### [MODIFY] `tests/test-sdd-drift.sh`

기존 fixture lib 사용해서 신규 시나리오 3개 추가:
- **T6** (Test A): tracked .harness-kit/* 가 sources/* 와 일치 → 보고 없음
- **T7** (Test B): tracked .harness-kit/hooks/foo.sh 가 sources/hooks/foo.sh 와 다름 → `도그푸딩 sync: 1 파일 ... 권장` 출력
- **T8** (Test C): fixture 에 `sources/` 디렉토리 없음 → `_drift_dogfood_sync` skip (보고 없음)

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)

```bash
bash tests/test-drift-stale-adr.sh
bash tests/test-sdd-drift.sh
```

**기대 결과**: 두 파일 모두 PASS (기존 + 신규 모두).

### 수동 검증 시나리오

1. 본 프로젝트 (dogfood 환경) 에서 `bash .harness-kit/bin/sdd status` 실행 → `stale ADR: 1 ...` 줄 *사라짐* (ADR-003 의 `../` token 이 제외됨).
2. 본 프로젝트 sources/bin/sdd 만 패치한 시점 (.harness-kit/bin/sdd 미동기화) 에서 `sdd status` 실행 → `도그푸딩 sync: 1 파일 ... 권장` 출력 (dogfood-sync drift 자체 감지).
3. `bash update.sh --yes` 실행 후 `sdd status` 재실행 → `도그푸딩 sync` 줄 사라짐 + `🔄 동기화 상태` 가 `깔끔` 출력 (워킹트리 변경만 있을 시).

### 통합 테스트

Integration Test Required = no — 단위 테스트로 충분.

## 🔁 Rollback Plan

- **변경량**: sdd 한 함수 신규 추가 (~25줄) + 한 줄 추가 (stale_adr filter) + 테스트 4건.
- **롤백 방법**: `git revert <commit>` — drift 검사는 순수 함수형. 상태 영향 없음.

## 📦 Deliverables 체크

- [x] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
