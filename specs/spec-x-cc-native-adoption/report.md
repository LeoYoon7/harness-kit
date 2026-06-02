# Research Report: Claude Code 네이티브 기능의 harness-kit 도입 적합도

> 본 문서는 `spec.md`(조사 정의)에 대한 **Research Report**다 (agent.md §9.2). 17개 고유 네이티브 기능을 실제 harness-kit 상태 기준으로 재검증하고, 단계별 도입 로드맵과 기능별 Go/No-Go 를 제시한다.

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec** | `spec-x-cc-native-adoption` |
| **타입** | Research |
| **작성일** | 2026-06-02 |
| **입력 문서** | `D:\tmp\claude-code-기능-활용-가이드.md`, `D:\tmp\claude-code-harness-kit-compatibility.md` |
| **검증 기준** | https://code.claude.com/docs/en/commands (문서 측 2026-06-02 검증 주장) + 실제 harness-kit 소스 |

## 1. 조사 배경 · 목적

harness-kit 은 Claude Code 전용 SDD 거버넌스 부트스트랩이다. Claude Code 네이티브에는 슬래시 명령 23개(alias 포함, 고유 기능 17개)가 존재하나, 이를 harness-kit 거버넌스에 도입할 방침이 미정이었다.

외부 검토 문서 2종이 4등급 적합도를 제시했으나 **메모리 기반 가정으로 작성되어 실제 구현과 최소 4건 어긋난다**(§3). 본 조사는 그 어긋남을 교정하고, 17개 기능을 실제 상태 기준으로 재검증하여 실행 가능한 도입 로드맵을 산출하는 것을 목적으로 한다.

**분석 단위**: 고유 기능 17개 (alias 통합). `/bg`=`/background`, `/ultrareview`=`/code-review ultra`, `/fork`=`/branch`, `/checkpoint`·`/undo`=`/rewind` 는 같은 기능의 별칭이므로 하나로 묶는다.

## 2. 분석 프레임 — 7개 충돌 축

문서 2의 4등급을 그대로 계승하지 않고, 각 기능을 아래 7개 축으로 실제 harness-kit 상태에 비추어 재평가한다. "왜 그 등급인가"를 축으로 추적할 수 있게 한다.

