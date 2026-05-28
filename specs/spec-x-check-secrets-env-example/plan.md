# Implementation Plan: spec-x-check-secrets-env-example

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-check-secrets-env-example` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main` (현재 HEAD: `75b6829`)
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [x] regex 변경 범위: `.env.*.example` / `.env.*.sample` *만* 제외. `.env` / `.env.telegram` / `.env.production` 등 실제 env 파일은 계속 차단.
> - [x] 영향 범위: target 프로젝트 (`install.sh` 가 생성한 `.env.*.example` 의 git 추적 가능 여부). false positive 해소 = 정상 UX 회복.

> [!WARNING]
> - [x] **false negative 회귀 리스크**: 만약 regex 변경이 잘못되어 `.env.production` 같은 실제 파일까지 통과시키면 시크릿 유출 가능. → 본 spec 의 핵심 가드는 *기존 Test 9 (`.env` staged 차단)* 가 계속 PASS 인지 검증.
> - [x] **bash 3.2 호환**: `grep -vE` 는 POSIX 표준, macOS bash 3.2 에서 안전.

## 🎯 핵심 전략 (Core Strategy)

### 아키텍처 컨텍스트

`sources/hooks/check-secrets.sh` 는 두 경로로 호출됩니다 (이전 spec-x-check-secrets-dual-mode 의 산출물):

```
Claude Code (PreToolUse: Bash, git commit)  ─┐
                                              ├─→ check-secrets.sh
git pre-commit.sh (HARNESS_GIT_HOOK_MODE=1) ─┘   ├─ .env 파일명 검사 (line 36)  ← 본 spec 의 패치 대상
                                                  ├─ AWS 키 / Private Key 패턴
                                                  ├─ 시크릿 할당 패턴
                                                  └─ GitHub/GitLab 토큰
```

본 변경은 `.env` 파일명 검사 한 줄에만 영향. 다른 4개 패턴 검사는 손대지 않음.

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **Filter 위치** | 기존 grep 파이프 끝에 `grep -vE` 추가 | regex 자체를 더 복잡하게 만드는 것보다 *양성 매칭 → 음성 필터* 가 가독성·테스트 용이성 우월 |
| **제외 패턴** | `\.(example\|sample)$` | spec.md Out of Scope 에 명시. `.env.*.example`/`.env.*.sample` 두 관용 표기만 다룸 |
| **테스트 위치** | 기존 `test-check-secrets-dual-mode.sh` 에 Test 12·13 append | dual-mode 의 .env 파일명 검사 (Test 9) 와 같은 토픽 → 분리할 가치 없음 |
| **테스트 reuse** | `_run_secrets` + `HARNESS_GIT_HOOK_MODE=1` 패턴 재사용 | Test 9 와 동일한 setup |

### 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음 → 후보 한 줄 요약: `<slug-후보>` (type: decision / invariant / convention / tradeoff)
- [x] 없음 — 단순 regex 보강. ADR-003 의 dogfood-sync 운영 원칙은 그대로 유지.

## 📂 Proposed Changes

### Hook 패치

#### [MODIFY] `sources/hooks/check-secrets.sh`

line 36 의 staged 파일 검사 파이프라인 끝에 `.example`/`.sample` 제외 필터 추가.

```bash
# Before (line 36)
env_files="$(git -C "$HARNESS_ROOT" diff --cached --name-only 2>/dev/null | grep -E '(^|/)\.env(\..+)?$')"

# After
env_files="$(git -C "$HARNESS_ROOT" diff --cached --name-only 2>/dev/null \
  | grep -E '(^|/)\.env(\..+)?$' \
  | grep -vE '\.(example|sample)$')"
```

### 테스트 보강

#### [MODIFY] `tests/test-check-secrets-dual-mode.sh`

Test 11 다음, "결과" 섹션 직전에 Test 12·13 추가. 셋업 패턴은 Test 9 와 동일.

```bash
# Test 12: .env.telegram.example staged → 통과 (false positive 해소)
# Test 13: .env.discord.sample staged → 통과 (false positive 해소)
```

회귀 가드: 기존 Test 9 (`.env` staged → 차단) 는 변경 없이 계속 PASS 해야 함.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)

```bash
bash tests/test-check-secrets-dual-mode.sh
```

**기대 결과**: `PASS: 13  FAIL: 0`

**회귀 가드 (반드시 확인)**:
- Test 9 (`.env` 차단) → 계속 PASS
- Test 2, 4, 8 (AWS 키 차단) → 계속 PASS
- Test 11 (Private Key 차단) → 계속 PASS

### 통합 테스트

Integration Test Required = no — 생략.

### 수동 검증 시나리오

1. 임시 repo 에 `.env.telegram.example` 만 staged → `bash sources/hooks/check-secrets.sh` (HARNESS_GIT_HOOK_MODE=1) → exit 0 (통과)
2. 같은 repo 에 `.env` 만 staged → 차단 (exit ≠ 0)
3. (참고) target 프로젝트 시뮬레이션은 본 spec 범위 외 — 단위 테스트로 충분.

## 🔁 Rollback Plan

- **변경량**: 단일 줄 (regex 파이프 1줄) + 테스트 ~30줄.
- **롤백 방법**: `git revert <commit>` 또는 해당 라인 원복. 상태 영향 없음 (순수 함수형 검사 로직).
- **사후 false negative 발견 시**: 즉시 revert + 새 spec 으로 정밀 패턴 재설계.

## 📦 Deliverables 체크

- [x] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
