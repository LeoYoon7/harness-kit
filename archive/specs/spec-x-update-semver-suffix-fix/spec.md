# spec-x-update-semver-suffix-fix: update.sh semver 비교의 pre-release suffix crash 수정

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-update-semver-suffix-fix` |
| **Phase** | `phase-x` |
| **Branch** | `spec-x-update-semver-suffix-fix` |
| **상태** | Planning |
| **타입** | Fix |
| **Integration Test Required** | no |
| **작성일** | 2026-06-01 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

`update.sh` 는 갱신 전 preflight 단계에서 `semver_lt()` 로 버전 다운그레이드를 감지한다 (`update.sh:78-95`).

```bash
semver_lt() {
  local IFS=.
  local i
  local a=($1) b=($2)
  for ((i=0; i<3; i++)); do
    local x=${a[i]:-0} y=${b[i]:-0}
    if ((x < y)); then return 0; fi
    if ((x > y)); then return 1; fi
  done
  return 1
}
```

### 문제점

leo fork 의 버전은 `0.15.0-leo.1` 형태다. `local IFS=.` 로 split 하면 셋째 요소가 `0-leo` 가 된다. 이를 `((x < y))` arithmetic context 에서 평가하면 bash 는 `0-leo` 를 `0 - leo` 로 해석하고 `leo` 를 변수로 본다. `update.sh` 는 `set -euo pipefail` (`update.sh:16`) 이므로 `leo` 는 **unbound variable** 로 에러를 일으키고 스크립트 전체가 즉시 중단된다.

- **영향**: `bash update.sh --yes` 가 leo fork 환경에서 항상 crash → ADR-003 이 도그푸딩 sync 의 SSOT 로 지정한 `update.sh` 가 leo fork 에서 **호출 불가**.
- **실증**: 본 spec-x 직전 세션(도그푸딩 sync 해소)에서 `update.sh` 대신 surgical `cp` 로 우회한 근본 원인. Icebox 에도 `spec-x-notify-channel-formatter` Task 11 노출 사례로 기록됨.

### 해결 방안 (요약)

`semver_lt()` 가 각 버전 요소에서 **선행 숫자 부분만 추출**하도록 정규화한다 (`0-leo` → `0`). 비숫자 suffix 는 비교에서 무시되어 crash 가 사라지고, MAJOR.MINOR.PATCH 숫자 비교는 그대로 유지된다.

## 🎯 요구사항

### Functional Requirements

1. `semver_lt` 가 pre-release suffix 를 포함한 버전(`0.15.0-leo.1`)을 인자로 받아도 crash 없이 동작한다.
2. 각 요소는 선행 숫자 부분만으로 비교한다 (`0.15.0-leo.1` 의 PATCH = `0`).
3. `bash update.sh --yes` 가 leo fork 버전 환경에서 preflight 를 통과해 정상 진행한다.

### Non-Functional Requirements

1. bash 3.2+ 호환 (POSIX parameter expansion 만 사용, bash 4+ 기능 금지).
2. 기존 정상 버전(suffix 없는 `X.Y.Z`) 비교 동작은 불변 — 회귀 없음.

## 🚫 Out of Scope

- 정식 SemVer 2 pre-release 우선순위 비교 (예: `1.0.0-alpha` < `1.0.0` 규칙). 본 spec 은 crash 제거 + 숫자 비교 유지가 목표.
- fork 내 suffix 버전 간 비교 (`0.15.0-leo.1` vs `0.15.0-leo.2`). 현재 loop 는 `i<3` 만 보므로 넷째 요소(`.1`)는 비교 대상이 아니며, 이는 별도 이슈.
- `update.sh` 의 다른 로직(uninstall/install/cleanup) 변경.

## 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — 국소 버그 fix, 새 아키텍처 결정 없음.

## ✅ Definition of Done

- [ ] `bash tests/test-update-semver.sh` 단위 테스트 PASS (suffix 케이스 포함)
- [ ] 기존 회귀 테스트 PASS
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-update-semver-suffix-fix` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
