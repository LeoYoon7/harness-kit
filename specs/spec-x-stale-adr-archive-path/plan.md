# Implementation Plan: spec-x-stale-adr-archive-path

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-stale-adr-archive-path` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] **fix 방향 (a) 채택**: stale 검사가 `archive/` fallback 을 추가한다. queue 제안 (b)(ADR 영구 식별자 권장)는 OOS — Icebox follow-up.
> - [ ] **line 56 queue 정리 동반**: #50 이 이미 고친 ship-scope 항목(line 56)의 strike-through 를 본 PR 의 queue 하우스키핑 커밋으로 함께 처리 (사용자 승인됨, §10.1 main 제약 회피).

> [!WARNING]
> - [ ] archive 를 "존재" 로 간주하므로, archived spec 을 가리키는 ADR 은 더 이상 stale 로 잡히지 않는다 — 이는 *의도된* 동작(이동 ≠ 삭제). 진짜 삭제(root·archive 모두 부재)는 그대로 탐지됨.

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **존재 검사** | root 검사 실패 시 `$SDD_ROOT/archive/$token` fallback 추가 | `sdd archive` 가 `specs/`·`backlog/` 1단계 prefix 를 `archive/` 하위 동명 디렉토리로 보존 이동(기본 경로 전제)하므로 `archive/`+token 으로 해소 |
| **수정 범위** | line 401 다음에 1줄 추가 (기존 필터 미수정) | surgical — 슬래시/URL/확장자/`../` 제외 로직은 정상 동작 중 |
| **dogfood sync** | `sources/bin/sdd` + `.harness-kit/bin/sdd` 동일 반영 | ADR-003 dogfood sync 정책 (#50 와 동일 패턴) |
| **테스트** | `tests/test-drift-stale-adr.sh` 에 Step 5 (archived path) 추가 | 기존 4 step 패턴 일관 — fixture ADR + archive 픽스처 생성 후 검증, trap 정리 |

### 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — 작은 robustness 버그 fix. 관례 충돌 해소는 spec.md 에 인라인 기록으로 충분.

## 📂 Proposed Changes

### drift 검사 (sdd)

#### [MODIFY] `sources/bin/sdd` — `_drift_stale_adr()`

line 401 (`[ -e "$SDD_ROOT/$token" ] && continue`) 직후에 archive fallback 한 줄 추가.

```bash
      # 5) 존재하면 skip
      [ -e "$SDD_ROOT/$token" ] && continue
      # 5b) archive 로 이동된 참조도 존재로 간주 (spec-x-stale-adr-archive-path)
      #     sdd archive 는 specs/·backlog/ 1단계 prefix 를 archive/ 하위 동명 디렉토리로 보존 이동 (기본 경로 전제)
      [ -e "$SDD_ROOT/archive/$token" ] && continue
      has_missing=1
```

#### [MODIFY] `.harness-kit/bin/sdd` — 동일 변경 (dogfood sync)

설치본에 동일한 1줄을 반영. 변경 후 `sdd status` drift 의 dogfood sync 경고가 없음을 확인.

### 테스트

#### [MODIFY] `tests/test-drift-stale-adr.sh` — Step 5 + Step 6 추가

**Step 5 — archived spec 참조**: archived spec 을 가리키는 ADR 픽스처가 stale 로 잡히지 **않음** 검증.
- `archive/specs/spec-x-archived-fixture/spec.md` 픽스처 생성
- `docs/decisions/ADR-996-archived-path-fixture.md` 가 `specs/spec-x-archived-fixture/spec.md` 참조
- `sdd status` → "stale ADR" 미출력 기대
- trap 으로 양쪽 픽스처 정리

**Step 6 — archived backlog 참조 (critique 반영, prefix 일반성 검증)**: `specs/` 외 `backlog/` prefix 도 fallback 이 동작함을 검증.
- `archive/backlog/phase-fixture.md` 픽스처 생성
- `docs/decisions/ADR-995-archived-backlog-fixture.md` 가 `backlog/phase-fixture.md` 참조
- `sdd status` → "stale ADR" 미출력 기대
- trap 으로 픽스처 정리

### queue 하우스키핑

#### [MODIFY] `backlog/queue.md` — line 56 strike-through

#50 이 이미 해결한 "sdd ship spec-x slug truncation 버그" 항목을 `~~...~~` 로 표시하고 `→ ✓ #50 (f495749)` 포인터 추가.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)

```bash
bash tests/test-drift-stale-adr.sh
```

기대: 기존 4 step + 신규 archive step 모두 PASS.

### 회귀 확인

```bash
bash tests/test-sdd-ship-scope.sh
```

(직접 관련은 없으나 같은 파일 수정이므로 sanity — 5/5 PASS 유지)

### 수동 검증 시나리오

1. fix 전 Step 5 추가 후 `bash tests/test-drift-stale-adr.sh` → Step 5 에서 FAIL (Red 확인).
2. fix 적용 후 재실행 → 전 step PASS (Green).
3. `bash .harness-kit/bin/sdd status` → drift 섹션 "깔끔" 또는 dogfood sync 경고 없음.

## 🔁 Rollback Plan

- 단일 1줄 추가 + 테스트/문서이므로 해당 커밋 revert 로 즉시 원복.
- 상태/데이터 영향 없음 (진단 전용 함수).

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
