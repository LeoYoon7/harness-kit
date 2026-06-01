# Implementation Plan: spec-x-update-semver-suffix-fix

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-update-semver-suffix-fix` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] 비교 의미 변경: pre-release suffix 를 **무시**(숫자만 비교)하는 방식 채택. 정식 SemVer pre-release 우선순위는 구현하지 않음 (Out of Scope). 본 fix 의 목적은 *crash 제거* 이며, 다운그레이드 감지는 MAJOR.MINOR.PATCH 숫자로 충분.

> [!WARNING]
> - [ ] `update.sh` 는 키트 루트 전용 스크립트로 install 자산이 아님 → 대상 프로젝트로 복사되지 않음. 도그푸딩 sync 대상 아님 (수정 1곳).

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **semver_lt** | 각 요소에서 선행 숫자만 추출 후 비교 (`${x%%[!0-9]*}` + 빈 값 `:-0` fallback) | crash 제거 + 숫자 비교 유지. POSIX param expansion 으로 bash 3.2 호환 |
| **단위 테스트** | `update.sh` 에서 `semver_lt` 함수만 awk 추출해 source → 케이스 검증 | `update.sh` 는 실행 시 uninstall/install 부작용이 있어 통째 source 불가. 함수만 떼어 SSOT 유지하며 순수 검증 |

### 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — 국소 버그 fix.

## 📂 Proposed Changes

### update.sh

#### [MODIFY] `update.sh` (semver_lt, line 84 근처)

각 요소 추출 직후 선행 숫자 정규화를 추가한다.

```bash
for ((i=0; i<3; i++)); do
  local x=${a[i]:-0} y=${b[i]:-0}
  x=${x%%[!0-9]*}; x=${x:-0}   # 추가: '0-leo' → '0', 빈 값 → '0'
  y=${y%%[!0-9]*}; y=${y:-0}   # 추가
  if ((x < y)); then return 0; fi
  if ((x > y)); then return 1; fi
done
```

### tests

#### [NEW] `tests/test-update-semver.sh`

- `update.sh` 에서 `semver_lt() { ... }` 정의를 awk 범위(`/^semver_lt\(\) \{/,/^\}/`)로 추출해 임시 파일에 쓰고 source.
- 케이스별 종료코드 검증 (0 = less, 1 = not-less):

| 인자 (NEW, PREV) | 기대 | 의미 |
|---|:---:|---|
| `0.15.0` `0.16.0` | 0 | 정상: 작음 |
| `0.16.0` `0.15.0` | 1 | 정상: 큼 |
| `0.15.0` `0.15.0` | 1 | 정상: 같음 |
| `0.15.0-leo.1` `0.15.0-leo.1` | 1 | **suffix 동일 — crash 없이 not-less** |
| `0.15.0-leo.1` `0.16.0-leo.1` | 0 | suffix 무시, MINOR 비교 작음 |
| `0.16.0-leo.1` `0.15.0` | 1 | suffix 무시, MINOR 비교 큼 |

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)

```bash
bash tests/test-update-semver.sh
```

### 회귀 테스트

```bash
bash .harness-kit/bin/sdd test passed
```

### 수동 검증 시나리오

1. fix 전 `tests/test-update-semver.sh` 실행 → suffix 케이스에서 FAIL/에러(Red) 확인.
2. fix 후 동일 테스트 → ALL PASS(Green).
3. (선택) leo fork 버전에서 `semver_lt 0.15.0-leo.1 0.15.0-leo.1` 가 unbound variable 없이 종료코드 1 반환.

## 🔁 Rollback Plan

- 단일 함수 4줄 변경 + 테스트 1파일. 문제 시 해당 commit revert 로 즉시 원복.
- 상태/데이터 영향 없음 (순수 함수).

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
