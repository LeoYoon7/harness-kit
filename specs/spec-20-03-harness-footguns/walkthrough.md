# Walkthrough: spec-20-03

> 본 문서는 *작업 기록* 입니다. 결정·협의·검증·발견을 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 통합 방식 | 포팅 / 재구현 / 보류 | **묶음 spec (3종 일괄, TDD)** | upstream 도 1 spec 으로 묶음 + §11.4 bundle 패턴 + 각 footgun TDD 필요 |
| **#2 머지 범위** (실행 중 Hard Stop) | 보간만(`_var_re`/`_op_re`) / 완전 parity(+`_ph_re`) / 보류 | **보간만** | upstream `_ph_re`(placeholder) 가 fork 기존 Test 15(비-.md 맨 placeholder 차단)와 충돌 → 무회귀 위반. 보고된 footgun(`${VAR:-default}` env 보간)은 `_var_re`+`_op_re` 만으로 완전 해결 |
| #1b 채택 | status drift 와 중복 우려 / 채택 | **채택** | `sdd status` 는 수동 조회(passive), `_warn_install_drift` 는 브랜치 생성 직전 능동 발화(active) — 보완 관계 |
| #3 base 메타 갱신 | phase_new 인라인 sed 재사용 / 범용 헬퍼 | **`_set_phase_base_meta` 헬퍼 포팅** | phase_new 의 sed 는 template placeholder 전용. 재활성 케이스(임의 값 치환)엔 범용 헬퍼 필요 |
| sources↔installed sync | 수동 양쪽 편집 / `cp` 동기화 | **`cp` 동기화** | sdd 처럼 큰 파일은 `cp` 가 drift 없이 확실. `diff -q` 로 검증 |

### ADR 승격 가이드
- [x] 없음 — upstream 검증된 footgun fix 의 fork 적응. #2 병렬 진화 머지는 국소 결정(장기 불변식 아님). phase-20 plan 도 footgun 을 ADR 비대상으로 명시(ADR 009+ 는 director mode/phase-FF 예약).

## 💬 사용자 협의

- **주제 1**: phase-20 후속 작업 선택 → 사용자 1번(footgun #158) 선택.
- **주제 2**: footgun work mode → triage 결과 "phase-FF 후보"가 #2 병렬 진화 머지(신규 결정) 탓에 phase-FF 범위 초과 → 사용자 1번(묶음 spec-20-03) 선택.
- **주제 3 (Hard Stop)**: #2 머지 중 `_ph_re` × Test 15 충돌 발견 → 사용자 1번(보간만 머지, `_ph_re` 제외) 선택. plan.md [IMPORTANT] + task.md 에 결정 기록(commit `f10f194`).
- **주제 4**: Ship 전 코드 리뷰 게이트 → 사용자 1번(Gemini cross-model) 선택.

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령 / 결과**:
```text
test-check-secrets-dual-mode.sh   ✅ 19/19  (Test 17/18 보간 통과, Test 19 실제 시크릿 차단, Test 15 placeholder 차단 보존)
test-update.sh                    ✅ 12/12  (시나리오 D: update 후 미커밋 산물 안내)
test-sdd-spec-new-drift-warn.sh   ✅ 7/7    (신규 — dirty→경고+rc0+생성, clean→무경고)
test-sdd-phase-activate.sh        ✅ 17/17  (Check 10 --base=<branch>, Check 11 재활성 spec 보존, 1-9 회귀)
test-sdd-spec-new-seq.sh          ✅ 5/5    (spec_new 회귀)
```
- 각 footgun TDD Red→Green 전환 확인.

#### 회귀 / sync
- **governance-dedup**: 7/8 — Check 3(constitution+agent.md word count 7073w > 6000w) FAIL. **본 spec 무관 — 변경 파일에 governance 문서 없음**(아래 발견 사항). 나머지 7 PASS(sync Check 2/6 포함).
- **sync**: `diff -q sources/bin/sdd .harness-kit/bin/sdd` + `diff -q sources/hooks/check-secrets.sh .harness-kit/hooks/check-secrets.sh` → **SYNCED**.

### 2. 수동 검증
1. **Action**: 커밋 전 `HARNESS_GIT_HOOK_MODE=1 check-secrets.sh` dry-run (테스트 파일 self-trigger 점검) — **Result**: exit=0 (분리 리터럴로 self-trigger 없음).
2. **Action**: `git commit` 시 `[plan-accept]` hook 차단 발생 → `sdd plan accept` 로 state 플래그 반영 후 재시도 — **Result**: 통과(hook 정상 작동 확인 — memory "Hook no-op" 노트와 달리 pre-commit hook 은 활성).

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Gemini cross-model) |
| **결과 파일** | `specs/spec-20-03-harness-footguns/code-review-gemini.md` |
| **요약** | **Approve** — Critical 0 / Major 0 / Minor 2 |

**Minor 2건 처리 (둘 다 변경 없음)**:
- **`_var_re` 대소문자** (`grep -vE` → `-viE` 권장): `_var_re` alpha 클래스가 이미 `[A-Za-z_]` 로 양쪽 케이스 포함 → `-i` 는 기능상 no-op. upstream 도 동일(`_op_re` 만 `-i` 필요한 의도적 비대칭). 미변경.
- **sed `#` 구분자**: `--base=<branch>` 가 `phase-[0-9]*-*` 로 검증돼 `#` 입력 불가 + git 컨벤션상 무관. upstream 동일. 미변경.

## 🔍 발견 사항

- **pre-commit hook 활성**: memory 노트("Hook no-op (env vs stdin)")와 달리 이 환경의 git pre-commit hook(check-secrets / check-plan-accept / staged-lint)은 **정상 작동**. `[plan-accept]` 가 `sdd plan accept` 전 production 코드 커밋을 실제 차단함 → memory 갱신 필요.
- **governance 문서 비대화**: `test-governance-dedup.sh` Check 3 가 constitution(2672w)+agent.md(4401w)=7073w 로 상한(6000w) 초과 경고. 본 spec 무관(기존). phase-20 후속 director mode/phase-FF 재구현이 agent.md 를 줄이면 해소 가능 — 잠재 Icebox.
- **fork↔upstream 병렬 진화**: check-secrets 는 fork(`.md` 제외)·upstream(보간/placeholder 제외)이 독립 진화. 두 오탐 원인이 직교라 머지 가능했으나 `_ph_re`만 Test 15 와 충돌 — 병렬 진화 머지는 케이스별 충돌 점검 필수.

## 🚧 이월 항목

- governance 문서 word count 초과(Check 3) — phase-20 director mode/phase-FF 재구현 시 agent.md 축소로 해소 검토.
- memory `hooks-noop-stdin-vs-env` 갱신 — 이 환경 pre-commit hook 활성 확인.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-04 |
| **최종 commit** | (ship commit, push 직전) |
