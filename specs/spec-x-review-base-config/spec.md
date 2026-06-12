# spec-x-review-base-config: 리뷰 게이트 통합 base 브랜치 설정화

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-review-base-config` |
| **Phase** | 없음 (Solo Spec) |
| **Branch** | `spec-x-review-base-config` |
| **상태** | Planning |
| **타입** | Fix |
| **Integration Test Required** | no |
| **작성일** | 2026-06-12 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

코드 리뷰 게이트 2종이 리뷰 대상 diff 의 base 브랜치를 다음과 같이 결정한다.

- `sources/bin/gemini-review.sh:65` — `jq -r '.baseBranch // "main"'`: phase base 브랜치가 없으면 (spec-x, 비-base 모드 phase) 무조건 `main` 으로 fallback. ref 부재 fallback (`:73-80`) 의 목적지도 리터럴 `main`.
- `sources/commands/hk-code-review.md:22,53,83` — `git diff main...HEAD` 를 **하드코딩**.

### 문제점

install 대상 프로젝트의 통합 base 가 `main` 이 아닌 경우 (예: `develop` 통합 후 주기 승격 — nextmarket 프로젝트에서 라이브 실증, 2026-06-12 세션), `main...HEAD` diff 는 본 spec 변경 외에 **미승격 백로그 전체**를 끌어와 리뷰 입력이 오염된다. 리뷰어 (Gemini/Opus) 가 무관한 수백~수천 줄을 함께 받아 신호가 묻히고, 사용자는 kit 스크립트를 우회한 수동 dual-script 로 회피해야 했다.

근본 원인은 두 게이트 모두 **"통합 base = main" 가정이 하드코딩**되어 있다는 것. 이 전제는 멀티레포가 아니어도 (develop-base 단일 레포) 흔히 깨진다.

### 해결 방안 (요약)

`installed.json` 에 `defaultBranch` 설정 키를 도입하고 (부재 시 `main` — 기존 동작 100% 보존), 두 리뷰 게이트의 base 결정을 `phase baseBranch → defaultBranch → main` 체인으로 교체한다. 설정은 기존 config 패턴 (`sdd config ux-mode` 등) 을 따라 `sdd config default-branch [<branch>]` 로 조회/변경하며, `sdd status --json` 과 `sdd doctor` 가 값을 노출해 단일 소스·진단 가시성을 확보한다.

## 🎯 요구사항

### Functional Requirements

1. `sdd config default-branch` — 현재값 조회 (installed.json `.defaultBranch`, 부재 시 `main` 표기).
2. `sdd config default-branch <branch>` — 설정. `git check-ref-format --branch` 로 형식 검증 (부적합 시 거부), `git rev-parse --verify` 로 실재 확인 (**부재 시 경고만, 거부 아님** — 오타 방지 목적; phase base just-in-time 생성 케이스와 달리 defaultBranch 는 통상 실재해야 정상).
3. `sdd status --json` 출력에 `defaultBranch` 필드 노출 (installed.json 해석값, 부재 시 `"main"`). state 파일 부재 fallback JSON 에도 포함 — LLM 절차 (hk-code-review) 가 **단일 소스**로 base 를 결정할 수 있게 한다.
4. `sdd doctor` 출력에 `defaultBranch` 현재값 한 줄 표기 (directorMode 노출 선례) — diff 범위가 조용히 바뀌는 키라 진단 가시성 필요.
5. `gemini-review.sh` 의 base 해석 체인 (2단 fallback 종착 명시):
   - `DEFAULT_BRANCH` = installed.json `.defaultBranch` (부재/null 시 리터럴 `main`)
   - `BASE_BRANCH` = state `.baseBranch` (phase base; 부재/null 시 `DEFAULT_BRANCH`)
   - `BASE_BRANCH` ref 부재 시 (첫 spec just-in-time): `DEFAULT_BRANCH` 로 fallback (경고)
   - `DEFAULT_BRANCH` ref 도 부재 시: 리터럴 `main` 으로 최종 fallback (경고) — 무한 체인 없음
   - `main` 도 부재 시: 기존과 동일하게 빈 diff → "리뷰할 변경이 없습니다" 안전 종료
6. `hk-code-review.md` 의 `git diff main...HEAD` 하드코딩 3곳을 `${REVIEW_BASE}` 로 교체. `REVIEW_BASE` 는 `sdd status --json | jq -r '.baseBranch // .defaultBranch // "main"'` **한 번**으로 결정 (FR 3 의 단일 소스) + ref 부재 시 FR 5 와 동일한 fallback 절차를 문서에 명시.
7. `hk-gemini-review.md` 의 base 서술 ("phase base 또는 main") 을 새 체인 반영으로 갱신 — 사용자-대면 문서 drift 방지.
8. **기존 동작 보존**: `defaultBranch` 미설정 시 모든 게이트·명령이 현 동작과 완전 동일 (main fallback).

### Non-Functional Requirements

1. bash 3.2+ 호환 (bash 4+ 전용 기능 금지), `jq` 외 신규 의존성 없음.
2. 기존 테스트 전부 PASS (특히 `tests/test-gemini-review-guard.sh` T1~T7, `tests/test-sdd-config.sh`).
3. **스키마 마이그레이션 불요** — 키 부재가 곧 기본값 (`main`) 이라 install/update 의 변환 로직 추가 없음. (설치 프로젝트로의 파일 전파 자체는 통상 `update.sh` 경로 — 본 NFR 은 마이그레이션 코드 불요만 의미.)
4. 키트 원본 (`sources/`) 과 도그푸딩 결과 (`.harness-kit/`, `.claude/`) 동기 갱신.

## 🚫 Out of Scope

- **멀티레포 리뷰** (2-repo diff 수집) — kit 1차 타깃 (단일 레포 NestJS) 밖. Icebox 등록.
- **sdd 내부의 main fallback** (`sources/bin/sdd:515,1908` git log 캐시, drift 감지) — 리뷰 게이트와 별개 경로, 영향 범위가 커서 별도 검토. Icebox 등록.
- **hk-ship `PR_BASE="main"` fallback / hk-phase-ship / governance 문서의 main 전제** — PR 타깃 정책은 constitution §3.3 ("spec-x PR Target: always main") 과 얽혀 거버넌스 개정 필요. Icebox 등록.
- **hk-cleanup 의 `defaultBranch` 검사** — cleanup 은 현재 `baseBranch` 의 remote 부재만 점검. `defaultBranch` 에 같은 검사를 추가할지는 sdd 내부 fallback 설정화 (위 Icebox) 와 함께 별도 검토.
- **origin/HEAD 자동 추론** (critique 대안 A) — GitHub default=main 인 채 develop 통합하는 본 라이브 케이스를 자동으로 못 풀 수 있어 기본값으로 부적합. 채택 안 함.
- **런타임 1회성 override** (`--base` 인자 / 환경변수, critique 대안 B) — 현 문제는 주기적 develop 통합이라 영속 설정이 적합. 필요 시 후속.
- diff-only 리뷰의 본질 한계 (모듈 그래프 미인지 오탐) — 거버넌스 (agent.md §6.3 "판단 보조") 가 이미 커버, 조치 불요.

## 📑 ADR 후보 (Architecture Decision Records)

- [x] ADR 가치 있는 결정 있음 → 후보 한 줄 요약: `review-base-resolution-chain` (type: tradeoff) — "phase baseBranch → defaultBranch → main" 해석 체인 + 자동추론 비채택 근거. 단 **deferred** — kit 의 "ADR 은 트리거 대기" 관행 (notify-channel-adapter 선례) 에 따라 Icebox 항목 (sdd 내부 fallback / PR base 재검토) 착수 시 작성. queue.md Icebox 에 함께 기록.
- [ ] 없음

## 🔍 Critique 결과 (선택)

`/hk-spec-critique` (Opus 독립 컨텍스트) 수행 — 전체: `specs/spec-x-review-base-config/critique.md`.

- **권장안**: 대안 C (현재 설계 유지 + status JSON 단일화 + doctor 노출 보강) → **반영 완료** (FR 3, FR 4).
- 누락 5건 (status JSON / doctor / 실재 경고 / hk-gemini-review.md drift / hk-cleanup 관계) → FR 2·3·4·7, Out of Scope 반영.
- 모순 1건 (NFR 3 vs 4) → NFR 3 "스키마 마이그레이션 불요" 로 한정.
- 모호함 2건 (2단 fallback 종착, phase base 부재 시 경로) → FR 5 에 체인 전체 명시.
- ADR 후보 1건 → deferred 후보로 기록.
- 대안 A (origin/HEAD 추론) / B (1회성 override) → 기각, Out of Scope 에 근거 기록.

## ✅ Definition of Done

- [ ] 모든 단위 테스트 PASS
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-review-base-config` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
