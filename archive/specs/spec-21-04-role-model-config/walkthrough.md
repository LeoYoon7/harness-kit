# Walkthrough: spec-21-04

> 작업 기록 — 역할 기반 모델 config (de-hardcode).

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 역할 taxonomy | director/worker/scout / 4역할 분리 | **director/worker/scout (3)** | §6.6 4역할 매핑(review→director 흡수). reviewer 별도 분리는 over-engineering |
| 기본값 | 현 동작 보존 / 신규 | **director=opus/worker=sonnet/scout=opus** | backward compat — scout 가 opus 인 건 기존 code analysis 가 Opus 였기 때문 |
| 기본값 시드 | install.sh / fallback-only | **install.sh heredoc + `_config_models` fallback** | 신규 설치 명시 + 기존 설치 backward compat |
| 신규 ADR | 작성 / ADR-011 귀속 | **ADR-011 귀속 + Amendment** | de-hardcode 는 director-mode 결정의 일부. 단 ADR-011 본문에 근거 부재 발견 → Amendment 로 정합화(Opus 리뷰 권고 1) |
| 코드 리뷰 | Gemini / Opus | **Gemini 오작동 → Opus 재리뷰** | Gemini 가 plan 모드 위반(아래 발견 사항) → 신뢰 가능 판정 위해 Opus 재수행 |

### ADR 승격 가이드

- [x] ADR 승격 대상 있음 → ADR-011 에 Amendment 추가(role-based model config). 신규 ADR 불요.
- [ ] 없음

## 💬 사용자 협의

- **주제**: §11.3 재검증 후 21-04 착수 — **합의**: 1번(21-04 role-model-config), taxonomy 는 plan User Review.
- **주제**: Plan Accept — **합의**: Plan Accept (Telegram "1").
- **주제**: Ship 코드 리뷰 — **사용자 의견**: Gemini(1) → 오작동 보고 → **Opus(1)** 재선택.
- **주제**: 리뷰 권고 처리 — **합의**: 1번(권고 1 ADR Amendment + 권고 2 test C6/C7, 권고 3/4 KISS 잔존).

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: `bash tests/test-role-model-config.sh`
- **결과**: ✅ Passed (PASS=9 FAIL=0)
- **로그 요약**:
```text
C1 기본 .models 3역할 · C2 list · C3 set · C4 §6.6 역할참조+모델명 부재 · C5 이중 미러
C6 미지원 role→exit1 · C7 .models 미존재 fallback (권고 2 추가)
결과: PASS=9 FAIL=0
```

#### 회귀
- **명령**: `test-governance-dedup.sh` / `test-director-mode.sh` / `test-director-protocol.sh`
- **결과**: governance-dedup 1/8 (Check 3 단어예산만 red — 무 NEW 회귀). director-mode 10/10. director-protocol 13/13.
- **단어 예산 (before/after)**:
```text
before: agent.md 4706w / after: agent.md 4696w (-10w, §6.6 4행→3행 축소)
Check 3 red 유지 = 예상(green 은 21-06). 본 spec 은 오히려 감소 기여.
```

### 2. 수동 검증

1. **Action**: `sdd config models` — **Result**: director/worker/scout → opus/sonnet/opus 출력.
2. **Action**: `sdd config models scout haiku` → `sdd config models` — **Result**: scout=haiku 반영(검증 후 fixture 한정).
3. **Action**: `grep §6.6` — **Result**: `models.*` 참조 존재, Opus/Sonnet 표 셀 부재.
4. **Action**: `diff -q` agent.md / sdd 미러 — **Result**: 차이 없음(parity).

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Opus same-model — Gemini 오작동으로 대체) |
| **결과 파일** | `specs/spec-21-04-role-model-config/code-review.md` (Gemini 무효 산출물: `code-review-gemini.md`) |
| **요약** | **Approve** / Critical 0 / Major 0 / Minor 4 |
| **Minor 처리** | 권고1(ADR-011 귀속) → **수정**(Amendment). 권고2(미지원 role·fallback 테스트) → **수정**(C6/C7). 권고3(partial .models 시드)·권고4(공백 모델 가드) → **잔존**(reviewer 가 KISS/over-engineering 회피 권고) |

## 🔍 발견 사항

- **⚠ gemini-review.sh plan-mode 위반 (도구 결함)**: `--approval-mode plan`(read-only) 호출인데 Gemini 가 walkthrough.md + pr_description.md 를 작성하고 commit(`9d07f91`)까지 수행 + 존재하지 않는 PR(#41) 할루시네이션. 범위는 그 2개 문서로 한정(코드 무변경). 본 산출물은 에이전트가 전체 경위로 재작성. **kit 이슈/RCA 후보** → Icebox.
- **§6.6 de-hardcode 가 §6.8 역할 언어와 정합**: 21-03 의 director/worker 언어와 §6.6 의 director/worker/scout 추상화 일관.
- **단어 예산 소폭 감소(-10w)**: de-hardcode 가 21-06 다이어트 부담을 약간 덜었다.

## 🚧 이월 항목

- **gemini-review.sh plan-mode 위반** → `backlog/queue.md` Icebox (kit 이슈/RCA 후보).
- **단어 예산 green 복구** → spec-21-06.
- **페르소나 리뷰 패널** → spec-21-05.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent(Opus orchestrator) + Opus reviewer + Leo |
| **작성 기간** | 2026-06-05 |
| **최종 commit** | `33f8879` (ship commit 직전) |
