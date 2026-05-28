# Spec Critique: spec-x-dogfood-sync

## 1. 유사 기법 조사

### 발견된 패턴/도구

- **chezmoi / GNU stow (dotfile managers)**: source-of-truth 디렉토리 → 사용자 홈으로 idempotent apply. `chezmoi apply` 는 destructive 가 아니라 *render+diff+patch* 방식. — 현재 spec 과의 비교: 본 spec 의 `update.sh` 는 *uninstall → install* 패턴(통째로 갈아끼움 + state 보존)이라 chezmoi 의 부분 패치보다 거칠지만, 키트 1개당 1회 호출이라는 단순성은 우월. dotfile 도구들이 *드라이런* 을 1급 시민으로 두는 점은 본 spec 에 일부 누락.

- **GitOps reconciliation (ArgoCD/Flux)**: desired state vs live state 의 지속적 diff 와 `Sync` 액션. drift 가 *시각화* 됨 (out-of-sync 마커). — 비교: 본 spec 은 일회성 sync 만 다루고 *재발 방지/감지* 는 명시적으로 out-of-scope. drift 발견을 사람의 우연한 `diff -rq` 에 의존하고 있음. GitOps 의 핵심 통찰은 "sync 자체보다 *drift 가시화* 가 본질" — 이 부분은 후속 spec 으로 분리되어 있어 acceptable.

- **npm/yarn `link` vs `install`**: link 는 source 를 *심볼릭* 으로 가리켜 drift 가 원천적으로 발생 안 함. install 은 snapshot → drift 발생. — 비교: 본 프로젝트는 이미 install 모델을 채택했고, 키트는 *복사* 라는 정책이 의도된 것 (각 프로젝트가 자기 시점의 키트를 가짐). 하지만 *자기 자신* 에 대한 도그푸딩에서는 link 모델이 더 자연스러울 수 있는데, 본 spec 은 이 가능성을 검토하지 않았음.

- **Hugo/Jekyll self-hosting**: docs 사이트 도구가 자기 docs 를 자기로 빌드. 보통 `Makefile` 의 `make site-self` 같은 단일 명령 + CI 에서 *매 PR* 빌드 검증. — 비교: 본 spec 은 단일 명령 호출 부분은 일치하지만 *CI 자동화* 가 없음. Hugo 류는 사람이 수동 sync 를 안 한다.

- **monorepo manifest sync (Bazel `gazelle`, Nx `sync`)**: source 변경 시 `gazelle update`/`nx sync` 가 BUILD 파일 / project.json 을 재생성. `--check` 모드가 CI 에서 drift 를 fail 처리. — 비교: 본 spec 의 `update.sh` 에는 `--check` (= apply 없이 drift 만 보고) 기능이 없음. spec 의 DoD 가 "diff -rq 빈 출력" 인 점은 사실상 `--check` 의 결과를 사람이 수동 확인하는 형태.

### 시사점

1. 본 spec 의 "키트 자체 메커니즘 1회 호출" 전략은 dotfile manager 군과 정렬되어 있고, **단순성 면에서 정당화 가능**.
2. 다만 1회 sync 의 *검증 부담* (diff -rq 수동, smoke test 수동) 이 큰 편 — 본 PR 의 DoD 안에서 이를 자동화한 *one-liner verify 스크립트* 가 있으면 미래 dogfood sync 에서도 재사용 가능. 본 spec 은 인라인 명령으로만 기술.
3. *drift 가시화 메커니즘 부재* 가 이번 사건의 진짜 근본 원인. 본 spec 이 OOS 로 분리한 것은 합리적이나, **walkthrough ideabox 캡처보다 강한 후속 보장 장치**(예: 별도 spec stub 을 본 PR 안에서 생성)가 안전.

## 2. 요구사항 비판

### 누락

- **본 PR 실행 중 hook 자체가 destructive 동작을 막을 가능성에 대한 가드 명시 부재**: `update.sh` 가 `uninstall.sh` 를 먼저 호출하는데, 이때 *현재 세션이 사용하는* `.harness-kit/hooks/*` 가 사라졌다 다시 깔립니다. 본 spec 실행 도중 Claude Code 가 hook 을 trigger 하면 (예: 중간에 Edit 호출) **transient 한 hook 부재 상태**에서 fail-open 동작이 일어남. spec 은 "워킹트리 변경이 없어야 함" 만 경고하고, *update.sh 실행 중에는 다른 도구 호출을 하지 말 것* 이라는 운영 가드를 누락. 또한 `pre-commit.sh` 는 `.git/hooks/pre-commit` 으로 *재설치* 되므로 본 PR 의 최종 commit 시점에는 새 pre-commit 이 동작 — 만약 새 pre-commit 의 secret 검사가 `.env.*.example` 의 placeholder 토큰을 false positive 로 잡으면 commit 차단됨. **placeholder 가 secret pattern 을 trigger 하지 않는다는 검증** 이 DoD 에 없음.

