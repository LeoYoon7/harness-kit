# Walkthrough: spec-x-check-secrets-env-example

> `.env.*.example` / `.env.*.sample` 템플릿 파일의 `check-secrets` hook false positive 해소.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| Filter 위치 | (A) 기존 regex 자체를 negative lookahead 등으로 보강 / (B) 파이프 끝에 `grep -vE` 추가 | **B** | 양성 매칭 → 음성 필터 분리가 가독성·테스트 용이성 우월. POSIX `grep -vE` 만 사용 (bash 3.2 호환). |
| 제외 패턴 범위 | (A) `.example` 만 / (B) `.example` + `.sample` | **B** | `.sample` 도 관용 표기로 사용됨. spec.md 요구사항에 명시. |
| 테스트 위치 | (A) 별도 테스트 파일 신규 / (B) `test-check-secrets-dual-mode.sh` 에 append | **B** | .env 파일명 검사 (Test 9) 와 같은 토픽. 분리할 가치 없음. |
| **Task 2 Red commit 시 hook 자체 차단** | (A) spec.md Out of Scope 설명 한 줄 reword / (B) `HARNESS_HOOK_MODE_SECRETS=warn` 단발 우회 / (C) docs 컨텍스트 인식 본 spec 에 포함 | **A** | spec.md Out of Scope 가 이미 *"docs-context fix는 별도 spec"* 으로 명시. 본 PR 범위 보존 + hook 통과의 최소 변경. B 는 우회 흔적이 commit 환경에 남고 C 는 scope creep. |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — 단순 regex 보강. ADR-003 의 dogfood-sync 운영 원칙은 그대로 유지.

## 💬 사용자 협의

- **주제**: 미완 spec-x 처리 방향 (세션 시작 시 작성된 spec.md 만 있고 plan/task 비어 있음)
  - **사용자 의견**: 이어서 진행 (1번)
  - **합의**: plan/task 재작성 후 Plan Accept → Strict Loop 진행
- **주제**: Plan Accept vs Critique
  - **사용자 의견**: Plan Accept (1번)
  - **합의**: 즉시 실행 진입. spec 이 명확하고 변경 범위 작음 (1줄 + 테스트 2건).
- **주제**: Task 2 Red commit hook 차단 시 해소 방법
  - **사용자 의견**: 1번 (spec.md 한 줄 reword)
  - **합의**: 해당 리터럴(`secret` 키워드 + `=` + 값 형태)을 `password / secret / api_key 등 키워드 뒤에 = 와 값이 오는 형태` 풀어쓰기로 변경.

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: `bash tests/test-check-secrets-dual-mode.sh`
- **결과**: ✅ Passed (PASS: 13 / FAIL: 0)
- **로그 요약**:

```text
▶ Test 9:  git hook 모드에서 .env staged → 차단됨 (exit=2)        ← 회귀 가드 OK
▶ Test 11: Private Key staged → 차단됨 (exit=2)                  ← 회귀 가드 OK
▶ Test 12: .env.telegram.example staged → 통과 (exit=0)          ← 신규 (Red→Green)
▶ Test 13: .env.discord.sample staged → 통과 (exit=0)            ← 신규 (Red→Green)
───────────────────────────────────────────────────────
 PASS: 13  FAIL: 0
───────────────────────────────────────────────────────
```

#### 통합 테스트
Integration Test Required = no — 생략.

### 2. 수동 검증

1. **Action**: 패치 *이전* `bash tests/test-check-secrets-dual-mode.sh` 실행
   - **Result**: `PASS: 11  FAIL: 2` — Test 12·13 만 차단 (Red 확인).
2. **Action**: `sources/hooks/check-secrets.sh` line 36 파이프 끝에 `grep -vE '\.(example|sample)$'` 추가
   - **Result**: 단일 줄 (다중 라인 백슬래시 continuation) 변경.
3. **Action**: 패치 *이후* 전체 테스트 재실행
   - **Result**: `PASS: 13  FAIL: 0` — Test 9 (`.env` 차단) / Test 11 (Private Key) 등 회귀 가드 PASS.

## 🔍 발견 사항

- **Self-trigger 패턴 재발**: spec.md 의 Out of Scope 섹션이 *언급한* 패턴 (백틱 안에 `secret` 키워드 + `=` + 값을 그대로 적은 리터럴) 이 본 spec 의 commit 자체를 차단했다. `spec-x-dogfood-sync` ship 시 동일 현상이 있었음. → **별도 spec 후보**: `check-secrets` hook 의 *docs 컨텍스트 (.md 본문, 코드 fence 내부) 인식 보강*. 본 spec 범위 외 (Out of Scope).
- **bash 3.2 호환 확인**: `grep -vE` 는 POSIX, BSD grep / GNU grep 모두 동일 동작. 추가 검증 불필요.
- **`.sample` 사용처**: 현재 키트 자체에는 `.env.*.sample` 미사용이지만 외부 관용 표기로 미리 지원. install.sh 가 향후 `.sample` 로 변경해도 회귀 없음.

## 🚧 이월 항목

- `check-secrets` hook 의 docs 컨텍스트 (.md / 코드 fence) 인식 보강 → `backlog/queue.md` Icebox 후보 (사용자 결정 후 등록).

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Opus 4.7) + Leo |
| **작성 기간** | 2026-05-28 |
| **최종 commit** | `a6d816f` (fix), `37df8cc` (test) |
