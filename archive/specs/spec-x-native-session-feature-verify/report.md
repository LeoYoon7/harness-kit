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

### 3.1 동작 (확정 — sessions.md / how-claude-code-works.md)

- 현재 대화를 **새 session ID 로 복사(fork)** 한다. 원본 세션은 불변·재개 가능. fork 세션은 독립적이라 한쪽 변경이 다른 쪽에 영향을 주지 않는다. CLI: `claude --continue --fork-session`. 이름 지정 가능: `/branch try-streaming-approach`.

### 3.2 승계 (확정 — sessions.md / agent-view.md)

| 구분 | 항목 |
|---|---|
| **승계함** | fork 시점까지의 대화 히스토리(전체 컨텍스트), 프로젝트 디렉토리 + git 상태(같은 working dir/worktree), **부모 모델 선택**(settings override 없으면), CLAUDE.md instructions, **project/user settings(= hook 설정 포함)**, fork 시점 MCP 서버 |
| **승계 안 함** | "이 세션 동안 허용" 권한 승인 → fork 세션에서 재승인 필요 |

### 3.3 축 A/F/C 판정

- **축 F (git hook)** — fork 는 부모와 *같은 working dir/worktree* 에서 동작 → `check-branch`·`check-commit-msg`·`check-plan-accept`·`check-scope` 등 `PreToolUse` hook + git branch protection 이 그대로 적용된다. ✅ **확정**. main 직접 작업 금지(§10.1)·커밋 포맷 강제가 fork 에서도 보존.
- **축 C (멀티모델)** — 부모의 모델 선택을 승계. fork 내부 서브에이전트 dispatch(§6.6 model override)도 동일하게 작동. ✅ **확정**.
- **축 A (텍스트 게이트)** — `CLAUDE_CODE_FORK_SUBAGENT` 미설정 시 fork 는 *peer 대화형 세션* 이므로 §8.5 텍스트 게이트·Plan Accept 가 정상 발화한다. settings(hook 배선 포함)가 명시적으로 승계되므로 계층 1 알림 hook 발화도 부모와 동일하다고 **강하게 추론**된다(문서가 hook 발화를 콕 집어 명시하진 않음 → ⚠️→✅ 근접).

### 3.4 `CLAUDE_CODE_FORK_SUBAGENT` (확정 — env-vars)

- `=1` 설정 시 `/fork` 가 `/branch` 의 alias 가 아니라 **forked subagent** 를 spawn 한다(부모 컨텍스트 전체 승계, **백그라운드 실행**). 미설정 시 `/fork` = `/branch`(peer 세션 fork).
- **함의**: `=1` 경로는 백그라운드 subagent 이므로 §2(`/background`)의 계층 1 자동 알림 불확실성을 그대로 **상속**한다. 게이트가 예상되는 작업에 `=1` fork 를 쓰면 §2.2 와 동일한 주의(계층 2 명시 알림 의존)가 필요하다. peer fork(미설정)는 대화형이라 게이트가 보존된다.

### 3.5 확정 vs 라이브 필요 (정리)

| 항목 | 판정 |
|---|---|
| fork 동작·컨텍스트/모델/CLAUDE.md/settings(hook 배선)/MCP 승계 | ✅ 확정 (문서) |
| 같은 working dir → git hook·branch protection 적용 (축 F) | ✅ 확정 |
| 부모 모델 승계 (축 C) | ✅ 확정 |
| peer fork 세션의 계층 1 알림 hook 실제 발화 (축 A) | ⚠️ settings 승계로 강한 추론 — 라이브 권장(필수 아님, test 4) |
| `FORK_SUBAGENT=1` 경로의 알림 발화 | ⚠️ §2 test 1 과 동일 (백그라운드) |

## 4. Go/No-Go 종합

| 기능 | 판정 | 핵심 근거 | 등급 변화 |
|---|---|---|---|
| `/branch` (peer fork) | **조건부 Go** | 컨텍스트·모델·CLAUDE.md·settings(hook)·git 상태 승계 + 같은 working dir → 게이트(축 A/F/C) 보존 doc-확정 | 3단계 → 2단계 |
| `/background` | **조건부 Go (제한적)** | 동작·worktree 격리·계층 2 알림 확정. 계층 1 자동 알림만 미확정 → 게이트 없는 구간 한정 + 계층 2 필수로 리스크 한정 | 3단계 → 2단계 (라이브 확인 권장) |

