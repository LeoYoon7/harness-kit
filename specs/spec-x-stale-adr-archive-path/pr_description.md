# fix(spec-x-stale-adr-archive-path): stale ADR 검사가 archive 이동 참조를 오탐하지 않도록 수정

## 📋 Summary

### 배경 및 목적

`sdd status` drift 진단의 `_drift_stale_adr()` 는 live ADR(`docs/decisions/ADR-*.md`) 본문의 backtick 경로 토큰 존재 여부를 검사한다. 검사가 **repo 루트만**(`[ -e "$SDD_ROOT/$token" ]`) 보므로, ADR 이 참조하는 spec 이 `sdd archive` 로 `archive/specs/...` 로 이동하면 root 경로가 사라져 **stale ADR 로 오탐**한다. 참조 대상은 *삭제된 게 아니라 이동*했을 뿐이므로 ADR 은 여전히 유효하다.

- 실증: 2026-06-01 ADR-003/004/005 가 참조하던 spec 들이 archive 되며 오탐 → ADR 경로를 수동 갱신해야 했음. archive 는 루틴 작업인데 매번 ADR 편집을 강요하는 비대칭 비용.
- #50(spec-x-sdd-robustness-fixes)은 같은 함수의 fd-race 만 고쳤고 archive 경로 미탐색은 잔존.

### 주요 변경 사항

- [x] `_drift_stale_adr()` 존재 검사에 archive fallback 1줄 추가 — root 부재 시 `$SDD_ROOT/archive/$token` 도 확인, 있으면 존재로 간주 (이동 ≠ 삭제)
- [x] `sources/bin/sdd` + `.harness-kit/bin/sdd` 동일 반영 (dogfood sync, ADR-003)
- [x] 회귀 테스트 Step 5(archived spec) / Step 6(archived backlog) 추가 — prefix 일반성 검증
- [x] 동반 정리: #50 이 이미 해결한 queue line(ship-scope truncation) strike-through

### Phase 컨텍스트

- **Phase**: 없음 (spec-x, SDD-x)
- **본 SPEC 의 역할**: sdd drift 진단 신뢰성 강화 — archive 루틴이 false-positive stale 를 낳지 않게 함.

## 🎯 Key Review Points

1. **archive fallback 의 회귀 안전성**: root·archive 모두 부재(진짜 삭제/오타)는 **여전히** stale 로 탐지됨. archive 존재 시에만 면제 — Step 2(real missing → stale 1) 가 그대로 PASS 로 보장.
2. **prefix 전제**: `archive/$token` 매칭은 `sdd archive` 가 `specs/`·`backlog/` 1단계 prefix 를 `archive/` 하위 동명 디렉토리로 보존함에 의존. 비기본 `specsDir`/`backlogDir`(config override)는 OOS — spec.md "적용 전제" 에 명시.
3. **관례 정합**: `specs/CLAUDE.md` 의 "archive 건너뛰기" 와 충돌 아님 — 본 fix 는 archived 파일을 *스캔*하지 않고 *단일 target 의 존재만 확인*. 루프는 여전히 live ADR 만 순회.

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-drift-stale-adr.sh
bash tests/test-sdd-ship-scope.sh
```

**결과 요약**:
- ✅ `test-drift-stale-adr.sh`: 6/6 (clean / real-missing→stale / valid / `../` exclude / **archived spec** / **archived backlog**)
- ✅ `test-sdd-ship-scope.sh`: 5/5 (회귀 sanity — 동일 파일 수정)

### 수동 검증 시나리오
1. **fix 전 (Red)**: Step 5 추가 후 실행 → `stale ADR: 1 (missing-path) — ADR-996` 으로 FAIL (오탐 재현)
2. **fix 후 (Green)**: 재실행 → 6 step 전부 PASS
3. **dogfood sync**: `sdd status` → sources↔installed mismatch 경고 없음

## 📦 Files Changed

### 🛠 Modified Files
- `sources/bin/sdd` (+3): `_drift_stale_adr()` archive fallback 1줄 + 주석
- `.harness-kit/bin/sdd` (+3): 동일 (dogfood sync)
- `tests/test-drift-stale-adr.sh` (+64): Step 5/6 + 픽스처 변수/cleanup
- `backlog/queue.md` (+1/-1): #50-resolved 항목 strike-through

### 🆕 New Files
- `specs/spec-x-stale-adr-archive-path/`: spec / plan / task / critique / walkthrough / pr_description

**Total**: 코드/테스트 3 + 문서

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과 (6/6 + 5/5)
- [x] `walkthrough.md` ship commit 완료
- [x] `pr_description.md` ship commit 완료
- [x] 코드 리뷰 게이트 수행 (Gemini cross-model)
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Spec: `specs/spec-x-stale-adr-archive-path/spec.md`
- Walkthrough: `specs/spec-x-stale-adr-archive-path/walkthrough.md`
- Critique: `specs/spec-x-stale-adr-archive-path/critique.md`
- 관련: #50 (spec-x-sdd-robustness-fixes) — 같은 함수 fd-race fix
