fix(spec-x-gitignore-archive-coverage): cover archive review outputs in ignore symmetry sites

## 📋 Summary

### 배경 및 목적
리뷰 도구 출력물(`code-review*.md`)의 ignore 규칙이 `specs/**` 로 한정돼 `archive/specs/` 를 커버하지 못했다. `sdd archive` 가 spec 을 `archive/specs/` 로 옮기면 그동안 ignore 되던 산출물이 untracked 로 드러나 워킹트리가 더러워진다 (phase-21 archive 에서 10개 실증). install 대상 프로젝트도 동일 갭에 노출. 본 fix 는 `archive/specs/**/code-review*.md` 패턴을 ADR-005 ignore line symmetry 사이트 전체에 추가한다.

### 주요 변경 사항
- [x] `.gitignore` — `archive/specs/**/code-review*.md` 추가
- [x] `install.sh` — `_gi_ensure` archive 라인 (install 대상 커버)
- [x] `uninstall.sh` — awk 제거 패턴 archive 라인 (install/uninstall 대칭)
- [x] `sources/bin/sdd` + `.harness-kit/bin/sdd` (미러) — doctor 점검에 archive 패턴
- [x] 가드 테스트 — install(A-5)/self-host(H-4)/uninstall(J-2b)/update 멱등(I-1b)/doctor(a-3)

### Phase 컨텍스트
- **Phase**: 없음 (spec-x)
- **역할**: phase-21 archive 가 노출한 kit 버그 fix. ADR-005 불변식의 archive 확장.

## 🎯 Key Review Points

1. **surgical vs broad 패턴**: `archive/specs/**/code-review*.md` (surgical mirror) 채택 — broad `**/code-review*.md` 의 정의파일(`code-review.md`) 오매칭 회피.
2. **install ↔ uninstall 대칭**: `_gi_ensure` 추가 라인은 uninstall awk 제거 패턴에도 등재 필수 (ADR-005, test J-2b).
3. **sdd 미러 parity**: `sources/bin/sdd` ↔ `.harness-kit/bin/sdd` diff 동일.
4. **upgrade 경로**: `update.sh` = uninstall+install 사이클로 기존 install 도 자동 커버.

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-gitignore-config.sh        # 26/26 (A-5/H-4/J-2b/I-1b 포함)
bash tests/test-doctor-ignore-coverage.sh  # 10/10 (a-3 archive WARN)
```
**결과 요약**: ✅ 전체 PASS (TDD red→green). sdd 미러 diff 동일.

### 수동 검증
1. `git check-ignore archive/specs/foo/code-review.md` → 매칭(ignore), fix 전엔 미매칭.
2. 코드 리뷰(Opus): **Approve**, Critical 0 / Major 0 / Minor 3 (모두 비-결함, #1 보강·#2 skip·#3 본 ship).

## 📦 Files Changed

### 🛠 Modified Files
- `.gitignore` (+1): archive 리뷰 출력 패턴
- `install.sh` (+2): `_gi_ensure` archive 라인
- `uninstall.sh` (+1): awk 제거 archive 라인
- `sources/bin/sdd` (+5): doctor archive 점검
- `.harness-kit/bin/sdd` (+5): 미러
- `tests/test-gitignore-config.sh` (+~20): A-5/H-4/J-2b/I-1b
- `tests/test-doctor-ignore-coverage.sh` (+~10): a-3

**Total**: 7 files (+ spec 산출물)

## ✅ Definition of Done

- [x] 가드 테스트 PASS (archive 패턴 커버 + symmetry)
- [x] 기존 gitignore/doctor 테스트 무회귀 + 미러 parity 무회귀
- [x] 코드 리뷰 Approve (Opus)
- [x] `walkthrough.md` / `pr_description.md` ship commit
- [x] 브랜치 push + 사용자 알림

## 🔗 관련 자료

- Spec: `specs/spec-x-gitignore-archive-coverage/spec.md`
- 관련 ADR: ADR-005 (kit-managed ignore line symmetry invariant — 본 fix 가 적용)
