# spec-x-drift-test-fixture-race: drift-stale-adr 테스트의 cross-test fixture 간섭 견고화

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-drift-test-fixture-race` |
| **Phase** | `phase-x` |
| **Branch** | `spec-x-drift-test-fixture-race` |
| **상태** | Planning (재설계 — 이전 plan 무효) |
| **타입** | Fix (test isolation) |
| **Integration Test Required** | no |
| **작성일** | 2026-06-09 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

`_drift_stale_adr()` (`sources/bin/sdd`) 는 `docs/decisions/ADR-*.md` 를 **전역 glob** 하여 각 ADR 의 missing-path 토큰을 검사하고 stale ADR **총 개수**를 출력한다(`stale ADR: N (missing-path) — <files>`). `tests/test-drift-stale-adr.sh` 의 각 step 은 이 *전역 카운트/부재* 에 의존한다:
- Step 1: "stale ADR" 라인이 **전혀 없음** (clean) 단언.
- Step 2: `grep "stale ADR: 1 (missing-path)"` — **정확히 1개** 단언.

### 문제점

여러 테스트가 `docs/decisions/` 에 missing-path ADR fixture 를 떨군다. 특히 `tests/test-phase16-integration.sh` 도 `docs/decisions/ADR-999-phase16-integration-fixture.md`(missing path 포함)를 만든다. 두 fixture 는 **같은 전역 glob `ADR-*.md` 에 걸린다.**

→ 두 테스트가 **동시에 실행**되면(예: Claude Code 백그라운드 task 로 여러 테스트를 병렬 실행), 한 테스트의 fixture 가 다른 테스트의 `sdd status` 스캔에 **간섭**한다:
- Step 1 도중 phase16 fixture 존재 → "stale ADR" 출현 → Step 1 **실패**.
- Step 2 도중 phase16 fixture 존재 → count=2 → `grep "stale ADR: 1"` **실패**.

- **증거 (2026-06-09)**: `docs/decisions/ADR-999-phase16-integration-fixture.md` 를 만들고 `sdd status` 를 실행하니 **그 fixture 가 stale ADR 로 잡혔다** — 즉 *다른 테스트의 fixture 가 본 테스트의 drift 스캔에 보인다*.
- **원래 플래키 보고 정정**: Icebox 의 "b6c2rakls PASS / bze38u4y7 FAIL" 는 CI 가 아니라 **이 하네스의 백그라운드 task ID** 형식이다. 즉 원래 관찰도 *여러 테스트를 동시 백그라운드 실행* 중 발생한 cross-test 간섭이며, **serial 실행에선 결정적(플래키 아님)**.
- (정정) 초기 가설 "fs-visibility race / fixture write→read 가시성"은 **오진**이었다. 당시 재현은 같은 fixture 파일을 쓰는 repro 스크립트 2개를 동시 실행한 *자가 collision* 아티팩트였고, 격리 micro-repro 는 solo·동시부하 모두 0 miss 였다. 제품 `_drift_stale_adr` 에는 fs race 결함이 없다.

### 해결 방안 (요약)

테스트 단언을 **전역 카운트/부재 → 자기 fixture 특정**으로 바꾼다. 각 step 은 `sdd status` 출력의 stale 목록에서 *자기 fixture 의 ADR 파일명* 존재/부재만 확인한다. 그러면 동시 실행으로 foreign fixture 가 끼어도 단언이 깨지지 않는다. 제품 코드(`sdd`)는 변경하지 않는다 — 간섭은 *테스트 단언 설계* 문제이지 진단 함수 결함이 아니다.

## 🎯 요구사항

### Functional Requirements

1. Step 2(missing path): 출력에 **자기 fixture(`ADR-999-stale-fixture.md`)가 stale 로 포함**됨을 단언 (전역 count "1" 매칭 제거).
2. Step 1/3/4/5/6(비탐지 단언): 출력에 **자기 fixture 가 stale 로 포함되지 않음**을 단언 ("stale ADR 전무" 매칭 제거).
3. 동시 실행으로 foreign ADR fixture (예: phase16)가 존재해도 모든 step 단언이 안정적으로 통과한다.
4. 제품 코드 `sources/bin/sdd` / `.harness-kit/bin/sdd` 는 변경하지 않는다.

### Non-Functional Requirements

1. bash 3.2+ 호환. 기존 step 로직(픽스처 내용, 순서)은 단언부만 변경, 구조 보존.
2. serial 단독 실행에서도 동일하게 통과 (회귀 없음).
3. surgical — 각 step 의 grep 단언 1줄씩 교체 수준.

## 🚫 Out of Scope

- **제품 `_drift_stale_adr` 변경** (예: 전역 대신 scoped 디렉토리). 간섭은 테스트 단언 설계 문제 — 진단 함수는 의도대로 전역 스캔.
- **`sdd status` Windows 성능 저하** (solo ~1m24s). 별개 → Icebox. macOS 1차라 best-effort.
- **stale 목록 표시 truncation(>3개 시 "…")**: 동시 stale fixture 가 4개 이상이면 자기 fixture 가 목록에서 잘려 Step 2(포함 단언)가 false-fail 가능. 현실적으로 동시 stale fixture 는 ≤3(drift+phase16 류)이라 무시. 필요 시 별도.

## 🔍 검증 전략 (deterministic — race 아님)

cross-test 간섭은 **결정적**으로 재현된다(타이밍 무관). foreign fixture 를 만들어 놓고 `sdd status` 1회 호출로 검증:
1. `docs/decisions/ADR-999-phase16-integration-fixture.md`(foreign stale) 생성.
2. drift 테스트의 자기 fixture(`ADR-999-stale-fixture.md`) 생성 후 `sdd status` 1회.
3. 출력에 대해: 구(舊) 단언 `grep "stale ADR: 1"` → **실패**(count=2), 신(新) 단언 `grep "ADR-999-stale-fixture"` → **통과**. → fix 가 간섭에 견고함을 1회 호출로 증명.
4. full `tests/test-drift-stale-adr.sh` 1회 solo → 6/6 통과(회귀 sanity).

> full status 가 느려(~1.4분/호출) 고N 반복은 불가하나, 본 fix 는 race 가 아니라 *결정적 간섭* 대응이라 **1~2회 호출로 충분히 검증**된다.

## ✅ Definition of Done

- [ ] foreign fixture 주입 시: 구 단언 실패 / 신 단언 통과 (1회 호출 deterministic 증명)
- [ ] `tests/test-drift-stale-adr.sh` 1회 solo 전체 PASS (회귀 sanity)
- [ ] (해당 시) `tests/test-phase16-integration.sh` 대칭 견고화 여부 평가/반영
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-drift-test-fixture-race` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
