# Spec Critique: spec-x-defaultbranch-consistency

> /hk-spec-critique (Opus 독립 서브에이전트) 결과. 2026-06-16.

## 1. 유사 기법 조사

### 발견된 패턴/도구

- **`git symbolic-ref refs/remotes/origin/HEAD` (origin/HEAD 추론)**: 원격 기본 브랜치를 ref 로 직접 조회. `git remote set-head origin -a` 로 채워야 존재. — 현재 spec 은 이를 **비채택**(ADR-015)했는데 검색 근거가 이 결정을 강하게 뒷받침. 핵심 함정: *이 ref 는 항상 존재하지 않으며 존재할 필요도 없다*. 갓 clone / set-head 미실행 저장소에서는 심볼릭 ref 부재로 추론 alias 가 에러. harness-kit 의 dogfood·CI fixture 는 대부분 set-head 미설정 → 자동추론이 오히려 불안정. 명시 설정 우선이 옳음.
- **`anthropics/claude-code` issue #31614 — "Branch detection uses init.defaultBranch instead of remote HEAD"**: Claude Code 자체가 `init.defaultBranch`(전역 신규-repo 설정)와 실제 origin/HEAD 를 혼동한 실제 버그. "어떤 소스가 진짜 기본 브랜치인가" 가 툴 레벨에서 실제로 헷갈림을 입증. spec 의 `installed.json defaultBranch`(명시적 단일 소스)는 이 혼동을 회피.
- **git config 우선순위 (local > global > system > 리터럴)**: spec 의 `state.baseBranch → installed.json defaultBranch → "main"` 가 정확히 "구체→일반→리터럴" 표준 멘탈모델과 일치.
- **kit 내부 기존 패턴 (`hk-code-review.md:22`, `gemini-review.sh:64-92`)**: 이미 동일 문제를 푼 살아있는 레퍼런스. `jq -r '.baseBranch // .defaultBranch // "main"'` 체인 + **ref 실재 확인 2단 fallback**. spec 의 헬퍼는 우선순위 체인은 일치하나 **ref-실재 확인 단계를 누락**(§2 참조).

### 시사점

자동추론 비채택은 외부(ref 부재 함정)+내부(claude-code 자체 버그) 양쪽 근거로 정당 — ADR-015 핵심 논거로 충분. 본 spec 의 본질은 "새 헬퍼 설계" 가 아니라 **이미 두 곳(hk-code-review/gemini-review)에 구현된 체인을 sdd 본체로 흡수·정합** — 기준 구현은 gemini-review.sh 의 2단 ref-fallback 이어야 한다.

## 2. 요구사항 비판

### 누락

- **ref-실재 확인 누락 (가장 중요)**: 헬퍼가 값만 결정하고 해석된 브랜치 실재를 확인 안 함. 소비처(517/1941)는 `git log "$base_branch"` 로 즉시 사용. base-branch 모드 phase 첫 spec 은 `baseBranch`(phase 브랜치)가 JIT 생성이라 작업 중 미존재(constitution §3.1). 현재 코드는 `main` 안전 폴백이나, 새 헬퍼가 미존재 phase 브랜치를 반환하면 `git log` 빈 결과(`|| true`) → **머지 감지가 조용히 깨짐**. 헬퍼는 gemini-review.sh:78-92 의 2단 ref-fallback 포함 필요.
- **§3.2 (constitution line 67) `else main` 누락**: spec 은 §3.3 만 지목하나 §3.2 의 `phase-{N}-{slug} (base mode) else main` 에도 동일 `main` 리터럴. §3.2 도 정합하거나 "왜 범위 외인지" 명시 필요.
- **hk-ship line 139 추출 체인 누락**: 현재 `jq -r '.baseBranch // "null"'` 가 defaultBranch 단계를 건너뜀. FR-2/plan 이 "PR_BASE 폴백" 만 언급 → line 139 를 `.baseBranch // .defaultBranch // "null"` 로 고치는 게 빠질 위험 (hk-code-review.md:22 가 레퍼런스).
- **installed.json 부재/jq 부재/null 처리**: 기존 경로(sdd:673-674)는 `// "main"` + `|| echo "main"` + null/빈 가드 3중. test fixture `make_fixture` 는 installed.json 미생성 → 헬퍼가 파일 부재 graceful 처리 안 하면 기존 테스트 깨짐.
- **회귀 fixture 보강**: defaultBranch="develop" fixture 는 installed.json 생성 + develop 브랜치 실제 생성(ref 실재 통과용) 필요.

### 모순

- **"surgical 하게 두되 헬퍼 흡수" vs FR-1**: 폴백 가드가 헬퍼·sdd:673·gemini-review 3벌로 남음. 헬퍼 내부에서 installed.json 읽기를 공통화하되 sdd:673 호출처는 안 건드리는 절충 권장.