- **`check-diff-size.sh` 가 본 commit 을 차단할 가능성**: 임계치 500줄 (기본값). agent.md 만 +48줄, CLAUDE.fragment.md 는 26→305줄 (≈+280), 신규 7개 파일 (hooks 1 + bin 3 + 루트 4 — 합쳐 수백 줄 가능), settings.json 재생성 등 — **합산 1000줄 초과 가능성이 매우 높음**. spec 은 "단일 chore commit" 을 못 박았지만, hook 가드가 경고(warn)인지 차단(block)인지 plan/spec 에 명시 없음. `hook_resolve_mode "DIFF_SIZE" "warn"` 로 warn 모드 — 통과는 하지만 노이즈. *임계치 일시 우회 (`HARNESS_DIFF_MAX_LINES=...`) 결정* 이 누락.

- **`.gitattributes` 의 `*.sh text eol=lf` 가 Windows 환경에서 본 저장소 자체에 미치는 영향**: install.sh 가 신규 `*.sh` 를 만들 때 (CRLF 로 쓸 가능성) git 이 normalize 하는 과정에서 LF 로 강제 — 결과적으로 diff 가 깔끔. 하지만 *기존 설치본을 uninstall 후 재install 할 때* 의 race 에서 부분적으로 CRLF 가 끼면 한 commit 안에 EOL 변경이 섞일 수 있음. **본 PR 실행 환경(Windows Git Bash)** 가 명시되지 않음. 1차 타깃이 macOS 이긴 하나, 본 도그푸딩은 *Windows 에서* 실행됨.

- **gh PR 작성 시 fork 환경 가드**: spec 은 "fork(LeoYoon7) main 만 대상" 이라 못박았지만 *어떻게* (`gh pr create --repo LeoYoon7/harness-kit --base main`) 인지 명시 없음. `hk-pr-gh` 가 origin 을 잘못 추정해 upstream(Changsik00) 로 PR 을 쏠 가능성. **PR base/head 명시적 검증 단계** 누락.

- **본 spec 자체의 산출물 (`specs/spec-x-dogfood-sync/*`) 이 update.sh 실행 후 어떻게 보존되는지**: update.sh 는 `specs/` 를 건드리지 않으나, 본 spec 작성 도중 plan accept 가 안 된 상태에서 워킹트리에 미커밋 산출물이 있는 시점에 update.sh 가 도는 시나리오에서 위험. plan 의 "현재 spec 산출물만 변경 중 — update.sh 가 spec 디렉토리는 안 건드림" 은 사실 확인이고 좋지만, **실행 직전에 spec 산출물을 별도 commit 으로 분리** 하는 절차가 task 순서에 명시되지 않으면 sync diff 와 spec 작성 diff 가 섞일 위험.

- **`.claude/state/current.json` 의 초기값 정의 부재**: spec FR3·plan §[NEW] 둘 다 "부트스트랩 한다" 만 적고 *어떤 초기값* 인지 명시 없음. install.sh 의 fresh 초기값을 그대로 쓰는지, 본 세션에서 임시로 만든 값이 있는지 (있다면 그것을 보존하는지) 모호. 본 spec 의 *직접 동기* 가 state 부재였으므로 초기값 정책은 핵심.

### 모순

- **FR3 "dummy 산출물은 삭제·복원"** vs **plan §검증 4 "queue.md / state 복원"**: dummy specx new 가 무엇을 *건드리는지* 가 정의 안 됨. queue.md 는 본 저장소에 존재하는가? state 는 부트스트랩 직후 값으로 복원? 아니면 dummy 직전 값? — *복원 기준점* 이 모호.

- **NFR1 "state 보존" vs "본 저장소엔 state 가 없으니 사실상 fresh 설치"**: 본 PR 실행 전에 본 세션에서 *임시 state* 를 수동 부트스트랩한 것으로 보임 (plan §Branch Strategy 의 "sdd specx new 가 state 부재로 실패하여 수동 git checkout -b 로 부트스트랩"). 이 임시 state 가 update.sh 실행 시점에 *존재* 한다면 보존 대상이고, *부재* 라면 install 이 신규 작성. 본 spec 은 둘 중 어느 상태에서 update.sh 가 도는지 단정하지 못함.

### 과잉 설계

