# Walkthrough: spec-x-sdd-robustness-fixes

> 작업 기록 — 결정·협의·검증·발견.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 작업 묶음 | 버그 2종 bundle / 각각 / bug1만 | **2종 bundle spec-x** | 같은 `sdd` robustness 테마, 둘 다 이번 세션 실증. bundle 패턴(ceremony 절감). 사용자 선택 |
| Bug1 테스트 방식 | 헬퍼 추출+소스가드 / 블랙박스 ship / grep 구조 | **헬퍼 + 소스가드** | 결정적 단위 테스트 가능. 소스가드는 표준 관용구(직접실행 불변) |
| Bug2 검증 경계 | 결정적 repro / 회귀만 | **회귀만(detection green)** | git-bash fd race 는 결정적 repro 불가(플래키 테스트=안티패턴). 프로세스치환 제거=robustness fix |
| 테스트 헬퍼 충돌 | (작업 중 발견) | t_ok/t_bad 로 rename | sdd `ok()` 가 source 시 내 `ok()` 덮어써 PASS=0 오탐 → source 후 고유 이름 정의 |

### ADR 승격 가이드
- [ ] ADR 승격 대상 있음
- [x] 없음 — 국소 버그 수정. 새 장기 불변식 없음.

## 💬 사용자 협의

- **주제**: 다음 작업 선택 (post-merge idle)
  - **사용자 의견**: 1 (kit 버그 2종 묶어 spec-x) — Telegram
  - **합의**: spec-x-sdd-robustness-fixes
- **주제**: Plan Accept
  - **사용자 의견**: 1 (Accept) — Telegram
  - **합의**: Strict Loop 실행

## 🧪 검증 결과

### 자동화 테스트
- `bash tests/test-sdd-ship-scope.sh` → ✅ PASS=5/0 (spec-x 전체보존 3 + 일반 spec 첫3필드 2). TDD: 미정의 Red → 헬퍼+가드 Green.
- `bash tests/test-drift-stale-adr.sh` → ✅ 4/4 (Step1-4, here-string 교체 후 detection 정확성 보존).

### 직접 실행 회귀 (소스 가드)
- `bash .harness-kit/bin/sdd help` / `version` / `status --brief --no-drift` → 모두 exit 0, 정상 출력. 소스가드가 직접 실행을 깨지 않음 확인.
- `bash -n sources/bin/sdd` → 구문 OK.

### 수동 검증
1. 미러 diff `diff sources/bin/sdd .harness-kit/bin/sdd` → 차이 0 (ADR-003).
2. (도그푸딩) 본 spec ship 커밋 subject 가 `docs(spec-x-sdd-robustness-fixes):` 로 온전 — Bug1 라이브 검증(아래 ship 단계).

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Gemini cross-model) |
| **결과 파일** | `specs/spec-x-sdd-robustness-fixes/code-review-gemini.md` |
| **요약** | **Approve** — Critical 0 / Major 0 / Minor 0. 4 FR 모두 충족 확인, 빈 toks 처리(`sdd:395`)·bash 3.2 호환 검증. 권고 없음. |
| **Skip 사유** | — |

## 🔍 발견 사항

- **테스트 헬퍼 충돌(잠복 버그)** — 테스트가 sdd 를 source 하면 sdd 의 `ok()`/`fail()` 가 테스트 헬퍼를 덮어써 카운터가 0 으로 오탐. source *후* 고유 이름 정의가 원칙. (Red 단계에선 함수-미정의 early-exit 로 가려졌다가 Green 에서 PASS=0 으로 드러남.)
- **소스 가드의 부수 효과** — `[ "${BASH_SOURCE[0]}" = "$0" ] && main` 으로 sdd 가 sourceable 해져 향후 sdd 함수 단위 테스트 확대 가능(이번엔 Bug1 한정).
- **여기서 here-string** — `done <<< "$toks"` 는 임시 파일 기반이라 git-bash 프로세스 치환 fd race 를 회피. 빈 `toks` 는 빈 줄 1회 → 기존 `[ -z ]` 가드가 처리.

## 🚧 이월 항목
- 없음(이번 세션 발견 2종을 본 spec 에서 해소). 잔여 Icebox(B2 N측정 등)는 별개.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-09 |
| **최종 commit** | (ship 후 갱신) |
