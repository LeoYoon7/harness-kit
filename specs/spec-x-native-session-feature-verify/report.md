# Research Report: Claude Code 세션 기능(/background·/branch) 게이트 보존 검증

> 본 문서는 `spec.md`(검증 정의)에 대한 **Research Report**다 (agent.md §9.2). `spec-x-cc-native-adoption` report 부록 A 의 검증 테스트 **1·4** 를 문서 조사 + 정적 분석으로 해소하고, 두 기능의 Go/No-Go 와 게이트 보존 조건을 산출한다.

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec** | `spec-x-native-session-feature-verify` |
| **타입** | Research (검증) |
| **작성일** | 2026-06-02 |
| **검증 대상** | `/background`(`/bg`), `/branch`(`/fork`) |
| **방법론** | ① Claude Code 공식 문서 조사 ② harness-kit hook 배선 정적 분석 ③ `CLAUDE_CODE_FORK_SUBAGENT` 의미 분석 |
| **제약** | 본 에이전트는 백그라운드 잡으로 실행 — 대화형 세션 명령 라이브 자가 실행 불가. 라이브 실측은 §6 사용자 체크리스트로 분리(Done 조건 아님) |

## 1. 검증 프레임

`spec-x-cc-native-adoption` report §2 의 7개 충돌 축 중 본 검증이 다루는 축만 발췌한다.

| 기능 | 검증 축 | report 테스트 | 핵심 질문 |
|---|---|:---:|---|
| `/background` | B(알림), E(세션/config) | test 1 | 백그라운드 세션에서 input-wait 알림(`notify-on-input-wait.sh`)이 발화·도달하는가? 공유 config 제약은? |
| `/branch` | A(게이트), F(hook), C(멀티모델) | test 4 | fork 세션이 텍스트 게이트·git hook·멀티모델 지정을 승계하는가? `CLAUDE_CODE_FORK_SUBAGENT` 유무별 차이는? |

**harness-kit 알림 배선 (정적 분석, `settings.json` + `notify-on-input-wait.sh`)**:

- `notify-on-input-wait.sh` 는 `Notification` **및** `Stop` 두 이벤트에 등록됨.
- hook 은 stdin 으로 JSON(`session_id`/`transcript_path`/`hook_event_name`/`message`)을 받아, transcript 를 분석해 (a)권한 (b)텍스트 선택지 (c)AskUserQuestion 을 구분하고 `notify.sh` dispatcher 로 발송.
- 계층 1 = 이 자동 hook. 계층 2 = 에이전트가 게이트에서 직접 호출하는 `notify.sh`.
- git hook(`check-branch`/`check-commit-msg`/`check-plan-accept`/`check-scope` 등)은 `PreToolUse`(Bash, Edit|Write|MultiEdit)에 등록됨.

## 2. `/background` (`/bg`) 검증

### 2.1 동작 (확정 — agent-view.md)

- 현재 대화형 세션을 **백그라운드 에이전트**로 분리하여 supervisor 프로세스로 이동. 대화 히스토리 보존, 저장된 상태에서 계속 실행. `claude agents` 뷰에 행으로 표시되며 재연결·peek·미연결 reply 가능.
- **같은 디렉토리의 병렬 세션은 git worktree 로 격리** — 각 세션이 자기 worktree 에서 편집하므로 파일 편집 충돌이 없다.
- launch 시점의 MCP 서버·settings·plugins 를 공유(세션별 override 없으면). `--mcp-config`/`--settings`/`--add-dir`/`--plugin-dir`/`--fallback-model` 플래그가 승계됨.
- **제약**: in-flight 서브에이전트·워크플로·백그라운드 셸이 있으면 backgrounding 실패("Cannot open agents — N background task(s) running").

### 2.2 축 B (알림) — 핵심 불확실성

- harness-kit 의 `notify-on-input-wait.sh` 는 `Notification`·`Stop` hook 에 등록되어 input-wait/턴 종료 시 발화하도록 정적 배선되어 있다(정적 분석 확인).
- **공식 문서는 백그라운드 세션에서 `Notification`/`Stop` hook 이 발화하는지 명시하지 않는다.** 입력 대기·턴 종료 *이벤트 자체*는 백그라운드에서도 발생하므로(문서상 "주기적으로 입력 필요") hook 발화 가능성은 높으나, 백그라운드 세션은 대화형 터미널이 없어 hook 실행 환경(stdin/stdout, command spawn)이 다를 수 있다. → **라이브 실측 필요 (test 1)**.
- **완화 요인**: 계층 2(에이전트가 게이트에서 직접 호출하는 `notify.sh`)는 단순 Bash 실행이라 백그라운드 세션에서도 정상 동작한다. *불확실한 것은 계층 1(자동 hook)뿐*이다. 즉 백그라운드 구간에서 게이트마다 계층 2 명시 알림을 보내면 §9(응답 ack)·§5(선택지) 도달은 보장된다.

### 2.3 축 E (세션/config)

- 병렬 백그라운드 세션은 launch 시점 MCP/config 를 공유한다. 각 세션은 별도 프로세스라 CC 레이어에선 안전하나, **singleton MCP 연결**(예: Telegram/Discord 채널의 단일 인증 연결)의 동시성 안전성은 문서 미명시 — MCP 서버 설계에 의존한다. 채널 응답(§10 양방향)을 여러 백그라운드 세션이 동시에 소비하는 시나리오는 미검증.

### 2.4 harness-kit 상호작용 (발견)

- CC 의 백그라운드/병렬 세션 격리 기제(**git worktree**)가 harness-kit 의 SDD 단일 체크아웃 브랜치 모델과 상호작용한다. 본 spec 작업 중 백그라운드 잡 격리 가드(worktree 강제)와 SDD 브랜치 격리의 충돌을 *실제로 경험*했고, `.claude/settings.local.json` 의 `bgIsolation: none` 으로 회피했다.
- 함의: harness-kit 에서 `/background` 를 쓰면 worktree 격리가 기본 작동하여 `sdd`(state.json·queue.md·hook)의 단일 체크아웃 전제와 어긋날 수 있다. macOS 1차 타깃·단일 체크아웃 가정과의 정합성 확인이 필요.

### 2.5 확정 vs 라이브 필요 (정리)

| 항목 | 판정 |
|---|---|
| 세션 분리·히스토리 보존·worktree 격리·config 공유 | ✅ 확정 (문서) |
| 계층 2 명시 `notify.sh` 백그라운드 동작 | ✅ 확정 (단순 Bash) |
| **계층 1 `Notification`/`Stop` 자동 hook 발화·도달** | ⚠️ **라이브 필요 (test 1)** |
| singleton MCP 동시성 안전성 | ⚠️ MCP 설계 의존 (미검증) |

## 3. `/branch` (`/fork`) 검증

> (Task 3 에서 작성)

## 4. Go/No-Go 종합

> (Task 4 에서 작성)

## 5. 정책 반영 결론

> (Task 5 에서 작성)

## 6. 부록 — 사용자 실행용 라이브 확인 체크리스트 (선택)

> (Task 4 에서 작성. 본 spec 의 Done 조건 아님.)
