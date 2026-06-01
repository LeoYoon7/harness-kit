# Walkthrough: spec-x-update-semver-suffix-fix

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| suffix 처리 방식 | A: 숫자만 추출 / B: 정식 SemVer pre-release 우선순위 비교 | A | 본 fix 의 목적은 *crash 제거*. 다운그레이드 감지는 MAJOR.MINOR.PATCH 숫자로 충분하며, 정식 SemVer 우선순위는 over-engineering (Out of Scope) |
| `semver_lt` 단위 테스트 방법 | A: 함수만 awk 추출 후 source / B: update.sh 통째 source / C: semver lib 파일 분리 | A | update.sh 는 source 시 uninstall/install 부작용이 있어 B 불가. C 는 단일 함수 위해 파일 분리라 과함. A 는 SSOT 유지하며 순수 검증 |
| 빈 값 fallback | `${x%%[!0-9]*}` 만 / `+ ${x:-0}` | 둘 다 | 선행 숫자가 없는 요소(예: `-leo`)는 추출 결과가 빈 문자열 → `((  < y))` 또 다른 crash. `:-0` fallback 으로 방어 |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — 국소 버그 fix, cross-spec 의존/장기 결정 없음.

## 💬 사용자 협의

- **주제**: 새 작업 선택 (drift 해소 후)
  - **사용자 의견**: 1번 — `update.sh` semver suffix fix 를 spec-x 로 진행
  - **합의**: 이번 세션에서 `update.sh` 가 leo fork 에서 작동 안 해 surgical cp 로 우회한 근본 원인을 해소. ADR-003 도그푸딩 sync SSOT 복구.

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: `bash tests/test-update-semver.sh`
- **결과 (fix 전, Red)**: ❌ 정상 케이스 3개 PASS 후 suffix 케이스에서 `leo: unbound variable` crash, exit=1
- **결과 (fix 후, Green)**: ✅ PASS=6 FAIL=0, exit=0
- **로그 요약 (Green)**:
```text
  ✅ PASS: 정상: 0.15.0 < 0.16.0
  ✅ PASS: 정상: 0.16.0 > 0.15.0
  ✅ PASS: 정상: 동일 버전
  ✅ PASS: suffix 동일 — crash 없이 not-less
  ✅ PASS: suffix 무시 — MINOR 작음
  ✅ PASS: suffix 무시 — MINOR 큼
  결과: PASS=6  FAIL=0
```

### 2. 수동 검증

1. **Action**: `bash -n update.sh`
   - **Result**: ✓ 문법 정상 (편집 무결성 확인)
2. **Action**: `bash .harness-kit/bin/sdd test passed`
   - **Result**: ✓ lastTestPass = 2026-06-01T04:20:23Z 기록

## 🔍 발견 사항

- `sdd run-test "bash tests/test-update-semver.sh"` 가 따옴표로 묶은 명령을 단일 토큰(파일명)으로 해석해 exit 127. 직접 실행 + `sdd test passed` 로 우회. → `sdd run-test` 인자 파싱 개선 여지 (별도 검토 후보).
- 직전 세션 재검증 중 발견한 `test-uninstall-cmd-list.sh` Scenario 2 FAIL(uninstall 잔재)은 이미 Icebox 캡처됨 — 본 spec 범위 밖.

## 🚧 이월 항목

- 없음 (fork 내 suffix 버전 비교 `leo.1` vs `leo.2` 는 spec.md Out of Scope 로 명시, 현재 불필요).

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-01 |
| **최종 commit** | `116ab55` (Ship 전) |
