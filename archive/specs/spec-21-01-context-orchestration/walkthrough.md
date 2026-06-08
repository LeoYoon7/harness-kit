# Walkthrough: spec-21-01

> 작업 기록 — 결정 과정, 사용자 협의, 검증 결과.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 통합 방식 | cherry-pick / 재구현 | **재구현** | upstream agent.md §6.6 구조가 fork §6.6/§6.7 과 충돌 — fork 구조에 5축 재작성 |
| ADR 번호 | upstream 005 재사용 / fork 신규 | **fork 010** | fork ADR-005 = ignore-symmetry — 의미 충돌. upstream 005 는 참조로만 |
| §6.6 배치 | 인라인 / 별도 가이드 | **§6.6 인라인** | always-on 정책은 항상 로딩되는 본문에 있어야 강제력 일관 (토글형 §6.8 만 분리 후보 — spec-21-03) |
| 단어 예산 가드 | 신규 테스트 Check 4(7285) / 기존 Check 3 증빙 | **기존 Check 3 before/after** (critique 대안 C) | 동일 지표 이중 baseline·7285 하드코딩 취약성 제거 |
| 단어 예산 목표 | net-neutral(0) / ±50w | **±50w** | 5축(~95w) > 상쇄 여지(~45w)라 0 비현실 (critique 모순 지적). 결과 +48w 안착 |
| Gemini Minor (①-⑤ 유니코드) | 유지 / ASCII | **ASCII `(1)-(5)`** | fork ASCII 지향 정합, 호환성. 테스트 영향 없음(용어 기반 grep) |

### ADR 승격 가이드

- [x] ADR 승격 대상 있음 → 작성됨: `docs/decisions/ADR-010-context-orchestration.md` (type: decision)
- [ ] 없음

## 💬 사용자 협의

- **주제**: Work Mode (phase-21 director-mode 착수)
  - **합의**: SDD-P + base branch (`phase-21-director-mode`), slug=director-mode. Telegram 승인.
- **주제**: Plan Accept vs Critique
  - **사용자 의견**: Critique 먼저 (Telegram "2")
  - **합의**: Opus 서브에이전트 critique 실행 → 6개 개선 항목 **all 반영** (Telegram "1") → Plan Accept (Telegram "1")
- **주제**: 단어 예산 net-neutral 스코핑
  - **합의**: spec-21-01 은 ±50w 순증 허용, 완전 green(<6000w)은 phase 누적 (성공기준 4)
- **주제**: Ship 코드 리뷰 게이트
  - **사용자 의견**: Gemini cross-model (Telegram "1")
  - **합의**: Gemini 리뷰 실행 → Approve

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: `bash tests/test-context-orchestration.sh`
- **결과**: ✅ Passed (6/6 checks)
- **로그 요약**:
```text
Check 1: 용어 orchestrator/worker/offloading/distilled ✅×4
Check 2: sources ↔ .harness-kit agent.md 미러 parity ✅
Check 3: ADR-010 존재 + type: decision ✅
ALL 6 CHECKS PASSED
```

#### 회귀 (거버넌스)
- **명령**: `bash tests/test-governance-dedup.sh`
- **결과**: 1/8 (Check 3 단어 예산만 red — **baseline 그대로**, 무 NEW 회귀)
- **단어 예산 (NFR1 증빙, before/after)**:
```text
baseline (머지 전):  constitution 2798 + agent.md 4487 = 7285w
after   (본 spec):   constitution 2798 + agent.md 4535 = 7333w
순증: +48w (±50w 목표 내). agent.md 만 변경.
Check 1(중복문장 0)/2(sync)/4/5/6 모두 PASS — NEW 회귀 없음.
```

### 2. 수동 검증

1. **Action**: `git diff main...HEAD` 의 §6.6 — **Result**: orchestrator–worker 5축 + always-on disambiguation 확인.
2. **Action**: `diff sources/governance/agent.md .harness-kit/agent/agent.md` — **Result**: 차이 없음 (parity).

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Gemini cross-model) |
| **결과 파일** | `specs/spec-21-01-context-orchestration/code-review-gemini.md` |
| **요약** | **Approve** / Critical 0 / Major 0 / Minor 1 |
| **Minor 처리** | ①-⑤ 유니코드 → ASCII `(1)-(5)` 반영 (commit `style`) |

> 참고: Plan Accept 전 Opus 서브에이전트 **critique** 도 별도 수행(`critique.md`) — 설계 단계 검증. Gemini 는 구현(diff) 검증. 두 모델 cross-validation.

## 🔍 발견 사항

- **도그푸딩**: 본 spec 이 확립한 context-orchestration 정책을 즉시 적용 — critique 를 Opus 워커에 위임하고 **distilled 요약만 반환**(5축 (2)·(3) 실증). ADR-010 "첫 사용자"로 기록.
- **gemini-review.sh Windows/엣지케이스 2종** (→ 이월): (a) base-branch phase 의 *첫 spec* 은 base 브랜치가 아직 미생성이라 `git diff <base>...HEAD` 가 빈 결과 → 본 작업은 `main` 대상으로 우회. (b) 스크립트가 Gemini 지시문을 한국어 argv 로 전달 → Windows git-bash 의 CP949 손상 위험 → ASCII 영어 지시문으로 우회. Gemini 서버 429(capacity) 는 backoff 재시도로 해소.

## 🚧 이월 항목

- §6.8 director protocol **배치 결정**(인라인 vs 별도 가이드) → spec-21-03 (phase-21.md OPEN).
- **no-nested-dispatch 불변식** / **always-on-vs-toggle 배치 invariant** → spec-21-03 (ADR-011 시점). (critique 추적 항목)
- **gemini-review.sh 개선** (first-spec base fallback + 비-ASCII argv 안전) → `backlog/queue.md` Icebox 추가.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-04 |
| **최종 commit** | `6da17ef` (ship commit 직전) |
