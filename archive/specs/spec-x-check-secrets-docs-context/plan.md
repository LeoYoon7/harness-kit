# Implementation Plan: spec-x-check-secrets-docs-context

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-check-secrets-docs-context` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main` (현재 HEAD: `3050222`)
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [x] 분기 선택 확정: 옵션 **A** (`.md` exclude pathspec). 다른 옵션은 spec.md §🎯 분기 분석 표 참조.
> - [x] 약한 형식 시크릿이 `.md` 본문에 들어가는 case 는 *의도적으로 허용* (Out of Scope). 강한 형식 (AWS / Private Key / GitHub 토큰) 검사는 `.md` 포함 모든 파일에 계속 적용.

> [!WARNING]
> - [x] **regression 가드 핵심**: `.py`/`.ts`/`.sh`/`.env` 등 *비-md* 파일에 동일 패턴이 staged 되면 *계속 차단* 되어야 함. Test 15 가 이를 자동 검증.
> - [x] `.md` 안의 AWS 키 패턴 등 강한 형식은 별개 검사라 영향 없음. Test 16 이 이를 자동 검증.

## 🎯 핵심 전략 (Core Strategy)

### 아키텍처 컨텍스트

```text
sources/hooks/check-secrets.sh
  └─ line 42: staged_diff = git diff --cached                      (이전: 모든 파일)
  └─ line 42 ↓ NEW:
        staged_diff_no_md = git diff --cached -- ':(exclude)*.md'   (시크릿 할당 패턴 검사용)
  └─ line 46-66 의 4개 패턴 검사:
        AWS 키          → staged_diff       (그대로, 모든 파일)
        Private Key     → staged_diff       (그대로, 모든 파일)
        시크릿 할당 패턴 → staged_diff_no_md  ← .md 제외
        GitHub 토큰     → staged_diff       (그대로, 모든 파일)
```

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **Filter 위치** | 시크릿 할당 패턴 검사 *전용* staged_diff 변수 분리 | grep regex 자체 변경보다 *소스 데이터 범위 축소* 가 의도 표현이 명확. AWS 키 / Private Key / GitHub 토큰 검사는 영향 없음 (`.md` 안의 강한 형식도 계속 잡힘). |
| **Pathspec 표기** | `:(exclude)*.md` | git 1.9+ 표준. bash 따옴표 / shellcheck 모두 무해. |
| **테스트 분리** | 신규 Test 14·15·16 을 Test 13 다음에 append | 기존 dual-mode 테스트 구조 유지. 분리 파일 신규는 비용 대비 효과 낮음. |
| **Task 순서 (self-trigger 회피)** | Red(테스트 추가) → Green(hook 패치) → Ship(walkthrough/pr_description) | Ship 단계 *전* 에 hook 의 `.md` 제외가 commit 되어 있어야 walkthrough/pr_description.md 본문에 시크릿 패턴 리터럴을 자유롭게 적을 수 있음. |

### 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — 단발 fix.

## 📂 Proposed Changes

### Hook 패치

#### [MODIFY] `sources/hooks/check-secrets.sh`

시크릿 할당 패턴 검사에만 `.md` 를 제외한 별도 staged diff 변수를 만들어 사용.

```bash
# Before (line 42)
staged_diff="$(git -C "$HARNESS_ROOT" diff --cached 2>/dev/null)"

# After
staged_diff="$(git -C "$HARNESS_ROOT" diff --cached 2>/dev/null)"
# 시크릿 할당 패턴 검사 전용 — .md 본문의 설명용 리터럴 false positive 회피
# (AWS 키 / Private Key / GitHub 토큰은 강한 형식이라 모든 파일에 계속 적용)
staged_diff_no_md="$(git -C "$HARNESS_ROOT" diff --cached -- ':(exclude)*.md' 2>/dev/null)"
```

그리고 line 57-60 의 시크릿 할당 패턴 검사 한 곳만 `$staged_diff` → `$staged_diff_no_md` 로 변경.

### 테스트 보강

#### [MODIFY] `tests/test-check-secrets-dual-mode.sh`

Test 13 다음, "결과" 섹션 직전에 Test 14·15·16 추가.

```text
Test 14: .md 본문에 시크릿 할당 패턴 리터럴 staged → 통과 (false positive 해소)
Test 15: .py 본문에 동일 패턴 staged → 차단 (regression 가드)
Test 16: .md 본문에 AWS 키 패턴 staged → 차단 (다른 패턴 영향 없음)
```

테스트 셋업은 Test 9 / Test 12 와 동일 (`_run_secrets` + `HARNESS_GIT_HOOK_MODE=1`).
self-trigger 회피용 변수 분리 패턴은 Test 2 의 `_AKIA_PFX` 와 동일하게 사용.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)

```bash
bash tests/test-check-secrets-dual-mode.sh
```

**기대 결과**: `PASS: 16  FAIL: 0`

**회귀 가드 (반드시 확인)**:
- Test 9 (`.env` 차단) → 계속 PASS
- Test 11 (Private Key 차단) → 계속 PASS
- Test 12·13 (`.env.*.example` / `.sample` 통과) → 계속 PASS
- Test 15 (`.py` 차단) → 신규 가드, 비-md 파일의 시크릿 할당 패턴 검출 유지
- Test 16 (`.md` 안 AWS 키 차단) → 신규 가드, 강한 형식 시크릿 검출 유지

### 통합 테스트

Integration Test Required = no — 생략.

### 수동 검증 시나리오

1. 임시 repo 에 `notes.md` 만 staged (시크릿 할당 패턴 리터럴 포함) → `bash sources/hooks/check-secrets.sh` (HARNESS_GIT_HOOK_MODE=1) → exit 0 (통과)
2. 같은 repo 에 `config.py` (동일 패턴) → exit ≠ 0 (차단)
3. `notes.md` 에 AWS 키 형식 staged → exit ≠ 0 (차단)

## 🔁 Rollback Plan

- **변경량**: hook 의 staged_diff_no_md 변수 추가 (1-2줄) + 시크릿 할당 패턴 검사 한 곳 변수 교체 (1줄) + 테스트 ~45줄.
- **롤백 방법**: `git revert <commit>` — 순수 함수형 검사 로직이라 상태 영향 없음.
- **사후 false negative 발견 시**: 즉시 revert + 새 spec 으로 정밀 보강.

## 📦 Deliverables 체크

- [x] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
