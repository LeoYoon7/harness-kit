# fix(spec-x-update-semver-suffix-fix): strip pre-release suffix in semver_lt

## 📋 Summary

### 배경 및 목적

`update.sh` 의 preflight 다운그레이드 감지 함수 `semver_lt` 가 leo fork 버전(`0.15.0-leo.1`)을 `IFS=.` 로 split 하면 셋째 요소가 `0-leo` 가 된다. 이를 `((x < y))` arithmetic context 에서 평가하면 `leo` 가 변수로 해석되고, `set -euo pipefail` 환경에서 **unbound variable** crash 가 발생해 `update.sh` 전체가 중단된다.

결과적으로 `bash update.sh --yes` 가 leo fork 에서 호출 불가 → ADR-003 이 도그푸딩 sync SSOT 로 지정한 `update.sh` 가 마비. 직전 세션에서 도그푸딩 sync 를 surgical `cp` 로 우회한 근본 원인이다.

### 주요 변경 사항
- [x] `semver_lt` 가 각 버전 요소에서 선행 숫자만 추출하도록 정규화 (`0-leo` → `0`, 빈 값 → `0`)
- [x] pre-release suffix 포함 버전에서 crash 제거, MAJOR.MINOR.PATCH 숫자 비교는 유지
- [x] `tests/test-update-semver.sh` 신규 — suffix 케이스 포함 6개 회귀 테스트

### Phase 컨텍스트
- **Phase**: 없음 (spec-x, 독립 fix)
- **본 SPEC 의 역할**: leo fork 환경에서 `update.sh` 정상화 → 도그푸딩 sync SSOT 복구

## 🎯 Key Review Points

1. **suffix 무시 비교 의미**: pre-release suffix 를 *무시*(숫자만 비교)하는 방식 채택. 정식 SemVer pre-release 우선순위(`1.0.0-alpha < 1.0.0`)는 구현하지 않음 — 목적은 crash 제거. (spec.md Out of Scope)
2. **빈 값 fallback**: `${x%%[!0-9]*}` 추출 후 `${x:-0}` 로 빈 문자열을 0 처리 — 선행 숫자 없는 요소의 2차 crash 방어.
3. **bash 3.2 호환**: POSIX parameter expansion 만 사용 (bash 4+ 기능 없음).

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-update-semver.sh
```

**결과 요약**:
- ✅ fix 전(Red): suffix 케이스에서 `leo: unbound variable` crash, exit=1
- ✅ fix 후(Green): PASS=6 FAIL=0, exit=0

### 수동 검증 시나리오
1. **문법 검사**: `bash -n update.sh` → ✓ 정상
2. **leo fork 비교**: `semver_lt 0.15.0-leo.1 0.15.0-leo.1` → unbound variable 없이 종료코드 1(not-less)

## 📦 Files Changed

### 🆕 New Files
- `tests/test-update-semver.sh`: `semver_lt` 함수 awk 추출 후 source, suffix 포함 6개 케이스 검증

### 🛠 Modified Files
- `update.sh` (+2, -0): `semver_lt` 루프에 선행 숫자 정규화 2줄 추가

**Total**: 2 files changed (+ spec/plan/task/walkthrough 산출물)

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과 (6/6)
- [-] 통합 테스트 — 해당 없음 (Integration Test Required = no)
- [x] `walkthrough.md` ship commit 완료
- [x] `pr_description.md` ship commit 완료
- [-] lint — shellcheck 미설치 (staged-lint skip), `bash -n` 문법 검사로 대체
- [ ] 사용자 검토 요청 알림 완료 (push 후)

## 🔗 관련 자료

- Spec: `specs/spec-x-update-semver-suffix-fix/spec.md`
- Walkthrough: `specs/spec-x-update-semver-suffix-fix/walkthrough.md`
- 관련 ADR: `docs/decisions/ADR-003-dogfood-sync-policy.md` (도그푸딩 sync SSOT)
