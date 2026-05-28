# spec-x-check-secrets-docs-context: check-secrets.sh 의 .md 본문 시크릿 할당 패턴 false positive 제거

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-check-secrets-docs-context` |
| **Phase** | (없음 — spec-x) |
| **Branch** | `spec-x-check-secrets-docs-context` |
| **상태** | Planning |
| **타입** | Fix |
| **Integration Test Required** | no |
| **작성일** | 2026-05-28 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

`sources/hooks/check-secrets.sh` 의 시크릿 할당 패턴 검사 (현 line 57-60):

```bash
# 일반 시크릿 (추가된 줄만, 값이 있는 경우)
if echo "$staged_diff" | grep -E '^\+' | grep -qiE '(password|secret|api_key|api_secret|access_token|private_key)[[:space:]]*[=:][[:space:]]*[^[:space:]]+'; then
  violations="${violations}  시크릿 할당 패턴 발견 (...)\n"
fi
```

이 검사는 *staged diff 전체* (파일 종류 무관) 의 `+` 추가 라인에서 `password|secret|api_key|...` 키워드 뒤에 `=`/`:` + 값이 오는 형태를 모두 잡는다.

### 문제점

`spec-x-dogfood-sync` (PR #2) 및 `spec-x-check-secrets-env-example` (PR #3) 두 차례 작업 중 **자기 차단 (self-trigger)** 이 재현되었다.

- 양쪽 spec 모두 `.md` 본문 (spec.md / walkthrough.md / pr_description.md) 에 *설명용 리터럴* 로 해당 패턴을 적었더니, 본 spec 작업의 commit 자체가 차단됨.
- spec-x-check-secrets-env-example 의 Out of Scope 에 이미 "docs 컨텍스트 인식 보강은 별도 spec" 으로 명시되어 있던 이슈.
- `.md` 는 문서 — 시크릿 자체가 들어갈 리 없는 파일 종류임에도, 시크릿 할당 패턴 검사가 무차별 적용되어 *문서 작업이 차단* 되는 ergonomic 사고.

### 해결 방안 (요약)

**옵션 A 채택** (권장): 시크릿 할당 패턴 검사 단계에서 staged diff 를 호출할 때 git pathspec `:(exclude)*.md` 로 `.md` 파일의 변경을 제외한다. AWS 키 / Private Key / GitHub 토큰 검사는 *모든* 파일에 계속 적용 (이들 패턴은 placeholder 와 충돌하지 않는 강한 형식).

대안 분석은 아래 §🎯 요구사항 - 분기 분석 참고.

## 📊 개념도

```text
[현재]
git diff --cached  ──┐
                     ├─→ grep 시크릿 키워드 + = + 값   ←  .md 본문 false positive
                     ├─→ grep AWS 키
                     ├─→ grep Private Key
                     └─→ grep GitHub 토큰