- **smoke 검증의 dummy slug 정리 절차**: `sdd specx new __test_dogfood_sync` → 즉시 삭제 → 복원. 절차 자체는 합리적이나 **dummy 가 만들 수 있는 부수효과** (queue.md 변경, state 갱신, 디렉토리 생성, git stash 흔적 등) 를 청소하는 것이 본 PR 가치에 비해 무거움. 더 가벼운 검증으로 충분: `bash .harness-kit/bin/sdd doctor` 가 state 파일 인식 여부만 보고. dummy specx new 까지 가는 것은 *integration test* 성격인데 spec frontmatter 는 `Integration Test Required: no`. 일관성 결여.

- **회귀 테스트 2개**: `test-gitignore-idempotent.sh` 와 `test-install-layout.sh` 는 이미 `spec-x-notify-channels` 에서 PASS 한 것. 본 PR 은 *키트 코드 변경 없이* update.sh 만 호출. 즉 본 PR 이 회귀를 *유발할 가능성이 0* — 그럼에도 DoD 에 묶는 것은 ceremony. *키트 코드 변경이 없음* 을 명시하는 가드로 충분.

### 모호함

- **"drift 표의 모든 항목 해소"의 판정 기준**: spec 표의 항목 중 `.claude/settings.json` 은 표에 명시 없지만 plan §Proposed Changes §[MODIFY] 에 등장. "표의 모든 항목" 인지 "plan 의 모든 항목" 인지 — 판정 모집합이 둘 사이에서 흔들림.

- **`diff -rq sources/governance .harness-kit/agent` 빈 출력**: `.harness-kit/agent/` 와 `sources/governance/` 의 구조가 *정말 1:1* 인가? `sources/governance/` 에는 constitution/agent/align 외에 다른 파일이 있을 수 있고, `.harness-kit/agent/` 에는 templates 가 들어갈 수도 있음 (실제로 plan §검증 3 은 `sources/templates` 와 `.harness-kit/agent/templates` 를 비교). install.sh 가 매핑하는 *정확한 1:1 관계* 가 명시되지 않으면 `diff -rq` 가 false positive/negative 를 낼 수 있음.

- **"실제 .env.* 파일은 건드리지 않는다 (없으면 미생성, 있으면 보존)"** — 본 저장소엔 미존재이므로 미생성 분기만 검증됨. spec FR5 의 단언이 *본 PR 에서 실제로 검증되는 부분은 절반* 임이 모호하게 표현됨 (plan 에서 보완은 하나 spec 본문은 그대로).

## 3. 대안 제안

### 대안 A: 카테고리별 분할 commit (governance / dispatcher / runtime hooks / runtime root)

- **아이디어**: update.sh 의 결과 diff 를 `git add -p` 또는 카테고리 path 선택으로 4~5개 chore commit 으로 분할. 각 commit 은 (a) governance(`.harness-kit/agent/*`, `CLAUDE.fragment.md`) (b) commands(`.claude/commands/*`) (c) runtime hooks/bin (`.harness-kit/hooks|bin/*`) (d) 루트 런처/env (`telegram.sh`, `discord.sh`, `.env.*.example`) (e) state/gitignore/settings 분리.
- **장점**:
  - 리뷰 시 카테고리별 가독성. PR 본문 "key change point" 가 commit 단위로 1:1.
  - 회귀 시 *어느 카테고리* 가 원인인지 git bisect 용이.
  - `check-diff-size.sh` 임계치 한 번에 위반 방지.
- **단점**:
  - update.sh 한 번에 모든 게 적용되므로 분할이 *인공적* (의미 단위가 sources@v0.13.6 하나).
  - 분할 작업 자체가 task 수를 늘려 ceremony 증가.
  - 부분 revert 시 카테고리 사이의 의존성 (예: bin/notify.sh 없이 hooks/notify-on-input-wait.sh 만 남으면 동작 안 함) 이 위험.

### 대안 B: 본 sync + 재발 방지 메커니즘을 같은 PR 에 포함

- **아이디어**: `doctor.sh` 에 sources vs installed drift 경고 1개를 본 PR 에서 함께 추가. 다음번 sync drift 누적을 자동 가시화.
- **장점**:
  - 본 사건 (drift 누적 → 사고) 의 *근본 원인* 을 같은 PR 에서 닫음. GitOps 식 "drift 가시화" 원칙 충족.
  - 후속 spec stub 을 만들 필요 없음.
- **단점**:
  - spec 의 "Out of Scope" 를 깸. spec 범위 부풀림.
  - 본 PR 의 의미가 "sync" 단일에서 "sync + 새 기능" 으로 흐려져 commit 분리 압박.
  - doctor 가 키트 자체 작업 흐름에 영향 (false positive 시 작업 노이즈) — 별도 검토 가치가 있어 *다른 spec 에서 신중히 설계* 가 옳음.

### 대안 C: FF (Fast-Forward) 강등 — spec ceremony 자체 제거

