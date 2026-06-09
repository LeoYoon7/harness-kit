# Walkthrough: spec-x-drift-test-fixture-race

> drift-stale-adr / phase16 테스트가 *전역 ADR 스캔* 에 대해 전역 count 단언을 써서, 동시 실행 시 cross-test fixture 간섭으로 간헐 실패하던 문제를 *자기 fixture 특정 단언* 으로 견고화한 작업 기록. 초기 오진(fs-visibility)→정정(cross-test 간섭)의 경위 포함.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 근본원인 | fs-visibility race / cross-test 간섭 | **cross-test 간섭** | 격리 micro-repro 가 race 재현 0; phase16 fixture 가 drift 스캔에 잡힘을 실증 |
| fix 방향 | ensure_visible(sync) / 단언 견고화 / 제품 scoped 스캔 | **단언 견고화(자기 fixture 특정)** | 간섭은 테스트 단언 설계 문제. 제품 무변경, surgical |
| 검증 | race 반복(N회) / deterministic 1회 | **deterministic 1회** | 간섭은 결정적(타이밍 무관) — count=2 1회 호출로 증명 |
| phase16 처리 | drift 만 / 대칭 fix | **대칭 fix** | phase16 Scenario 2 도 동일 fragile 패턴 → 양방향 간섭 완전 해소 |

### ADR 승격 가이드
- [ ] 있음
- [x] 없음 — 테스트 격리 패턴(공유 글로벌 자원 단언은 자기 자원 특정으로). 일반 상식.

## 💬 사용자 협의

- **주제**: 초기 plan(fs-visibility) 무효 발견 → Hard Stop
  - **사용자 의견**: 1 (A — 재설계)
  - **합의**: 정정된 원인(cross-test 간섭)으로 spec/plan/task 재작성 + 재-Plan-Accept
- **주제**: 코드 리뷰 게이트
  - **사용자 의견**: 1 (Gemini cross-model)
  - **합의**: Gemini Approve(Minor 1, 의도된 trade-off) 확인 후 ship

## 🧪 검증 결과

### 1. deterministic 간섭 검증 (race 아님, 1회 호출)
- **방법**: foreign(`ADR-999-phase16-integration-fixture.md`) + own(`ADR-999-stale-fixture.md`) 동시 존재 → `sdd status` 1회
- **결과**:
```text
stale ADR: 2 (missing-path) — docs/decisions/ADR-999-phase16-integration-fixture.md; docs/decisions/ADR-999-stale-fixture.md
OLD: grep "stale ADR: 1 (missing-path)"  → NO MATCH  (구 Step2 FAIL = 간섭 재현)
NEW: grep "ADR-999-stale-fixture"        → MATCH     (신 Step2 PASS = 견고)
```
- phase16 fixture 도 목록에 나타남 → phase16 신 단언(`grep "ADR-999-phase16-integration-fixture"`)도 동일 run 으로 검증.

### 2. 회귀 sanity (full 테스트 solo)
- **명령**: `bash tests/test-drift-stale-adr.sh`
- **결과**: ✅ **6/6 PASS**
```text
  ✓ clean state: own fixture not in stale list
  ✓ fixture ADR (missing path) → own fixture detected stale
  ✓ regression: ADR-998 (all-valid-paths fixture) → not in stale list
  ✓ ADR with only ../ relative-path token → not in stale list
  ✓ archived spec ref (archive/specs/...) → resolved, not in stale list
  ✓ archived backlog ref (archive/backlog/...) → resolved, not in stale list
```

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Gemini cross-model) |
| **결과 파일** | `specs/spec-x-drift-test-fixture-race/code-review-gemini.md` |
| **요약** | **Approve** / Critical 0 / Major 0 / Minor 1 |
| **Skip 사유** | — (실행함) |

Minor 1: Step 1 의미 좁힘(real-ADR 건강 검사 상실). gemini 도 "격리 우선이므로 수용 가능"으로 판정 — 이미 spec OOS / plan 에 의도된 trade-off 로 명시. 조치 불요.

> 절차 메모: 첫 gemini 실행은 *uncommitted ship 산출물* 때문에 방어 가드(pre-clean 아님)에 막힘 → `git stash` 로 working tree clean 후 재실행 성공. 워크스페이스 변조는 없었음(가드 정상 동작).

## 🔍 발견 사항

- **오진→정정 경위**: 초기 "20% 재현" 은 같은 fixture 파일을 쓰는 repro 스크립트 2개를 동시 실행한 *자가 collision* 아티팩트였다. 끝까지 파고들어(격리 micro-repro 0 miss → phase16 fixture 가 drift 스캔에 잡힘 실증) 진짜 원인(cross-test 간섭)을 확정. *추측 금지·끝까지 검증* 의 가치.
- **`sdd status` Windows 성능 저하**: solo ~1m24s (sys 54s). 별개 → queue Icebox 기록.

## 🚧 이월 항목

- **`sdd status` Windows 성능 저하** → queue Icebox.
- (한계) stale 목록 truncation(동시 stale fixture ≥4)은 OOS — 현실적으로 ≤3.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-09 |
| **최종 commit** | (ship commit 시 갱신) |
