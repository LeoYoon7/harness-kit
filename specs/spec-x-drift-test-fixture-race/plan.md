# Implementation Plan: spec-x-drift-test-fixture-race (재설계)

## 📋 Branch Strategy

- 브랜치: `spec-x-drift-test-fixture-race` (이미 생성됨)
- 이전 plan(fs-visibility) 무효 → 본 plan 으로 대체. planAccepted 재요청.

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] **근본원인 정정**: fs-visibility race(오진) → **cross-test fixture 간섭**(동시 실행 시 foreign ADR fixture 가 전역 glob 에 보임). serial 은 결정적.
> - [ ] **테스트 전용 fix** — 단언을 자기 fixture 특정으로. 제품 `sdd` 무변경.

> [!WARNING]
> - [ ] truncation 한계(동시 stale fixture ≥4면 목록 잘림)는 OOS — 현실적으로 ≤3.
> - [ ] `sdd status` Windows 성능(solo ~1m24s)은 OOS → Icebox.

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **단언 기준** | 전역 count/부재 → **자기 fixture 파일명 존재/부재** | foreign fixture 간섭에 견고. stale 출력은 ADR rel-path 를 나열하므로 basename grep 가능 |
| **검증** | deterministic — foreign fixture 주입 후 `sdd status` 1회 | 간섭은 race 아님(결정적). 구 단언 실패/신 단언 통과를 1회로 증명 |
| **제품 코드** | 불변 | 간섭은 테스트 단언 설계 문제. `_drift_stale_adr` 전역 스캔은 의도된 동작 |
| **phase16 대칭** | 동일 패턴이면 phase16 단언도 견고화 | 양방향 간섭 완전 해소 |

### 📑 ADR 후보

- [ ] 있음
- [x] 없음 — 테스트 격리 패턴(공유 글로벌 자원 단언은 자기 자원 특정으로). 일반 상식, 장기 결정 아님.

## 📂 Proposed Changes

### [MODIFY] `tests/test-drift-stale-adr.sh` — 단언 fixture-특정화

각 step 의 stale 단언을 *자기 fixture basename* 기준으로 교체. (픽스처 생성/내용/순서는 불변.)

| Step | 구 단언 | 신 단언 |
|---|---|---|
| 1 (clean) | `grep -q "stale ADR"` → 있으면 fail | `grep -q "ADR-999-stale-fixture"` → 있으면 fail (자기 fixture 부재 확인) |
| 2 (missing) | `grep -q "stale ADR: 1 (missing-path)"` → 없으면 fail | `grep -q "ADR-999-stale-fixture"` → 없으면 fail (자기 fixture stale 확인) |
| 3 (valid) | `grep -q "stale ADR"` → 있으면 fail | `grep -q "ADR-998-valid-paths-fixture"` → 있으면 fail |
| 4 (../) | `grep -q "stale ADR"` → 있으면 fail | `grep -q "ADR-997-relative-path-fixture"` → 있으면 fail |
| 5 (archived spec) | `grep -q "stale ADR"` → 있으면 fail | `grep -q "ADR-996-archived-path-fixture"` → 있으면 fail |
| 6 (archived backlog) | `grep -q "stale ADR"` → 있으면 fail | `grep -q "ADR-995-archived-backlog-fixture"` → 있으면 fail |

> 비고: 신 Step 1 은 "자기 fixture 부재"만 보므로 real ADR 건강 검사 역할은 사라진다 — 이는 의도된 좁힘(real-ADR 건강은 본 테스트 범위 밖, foreign 간섭에 취약).

### [MODIFY] `tests/test-phase16-integration.sh` — (해당 시) 대칭 견고화

assertion 이 동일하게 전역 count/부재 의존이면 자기 fixture(`ADR-999-phase16-integration-fixture`) 특정으로 교체. 단일 패턴이면 함께, 아니면 OOS 처리하고 보고.

### [MODIFY] `backlog/queue.md` — queue 하우스키핑

- 본 플래키 항목 strike → ✓ 정정된 원인(cross-test 간섭) + 본 spec.
- 신규 Icebox: `sdd status` Windows 성능 저하 (solo ~1m24s).

## 🧪 검증 계획 (Verification Plan)

### deterministic 간섭 검증 (1회 호출)
```bash
# foreign(phase16) + 자기 fixture 동시 존재 → 출력 캡처
# 구 단언 grep "stale ADR: 1" → FAIL(count=2) / 신 단언 grep "ADR-999-stale-fixture" → PASS
```

### 회귀 sanity
```bash
bash tests/test-drift-stale-adr.sh         # 6/6 (solo, ~8분, 1회)
bash tests/test-phase16-integration.sh     # (수정 시) 통과
```

### 수동 시나리오
1. foreign fixture 주입 + `sdd status` 1회 → 신 단언 통과 / 구 단언 실패 확인 (간섭 견고 증명)
2. full drift 테스트 solo 1회 → All tests passed

## 🔁 Rollback Plan

- 테스트 단언 문자열 교체뿐 — 해당 커밋 revert 로 즉시 원복. 제품/상태 영향 없음.

## 📦 Deliverables 체크

- [ ] task.md 작성
- [ ] 사용자 Plan Accept (재요청)
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
