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

<!-- 이하 Task 2 에서 작성 -->
## 4. 기능별 적합도 분석 (17개 × 7축)

<!-- Task 2: ✅군 / ⚠️군 / 🔍군 / 등급외 2종 -->

## 5. 단계별 도입 로드맵

<!-- Task 3: 1단계(즉시) / 2단계(게이트 통합) / 3단계(검증 후) / 보류 -->

## 6. 결론 — Go/No-Go 종합

<!-- Task 3 -->

## 7. 후속 spec 후보

<!-- Task 4: queue.md Icebox 등록 대상 -->
