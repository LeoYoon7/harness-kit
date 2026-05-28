# Walkthrough: spec-x-sdd-drift-fixes

> `sdd status` 의 drift 진단 두 fix bundle — (#1) tracked dogfood-sync drift 검출 + (#2) ADR stale-path false positive 해소.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 후속 follow-up 우선순위 | (1) #1 update.sh 안내 / (2) #2 ADR stale / (3) #3 D 옵션 가설 | **1+2 bundle** | #1 = 매 머지마다 잠재 드리프트 (본 spec 작업도 영향), #2 = 매 status 노이즈. 두 fix 가 같은 sdd 파일 (carrier) 안에 있어 bundle ROI 우수 (ceremony 절감). #3 은 YAGNI. |
| #1 검출 위치 | (A) `_drift_install` 확장 (untracked + tracked 모두) / (B) `_drift_dogfood_sync` 신규 함수 | **B** | `_drift_install` 의 의도 ("install 부산물 = untracked") 보존. tracked 비동기는 다른 의도라 분리. 함수당 단일 책임. |
| #1 검사 대상 디렉토리 | (A) install.sh install 대상 전체 (hooks + templates + commands + bin + ...) / (B) `_drift_install` 과 동일 (hooks + templates + commands) / (C) 자유 확장 | **B** | `_drift_install` 과 동일 범위 → 일관성. bin/ 은 install 매핑 복잡 (sources/bin/sdd → .harness-kit/bin/sdd 명시적 단일 파일), `_drift_install` 도 제외했으므로 scope 한정. |
| #1 외부 target 가드 | (A) 항상 검사 (외부 환경 항목 0 자연 무영향) / (B) `sources/` 디렉토리 존재 시에만 검사 | **B** | 의도 명시적 가드. 외부 사용자에게 *함수 자체가 호출 안 됨* — 디버깅 시 명료. Test C 자동 검증. |
| #1 메시지 형식 | (A) 영문 sync drift 등 / (B) `도그푸딩 sync: N 파일 sources/와 비동기 — bash update.sh --yes 권장` | **B** | 기존 drift 줄 (`워킹트리: ...`, `install 부산물: ...`) 의 한국어 1줄 패턴 일관 유지 + 다음 행동 (`update.sh`) 안내 포함. |
| #2 false positive 해소 범위 | (A) `../` 시작만 / (B) `*` glob / repo reference / anchor 등 다른 패턴까지 / (C) 본문 컨텍스트 (코드 fence 인식) | **A** | 본 spec 의 직접 관찰은 `../` 케이스 (ADR-003) 만. (B), (C) 는 *관찰되지 않은* 가설 — YAGNI. 한 줄 fix 로 ROI 극대화. |
| Test 파일 선택 | (A) `test-drift-stale-adr.sh` + `test-sdd-drift.sh` 양쪽 추가 / (B) 새 test 파일 신규 | **A** | 같은 토픽이라 별도 파일 분리 가치 없음. 기존 fixture lib 재사용. |
| Plan deviation: test-drift-stale-adr 의 `SDD_BIN` 변경 | (A) `.harness-kit/bin/sdd` 유지 (기존) / (B) `sources/bin/sdd` 로 변경 | **B** | 같은 test suite 안에서 `test-sdd-drift.sh` 와 일관성. sources/ 패치가 즉시 테스트에 반영 — TDD Red→Green 사이클 단축. Task 2 commit 에 포함, walkthrough 결정 기록에 명시. |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — sdd 의 drift 검사 정확도 보강. ADR-003 의 dogfood-sync 원칙은 그대로 유지 (본 fix 가 그 원칙의 *가시성* 만 보강).

## 💬 사용자 협의

- **주제**: PR #4 머지 후 follow-up 우선순위 분석 요청
  - **사용자 의견**: 우선순위 선별 요청 → 분석 후 1+2 bundle 선택
  - **합의**: SDD-x 로 진행. 두 fix 가 sdd 의 같은 drift 검사 carrier 영역이라 bundle ROI 우수.
- **주제**: Plan Accept
  - **사용자 의견**: 1번 — A 권장안 그대로
  - **합의**: 즉시 Strict Loop 진입.

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: `bash tests/test-drift-stale-adr.sh && bash tests/test-sdd-drift.sh`
- **결과**: ✅ Passed (본 spec 신규 4건 + 기존 회귀 가드)
- **로그 요약**:

```text
[test-drift-stale-adr.sh]
  ✓ clean state: no stale ADR line
  ✓ fixture ADR (1 missing path) → stale ADR: 1 detected
  ✓ regression: ADR-998 (all-valid-paths fixture) → no stale line
  ✓ ADR with only ../ relative-path token → no stale line (false positive exclude)   ← 신규 (Test D)

[test-sdd-drift.sh]  (T6/T7/T8 신규)
  ✅ T6: sources/ 와 .harness-kit/ 동일 → 보고 없음
  ✅ T7: mismatch 검출 — '도그푸딩 sync: 1 파일' 출력           ← Red→Green 전환
  ✅ T8: sources/ 없음 → _drift_dogfood_sync skip (외부 target 무영향)
```

#### 통합 테스트
Integration Test Required = no — 생략.

### 2. 수동 검증 (dogfood self-verify)

1. **Action**: Task 5 commit 직후 (`bash update.sh --yes` 전) — `bash .harness-kit/bin/sdd status` 실행
   - **Result**: 옛 sdd 가 호출되어 `stale ADR: 1 (missing-path) — docs/decisions/ADR-003-...` 줄 출력 (fix 미반영 상태).
2. **Action**: `bash update.sh --yes` 실행 → `.harness-kit/bin/sdd` 동기화 → Task 6-0 commit `b4f73ae`
   - **Result**: `.harness-kit/bin/sdd` 가 본 spec 패치 반영.
3. **Action**: `bash .harness-kit/bin/sdd status` 재실행
   - **Result**: `stale ADR` 줄 *사라짐* ✓. `🔄 동기화 상태` 가 `워킹트리: 2 변경 ...` 만 (워킹트리 = update.sh 의 결과물). 본 spec 의 #2 fix 가 dogfood 환경에서 즉시 동작 확인.

### 3. EOL 정합성 (별 발견)

Task 3 의 `sources/bin/sdd` commit 이 `2402 insertions(+), 2400 deletions(-)` 로 표시됨 — 실제 content 변경은 1줄, 나머지는 CRLF→LF EOL 변환. Windows Git Bash 환경의 autocrlf 동작 결과. PR diff 가독성 영향, *기능 영향 없음*.

## 🔍 발견 사항

- **dogfood self-verify 입증**: 본 spec 의 fix 가 *자기 자신의 dogfood-sync drift* 를 fix 하는 메타 구조. Task 6-0 의 update.sh 호출 + chore commit 까지가 *예정된* 단계로 plan.md 에 사전 명시 (이전 spec 들은 deviation 으로 발견했던 것).
- **EOL 변환 노이즈** (Task 3 commit): Windows Git Bash 의 CRLF→LF 자동 변환이 sdd 같은 LF-only 파일의 첫 편집 시 전체 갈아엎힘으로 표시. **별 spec 후보**: `.gitattributes` 로 `sources/bin/sdd`, `tests/*.sh` 등 shell 파일을 `eol=lf` 강제. dogfood 환경 (Windows) 의 ergonomic 개선.
- **test-sdd-drift.sh T1 baseline fail**: 본 spec 변경 *이전부터* T1 의 첫 check ("동기화 상태 섹션 누락") fail. 본 spec 무관. **별 spec 후보**: fixture 의 sdd status 가 drift 섹션을 출력하지 않는 원인 추적 (아마 fixture 가 `--no-drift` 자동 적용 또는 fresh fixture 에서 status 가 drift 섹션 skip 경로).
- **다음 머지 시 dogfood-sync 가시화**: 본 spec 머지 후 임의 sources/* 변경이 .harness-kit/ 에 동기 안 된 상태에서 `sdd status` 호출 시 `도그푸딩 sync: N 파일 ... 권장` 자동 출력. drift 누락 패턴 재발 방지 — 이전 spec 들의 follow-up 가설 검증.

## 🚧 이월 항목

- **EOL 정합성 (.gitattributes)** spec-x 후보 — Windows Git Bash + Linux/macOS 혼용 환경의 LF-only 강제. 본 spec 의 Task 3 commit 노이즈의 직접 원인.
- **test-sdd-drift.sh T1 baseline fail 추적** spec-x 후보 — fixture/sdd status 동작 검증.
- (가설) **D 옵션** (다른 placeholder 확장자 false positive) — 본 spec 의 #3 보류. 관찰 시 진행.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Opus 4.7) + Leo |
| **작성 기간** | 2026-05-28 |
| **최종 commit** | `b4f73ae` (chore: dogfood sync), `e0e396e` (feat: _drift_dogfood_sync), `06bdcea` (test: T6/T7/T8), `c67cbfc` (fix: ../ exclude), `b5787ec` (test: Test D + SDD_BIN) |
