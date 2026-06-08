# Walkthrough: spec-x-gitignore-archive-coverage

> 작업 기록 — 결정·협의·검증. Fix (spec-x).

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 패턴 형태 | broad `**/code-review*.md` / surgical `archive/specs/**/...` | **surgical mirror** | broad 는 `code-review.md` 류 정의파일 오매칭 위험. 기존 `specs/**` 의 정의파일 보호 의도 보존 |
| 적용 범위 | 3사이트 / 4사이트 | **4사이트 (+미러)** | 실행 중 발견: ADR-005 symmetry 에 `uninstall.sh` awk 제거 패턴도 포함 (test J-2 가 이미 specs 라인에 대해 검증). 사용자 승인(2026-06-08) |
| tracked 잔존 3파일 | 제거 / 유지 | **유지** | archive immutability + gitignore 는 tracked 를 untrack 안 함 → 무해. 본 fix 영향 없음 |
| 커밋 구조 | 분할 / 원자 | **symmetry 1 commit** | 사이트 간 동기가 불변식 — 중간 상태가 회귀라 원자 변경 |
| review Minor #1 | 보강 / 보류 | **보강(I-1b)** | update 멱등 archive 라인 카운트 가드 추가 — specs 의 I-1 과 대칭 |

### ADR 승격 가이드
- [ ] ADR 승격 대상 있음
- [x] 없음 (ADR-005 기존 symmetry 불변식의 *적용* — 신규 결정 아님)

## 💬 사용자 협의

- **주제**: 작업 모드
  - **합의**: spec-x (fix) — testable + 4사이트 symmetry 라 PR/테스트 가치
- **주제**: 범위 (uninstall.sh 포함 여부)
  - **사용자 의견**: 실행 중 발견한 4번째 사이트 surface
  - **합의**: uninstall.sh 포함 (1번, 4사이트 symmetry)
- **주제**: 코드 리뷰 게이트
  - **합의**: Opus(/hk-code-review) 실행 — kit-critical bash

## 🧪 검증 결과

### 1. 자동화 테스트 (TDD red→green)
- **명령**: `bash tests/test-gitignore-config.sh`, `bash tests/test-doctor-ignore-coverage.sh`
- **결과**: ✅ Passed — gitignore **26/26**(I-1b 포함), doctor **10/10**
- **로그 요약**:
```text
A-5 install archive 라인 추가 ✅ / H-4 self-host ✅ / J-2b uninstall 제거 ✅ / I-1b update 멱등 ✅
a-3 doctor archive WARN ✅
(red 단계: A-5/H-4/a-3 fail → fix 후 green)
```

### 2. 수동 검증
1. **Action**: `git check-ignore archive/specs/foo/code-review.md`
   - **Result**: 매칭(ignore) 반환 — fix 전엔 미매칭
2. **Action**: `diff sources/bin/sdd .harness-kit/bin/sdd`
   - **Result**: 동일 (미러 parity OK)
3. **Action**: upgrade 경로 분석 — `update.sh` = uninstall + install
   - **Result**: archive 라인이 uninstall(awk 제거) + install(_gi_ensure 재추가) 사이클로 자동 커버 → 별도 update.sh 변경 불요

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Opus) |
| **결과 파일** | `specs/spec-x-gitignore-archive-coverage/code-review.md` (gitignore 로 미커밋) |
| **요약** | **Approve** / Critical 0 / Major 0 / Minor 3 |
| **Minor 처리** | #1(update 멱등 archive 가드) → 보강(I-1b). #2(ADR-005 context 목록) → skip(선택·이미 불완전 스냅샷). #3(walkthrough/pr) → 본 ship 에서 작성 |

## 🔍 발견 사항

- ADR-005 "ignore line symmetry" 는 4사이트(.gitignore/install/uninstall/doctor) — uninstall awk 제거 패턴이 누락되기 쉬운 4번째 사이트. (이번 plan 초안도 3사이트로 시작)
- `update.sh` 의 uninstall+install 구조 덕에 ignore 라인 변경이 upgrade 경로에 자동 전파 — 별도 처리 불요.
- 이 spec 의 산출물(`code-review.md`)이 본 fix 가 ignore 하는 대상 — 자기참조적 검증.

## 🚧 이월 항목

- ADR-005 context 라인 목록 갱신(Minor #2) — 선택. 필요 시 별도 chore.
- (관련) `archive/` 의 tracked 잔존 3 `code-review-gemini.md` 는 immutability 로 유지 — 정책 재검토 시 Icebox `.gitignore archive 갭` 항목 참조.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-08 |
| **최종 commit** | (ship commit 후) |
