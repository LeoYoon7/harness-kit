# Walkthrough: spec-x-stale-adr-archive-path

> stale ADR 검사가 archive 로 이동된 spec/backlog 참조를 false-positive 로 오탐하던 문제를 archive fallback 1줄로 근본 해결한 작업 기록.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 존재 검사 archive 대응 | (a) `archive/$token` prefix fallback / (b) ADR 영구 식별자(PR#/SHA) 권장 / (B) `find archive/ -path` | (a) | 1줄·가역·bash3.2·기존 필터 무수정. (B)는 성능·동명 오탐 역위험·surgical성 상실. (b)는 convention 변경 대공사 → Icebox 보완재 |
| queue line 56 정리 위치 | main FF 직접 / B 브랜치 동반 | B 브랜치 동반 docs 커밋 | §10.1 main 금지 + PLANNING 모드. 두 항목 모두 sdd 견고성 테마라 묶임 자연 |
| critique 반영 범위 | none / 1·2·3 / all(+4) | 1·2·3 (4 생략) | 1·2·3 은 fix 전제 정직화 + 테스트 사각지대 해소(실질 가치). 4는 가치 낮음 |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — 기존 immutable 불변식(`specs/CLAUDE.md` "archive 는 immutable 보존소" + `cmd_archive` prefix-보존)의 적용일 뿐, 새 장기 결정 아님. critique·gemini 모두 동의.

## 💬 사용자 협의

- **주제**: 최초 선택지 A(sdd ship slug truncation)가 이미 #50 에서 해결됨 발견
  - **사용자 의견**: 1번 (line 56 정리 + B 로 전환)
  - **합의**: line 56 strike 는 B 브랜치 동반, 새 작업은 B(stale ADR archive 근본책) spec-x

- **주제**: Plan Accept 게이트 — Critique 선택
  - **사용자 의견**: 2번 (Critique) → 이후 `권장` (1·2·3 반영) → `1` (Plan Accept)
  - **합의**: Opus critique 3건 반영 후 실행 진입

- **주제**: Ship 코드 리뷰 게이트
  - **사용자 의견**: 1번 (Gemini cross-model)
  - **합의**: Gemini 리뷰 Approve(0/0/0) 확인 후 ship

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: `bash tests/test-drift-stale-adr.sh`
- **결과**: ✅ Passed (6/6)
- **로그 요약**:
```text
  ✓ clean state: no stale ADR line
  ✓ fixture ADR (1 missing path) → stale ADR: 1 detected   ← 회귀: 진짜 missing 은 여전히 탐지
  ✓ regression: ADR-998 (all-valid-paths fixture) → no stale line
  ✓ ADR with only ../ relative-path token → no stale line
  ✓ archived spec ref (archive/specs/...) → resolved, no stale line     ← 신규(fix)
  ✓ archived backlog ref (archive/backlog/...) → resolved, no stale line ← 신규(prefix 일반성)
All tests passed.
```

- **명령**: `bash tests/test-sdd-ship-scope.sh`
- **결과**: ✅ Passed (5/5) — 동일 파일 수정 sanity

### 2. 수동 검증

1. **Action**: Step 5/6 추가 후 fix 미적용 상태로 `bash tests/test-drift-stale-adr.sh`
   - **Result**: `stale ADR: 1 (missing-path) — ADR-996` 으로 Step 5 FAIL (오탐 재현 = TDD Red)
2. **Action**: `sources/bin/sdd` + `.harness-kit/bin/sdd` archive fallback 추가 후 재실행
   - **Result**: 6 step 전부 PASS (Green)
3. **Action**: `bash .harness-kit/bin/sdd status`
   - **Result**: sources↔installed mismatch 경고 없음 (동일 편집)

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Gemini cross-model) |
| **결과 파일** | `specs/spec-x-stale-adr-archive-path/code-review-gemini.md` |
| **요약** | 전체 평가 **Approve** / Critical 0 / Major 0 / Minor 0 |
| **Skip 사유** | — (실행함) |

리뷰 핵심: spec-구현 정합(요구사항 1·2·3), scope creep 없음(queue 정리는 plan 승인됨), KISS/DRY + bash3.2 호환, blackbox 테스트로 사용자 경험 검증. 관찰 1건(`specsDir` override 시 한계)은 spec OOS 에 이미 명시 — gemini 도 "No Over-engineering 상 1줄이 적절"로 동의.

## 🔍 발견 사항

- **specsDir/backlogDir config override 한계**: 비기본 경로 설정 시 `archive/$token` prefix 매칭이 깨질 수 있음. 도그푸딩(기본 경로)엔 무해. 외부 확산 시 `$SDD_SPECS` 동적 경로 계산이 필요할 수 있음 (gemini/critique 공통 관찰). → spec OOS 명시 + 아래 이월.

## 🚧 이월 항목

- **queue 제안 (b) — ADR 가 spec 참조 시 영구 식별자(PR#/commit SHA) 권장** (convention): 본 fix(a)의 보완재. → Icebox 유지 (queue.md).
- **비기본 `specsDir`/`backlogDir` 대응 — `$SDD_SPECS` 기반 동적 archive 경로**: 외부 확산 시점에 재평가. → Icebox 신규 추가 후보.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-09 |
| **최종 commit** | (ship commit 시 갱신) |
