# Walkthrough: spec-x-check-secrets-docs-context

> `check-secrets` hook 의 시크릿 할당 패턴 검사에서 `.md` 본문을 제외해 docs 작업 self-trigger false positive 해소.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| docs false positive 해소 방식 | (A) `.md` 파일 제외 / (B) 코드 fence 인식 / (C) placeholder heuristic / (D) A + 다른 확장자 확대 | **A** | 본 spec 의 직접 트리거가 `.md` 본문에서 두 차례 재현 — A 로 100% 해결. B 는 .md 안의 fence 밖 본문에 여전히 false positive. C 는 heuristic 신뢰도 한계. D 는 관찰 안 된 가설을 다루는 YAGNI 위반. |
| Filter 구현 위치 | (A) grep regex 자체 변경 / (B) staged diff 호출 시 pathspec exclude | **B** | git pathspec `:(exclude)*.md` 가 표준이고 데이터 소스 범위 축소가 의도 표현이 명확. 다른 패턴 검사 (AWS / Private Key / GitHub 토큰) 와 *조건부로* 분리할 수 있어 강한 형식은 `.md` 도 계속 검사. |
| 강한 형식 검사 적용 범위 | (A) `.md` 도 그대로 검사 / (B) `.md` 도 제외 | **A** | AWS 키 / Private Key / GitHub 토큰은 placeholder 와 충돌하지 않는 강한 형식. `.md` 안의 실제 시크릿 누출 가드는 유지. Test 16 이 자동 검증. |
| Task 순서 | (A) Red → Green → Ship / (B) Green 먼저 (hook 패치) → Red → Ship | **A** | 표준 TDD 순서 유지. Task 2 Red commit 시점에 spec/plan/task 본문 self-trigger 가능성을 사전 grep 으로 확인했고 모두 clean. 변수 분리 (test 코드의 `_PWD_KW` / `_ASSIGN`) 패턴으로 self-trigger 완전 회피. |
| Ship 직전 dogfood-sync drift 발견 — `.harness-kit/check-secrets.sh` 가 PR #3 + 본 spec sources/ 패치 미반영 | (A) `update.sh` 실행 + main chore + spec branch 적용 / (B) walkthrough/pr_description reword / (C) `HARNESS_HOOK_MODE_SECRETS=warn` 단발 우회 | **A** | ADR-003 의 update.sh SSOT 정책 준수. PR #3 의 sync 누락도 부수 해소. 본 spec 의 fix 가 dogfood 환경에서 즉시 동작. B 는 본 spec 의 docs 자유 회복 의도와 모순, C 는 hook 우회 흔적이 commit 환경에 남음. |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — pathspec 한 줄 추가. ADR 가치 없음.

## 💬 사용자 협의