### 4.1 `/branch` — 조건부 Go

- **선택지 비교**
  1. *조건부 채택*: 대안 탐색용 컨텍스트 보존 분기. 게이트 보존이 doc-확정. peer fork 는 대화형이라 텍스트 게이트 정상.
  2. *보류 유지*: 라이브 미실측 리스크 회피. 그러나 doc 근거가 강해 보류 ROI 낮음.
  - → **1 채택**.
- **조건**
  1. 기본은 peer fork(`CLAUDE_CODE_FORK_SUBAGENT` 미설정) — 대화형 게이트 보존.
  2. `CLAUDE_CODE_FORK_SUBAGENT=1`(백그라운드 subagent) 경로는 `/background` 조건(§4.2)을 따른다.
  3. fork 세션은 세션 범위 권한 재승인이 필요함을 인지.

### 4.2 `/background` — 조건부 Go (제한적)

- **선택지 비교**
  1. *조건부 채택*: 긴 mechanical 실행(테스트 수트·대량 수정)을 백그라운드로 → 생산성. 단 계층 1 자동 알림 미확정.
  2. *보류 유지*: 알림 누락(축 B, §9 비대칭 비용) 회피. 그러나 계층 2 명시 알림으로 게이트 도달 보장 가능 → 완전 보류는 과함.
  - → **1 채택, 단 조건 강화**.
- **조건**
  1. background 는 *게이트가 예상되지 않는 mechanical 자동 실행 구간* 한정(ADR-007 의 `/goal` 정신과 동일). 게이트(§8.5/Plan Accept) 예상 구간은 foreground.
  2. background 중 게이트 발생 시 계층 2 명시 `notify.sh` 를 반드시 발송(계층 1 자동 hook 의존 금지).
  3. worktree 격리가 SDD 단일 체크아웃 모델과 어긋날 수 있음 — `bgIsolation` 설정 인지(§2.4).
  4. in-flight 서브에이전트·워크플로·백그라운드 셸이 있으면 backgrounding 실패함을 인지.
  5. singleton MCP 채널 동시성 미검증 — 다중 background 세션이 채널 응답(§10)을 동시 소비하는 시나리오 주의.
- **잔여 라이브 (test 1)**: 계층 1 자동 hook 발화 여부는 §6 체크리스트로 1회 확인 권장. 발화 확인 시 조건 2 완화 가능.

## 5. 정책 반영 결론

> (Task 5 에서 작성)

## 6. 부록 — 사용자 실행용 라이브 확인 체크리스트 (선택)

> 본 spec 의 Done 조건이 **아니다**. 사용자가 라이브 세션에서 실행해 판정을 경험적으로 보강할 때만 사용한다. 각 항목은 §2·§3 의 ⚠️(라이브 필요) 항목과 1:1 대응한다.

1. **test 1 — `/background` 계층 1 알림** (축 B): foreground 세션에서 게이트 직전 `/background` 로 분리 → 에이전트가 입력 대기 진입 → Telegram/Discord 에 `notify-on-input-wait.sh` 자동 알림 도달 여부 확인.
   - 기대: 도달(조건 §4.2-2 완화 가능) / 미도달(축 B 위험 실증 → 계층 2 필수 유지).
2. **test 4-a — `/branch` git hook 승계** (축 F): `/branch` fork 후 fork 세션에서 `main` 체크아웃 상태로 커밋 시도 → `check-branch` hook 차단 확인. 기대: 차단.
3. **test 4-b — `/branch` 텍스트 게이트 알림** (축 A): peer fork 세션에서 §8.5 선택지 제시 상황 → 계층 1 알림 hook 발화 확인. 기대: 발화(settings 승계).
4. **test 4-c — `FORK_SUBAGENT=1`**: `CLAUDE_CODE_FORK_SUBAGENT=1` 설정 후 `/fork` → 백그라운드 subagent spawn 확인 + 알림 동작이 test 1 과 동일한지 확인.

> 결과는 본 spec 머지 후 별도 메모(또는 RCA — 알림 누락이 반복 관측되면) 로 환류한다.
