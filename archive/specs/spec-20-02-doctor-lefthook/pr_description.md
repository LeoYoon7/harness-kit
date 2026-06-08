# fix(spec-20-02): doctor 의 lefthook × core.hooksPath 충돌 탐지 (upstream parity)

## 📋 Summary

### 배경 및 목적
**lefthook v2.x 는 `core.hooksPath` 가 설정되면 `lefthook install`(prepare)을 거부**한다 → `pnpm install`/`turbo` 연쇄 실패. harness-kit 이 hook 을 `core.hooksPath` 로 설치하는 프로젝트에서 lefthook 을 함께 쓰면 조용히 깨진다. upstream(#162, issue #161)이 doctor 에 이 충돌 탐지를 추가했고, fork 에 포팅한다.

### 주요 변경 사항
- [x] `sdd doctor`(sources + installed)에 `_check_lefthook_hookspath()` + `_check_hooks` 직후 호출
- [x] root `doctor.sh` 에 동일 검사 (섹션 6)
- [x] 단위 테스트 (`tests/test-doctor-hookspath-lefthook.sh`, 4 case)

### Phase 컨텍스트
- **Phase**: `phase-20` (upstream-parity) — **2번째 spec, quick win**
- **역할**: §11.3 재검증으로 #162(additive·저충돌) 선정. #158(footgun)은 fork 중복 triage 로 분리.

## 🎯 Key Review Points

1. **진단만**: 충돌 시 경고·해결안내(`git config --unset --local core.hooksPath`)만. git 설정 자동 변경 없음.
2. **additive**: `_check_hooks` 직후 새 검사 블록만 추가 → 기존 doctor 동작·출력 무변경 (실제 repo `sdd doctor` 여전히 ALL PASS, lefthook 미사용 시 skip).
3. **sources↔installed sdd 동일** (`diff -q` SYNCED).

## 🧪 Verification

```bash
bash tests/test-doctor-hookspath-lefthook.sh   # ✅ PASS 4 / FAIL 0 (TDD Red→Green)
```
- ✅ Case 1·2: sdd doctor + doctor.sh 가 충돌(#161) 경고
- ✅ Case 3·4: hooksPath 미설정 / lefthook 미사용 시 경고 없음
- ✅ 회귀: 실제 repo `sdd doctor` ALL PASS (lefthook skip)

## 📦 Files Changed

### 🆕 New Files
- `tests/test-doctor-hookspath-lefthook.sh`: 4-case 검사 테스트 (upstream 포팅)

### 🛠 Modified Files
- `sources/bin/sdd`, `.harness-kit/bin/sdd` (+each): `_check_lefthook_hookspath()` + 호출
- `doctor.sh`: root doctor 동일 검사

## ✅ Definition of Done

- [x] 단위 테스트 PASS (4/4)
- [x] sdd doctor + doctor.sh 양쪽 + sources↔installed sync
- [x] 기존 doctor 회귀 없음 (additive)
- [x] walkthrough.md / pr_description.md ship
- [x] 코드 리뷰 게이트 (`small-port` skip, walkthrough 기록)

## 🔗 관련 자료

- Phase: `backlog/phase-20.md`
- upstream 출처: `9db74c8` (#162 / issue #161)
- Walkthrough: `specs/spec-20-02-doctor-lefthook/walkthrough.md`
