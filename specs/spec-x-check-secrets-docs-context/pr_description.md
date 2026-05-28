# fix(spec-x-check-secrets-docs-context): exclude .md from secret-assignment pattern check

## 📋 Summary

### 배경 및 목적

`sources/hooks/check-secrets.sh` 의 시크릿 할당 패턴 검사가 `.md` 본문의 *설명용* 리터럴까지 무차별 잡아 docs 작업 commit 자체가 차단되는 self-trigger false positive 발생. `spec-x-dogfood-sync` (PR #2) 및 `spec-x-check-secrets-env-example` (PR #3) 두 차례 작업 중 재현된 ergonomic 사고.

본 PR 은 시크릿 할당 패턴 검사 단계에 한해 git pathspec `:(exclude)*.md` 로 `.md` 파일을 제외한다. AWS 키 / Private Key / GitHub 토큰 검사는 `.md` 포함 *모든* 파일에 계속 적용 — 강한 형식이라 placeholder 와 충돌하지 않고 실제 시크릿 누출 가드는 유지.

### 주요 변경 사항

- [x] `sources/hooks/check-secrets.sh` line 45 다음에 `staged_diff_no_md` 변수 추가 (pathspec `:(exclude)*.md`).
- [x] 시크릿 할당 패턴 검사 (현 line 61) 한 곳만 `$staged_diff` → `$staged_diff_no_md` 교체.
- [x] AWS 키 / Private Key / GitHub 토큰 검사는 그대로 `$staged_diff` 사용.
- [x] `tests/test-check-secrets-dual-mode.sh` 에 Test 14 (`.md` 통과), Test 15 (`.py` 차단 regression), Test 16 (`.md` 안 AWS 키 차단 강한 형식 가드) 3건 추가.

### Phase 컨텍스트

- **Phase**: 없음 (spec-x — 단발 fix)
- **본 SPEC 의 역할**: PR #3 의 walkthrough 에 *별도 spec 후보* 로 기록된 docs 컨텍스트 보강. PR #3 의 Out of Scope 에 명시되어 있던 follow-up.

## 🎯 Key Review Points

1. **분기 선택 (옵션 A)** — spec.md 의 §🎯 요구사항 §분기 분석 표에 A/B/C/D 비교 + 권장 근거 명시. A 채택 이유: 직접 트리거 100% 해결 + 단일 줄 변경 + YAGNI.
2. **regression 가드 핵심**: 비-md 파일 (`.py`, `.ts`, `.sh`, `.env`, …) 의 시크릿 할당 패턴은 *계속 차단*. Test 15 가 자동 검증.
3. **강한 형식 검사 유지**: AWS 키 / Private Key / GitHub 토큰은 `.md` 포함 모든 파일에 계속 적용. `.md` 안의 실제 시크릿 누출 가드는 깨지지 않음. Test 16 이 자동 검증.
4. **bash 3.2+ 호환**: git pathspec `:(exclude)*.md` 는 git 1.9+ 표준. shell 측 의존성 추가 없음.

## 🧪 Verification

### 자동 테스트

```bash
bash tests/test-check-secrets-dual-mode.sh
```

**결과 요약**: `PASS: 16  FAIL: 0`

- ✅ Test 1: hook 존재
- ✅ Test 2/4/8: AWS 키 staged → 차단 (강한 형식 회귀 가드)
- ✅ Test 3/5/6/10: 정상 파일 / git status / 환경변수 없음 → 통과
- ✅ Test 7: pre-commit.sh 의 `HARNESS_GIT_HOOK_MODE=1` 호출 존재
- ✅ Test 9: `.env` staged → 차단 (회귀 가드)
- ✅ Test 11: Private Key staged → 차단 (강한 형식 회귀 가드)
- ✅ Test 12/13: `.env.*.example` / `.sample` 통과 (PR #3 회귀 가드)
- ✅ Test 14: `.md` 본문 시크릿 할당 패턴 리터럴 → 통과 (**신규**)
- ✅ Test 15: `.py` 본문 동일 패턴 → 차단 (**신규 regression 가드**)
- ✅ Test 16: `.md` 본문 AWS 키 → 차단 (**신규 강한 형식 가드**)

### 수동 검증 시나리오

1. **시나리오 1**: 임시 repo 에 `notes.md` 만 staged (`password=<your-password>` 같은 설명용 리터럴 포함) → `bash sources/hooks/check-secrets.sh` (HARNESS_GIT_HOOK_MODE=1) → exit 0 (통과). *(Test 14 자동화)*
2. **시나리오 2**: 같은 repo 에 `config.py` (동일 패턴) → exit ≠ 0 (차단). *(Test 15 자동화)*
3. **시나리오 3**: `security-note.md` 에 AWS 키 형식 staged → exit ≠ 0 (차단). *(Test 16 자동화)*

## 📦 Files Changed

### 🛠 Modified Files

- `sources/hooks/check-secrets.sh` (+4, -1): `staged_diff_no_md` 변수 추가 + 시크릿 할당 패턴 검사 한 곳 교체.
- `tests/test-check-secrets-dual-mode.sh` (+60): Test 14·15·16 추가.

### 🆕 New Files

- `specs/spec-x-check-secrets-docs-context/spec.md` / `plan.md` / `task.md` / `walkthrough.md` / `pr_description.md`: SDD 산출물 (한국어).

### (자동 갱신)

- `backlog/queue.md` (+1): sdd specx new 의 마커 영역 등록.

**Total**: 7 files changed

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과 (16/16)
- [-] 통합 테스트 — Integration Test Required = no
- [x] `walkthrough.md` ship 완료
- [x] `pr_description.md` ship 완료
- [x] lint / type check — `shellcheck` 미설치 환경 (Windows Git Bash) 으로 skip. `check-staged-lint.sh` 경고만, 차단 아님.
- [x] 사용자 검토 요청 알림 — PR 생성 후 Telegram

## 🔗 관련 자료

- 선행 PR: `#3` (spec-x-check-secrets-env-example) — `.env.*.example`/`.sample` 파일명 false positive 해소.
- 선행 PR: `#2` (spec-x-dogfood-sync) — 최초 self-trigger 관찰.
- Walkthrough: `specs/spec-x-check-secrets-docs-context/walkthrough.md`