### 과잉 설계

- 해당 없음. 오히려 과소(ref-실재 확인 누락). origin/HEAD 자동추론 OOS 는 적절한 YAGNI.

### 모호함

- **hk-cleanup defaultBranch 감지 방법 미정**: `installed.json` defaultBranch 를 `git rev-parse --verify --quiet` 로 실재 확인하는 항목. remote/local 어느 기준인지 명시 필요.
- **동작 변경 범위**: nextmarket(defaultBranch≠main)에서 실제 동작 변화 + 기존 phase 진행 중 base 변경 안전성(read-only 판정) 한 줄 기재 권장.

## 3. 대안 제안

### 대안 A: gemini-review.sh ref-fallback 전체를 헬퍼화 (체인+실재 확인 통합, 전역 호출)
- 장점: ref-누락 회귀 원천 차단, 전역 1벌. 단점: gemini-review.sh 가 lib source 안 할 수 있어 진짜 1벌은 lib 공통화 필요(범위 확대).

### 대안 B: 현재 spec 유지 + 3줄 보강 (최소 보강)
- 아이디어: FR-1 에 ref-실재 fallback 한 줄, FR-2 에 hk-ship line 139 체인 한 줄, §3.2 처리 방침 한 줄. gemini-review.sh 는 안 건드림.
- 장점: surgical, 회귀 제거 + OOS 경계 유지, dogfood 검증 원칙 부합. 단점: 폴백 패턴 논리적 동일하나 물리 3벌.

### 대안 C: lib/base.sh 신설 + 전역 source (장기 자산화)
- 장점: 미래 신규 경로 자동 일치. 단점: 본 spec(1-PR) 범위 초과, 도그푸딩 전 추상화(CLAUDE.md 위배), YAGNI.

## 권장안

**대안 B (현재 spec 유지 + 보강)**. 근거: 본 spec 은 기존 체인의 sdd 흡수이고 그 레퍼런스가 ref-실재 확인을 포함하므로 값-체인만 만들면 base-mode 첫 spec 머지 감지 회귀. hk-ship line 139 체인은 1줄이나 빠지면 FR-2 반쪽. 대안 A/C 의 완전 DRY 는 gemini-review.sh 독립성 파괴 + 범위 phase 급 확대 → defaultBranch=main dogfood 에서 동작차 없는 리팩터에 과한 비용. 물리 3벌은 ADR-015 에 "현재 동일 패턴 3벌 허용, lib 통합은 다음 트리거 시 재평가" 로 부채 가시화. §3.2 는 안 건드리되 "범위 외, 별도 검토" 한 줄로 silent 누락 방지.

## 4. ADR 후보 추출

- [x] **후보 적정 (ADR-015 유효)**: `review-base-resolution-chain` — type: **tradeoff** — 적절. 기각안(origin/HEAD 자동추론)의 명시적 비용(symbolic-ref 부재 시 에러/오진단, 외부 근거 입증)이 있어 tradeoff 정의 부합. cross-spec·long-lived 충족. ADR-015 번호 정확.
  - **범위 보강 권고**: (a) 체인 정의, (b) origin/HEAD 비채택 근거(외부 함정 + claude-code #31614), (c) `init.defaultBranch`(신규 repo) vs `defaultBranch`(리뷰/PR base) 구분 1줄, (d) "동일 패턴 sdd 헬퍼·gemini-review·sdd:673 물리 3벌 — lib 단일화는 다음 트리거 시 재평가" 부채 가시화 1줄.
- [ ] 후보 없음: 해당 없음.

## 검증 요약 (실제 코드 대조)

| spec 주장 | 코드 대조 |
|---|---|
| sdd:517,1941 하드코딩 | ✅ 정확 |
| sdd:671-678/2429 이미 defaultBranch 읽음 | ✅ 정확 |
| hk-ship:144,150 main | ✅ 정확. 단 line 139 추출 체인도 미반영 — spec 미지목 |
| constitution §3.3 always main | ✅ 정확. 단 §3.2 line 67 else main 도 동일 — spec 미지목 |
| origin/HEAD 비채택 정당성 | ✅ 외부 근거로 강하게 뒷받침 |
| 헬퍼 값-체인만 정의 | ⚠️ ref-실재 확인 누락 (gemini-review.sh:78-92 기준) |
| test fixture defaultBranch≠main | ⚠️ make_fixture 는 installed.json 미생성 — fixture 보강 필요 |

## Sources
- https://github.com/anthropics/claude-code/issues/31614
- https://git-scm.com/docs/git-remote
- https://github.com/jhauberg/gitdoctor/issues/3
- https://til.codeinthehole.com/posts/how-to-set-the-default-branch-for-a-git-remote/
- https://git-scm.com/docs/git-init