| 축 | 질문 | 근거 |
|:---:|---|---|
| **A. 게이트** | Plan Accept(§5.2·5.3) / §8.5 Choice Presentation 결정 지점을 건너뛰는가? | constitution §5, agent.md §8.5 |
| **B. 알림** | 2계층 알림(`notify.sh` dispatcher, `notify-on-input-wait.sh` hook, 양방향 §10)이 정상 발화하는가? | CLAUDE.fragment §1~§10 |
| **C. 멀티모델** | phase별 모델 지정(main=Opus / 구현=Sonnet / 리뷰=Opus)을 override 하는가? | agent.md §6.6 |
| **D. PR 플랫폼** | GitHub(`/hk-pr-gh`, 도그푸딩) / Bitbucket(`/hk-pr-bb`, target) 흐름과 충돌하는가? | constitution §5.7, 두 시점 원칙 |
| **E. 세션/config** | 추가 세션·worktree 가 공유 글로벌 config 병렬 제약에 걸리는가? | 멀티세션 제약 (운영 메모리) |
| **F. git hook** | check-branch / check-plan-accept / check-test-passed 등 게이트와 어긋나는가? | sources/hooks/* |
| **G. 기존 자산** | 이미 있는 `/hk-*` 자산(특히 `/hk-gemini-review`)·AUQ 금지 정책과 중복/충돌하는가? | agent.md §6.3, 메모리 |
| **H. 사용 제한** | 플랜·사용량·크레딧·백엔드 제약이 *가용성*을 막는가? | 입력 문서 + CC 플랜 정책 |

> **두 시점 주의** (CLAUDE.md): 충돌이 *키트 원본 작업 시점*의 것인지, *도그푸딩/적용 결과 시점*의 것인지 구분하여 표기한다. 특히 축 D(PR 플랫폼)는 시점에 따라 충돌 양상이 다르다 — 본 repo 도그푸딩은 GitHub, target(nextmarket-api)은 Bitbucket.

## 3. 문서 가정 교정 (4건)

외부 문서 2가 전제한 harness-kit 구성 중, 실제 구현과 어긋나 **도입 판단을 바꾸는** 4건을 교정한다.

### 3.1 알림 구조 — `notify-telegram.sh` 단일 ❌ → `notify.sh` dispatcher 멀티채널 ✅

- **문서 가정**: 알림은 `notify-telegram.sh` 단일 스크립트.
- **실제**: `notify.sh`(dispatcher) + `notify-telegram.sh` / `notify-discord.sh` 멀티채널 + 양방향 응답 인식(CLAUDE.fragment §10) + 채널별 마크다운 포맷터(spec-x-notify-channel-formatter). `notify-on-input-wait.sh` hook 은 별도로 input-wait 이벤트에 발화.
- **판단 영향**: 문서가 우려한 "알림 훅 직격"(축 B)은 이미 더 정교하게 통제되고 있다. 그러나 *세션이 메인 밖으로 빠지는* 기능(`/background` 등)에서 hook 발화 타이밍이 어긋날 가능성은 여전히 유효 — 단, 실측 대상이지 선험적 ⛔ 아님.

### 3.2 PR 플랫폼 — Bitbucket 전제 ❌ → GitHub(도그푸딩) + Bitbucket(target) 병존 ✅

- **문서 가정**: harness-kit 은 Bitbucket(`/hk-pr-bb`)으로 PR 을 올린다.
- **실제**: `/hk-pr-gh`(GitHub) + `/hk-pr-bb`(Bitbucket) **둘 다** 존재. 본 repo 도그푸딩은 GitHub fork 로 PR. Bitbucket 은 *적용 대상* nextmarket-api 의 스택.
- **판단 영향**: 문서가 "`/batch` 자동 PR = GitHub 전제 → Bitbucket 불일치"로 본 충돌은 **시점에 따라 갈린다**. 키트 자체(GitHub)에서는 `gh` 전제 기능이 오히려 정합적이고, target(Bitbucket)에서만 불일치. 축 D 는 "어느 시점 적용이냐"를 먼저 물어야 한다.

### 3.3 cross-model 리뷰 — "역할 미정" ❌ → `/hk-gemini-review` 이미 통합 ✅

- **문서 가정**: `/code-review ultra` 가 Codex Review 와 역할 중복, "무엇을 정식 리뷰로 둘지" 미정.
- **실제**: 이미 `/hk-gemini-review`(Gemini cross-model)가 ship 게이트의 **권장 리뷰**로 통합됨(agent.md §6.3.8 Code Review Gate: default-run, auditable skip). `/hk-code-review`(Opus same-model)도 별도 존재.
- **판단 영향**: cross-model 리뷰의 역할 분담은 **이미 해결**되었다. native `/code-review ultra`(클라우드 멀티에이전트)는 *대체*가 아니라 ship 직전 *추가 보강* 옵션으로 위치가 분명하다(축 G).

### 3.4 AUQ 정책 — "AskUserQuestion 선호" ❌ → AUQ 절대 금지 ✅

- **문서 가정**: agent.md §8.4 가 AskUserQuestion 사용을 선호한다.
- **실제**: AUQ 절대 금지로 정책 전환됨(spec-x-notify-bidirectional-policy + 메모리 [[feedback-no-auq-ever]]). 모든 의사 확인은 텍스트 게이트로 통일(multi-device 응답 지원).
- **판단 영향**: 자율 기능(`/goal`, `/effort ultracode`)이 "§8.5 결정 지점을 건너뛰는가"(축 A)를 평가할 때, 기준은 **AUQ 모달이 아니라 텍스트 게이트 보존**이다. 자율 실행이 텍스트 게이트 없이 턴을 넘기면 양방향 알림(§10) 응답 기회를 박탈하므로 충돌 강도가 문서 가정보다 크다.

## 4. 기능별 적합도 분석 (17개 × 7축)

### 4.0 요약 매트릭스

> 등급: ✅ 바로 도입 / ⚠️ 게이트 안쪽에서만 / 🔍 검증 필요 / ⛔ 현 상태 지양 / **N/A 거버넌스 무관(개인 사용, 도입 판단 대상 아님)**. "주요 충돌 축"은 §2 의 A~H. 사용 제한 상세는 §4.5.

| # | 기능 (alias) | 주요 충돌 축 | 재검증 등급 | 판단 |
|---|---|---|:---:|---|
| 1 | `/deep-research` | H(비용) | ✅ | Go — 근거 수집. 사용량 큼이나 현 플랜 가용 |
| 2 | `/workflows` | (없음) | ✅ | Go — 워크플로 관찰 |
| 3 | `/copy` | (없음) | ✅ | Go — 산출물 이관 |
| 4 | `/rewind` (`/checkpoint`·`/undo`) | F | ✅\* | Go — 코드 롤백만 git 상태 확인 후 |
| 5 | `/team-onboarding` | G(순기능), H | ✅ | Go — 공유 링크 Pro/Max/Team/Ent 한정 |
| 6 | `/powerup` | — | **N/A** | 거버넌스 무관 — 개인 학습, 도입 대상 아님 |
| 7 | `/radio` | H(백엔드) | **N/A** | 거버넌스 무관 — BGM. Bedrock·Vertex·Foundry 미지원 |
| 8 | `/goal` | **A**, C | ⚠️ | 조건부 — 게이트 보존 조건 하 |
| 9 | `/effort ultracode` | **C**, A, H | ⚠️ | 조건부 — 구현 phase 한정. 토큰 소모 큼 |
| 10 | `/fewer-permission-prompts` | F, 거버넌스 | ⚠️ | 조건부 — 검토 커밋 |
| 11 | `/code-review ultra` (`/ultrareview`) | G, D, **H** | ⚠️ | 조건부 — ship 보강. 무료 3회 후 크레딧 |
| 11b | `/code-review` (기본형) | G(보완) | ⚠️ | **보조** — effort/`--fix`/`--comment` 는 hk-code-review 에 없는 고유 기능 |
| 12 | `/background` (`/bg`) | **B**, E, H | 🔍 | 검증 후 — 알림 타이밍 + 사용량(확인 필요) |
| 13 | `/batch` | **D**, E, B, H | 🔍→⛔근접 | 보류 — 마찰 최대 + 사용량 |
| 14 | `/branch` (`/fork`) | E, A, F, C | 🔍 | 검증 후 — 상태 승계 불명 |
| 15 | `/ultraplan` | A, C, H | 🔍 | 조건부 — 복귀 후 재게이팅. 웹 실행(플랜 확인) |
| 16 | `/btw` | A(Idea Gate) | ✅\* | Go — 정보성 질문만, 아이디어는 Idea Capture |
| 17 | 스킬 시스템 (`/skills`) | G | ⚠️ | 조건부 — 컨텍스트 비용 3순위 |

(\* = 조건부 ✅. **N/A** = 거버넌스 무관, 개인 사용 — 도입 판단 대상 아님)

### 4.1 ✅군 — 바로 도입 (5종) + 거버넌스 무관 (2종)

코드/state 변경이 없어 게이트(A)·hook(F)와 직교한다. 멀티채널 알림(교정 3.1)이 메인 세션 안에서 정상 동작하므로 축 B 도 무영향. 단 클라우드/웹 기능(`/deep-research`)은 사용량 제약이 있을 수 있다(축 H, §4.5).

- **`/deep-research`** — 웹 fan-out + 인용 리포트. `/hk-align` 전후, spec 작성 시 근거 수집에 보완적이며 기존 자산과 중복 없음(축 G). 결과를 spec.md 에 첨부해 `/hk-spec-critique` 로 넘기는 흐름 권장. *유의*: 웹 fan-out 은 Windows 네트워크/인증 정상 필요(가로지르는 리스크 6).
- **`/workflows`** — `/deep-research`·`/batch` 워크플로의 watch/pause/resume 관찰 뷰. 무해.
- **`/copy [N]`** — 직전 응답을 클립보드/파일로. spec·plan·리뷰 결과를 문서/PR 로 이관할 때 유용(SSH 시 `w` 파일 저장).
- **`/rewind`** — 체크포인트 롤백. **축 F 단서**: harness-kit 이 git hook 으로 커밋을 관리하므로, `/rewind` 의 *code-only 롤백*이 git 상태와 어긋날 수 있다. → conversation 롤백 위주로 쓰고, 코드 롤백은 `git status` 확인 후. 그래서 조건부 ✅.
- **`/team-onboarding`** — 최근 30일 세션·커맨드·MCP 사용 분석 → 온보딩 가이드. **축 G 순기능**: `/hk-*` 사용 패턴이 그대로 반영돼 SDD 워크플로 전파에 오히려 유리. *유의*: 클라우드 공유 링크는 Pro/Max/Team/Enterprise 한정.
- **`/powerup` · `/radio` — 거버넌스 무관 (N/A)** — 학습 레슨 / lo-fi BGM 으로 SDD 거버넌스·개발 워크플로와 무관하다. **"도입/미도입"을 논할 대상이 아니다** — 막을 이유도 권장할 이유도 없는 개인 사용 항목(사용자 피드백 반영). 따라서 도입 로드맵(§5)에서 제외한다. `/radio` 는 Bedrock·Vertex·Foundry 백엔드 미지원(축 H).

### 4.2 ⚠️군 — 게이트 안쪽에서만 (4종 + 1)

- **`/goal [condition]`** — 조건 충족까지 턴을 넘어 자율 지속. **축 A 가 핵심 충돌**: Plan Accept·§8.5 결정 지점을 건너뛴다. 교정 3.4 적용 — 기준은 AUQ 모달이 아니라 *텍스트 게이트* 보존이며, 자율 실행이 텍스트 게이트 없이 진행하면 양방향 알림(§10) 응답 기회를 박탈한다(충돌 강도가 문서 가정보다 큼). 축 C: `/goal` 자체 모델 동작이 phase별 지정과 충돌 가능.
  - **조건**: plan-accept 통과한 *단일 spec/phase 의 acceptance criteria* 를 조건으로 삼고, 조건문에 "각 게이트에서 멈추고 보고"를 명시해 §8.5 지점을 보존. phase 경계를 넘기지 않는다.
- **`/effort ultracode`** — xhigh 추론 + 자동 워크플로 오케스트레이션. **축 C 가 핵심**: 멀티모델 전략의 phase별 모델 지정을 override 할 수 있다. 축 A: 자동 오케스트레이션이 게이트를 건너뛸 수 있음.
  - **조건**: spec·plan 이 확정된 *구현 phase 내부에서만*. 전체 프로젝트 통째 적용은 ⛔. 토큰 소모 큼.
- **`/fewer-permission-prompts`** — 트랜스크립트 스캔 → `.claude/settings.json` allowlist 자동 추가. **축 F/거버넌스**: harness-kit 의 통제된 권한 자세를 약화. 메모리 [[claude-tool-permission-guards]] 의 `.env*`/`~/.ssh` 가드를 자동 allowlist 가 우회하면 안 됨.
  - **조건**: 생성된 allowlist 를 *커밋 전 검토*(spec-critique 처럼). 읽기 전용 위주·위험 동작 미포함 확인.
- **`/code-review ultra`** — 클라우드 멀티에이전트 리뷰. 교정 3.3 적용 — cross-model 역할 분담은 이미 `/hk-gemini-review` 로 해결됨. ultra 는 *대체가 아니라* 중요 PR 의 ship 직전 *추가 보강*. 축 D: 클라우드 실행 + `--comment` 는 GitHub PR 전제(도그푸딩 GitHub OK / target Bitbucket 불일치).
  - **조건**: 중요 PR 의 `/hk-ship`·`/hk-phase-ship` 직전 1회. 무료 3회 후 usage credits.
- **`/code-review` (기본형, 11b) — 보조 도입 (정정)** — **당초 `/hk-code-review` 와 "중복 → 도입 불요"로 판단했으나, 실제 구현(`sources/commands/hk-code-review.md`) 확인 결과 역할이 다르다(사용자 지적 반영).**
  - `/hk-code-review` 고유: *spec.md 대비 구현 검증*(Functional Req / DoD 충족 / scope creep) + *테스트 커버리지* 관점, 결과를 `code-review.md` SDD 산출물로 저장, Opus 서브에이전트 독립 컨텍스트.
  - native `/code-review` 고유: *effort level*(low~max/ultra) 조절, **`--fix`**(working tree 자동 수정), **`--comment`**(PR 인라인 코멘트). spec 인식 없음.
  - → **중복이 아니라 보완**. native `/code-review` 는 effort 조절·자동 정리(`--fix`)가 필요한 *수시 리뷰*에 보조 가치. 단 ship 게이트의 *정식 리뷰*는 여전히 `/hk-gemini-review`(cross-model) + `/hk-code-review`(spec 대비). 축 D: `--comment` 는 GitHub PR 전제(target Bitbucket 불일치).

### 4.3 🔍군 — 검증 필요 (4종)

세션이 메인 인터랙티브 밖으로 빠지거나 공유 글로벌 config 병렬 제약에 걸릴 수 있어, *실측 전엔 도입 판단 보류*.

- **`/background` (`/bg`)** — 세션을 백그라운드 에이전트로 분리. **축 B 직격**: `notify-on-input-wait.sh` 는 input-wait 이벤트에 발화하는데, 백그라운드 세션은 발화 타이밍/대상이 달라져 알림 누락·오발화 가능. 교정 3.1 — 멀티채널 dispatcher 라도 *hook 발화 타이밍*은 별개 문제라 실측 필요. 축 E: 추가 세션 → 공유 config 병렬 제약(Telegram Channels 건) 동일 한계 가능. → **검증 테스트 1**.
- **`/batch`** — 5~30 worktree 서브에이전트가 단위별 PR 자동 생성. **마찰 최대**. 축 D: 자동 PR = `gh` 전제 → 도그푸딩(GitHub) 정합 / target(Bitbucket) 불일치(교정 3.2). 축 E: 다수 worktree → 공유 config 한계. 축 B: 다수 서브에이전트의 `notify.sh` 중복/누락 양상 불명. → 자동 PR off 또는 worktree diff 만 받아 `/hk-pr-*` 로 별도 올리는 경로. **검증 테스트 2·3·5** 통과 전까지 사실상 ⛔ 근접.
- **`/branch` (`/fork`)** — 컨텍스트 유지 분기. 축 E: 추가 세션 → 공유 config 제약. 축 A/F/C: 포크 세션이 hook·§8.5·멀티모델 상태를 온전히 승계하는지 불명. `CLAUDE_CODE_FORK_SUBAGENT` 설정 시 동작이 또 달라짐(서브에이전트 포크). → **검증 테스트 4**.
- **`/ultraplan`** — 웹 핸드오프로 계획 수립. 축 A/C: 계획이 harness-kit 훅·멀티모델·§8.5 *바깥*에서 수립됨. → 복귀한 플랜을 반드시 `/hk-plan-accept` 로 재게이팅하면 정합성 회복(이 조건이면 ⚠️로 승격 가능). Windows 네트워크/인증 의존.

### 4.4 등급외 2종 (문서 2 미수록 → 본 조사 신규 평가)

- **`/btw`** — 흐름을 안 깨는 짧은 질문(히스토리 미축적). state 변경 없어 축 A/B 무해하나, **§5.5 Idea Capture Gate 와 상호작용**: `/btw` 로 새 작업 아이디어를 띄우면 Icebox 기록을 우회할 수 있다. → 순수 정보성 질문에만 사용하고, 새 작업 아이디어는 정식 Idea Capture 로. 조건부 ✅.
- **스킬 시스템 (`/skills`, `/reload-skills`)** — 반복 프로세스를 `.claude/skills/` 에 자산화. **축 G**: harness-kit 의 `/hk-*` 자산화 철학과 정합하나, 컨텍스트 비용 우선순위(CLAUDE.md: bash > slash > skill > MCP)에서 skill 은 3순위. → `/hk-*` 로 표준화된 SDD 워크플로와 *중복되지 않는* 개인 반복 작업에 한정. 거버넌스 워크플로는 `/hk-*` 유지. 조건부 ⚠️.

### 4.5 사용 제한 매트릭스 (축 H)

> 플랜·사용량·크레딧·백엔드 제약. 정확한 한도는 플랜·버전에 따라 변동하므로 *"확인 필요"* 항목은 세션의 `/help`·플랜 설정이 최종 기준이다. 클라우드/유료 기능은 무료·Pro 플랜에서 가용성이 제한될 수 있어 도입 판단(특히 "즉시 Go")에 단서를 단다.

| 기능 | 제약 유형 | 상세 | 현 환경(사용자 플랜) |
|---|---|---|---|
| `/code-review ultra` | **크레딧 (가용성)** | Pro·Max 무료 3회/월, 이후 usage credits | **유일한 실질 제약** |
| `/team-onboarding` | 부가기능 플랜 | *공유 링크*만 Pro·Max·Team·Ent 한정 (가이드 생성은 무관) | 가용 (공유 링크 불요 시 무관) |
| `/radio` | 배포 백엔드 | Bedrock·Vertex·Foundry 미지원 | 무관 (해당 백엔드 미사용 시) |
| `/deep-research`·`/ultraplan`·`/effort ultracode`·`/background`·`/batch` | 사용량/비용 | 토큰·세션 소모 큼 — 가용성 *차단* 아님 | 가용 — 비용 차원만 |

**판단 영향 (현 환경 실측 — 사용자 피드백)**: 사용자 플랜에서 *실질 가용성 제약*은 `/code-review ultra` 크레딧(무료 3회/월)뿐이다. 나머지는 사용량·비용(토큰) 차원이지 가용성 *차단*이 아니므로 도입 등급을 제약하지 않는다 — `/code-review ultra` 의 크레딧만 "중요 PR 1회"로 좁히는 조건의 근거다. **단 harness-kit 은 다양한 플랜에 배포되는 키트이므로, 하위 플랜(무료/Pro) 대상 배포 시 클라우드/Workflow 기능 가용성은 재확인이 필요하다(중립성).** 정확한 플랜별 한도는 세션 `/help` 가 최종 기준.


## 5. 단계별 도입 로드맵

문서 2의 4단계 로드맵을 실제 harness-kit 상태로 교정한 결과다. 교정점은 각 단계에 표기한다.

### 1단계 — 즉시 도입 (별도 spec 불필요, 운영 관행으로 채택)

거버넌스와 직교하고 코드/state 변경이 없는 6종. 도입에 spec 이 필요 없으며, *세션 운영 관행*으로 바로 쓸 수 있다. (`/powerup`·`/radio` 는 거버넌스 무관이라 도입 논의 밖 — 개인 사용.)

- `/deep-research`, `/workflows`, `/copy`, `/rewind`, `/team-onboarding`, `/btw`
- **(조건 명시) `/rewind`** — 코드 롤백은 `git status` 확인 후, conversation 롤백 위주.
- **(교정 추가) `/btw`** — 정보성 질문 한정. 새 작업 아이디어는 Idea Capture Gate 로.
- **(사용 제한, §4.5) `/deep-research`** 사용량 큼이나 현 플랜 가용(비용 차원), `/team-onboarding`** 공유 링크만 플랜 한정 — 가이드 생성은 무관.

### 2단계 — 게이트 통합 후 (정책 spec 1개로 묶음 권장)

자율성·권한·모델을 건드려 *조건부 도입*이 필요한 5종. 아래를 **하나의 도입 spec**(`native-feature-adoption-policy` ADR + agent.md 가이드 1절)으로 묶으면 ceremony 가 절감된다.

- `/goal` — 조건 = 단일 spec/phase 의 acceptance criteria + "각 게이트에서 멈추고 보고" 명시. phase 경계 불가침.
- `/effort ultracode` — 구현 phase 내부 한정. 전체 프로젝트 ⛔.
- `/fewer-permission-prompts` — 생성 allowlist 커밋 전 검토. `.env*`/`~/.ssh` 가드 우회 금지.
- `/code-review ultra` — 중요 PR 의 ship 직전 보강(무료 3회 후 유료). **(교정)** 역할은 이미 `/hk-gemini-review` 로 정의됨 — *대체 아닌 보강*.
- **(정정 추가) `/code-review` 기본형** — `/hk-code-review` 와 중복이 아닌 *보완*(effort/`--fix`/`--comment` 고유, §4.2). 수시 정리·자동수정용 보조 도구.
- **(교정 추가) 스킬 시스템** — `/hk-*` 와 중복 안 되는 개인 반복 작업 한정. 컨텍스트 비용 3순위 인지.

### 3단계 — 검증 테스트 통과 후

세션 라이프사이클/공유 config 실측이 선행되어야 하는 3종. 실측은 별도 검증 spec.

- `/background` — 검증: 백그라운드 중 input-wait 알림 도달 여부(테스트 1).
- `/branch` — 검증: 포크 세션의 hook·§8.5·멀티모델 상태 승계(테스트 4).
- `/ultraplan` — **(교정)** 복귀 플랜을 `/hk-plan-accept` 로 재게이팅하는 조건이면 2단계(⚠️)로 승격 가능. 그 전엔 3단계.

### 보류 / 도입 불요

- **`/batch` — 보류** — Bitbucket PR 자동생성 정합성(target) + worktree 병렬·알림 한계(테스트 2·3·5) 해결 전까지. 도그푸딩(GitHub)에선 자동 PR 이 정합하나, *키트가 배포되는 target 이 Bitbucket* 이므로 키트 차원의 권장은 보류.
- **`/code-review` (기본형) → 2단계로 이동(보조)** — *정정*: 중복이 아니라 보완(effort/`--fix`/`--comment` 고유, §4.2). "도입 불요" 판단 철회.

### 문서 2 로드맵과의 차이 (교정 요약)

| 항목 | 문서 2 | 본 조사 (교정) | 근거 |
|---|---|---|---|
| `/code-review ultra` 역할 | "Codex 와 중복, 정의 필요" | 보강으로 위치 확정 | 교정 3.3 (`/hk-gemini-review` 기존 통합) |
| `/code-review` 기본형 | 미분리 | **보조 도입(보완)** — *정정* | 실제 구현 확인 (§4.2) |
| `/powerup`·`/radio` | ✅ 도입 | **N/A 거버넌스 무관** — *정정* | 개인 사용, 도입 논의 밖 (사용자 피드백) |
| 사용 제한 차원 | 산발 언급 | **축 H + §4.5 매트릭스** 신설 | 클라우드/유료 가용성 |
| `/ultraplan` 단계 | 3단계 고정 | 재게이팅 조건 시 2단계 | 축 A 회복 경로 |
| 스킬 시스템 | 미분류 | 2단계 조건부 | 축 G + 컨텍스트 비용 |
| `/btw` | 미분류 | 1단계 (Idea Gate 주의) | §5.5 상호작용 |
| `/batch` PR 충돌 | "Bitbucket 불일치" 단정 | *시점 분기* (도그푸딩 GitHub 정합 / target Bitbucket 불일치) | 교정 3.2 |

## 6. 결론 — Go/No-Go 종합

**핵심 판단**: **6종 즉시 Go**(거버넌스 직교), **7종 조건부 Go**(게이트 보존 조건 명문화 필요), **`/background`·`/branch` 2종 검증 후 결정**, **`/batch` 1종 보류**, **`/powerup`·`/radio` 2종 거버넌스 무관**(개인 사용, 도입 논의 밖). 현 사용자 플랜에선 `/code-review ultra` 크레딧(무료 3회/월)만 실질 가용성 제약이고 나머지는 비용 차원이다(축 H, §4.5). 단 키트가 하위 플랜에 배포될 때는 클라우드 기능 가용성 재확인이 필요하다.

| 판단 | 기능 | 후속 액션 |
|---|---|---|
| **즉시 Go** (6) | `/deep-research` `/workflows` `/copy` `/rewind` `/team-onboarding` `/btw` | 운영 관행 채택. spec 불필요 (사용량 제한 단서) |
| **조건부 Go** (7) | `/goal` `/effort ultracode` `/fewer-permission-prompts` `/code-review ultra` `/code-review` 기본형 `/ultraplan` 스킬시스템 | 정책 spec 1개로 묶어 게이트 조건 명문화 |
| **검증 후** (2) | `/background` `/branch` | 검증 테스트 spec (실측) 선행 |
| **보류** (1) | `/batch` | Bitbucket 정합 + 병렬/알림 해결 후 재평가 |
| **거버넌스 무관** (2) | `/powerup` `/radio` | 개인 사용 — 도입 판단 대상 아님 |

**두 시점 관점** (CLAUDE.md): `gh` 전제 기능(`/batch` 자동 PR, `/code-review --comment`)은 *도그푸딩 시점*(본 repo, GitHub)에선 정합하나 *적용 결과 시점*(target nextmarket-api, Bitbucket)에선 불일치한다. 키트가 다른 프로젝트에 배포되는 메타 도구임을 고려하면, 이들 기능의 키트 차원 권장은 target 플랫폼 중립성을 우선해 보수적으로 둔다.

**권장 실행 순서**: 1단계(즉시 채택, 무비용) → 2단계 정책 spec 1개(게이트 조건 명문화) → 3단계 검증 spec(실측) → `/batch` 는 Bitbucket 정합성 확보 후. 각 단계는 §7 의 후속 spec 후보로 Icebox 에 등록한다.

## 7. 후속 spec 후보

본 조사 결과를 실행으로 옮기는 후속 작업. `backlog/queue.md` Icebox 에 등록한다(실행 불가 메모, 승격 시 spec 화).

| # | 후속 항목 | 성격 | 대상 기능 | 비고 |
|---|---|---|---|---|
| 1 | **1단계 즉시 채택** | 운영 관행 (spec 불필요) | ✅군 9종 | 별도 spec 없이 세션 관행으로. 필요 시 CLAUDE.md 한 줄 메모만 |
| 2 | **`spec-x-native-feature-adoption-policy`** | 정책 spec (2단계) | `/goal` `/effort ultracode` `/fewer-permission-prompts` `/code-review ultra` `/ultraplan` 스킬 | 게이트 보존 조건을 agent.md 가이드 1절 + ADR(`native-feature-adoption-policy`, convention)로 명문화 |
| 3 | **`spec-x-native-session-feature-verify`** | 검증 spec (3단계) | `/background` `/branch` | 알림 타이밍·상태 승계 실측 (검증 테스트 1·4). Research 성격 |
| 4 | **`/batch` Bitbucket 정합성** | 보류 (조건 해소 시) | `/batch` | target Bitbucket 에서 자동 PR off + worktree diff → `/hk-pr-bb` 경로. 검증 테스트 2·3·5 |

**우선순위 권장**: 2번(정책 spec) > 3번(검증 spec) > 4번(`/batch`, 조건부). 1번은 비용이 0 이라 본 spec 머지 직후 바로 관행화 가능.

---

## 부록 A. 검증 체크리스트 (3단계 spec 으로 이관)

문서 2의 검증 체크리스트 7종 중 본 조사가 *실측 대상*으로 분류한 것. 후속 검증 spec(§7-3)에서 실행한다.

1. `/background` 실행 중 input-wait 알림이 채널로 정상 도착하는가? (축 B)
2. `/batch` 다수 서브에이전트에서 `notify.sh` 중복/누락 양상 (축 B)
3. `/batch` 워커가 공유 글로벌 config 한계에 걸리는가? (축 E)
4. `/branch` 포크 세션이 §8.5·hook·멀티모델 상태를 승계하는가? (`CLAUDE_CODE_FORK_SUBAGENT` 유무별) (축 A/F/C)
5. `gh` 미설정 상태에서 `/batch` 자동 PR 동작/실패 (축 D, Bitbucket 정합)
6. `/effort ultracode` 가 phase별 모델 지정을 덮어쓰는가? (축 C)
7. 클라우드 기능(`/ultraplan`·`/ultrareview`·`/team-onboarding` 링크)이 Windows/네트워크에서 정상 동작하는가? (가로지르는 리스크 6)
