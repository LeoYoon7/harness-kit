# spec-x-check-secrets-env-example: check-secrets.sh 의 `.env.*.example`/`.sample` false positive 제거

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-check-secrets-env-example` |
| **Phase** | (없음 — spec-x) |
| **Branch** | `spec-x-check-secrets-env-example` |
| **상태** | Planning |
| **타입** | Fix |
| **Integration Test Required** | no |
| **작성일** | 2026-05-28 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

`sources/hooks/check-secrets.sh` 의 staged 파일 검사 (line 36).

```bash
env_files="$(git -C "$HARNESS_ROOT" diff --cached --name-only 2>/dev/null | grep -E '(^|/)\.env(\..+)?$')"
```

정규식 `(^|/)\.env(\..+)?$` 가 `.env.telegram.example`·`.env.discord.sample` 같은 *템플릿* 파일까지 매칭 → "`.env` 파일 staged" violation 으로 차단.

### 문제점

`spec-x-dogfood-sync` (PR #2) 작업 중 확정된 false positive (`critique.md` 의 누락 #1 예측 → 실측 확인). 우회로 self-host 한정 `.gitignore` 추가로 회피했으나.

1. **Target 프로젝트 영향**: `install.sh` 가 모든 target 프로젝트 루트에 `.env.*.example` 을 생성. 사용자가 이를 git 추적하려 하면 (보통 의도) commit 차단됨. ADR-003 의 "외부와 동일 install 경험" 원칙 위반.
2. **자가 인지 어려움**: hook 이 *block* 모드(기본값) 라 사용자가 우회 방법을 모르면 막힘. 에러 메시지에서 "`.example` 은 템플릿이라 안전" 안내가 없음.

### 해결 방안 (요약)

staged 파일 검사 파이프라인에 `grep -vE '\.(example|sample)$'` 추가 — `.env.*.example`·`.env.*.sample` 만 제외, 실제 `.env`·`.env.telegram` 등은 계속 차단. 단일 줄 변경 + 신규 테스트 2건.

## 🎯 요구사항

### Functional Requirements

1. `.env`, `.env.telegram`, `.env.production` 등 *실제* env 파일 staged → 계속 차단 (regression 없음).
2. `.env.telegram.example`, `.env.discord.sample`, `.env.foo.example` 등 템플릿 → 통과 (false positive 해소).
3. 다른 검사 (AWS 키, Private Key, 시크릿 할당 패턴, GitHub 토큰) 는 영향 없음.

### Non-Functional Requirements

1. bash 3.2+ 호환 (CLAUDE.md). `grep -vE` 는 표준 POSIX, 안전.
2. 기존 `tests/test-check-secrets-dual-mode.sh` 의 11개 테스트 모두 PASS 유지.

## 🚫 Out of Scope

- **시크릿 할당 패턴의 문서화 리터럴 false positive** — `password` / `secret` / `api_key` 등 키워드 뒤에 `=` 와 값이 오는 형태가 *설명용* 으로 .md 본문에 들어갔을 때 hook 가 잡는 case (`spec-x-dogfood-sync` ship 시 발견). 별도 fix (regex 가 docs 컨텍스트 인식하기 어려움 → reword 가이드 또는 코드 fence 인식 등 별도 검토). 본 PR 범위 외.
- **`.env.*.example` 의 *내용* 에 실제 시크릿이 들어가는 case** — 운영상 발생 가능하나, 본 패턴(파일명 차단) 으로는 원래도 검출 안 됨. 시크릿 할당 패턴 검사가 별도 동작.

## 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — 단순 regex 보강. ADR-003 의 운영 원칙은 그대로.

## ✅ Definition of Done

- [ ] `sources/hooks/check-secrets.sh` line 36 패치 적용
- [ ] `tests/test-check-secrets-dual-mode.sh` 에 Test 12 (`.env.*.example` 통과) + Test 13 (`.env.*.sample` 통과) 추가
- [ ] 전체 11+2 = 13 PASS / 0 FAIL
- [ ] `walkthrough.md` / `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-check-secrets-env-example` 브랜치 push + fork main PR
