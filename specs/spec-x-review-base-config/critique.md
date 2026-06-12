# Spec Critique: spec-x-review-base-config

> 작성: Opus 서브에이전트 (독립 컨텍스트), 2026-06-12. `/hk-spec-critique` 산출물.

## 1. 유사 기법 조사

### 발견된 패턴/도구
- **`gh pr create` base 결정 체인**: 명시 `--base` 플래그 → `git config branch.{cur}.gh-merge-base` → 리포지토리 default branch 순으로 fallback. 현재 spec과의 비교: spec의 `phase baseBranch → defaultBranch → main` 체인과 구조가 동일하다 (per-context override → per-repo 설정 → 최종 fallback). 다만 gh는 최종 fallback을 *리터럴 main* 이 아니라 *원격에서 조회한 실제 default branch* 로 둔다는 점이 다르다. spec은 최종 fallback이 리터럴 `main`.
- **`git symbolic-ref refs/remotes/origin/HEAD`**: 기존 리포의 *실제* default branch를 알아내는 권장 방법. `init.defaultBranch` 는 신규 `git init` 에만 적용되는 전역 설정이라 기존 리포의 실제 base와 어긋날 수 있음 (claude-code issue #31614이 바로 이 함정 — `init.defaultBranch` 를 본 게 오답을 냈다). 현재 spec과의 비교: spec은 자동 추론을 전혀 쓰지 않고 명시적 설정 키만 둔다. 자동 추론을 *기본값 결정* 보조로 쓸 여지가 있으나 spec은 채택하지 않음 (대안 A 참조).
- **`gh-merge-base` (git config 기반 per-branch 설정)**: gh가 PR base를 git config에 박아두는 방식. 현재 spec과의 비교: spec은 `installed.json` (kit 전용 JSON) 에 저장. `git config` 대신 JSON을 택한 이유는 기존 config 키 (uxMode/directorMode) 와 같은 저장소를 쓰기 위함 — 일관성 측면에서 타당.
- **Danger local `--base dev`**: 로컬 diff 비교 기준을 플래그로 override. reviewdog/pre-commit `no-commit-to-branch --branch` 도 base/protected 브랜치를 인자로 받음. 현재 spec과의 비교: 업계 도구들은 *런타임 인자 override* 를 표준 제공한다. spec은 영속 설정만 두고 1회성 override (환경변수/인자) 는 없음 (대안 B 참조).

### 시사점
업계 표준 체인 (`per-invocation override → per-repo 설정 → 자동 추론된 실제 default`) 과 비교하면, 본 spec은 가운데 단계(per-repo 설정)만 정확히 채운다. 양 끝(런타임 override, origin/HEAD 자동 추론)은 의도적으로 생략했고, 이는 YAGNI 관점에서 합리적이다. 다만 *최종 fallback을 리터럴 `main` 으로 고정* 한 부분은 gh/danger와 갈리는 지점이며, kit이 명시적으로 `master`/`trunk`/`develop`-only 리포를 1차 타깃 밖으로 둔 결과다 (gemini-review.sh:74 주석과 정합).

## 2. 요구사항 비판

### 누락
- **`defaultBranch` 가 status --json에 안 실림**: `hk-code-review.md` 는 LLM이 실행하는 절차 문서다. 현재 LLM은 `sdd status --json` 한 번으로 `.baseBranch` 를 얻지만, `defaultBranch` 는 `installed.json` 을 *별도로* 읽어야 한다 (status JSON은 state.json만 덤프 — sdd:668-674). plan.md는 이를 인지하고 두 단계를 적었으나, spec FR에는 "LLM이 두 소스를 합성해 `REVIEW_BASE` 를 도출" 한다는 절차가 명시되지 않았다. LLM 절차의 비결정성을 줄이려면 `sdd status --json` 출력에 `defaultBranch` (혹은 해석된 `reviewBase`) 를 함께 실어 단일 소스로 만드는 편이 견고하다. 미반영 시 `hk-code-review.md` 의 base 결정이 매 실행 LLM 해석에 의존.
- **doctor 진단 노출 부재**: `directorMode` 는 `cmd_doctor` 가 노출(sdd:2393)하는데 `defaultBranch` 는 spec/plan 어디에도 doctor 노출이 없다. 사용자가 "왜 리뷰가 develop 기준이지/main 기준이지" 를 진단할 단일 지점이 없음. uxMode조차 doctor에 안 나오므로 *기존 패턴과는 정합* 하나, 본 키의 효과(diff 범위가 바뀜)가 사용자에게 비가시적이라는 점은 uxMode보다 혼동 비용이 크다.
- **설정값 ↔ 실재 브랜치 불일치 UX**: `git check-ref-format` 은 *형식* 만 본다. `sdd config default-branch develpo` (오타) 같은 형식상-합법이지만 *실재하지 않는* 브랜치를 막지 못한다. 설정 시점에 `git rev-parse --verify` 로 실재 경고(거부 아님 — 첫 spec just-in-time 생성 케이스 보존)를 띄울지 spec이 침묵. gemini-review.sh 는 런타임에 부재 fallback이 있으나(`:73-80`), `hk-code-review.md` 쪽 런타임 fallback 절차는 plan에 명시가 약함.
- **hk-cleanup `baseBranch` 검사와의 관계**: cleanup(hk-cleanup.md:76)은 "`baseBranch` 설정됐는데 remote 브랜치 없음" 을 점검한다. `defaultBranch` 도입 후 같은 검사를 `defaultBranch` 에도 적용할지 침묵 — Out of Scope에도 안 들어가 누락 가능성.
- **`hk-gemini-review.md` 명령 문서 갱신 누락**: plan.md는 `hk-code-review.md` 만 수정 대상으로 두지만, `hk-gemini-review.md:13` 의 "현재 브랜치와 base (phase base 또는 main) 사이" 와 `:24` 의 "base branch 식별" 서술은 새 체인(`defaultBranch`)을 반영하지 못한다. 사용자-대면 문서 drift. plan 변경 목록에 명시 누락.
- **update.sh 경로**: NFR 3은 "install/update 변경 불요" 라 했는데, 도그푸딩 결과(`.harness-kit/bin/sdd` 등)를 `update.sh` 가 갱신하는 게 정상 경로다. 본 repo는 sources/와 .harness-kit/를 *수동 동기* (NFR 4) 한다고 했으나, *다른 설치 프로젝트* 가 이 변경을 받으려면 `update.sh` 실행이 필요하다 — "변경 불요" 는 *스키마 마이그레이션* 불요라는 뜻이지 *파일 갱신 불요* 가 아니다. 표현이 두 의미를 혼동시킴(모호함 항목과 연결).

### 모순
- **NFR 3 "install/update 변경 불요" vs NFR 4 "동기 갱신"**: NFR 3은 update가 필요 없다고 읽히고, NFR 4는 sources↔.harness-kit 동기 갱신을 요구한다. 실제로는 *키 마이그레이션은 불요하나 스크립트 파일 갱신(=update.sh 또는 수동 복사)은 필수* 다. 두 NFR이 표면상 충돌. NFR 3을 "스키마 마이그레이션 불요" 로 한정 표기하면 해소.

### 과잉 설계
- 해당 없음. config 키 1개 추가 + fallback 체인 교체는 최소 변경이며, 멀티레포/sdd 내부 fallback/PR base 정책을 모두 Out of Scope + Icebox로 분리한 점이 YAGNI를 잘 지킨다. 오히려 spec 범위가 적절히 좁다.

### 모호함
- **T9 테스트의 의도가 자기모순적으로 읽힘**: plan.md의 T9는 "`defaultBranch=no-such-branch` → 경고 fallback 후 `Diff (main...HEAD)` 진행 확인" 인데, 같은 문장 뒤에 "해석값 자체가 부재인 경우 diff가 비어 '리뷰할 변경 없음' exit" 라고 덧붙인다. *fallback 후 정상 진행* 과 *빈 diff로 exit* 는 다른 결과다. gemini-review.sh:76 로직상 `BASE_BRANCH != "main"` 이면 `main` 으로 fallback하므로 `no-such-branch` → `main` 진행이 맞다. 그런데 `defaultBranch` 가 `no-such-branch` 일 때 BASE_BRANCH가 거기서 다시 `main` 으로 가는지(즉 `defaultBranch` 해석값 부재 시 리터럴 main으로 2단 fallback 하는지)가 spec.md FR 3 ("ref 부재 fallback의 최종 목적지도 defaultBranch 해석값") 과 충돌한다. FR 3은 "main이 아닌 defaultBranch로 fallback" 이라 했는데, defaultBranch 자체가 부재면 무한 루프 위험 없이 *리터럴 main* 으로 떨어져야 한다 — 이 2단 종착(`baseBranch → defaultBranch → main`)이 코드에 어떻게 박히는지 plan의 의사코드가 명확히 보여주지 않음. 구현자가 해석에 따라 갈릴 수 있음.
- **"phase baseBranch → defaultBranch → main" 의 두 번째 화살표 조건**: state `.baseBranch` 가 *설정됐으나 실재하지 않을* 때(첫 spec just-in-time), 현 코드는 `main` 으로 fallback한다. 새 체인에서는 이때 `defaultBranch` 로 가야 하는지 `main` 으로 가야 하는지 — base-branch 모드 phase에서 defaultBranch가 develop이면, 첫 spec 작업 중 phase base 부재 시 develop으로 fallback해야 의미상 맞다. plan.md가 이를 다루나(`!= defaultBranch → defaultBranch`), spec.md FR에는 이 "phase base 부재 시 defaultBranch로" 가 명시 안 됨.

## 3. 대안 제안

### 대안 A: origin/HEAD 자동 추론 + 설정 override
- **아이디어**: 기본값을 리터럴 `main` 이 아니라 `git symbolic-ref --short refs/remotes/origin/HEAD` (없으면 `main`) 로 자동 추론하고, `installed.json .defaultBranch` 는 *명시 override* 로만 둔다. 즉 체인 = `phase baseBranch → defaultBranch(설정 시) → origin/HEAD 추론 → main`.
- **장점**: gh/git 업계 표준과 정합. develop-base 단일 레포라도 `origin/HEAD` 가 develop을 가리키면 사용자가 *아무 설정 없이* 올바른 base를 얻음 (zero-config). master/trunk 리포도 자동 커버.
- **단점**: `origin/HEAD` 는 clone 직후엔 세팅돼 있으나 `git remote set-head` 가 안 돌면 stale/부재. CI나 shallow clone 환경에서 비신뢰적. 본 키트의 라이브 케이스(develop *통합 후 주기 승격*)에서 origin/HEAD가 develop을 가리킨다는 보장이 없음(보통 GitHub default=main인 채 develop 통합) — 즉 *이 프로젝트의 실 문제를 자동으로 못 풀 수 있음*. 추론 실패 시 디버깅 비용 증가.

### 대안 B: 환경변수/CLI override (영속 설정 + 1회성 둘 다)
- **아이디어**: 현재 spec의 영속 설정 키는 유지하되, `HARNESS_REVIEW_BASE` 환경변수 또는 `gemini-review.sh --base <branch>` 인자를 최우선 단계로 추가. 체인 = `--base/env → phase baseBranch → defaultBranch → main`.
- **장점**: danger `--base dev` / reviewdog 패턴과 정합. 사용자가 수동 dual-script로 회피하던 *바로 그 1회성 케이스* 를 영속 설정 변경 없이 즉시 해결. 설정 키와 직교(보완 관계).
- **단점**: `hk-code-review.md` 는 LLM 절차 문서라 환경변수 전달 경로가 불명확(LLM이 env를 셋업해야). 표면적이 넓어지고 테스트 케이스 증가. 현 문제는 "주기적 develop 통합" 이라 *영속* 설정이 1회성보다 적합 — 1회성은 부차적 니즈.

### 대안 C: 현재 spec 유지 + status JSON 단일화 보강
- **아이디어**: 현재 접근(installed.json 키 + sdd config 서브커맨드 + 해석 체인)을 그대로 두되, 누락 항목 두 개만 흡수 — (1) `sdd status --json` 출력에 해석된 `reviewBase` (또는 `defaultBranch`) 필드 추가, (2) `cmd_doctor` 에 `defaultBranch` 한 줄 노출(directorMode 패턴 답습).
- **장점**: `hk-code-review.md` 의 LLM이 두 소스를 합성할 필요 없이 status JSON 한 번으로 base를 얻어 *비결정성 제거*. doctor 진단 가능. 변경 폭은 여전히 작음.
- **단점**: status JSON 스키마에 필드가 추가되어 이를 파싱하는 다른 곳(테스트/문서)과의 정합 확인 필요(소폭). 엄밀히는 현 spec 범위를 약간 넘음.

## 권장안

**대안 C (현재 spec 유지 + status JSON 단일화 + doctor 노출 보강)** 를 권장한다.

근거:
1. 현재 spec의 핵심 설계(installed.json 키 + config 서브커맨드 + 해석 체인)는 기존 패턴 답습이라 학습 비용 0이고, 라이브 실증된 실제 문제(develop 주기 승격)를 *영속 설정* 으로 정확히 푼다 — 대안 A/B의 자동추론/1회성보다 이 프로젝트 니즈에 적합.
2. 다만 `hk-code-review.md` 가 LLM 절차 문서라는 점이 약점이다. `.baseBranch` 는 status JSON에 있는데 `defaultBranch` 는 installed.json을 따로 읽어야 하므로, LLM이 매 실행 두 소스를 *해석해 합성* 해야 한다. 이 비결정성은 본 키트가 반복적으로 경계해온 패턴(LLM 절차의 단일 소스화)에 어긋난다. status JSON에 해석된 base를 한 번 실어주면 `git diff ${REVIEW_BASE}...HEAD` 가 결정적이 된다.
3. doctor 한 줄 노출은 directorMode 선례가 이미 있고, diff 범위가 조용히 바뀌는(uxMode보다 혼동 비용 큰) 키이므로 진단 가시성 가치가 크다.
4. 대안 A(origin/HEAD)는 매력적이나 *이 프로젝트의 실 케이스를 자동으로 못 풀 수 있는*(GitHub default=main인 채 develop 통합) 치명적 약점이 있어 기본값으로는 부적합. 추후 Icebox 후보로만.

추가로 spec 본문에서 **NFR 3/NFR 4 모순 표현 정리**(스키마 마이그레이션 불요 ≠ 파일 갱신 불요)와 **FR 3의 2단 fallback 종착(`defaultBranch` 부재 시 리터럴 main) 명시**, 그리고 plan에 **`hk-gemini-review.md` 문서 갱신**을 변경 목록에 추가할 것을 권한다.

## 4. ADR 후보 추출
- [x] **후보 발견**: `review-base-resolution-chain` — type: `tradeoff` — 이유: "리뷰 게이트 base = phase baseBranch → defaultBranch → main" 해석 체인은 향후 sdd 내부 main fallback 설정화 / hk-ship PR base 재검토(둘 다 Icebox) 가 트리거될 때 *동일 우선순위 규약을 재사용/참조* 해야 하는 cross-spec long-lived 결정. 특히 "최종 fallback은 리터럴 main 고정, 자동추론(origin/HEAD) 비채택" 의 트레이드오프 근거 보존 가치. 단, kit의 "ADR은 트리거 대기" 관행(notify-channel-adapter 선례)에 따라 *지금 작성보다는 Icebox 항목이 실제 착수될 때 작성*하는 deferred 후보.

## 출처
- [Git - git-symbolic-ref Documentation](https://git-scm.com/docs/git-symbolic-ref)
- [Branch detection uses init.defaultBranch instead of remote HEAD · Issue #31614 · anthropics/claude-code](https://github.com/anthropics/claude-code/issues/31614)
- [gh pr create manual](https://cli.github.com/manual/gh_pr_create)
- [Base branch for PR should respect remote's HEAD · Issue #6674 · cli/cli](https://github.com/cli/cli/issues/6674)
- [danger-js fast-feedback (local --base)](https://github.com/danger/danger-js/blob/main/docs/tutorials/fast-feedback.html.md)
- [pre-commit-hooks (no-commit-to-branch --branch)](https://github.com/pre-commit/pre-commit-hooks)