- **아이디어**: 본 작업은 "도구 1번 호출 + 검증" 이므로 spec/plan/task 산출물 없이 `spec-x-dogfood-sync` 브랜치에서 직접 update.sh 호출 → walkthrough 1장 → PR. CLAUDE.fragment.md 의 **phase-FF 패턴** 에 정확히 들어맞음 ("1-2 commit, 단일 파일, 가역적" 는 어긋나지만 "도구 1번 호출" 단일성은 부합).
- **장점**:
  - ceremony-over-work 안티패턴 방지 (CLAUDE.fragment.md 명시).
  - 본 spec 처럼 spec/plan/task/critique/walkthrough/pr_description 5종 산출물 작성 부담 제거.
- **단점**:
  - 본 작업은 변경량이 큼 (수백~수천 줄) — FF 조건 "1-2 commit, 가역적" 의 *가역성* 은 OK 지만 *크기* 가 어긋남.
  - 본 PR 이 drift 표·근본원인·후속 ideabox 등 *문서화 가치* 가 큰 사건이라 walkthrough 만으로는 부족할 수 있음. spec.md 의 drift 표 자체가 추후 ADR 재료.
  - 사용자가 spec-x 로 이미 진행 중이라 중도 강등은 작업 중단 비용.

### 대안 D: link 모델 도입 — 본 저장소 한정 sources/ 심볼릭

- **아이디어**: 본 저장소(self-hosting) 에 한해 `.harness-kit/agent/agent.md` → `../../sources/governance/agent.md` symlink. drift 가 원천적으로 발생 안 함.
- **장점**:
  - 미래 drift 0. 도그푸딩이 *진짜 한 소스* 가 됨.
- **단점**:
  - 키트의 *복사 모델* 정책을 self-hosting 만 예외 처리 → 일관성 깨짐. 다른 프로젝트는 여전히 snapshot, 본 저장소만 link → 본 저장소에서 잘 도는데 외부에서 깨지는 *도그푸딩 의미 상실*.
  - Windows symlink 권한 이슈.
  - install.sh 가 symlink 를 인식·보존하도록 복잡도 추가.

## 권장안

**현재 spec 유지 + 다음 4개 보완**.

1. **요구사항 누락 #1·#2 반영**: spec FR 에 (a) "update.sh 실행 중 동시 도구 호출 금지", (b) ".env.*.example placeholder 가 check-secrets 패턴에 걸리지 않음 검증", (c) "check-diff-size 임계치 일시 우회 결정 (warn 모드라 통과하지만 PR 본문에 기록)" 추가.
2. **gh PR base/head 명시**: DoD 에 `gh pr create --repo LeoYoon7/harness-kit --base main --head LeoYoon7:spec-x-dogfood-sync` 형태 명시.
3. **smoke 검증 축소**: dummy specx new 대신 `sdd doctor` 가 state 파일을 인식해 오류 없이 종료하는 것으로 갈음. dummy 정리 절차 제거.
4. **재발 방지 후속 작업 보장 강화**: walkthrough ideabox 한 줄 캡처를 *별도 backlog 항목* 으로 즉시 등록 (본 PR 머지 직후 처리 큐). 대안 B 의 *동일 PR 포함* 은 거부 (범위 확대 비용 > 이득).

대안 A·B·D 는 거부. C(FF 강등)는 *이미 spec 작성이 진행된 시점* 이라 매몰비용 회수가 어렵고, 본 사건의 문서화 가치(drift 표·근본원인) 가 walkthrough 만으로는 손실됨.

## 4. ADR 후보 추출

- [x] **후보 발견**: `dogfood-sync-policy` — type: **convention** — 이유: "본 저장소(harness-kit self-host) 에서 sources → installed 동기화는 *키트 자체 `update.sh`* 가 SSOT 다. 수동 cp / symlink / 직접 편집 금지" 는 cross-spec / long-lived 결정. 본 spec 이후 모든 도그푸딩 sync 작업의 *판단 기준* 이 됨. 동시에 "self-hosting 에 link 모델을 도입하지 않는다 (도그푸딩 의미 보존)" 라는 *부정 결정* 도 함께 박아두는 것이 가치 있음.

- [x] **후보 발견 (선택적, 약함)**: `drift-visibility-deferred` — type: **tradeoff** — 이유: "drift 가시화 (doctor 경고 / CI check) 를 본 sync PR 에서 의도적으로 분리한다" 결정. 6개월 안에 후속 spec 에서 뒤집힐 가능성이 있어 *tradeoff* 로 분류. 본 spec 이 OOS 명시한 결정의 이유 (PR 부풀림 방지) 를 미래에 기억하기 위한 trace. 다만 약한 후보 — convention ADR 안의 *Constraints* 섹션에 한 줄로 흡수해도 충분.
