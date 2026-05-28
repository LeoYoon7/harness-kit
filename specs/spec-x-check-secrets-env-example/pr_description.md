# fix(spec-x-check-secrets-env-example): exclude .env.*.example/.sample from staged check

## 📋 Summary

### 배경 및 목적

`sources/hooks/check-secrets.sh` 의 staged 파일명 검사가 정규식 `(^|/)\.env(\..+)?$` 만 사용해 `.env.telegram.example`·`.env.discord.sample` 같은 *템플릿* 파일까지 `.env` 로 매칭 → block 모드 hook 가 commit 차단.

`install.sh` 가 target 프로젝트 루트에 생성하는 `.env.*.example` 파일을 사용자가 git 추적하려 하면 (보통의 의도) 막히는 false positive — ADR-003 의 "외부와 동일 install 경험" 원칙 위반.

### 주요 변경 사항

- [x] `sources/hooks/check-secrets.sh` 의 staged 파일 검사 파이프 끝에 `grep -vE '\.(example|sample)$'` 추가 (단일 줄, 다중 라인 백슬래시 continuation).
- [x] `tests/test-check-secrets-dual-mode.sh` 에 Test 12 (`.env.telegram.example` 통과), Test 13 (`.env.discord.sample` 통과) 추가.
- [x] 기존 11 PASS 유지 — Test 9 (`.env` 차단), Test 2/4/8 (AWS 키), Test 11 (Private Key) 회귀 가드 모두 PASS.

### Phase 컨텍스트

- **Phase**: 없음 (spec-x — 단발 fix)
- **본 SPEC 의 역할**: `spec-x-dogfood-sync` (PR #2) 작업 중 확정된 false positive 의 본격 fix. 우회용 `.gitignore` 항목은 target 프로젝트엔 적용 안 되므로 hook 자체를 패치.

## 🎯 Key Review Points

1. **regex 정확도**: 새 필터가 `.env.*.example` / `.env.*.sample` *만* 제외하고 `.env` / `.env.telegram` / `.env.production` 등 *실제* env 파일은 계속 차단하는지 확인. → Test 9 가 회귀 가드. PASS 확인됨.
2. **POSIX 호환**: `grep -vE` 는 bash 3.2 (macOS 기본) / BSD grep / GNU grep 모두 동일 동작. 추가 의존성 없음.
3. **다른 hook 검사 미영향**: AWS 키 / Private Key / 시크릿 할당 패턴 / GitHub 토큰 4가지 검사는 손대지 않음. Test 2/4/8/11 PASS 로 확인.

## 🧪 Verification

### 자동 테스트

```bash
bash tests/test-check-secrets-dual-mode.sh
```

**결과 요약**: `PASS: 13  FAIL: 0`

- ✅ Test 1: `check-secrets.sh` 존재
- ✅ Test 2/4/8: AWS 키 staged → 차단 (회귀 가드)
- ✅ Test 3/5/6/10: 정상 파일 / git status / 환경변수 없음 → 통과
- ✅ Test 7: `pre-commit.sh` 의 `HARNESS_GIT_HOOK_MODE=1` 호출 존재
- ✅ Test 9: `.env` staged → 차단 (**핵심 회귀 가드**)
- ✅ Test 11: Private Key staged → 차단 (회귀 가드)
- ✅ Test 12: `.env.telegram.example` staged → 통과 (**신규**)
- ✅ Test 13: `.env.discord.sample` staged → 통과 (**신규**)

### 수동 검증 시나리오

1. **시나리오 1**: 임시 repo 에 `.env.telegram.example` 만 staged → `bash sources/hooks/check-secrets.sh` (HARNESS_GIT_HOOK_MODE=1) → exit 0 (통과). *(Test 12 자동화)*
2. **시나리오 2**: 같은 repo 에 `.env` 만 staged → exit ≠ 0 (차단). *(Test 9 자동화)*

## 📦 Files Changed

### 🛠 Modified Files

- `sources/hooks/check-secrets.sh` (+3, -1): line 36 파이프에 `.example`/`.sample` 제외 필터 추가 (다중 라인 가독성).
- `tests/test-check-secrets-dual-mode.sh` (+42): Test 12 / Test 13 추가.

### 🆕 New Files

- `specs/spec-x-check-secrets-env-example/spec.md` / `plan.md` / `task.md` / `walkthrough.md` / `pr_description.md`: SDD 산출물 (한국어).

### (자동 갱신)

- `backlog/queue.md` (+1): `<!-- sdd:specx -->` 마커 영역에 `spec-x-check-secrets-env-example` 등록 (sdd 자동 관리).

**Total**: 7 files changed

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과 (13/13)
- [-] 통합 테스트 — Integration Test Required = no
- [x] `walkthrough.md` ship 완료
- [x] `pr_description.md` ship 완료
- [x] lint / type check — `shellcheck` 미설치 환경 (Windows Git Bash) 으로 skip. `check-staged-lint.sh` 경고만, 차단 아님.
- [x] 사용자 검토 요청 알림 — PR 생성 후 Telegram

## 🔗 관련 자료

- 선행 PR: `#2` (spec-x-dogfood-sync) — false positive 확정 + `.gitignore` 우회.
- 관련 ADR: `docs/decisions/ADR-003-dogfood-sync-policy.md` (외부와 동일 install 경험 원칙).
- Walkthrough: `specs/spec-x-check-secrets-env-example/walkthrough.md`