- **주제**: follow-up 후보 선택 (PR #3 머지 후 walkthrough 의 두 발견)
  - **사용자 의견**: 1번 — `check-secrets` hook 의 docs 컨텍스트 false positive 보강
  - **합의**: SDD-x 로 진행. 분기 선택은 spec.md 의 분석 표를 보고 결정.
- **주제**: 분기 (A/B/C/D) 선택 및 Plan Accept
  - **사용자 의견**: Plan Accept (1번) — A 권장안 그대로
  - **합의**: 옵션 A (`.md` exclude pathspec) 채택. 즉시 Strict Loop 진입.
- **주제**: Ship 직전 hook 차단 (dogfood-sync drift) 해소 방법
  - **사용자 의견**: 1번 — `update.sh` 실행 + main chore commit 분리
  - **합의**: main 에서 `bash update.sh --yes` 로 PR #3 sync 적용 + chore commit 푸시 (`3ee4b1e`), spec branch rebase 후 동일 `update.sh` 로 본 spec 의 `.md` exclude 도 적용 + chore commit (`a86f086`). 본 spec 의 fix 가 dogfood 환경에서 즉시 효력 발휘 — walkthrough/pr_description 본문에 시크릿 패턴 리터럴 자유 사용.

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: `bash tests/test-check-secrets-dual-mode.sh`
- **결과**: ✅ Passed (PASS: 16 / FAIL: 0)
- **로그 요약**:

```text
▶ Test 9:  .env staged → 차단됨 (exit=2)                       ← 회귀 가드 OK
▶ Test 11: Private Key staged → 차단됨 (exit=2)                ← 회귀 가드 OK
▶ Test 12/13: .env.*.example / .sample → 통과 (exit=0)         ← 회귀 가드 OK (PR #3)
▶ Test 14: .md 본문 시크릿 할당 패턴 리터럴 → 통과 (exit=0)    ← 신규 (Red→Green)
▶ Test 15: .py 본문 동일 패턴 → 차단됨 (exit=2)                ← 신규 regression 가드
▶ Test 16: .md 본문 AWS 키 → 차단됨 (exit=2)                  ← 신규 강한 형식 가드
───────────────────────────────────────────────────────
 PASS: 16  FAIL: 0
───────────────────────────────────────────────────────
```

#### 통합 테스트
Integration Test Required = no — 생략.

### 2. 수동 검증

1. **Action**: 패치 *이전* `bash tests/test-check-secrets-dual-mode.sh` 실행
   - **Result**: `PASS: 15  FAIL: 1` — Test 14 만 차단됨 (Red 확인). Test 15·16 regression 가드 PASS.
2. **Action**: `sources/hooks/check-secrets.sh` 의 line 45 다음에 `staged_diff_no_md` 변수 추가 (pathspec `:(exclude)*.md`), 시크릿 할당 패턴 검사 한 곳만 `$staged_diff` → `$staged_diff_no_md` 로 교체
   - **Result**: 2줄 추가 + 1줄 교체. AWS 키 / Private Key / GitHub 토큰 검사는 그대로 `$staged_diff` 사용.
3. **Action**: 패치 *이후* 전체 테스트 재실행
   - **Result**: `PASS: 16  FAIL: 0`. 회귀 가드 9건 모두 PASS.
4. **Action**: 본 walkthrough.md / pr_description.md 작성 시도 — 본문에 `password=...`, `api_key=...` 같은 설명용 리터럴 사용
   - **Result**: 초기에 hook 차단 발생 → dogfood-sync drift 확인. `.harness-kit/check-secrets.sh` 가 sources/ 와 비동기.
5. **Action**: main 에서 `bash update.sh --yes` → `.harness-kit/hooks/check-secrets.sh` sync (PR #3 `.env.*.example` filter 반영) → main chore commit `3ee4b1e` push.
   - **Result**: PR #3 dogfood-sync drift 해소.
6. **Action**: spec branch rebase onto main → `bash update.sh --yes` 다시 실행 → 본 spec 의 `.md` exclude 도 `.harness-kit/` 에 반영 → chore commit `a86f086`.
   - **Result**: walkthrough/pr_description.md 본문에 시크릿 패턴 리터럴 자유 commit 가능 (현재 문서가 그 증거).

## 🔍 발견 사항

- **self-trigger 완전 회피 보장**: Task 2 Red commit 시점 (hook 패치 이전) 에는 spec/plan/task 본문에 패턴 리터럴 사용 *최소화* + 변수 분리. Task 3 + 본 spec 의 dogfood-sync chore (`a86f086`) 이후 `.md` 제외가 적용되어 Ship 단계의 walkthrough/pr_description 본문은 패턴 리터럴 자유 사용 — 본 spec 자체가 자기 fix 를 dogfooding 하는 구조.
- **dogfood-sync drift 누락 패턴 재발**: PR #3 머지 후에도 `update.sh` 호출이 누락되어 `.harness-kit/` 가 sources/ 와 비동기. ADR-003 정책은 있지만 *자동화된 실행 트리거* 가 없어 사람/에이전트가 잊으면 drift. → **별도 spec 후보**: PR 머지 후 `sdd specx done`/`sdd ship` 시 sources/* 변경이 있으면 `update.sh` 안내 / 자동 호출 옵션. 본 spec 범위 외 (별건 fix).
- **약한 형식 시크릿의 .md 위협**: `password=actual_secret` 처럼 약한 형식이 .md 본문에 들어가는 case 는 본 spec 으로 의도적으로 통과시킴 (Out of Scope). 실제 위협 시나리오 (악의적 사용자) 는 본 hook 의 1차 방어선이 아니라 코드 리뷰/secret scanning service 의 영역.
- **D 옵션의 잠재 follow-up**: `.example`/`.sample`/`.yml.example` 등 다른 placeholder 확장자의 시크릿 할당 패턴 false positive 는 *관찰되지 않은* 가설. 실제 발생 시 별도 spec 으로 D 옵션 (pathspec 다중 exclude) 적용 가능.

## 🚧 이월 항목

- (Optional) `.md` 외 다른 placeholder 확장자 false positive 관찰 시 D 옵션 (pathspec 다중 exclude) spec-x 후보. 현재는 가설 단계, Icebox 미등록.
- **(검증된 follow-up)** PR 머지 후 sources/* 변경 시 `update.sh` 자동/반자동 호출 — dogfood-sync drift 누락 패턴 재발 방지. 별도 spec-x 후보.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Opus 4.7) + Leo |
| **작성 기간** | 2026-05-28 |
| **최종 commit** | `efc7b09` (fix), `8a74595` (test), `a86f086` (chore: dogfood sync) — rebase 후 hash. main 의 `3ee4b1e` (chore: PR #3 sync) 도 본 작업 직전 분리 푸시. |