[변경 후]
git diff --cached ':(exclude)*.md'  ──→ grep 시크릿 키워드 + = + 값   ← .md 제외 ✓
git diff --cached (전체)            ──→ grep AWS 키 / Private Key / GitHub 토큰  (그대로)
```

## 🎯 요구사항

### Functional Requirements

1. `.md` 파일 본문에 `password|secret|api_key|...` 키워드 + `=`/`:` + 값 형태의 *설명용 리터럴* 이 있어도 commit 통과 (false positive 해소).
2. `.md` 가 *아닌* 파일 (예: `app.py`, `config.ts`, `Makefile`, `.env`) 에 같은 패턴이 있으면 계속 차단 (regression 없음).
3. AWS 키 / Private Key / GitHub 토큰 / `.env` 파일명 검사는 `.md` 포함 *모든* 파일에 계속 적용 (이들은 강한 형식 + `.env` 파일명은 이미 별도 처리됨).

### Non-Functional Requirements

1. bash 3.2+ 호환. `git diff --cached -- ':(exclude)*.md'` pathspec 은 git 1.9+ 표준.
2. 기존 13개 테스트 모두 PASS 유지.
3. 신규 테스트 최소 3건 (`.md` 통과 / `.py` 차단 / `.md` 안의 AWS 키 차단).

### 분기 분석 (사용자 검토용)

| 옵션 | 구현 | 정밀도 | 복잡도 | 본 spec 권장 |
|---|---|:---:|:---:|:---:|
| **A: `.md` 제외** | `git diff --cached -- ':(exclude)*.md'` 추가 | 본 spec 의 직접 문제 100% 해결, 다른 확장자 false positive 는 잔존 | ⭐ 단일 줄 변경 | ✅ |
| **B: 코드 fence 인식** | staged diff 에서 fence 안의 라인만 제외 | 정밀 | ⭐⭐⭐ regex 복잡, `.md` 안의 fence *밖* 본문은 여전히 false positive | ✗ |
| **C: placeholder heuristic** | 값이 placeholder 표기 (`<...>`, `your-...`, `xxx`, `example` 등) 이면 통과 | 매우 정밀 | ⭐⭐⭐⭐ heuristic 신뢰도 한계, 휴리스틱 누락 시 false positive | ✗ |
| **D: A + 다른 확장자 확대** | pathspec 다중 exclude (.md, .example, .sample 등) | A 의 상위집합 | ⭐⭐ | ▲ 본 spec 직접 트리거 외 영역까지 확장 → scope creep |

**A 권장 근거**:
- 본 spec 의 *직접* 트리거는 `.md` 본문에서 두 차례 재현. `.md` 만 다루면 100% 해결.
- B 는 `.md` 안의 fence *밖* 본문 (예: pr_description.md 의 평문 설명) 까지 다루려면 사실상 A 와 같아짐.
- C 는 false negative 위험 (placeholder 패턴 우연 매칭) + 휴리스틱 유지보수 부담.
- D 는 다른 확장자의 false positive 는 *실제 관찰되지 않은* 가설이므로 YAGNI. 발생 시 별도 spec 으로 분리.

## 🚫 Out of Scope

- **`.md` 안의 *실제* 시크릿 검출** — `.md` 본문에 실제 시크릿 토큰이 들어가는 case 는 본 변경으로 시크릿 할당 패턴 검사가 통과시킨다. 단 AWS 키 / Private Key / GitHub 토큰 검사는 계속 적용되어 강한 형식의 시크릿은 잡힌다. 약한 형식의 .md 본문 위협은 본 spec 에서 의도적으로 허용. 별도 spec 으로 검토.
- **`.example` / `.sample` / `.yml.example` 등 다른 확장자의 시크릿 할당 패턴 false positive** — 본 spec 의 직접 트리거가 아님. 실제 발생 관찰 시 별도 spec 으로 분리 (D 옵션 prefigure).
- **코드 fence 인식 / placeholder heuristic** — 옵션 B / C. 본 spec 의 ROI 비교에서 탈락. 미래에 .md 외부에서 강한 false positive 가 관찰되면 재검토.

## 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — pathspec 한 줄 추가. ADR 가치 없음.

## ✅ Definition of Done

- [ ] `sources/hooks/check-secrets.sh` 의 시크릿 할당 패턴 검사 단계에 `:(exclude)*.md` pathspec 적용
- [ ] `tests/test-check-secrets-dual-mode.sh` 에 신규 테스트 3건 추가:
  - Test 14: `.md` 본문에 시크릿 할당 패턴 리터럴 staged → 통과
  - Test 15: `.py` 본문에 동일 패턴 staged → 차단 (regression 가드)
  - Test 16: `.md` 본문에 AWS 키 패턴 staged → 차단 (다른 패턴 영향 없음 확인)
- [ ] 전체 13 + 3 = 16 PASS / 0 FAIL
- [ ] `walkthrough.md` / `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-check-secrets-docs-context` 브랜치 push + fork main PR
