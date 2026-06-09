# Implementation Plan: spec-x-sdd-robustness-fixes

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-sdd-robustness-fixes` (= spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] **Bug 2 는 결정적 테스트 없음** — git-bash fd race 플래키는 결정적 repro 불가(플래키 테스트=안티패턴). here-string 교체(=프로세스 치환 제거)를 robustness fix 로 자리매김 + 기존 detection 테스트 green 으로 회귀만 보장. 수용?
> - [ ] **sdd 소스 가드 추가** — 말미 `main "$@"` → `[ "${BASH_SOURCE[0]}" = "$0" ] && main "$@"`. 표준 관용구지만 sdd 진입점 변경 — 직접 실행 동작 불변 검증 필수.

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **Bug 1 fix** | `sdd_ship_scope()` 헬퍼 + `spec-x-*` case 분기 | spec-x 는 전체 id 가 scope, 일반 spec 은 첫 3필드 — 헬퍼화로 단위 테스트 가능 |
| **소스 가드** | `[ "${BASH_SOURCE[0]}" = "$0" ] && main "$@"` | 소싱 시 main 미실행 → 함수 단위 테스트 활성화. 직접 실행 불변 |
| **Bug 2 fix** | `done < <(...)` → `toks="$(...)"; done <<< "$toks"` | git-bash 프로세스 치환 fd race 제거. `has_missing` 부모 스코프 유지(here-string 은 서브셸 안 만듦) |
| **테스트** | Bug1=결정적 단위 / Bug2=기존 detection 회귀 | 플래키 테스트 회피, 정직한 검증 경계 |
| **미러** | 같은 commit 에 `.harness-kit/bin/sdd` 동기화 | ADR-003 도그푸딩 sync |

### 📑 ADR 후보

- [x] 없음 — 국소 버그 수정.

## 📂 Proposed Changes

### Bug 1 — ship spec-x scope

#### [MODIFY] `sources/bin/sdd` (`cmd_ship` 부근 + 말미)
- 신규 헬퍼(전역 함수 영역):
```bash
# spec-id → commit subject scope. spec-x-{slug} 는 전체, spec-{N}-{seq}-{slug} 는 첫 3필드.
sdd_ship_scope() {
  case "$1" in
    spec-x-*) printf '%s' "$1" ;;
    *)        printf '%s' "$1" | awk -F- '{print $1"-"$2"-"$3}' ;;
  esac
}
```
- `cmd_ship()`: `scope="$(echo "$spec_id" | awk -F- '{print $1"-"$2"-"$3}')"` → `scope="$(sdd_ship_scope "$spec_id")"`.
- 말미: `main "$@"` → `[ "${BASH_SOURCE[0]}" = "$0" ] && main "$@"`.

### Bug 2 — stale-adr fd race

#### [MODIFY] `sources/bin/sdd` (`_drift_stale_adr`)
```bash
# 변경 전: done < <(grep -oE '`[^`]+`' "$adr" 2>/dev/null | tr -d '`')
# 변경 후:
local toks
toks="$(grep -oE '`[^`]+`' "$adr" 2>/dev/null | tr -d '`')"
while IFS= read -r token; do
  ...
done <<< "$toks"
```
(빈 `toks` 일 때 here-string 은 빈 줄 1회 — `[ -z "$token" ] && continue` 가 이미 처리.)

### 미러

#### [MODIFY] `.harness-kit/bin/sdd`
위 변경을 **byte-identical** 동기화(ADR-003). 같은 commit. (도그푸딩: 본 spec ship 시 이 미러가 Bug1 fix 를 적용해 자기 검증.)

### 테스트

#### [NEW] `tests/test-sdd-ship-scope.sh`
sdd 를 source 후 `sdd_ship_scope` 단위 검증:
- `sdd_ship_scope spec-x-review-b1-default` == `spec-x-review-b1-default`
- `sdd_ship_scope spec-x-a-b-c` == `spec-x-a-b-c`
- `sdd_ship_scope spec-08-01-foo` == `spec-08-01`
- `sdd_ship_scope spec-x-single` == `spec-x-single`
- (회귀) source 시 main 미실행 — 출력/exit 부작용 없음.

#### [VERIFY] `tests/test-drift-stale-adr.sh`
here-string 교체 후 Step 1-4 green 유지(detection 정확성 회귀 확인). 신규 케이스 불요.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트
```bash
bash tests/test-sdd-ship-scope.sh
bash tests/test-drift-stale-adr.sh
```

### 직접 실행 회귀 (소스 가드)
```bash
bash .harness-kit/bin/sdd help
bash .harness-kit/bin/sdd status --brief --no-drift
```
기대: 소스 가드 추가 후에도 정상 출력 + exit 0.

### 수동 검증
1. `sdd_ship_scope` 4 케이스 — 기대값 일치.
2. 미러 diff — `diff sources/bin/sdd .harness-kit/bin/sdd` → 차이 0.
3. (도그푸딩) 본 spec ship 커밋 subject = `docs(spec-x-sdd-robustness-fixes): ...` (truncate 없음).

## 🔁 Rollback Plan

- `sources/bin/sdd` 국소 변경 — `git revert` 단순 원복. 런타임 상태 영향 없음.
- 소스 가드가 직접 실행을 깨면(검증서 발견 시) 즉시 STOP + 원복.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
