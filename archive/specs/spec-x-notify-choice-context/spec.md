# spec-x-notify-choice-context: 의사결정 알림 flow 양방향 강화 (요청 시 선택지 보존 + 응답 시 진행 상태 알림)

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-notify-choice-context` |
| **Phase** | (없음 — Solo Spec) |
| **Branch** | `spec-x-notify-choice-context` |
| **상태** | Planning |
| **타입** | Fix (hook 로직 개선) |
| **Integration Test Required** | no |
| **작성일** | 2026-05-28 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

`sources/hooks/notify-on-input-wait.sh` 는 Claude Code 의 `Notification` / `Stop` 이벤트 시 자동으로 Telegram / Discord 알림을 발송합니다 (CLAUDE.fragment.md "계층 1 자동 감지 알림").

핵심 로직 (`notify-on-input-wait.sh:62-66, 73-77, 83-86`):

```bash
# 권한 요청 감지
IS_PERMISSION=0
if [ "$EVENT" = "Notification" ] && \
   echo "$HOOK_MSG" | grep -qiE 'permission|approve|requesting|needs|allow|승인|허가|권한'; then
    IS_PERMISSION=1
fi

# IS_PERMISSION=1 이면 transcript 발췌 skip
if [ "$IS_PERMISSION" = "0" ] && [ -n "$TRANSCRIPT" ] && ...
    CONTEXT=$(...)
fi

# 본문 분기
if [ "$IS_PERMISSION" = "1" ]; then
    NOTIFY_BODY="권한 승인 대기\nBranch: $BRANCH\n$HOOK_MSG"
elif [ -n "$CONTEXT" ]; then
    NOTIFY_BODY="사용자 입력 대기 중\nBranch: $BRANCH\n[최근 Claude 메시지 일부]\n$CONTEXT"
else
    NOTIFY_BODY="사용자 입력 대기 중\nBranch: $BRANCH\nMessage: $HOOK_MSG"
fi
```

### 문제점

`IS_PERMISSION=1` 분기가 너무 광범위하여 **사용자 의사결정 선택지가 알림에서 사라지는** 케이스가 다수 발생.

구체적 시나리오:
1. 에이전트가 `[선택지]\n1. A\n2. B\n[권장]` 형식 텍스트 출력
2. 직후 `AskUserQuestion` 또는 다른 도구 호출
3. Claude Code 가 권한 다이얼로그 발화 → `Notification` 이벤트 + 권한 메시지
4. hook 가 `IS_PERMISSION=1` 판정 → context skip
5. 사용자는 Telegram 에서 "권한 승인 대기" 한 줄만 봄 — 선택지 누락 → 무엇을 선택해야 할지 알 수 없음

**추가 미고려 케이스**: `AskUserQuestion` tool 자체가 다수 질문 (탭) + 옵션 라벨을 가짐. 현재 hook 은 이 구조를 파싱하지 않아 질문 / 옵션 라벨이 알림에 노출되지 않음.

**Multi-device 사용 시 응답 측 알림 부재** (사용자 추가 지적):
- PC 에서 의사결정 요청 알림 수신 → 사용자가 PC 에서 응답 → 에이전트 진행 시작
- 모바일에서는 "응답됨" 신호가 오지 않아 "응답을 해야 하는 상황인지, 응답 후 진행 중인지" 구분 불가
- 결과: 사용자가 두 디바이스를 모두 확인하며 상태 추측해야 함

### 해결 방안 (요약)

**양방향 강화**:

**[입력 측 — Hook]** transcript 분석으로 3 케이스 구분:
- **(a) 순수 도구 권한** (Bash / Edit 등 Allow/Deny 명확): 현재 brief 알림 유지
- **(b) 텍스트 선택지** (Claude 메시지 내 `[선택지]` / `[권장]` 등): transcript 발췌 포함
- **(c) AskUserQuestion (탭 멀티 질문)**: tool_use 입력에서 질문 / 옵션 라벨 추출하여 요약 노출

**[출력 측 — 에이전트 절차]** CLAUDE.fragment.md 의 알림 프로토콜에 신규 §9 추가:
- 사용자가 의사결정 응답 (선택지 / AskUserQuestion / `[Y/n]` 게이트) 직후, 에이전트가 즉시 `notify-telegram.sh` 호출
- 본문: "사용자 응답: <선택 요약> / 진행: <다음 단계>"
- 트리거: 명시적 선택지 응답만 (일반 대화 / task 완료 / merge signal 은 제외)

## 🎯 요구사항

### Functional Requirements (입력 측 — Hook)

1. **(a) 순수 도구 권한 식별**
   - `IS_PERMISSION=1` *and* transcript 최근에 선택지 패턴 미존재 *and* AskUserQuestion tool_use 미존재 → 현재 brief "권한 승인 대기" 본문 유지.
2. **(b) 텍스트 선택지 감지**
   - 최근 assistant text 의 **마지막 단락 (직전 5줄)** 에 다음 패턴 중 하나 존재 시 → transcript 발췌를 알림에 포함:
     - `[선택지]`, `[권장]`, `[Recommendation]`, `[의사결정 요청]`, `[Decision Request]`
     - `[Y/n]`, `[y/N]`
   - **`^\d+\)` 제거** — 본 프로젝트는 `1.` 점 표기를 사용하며, `1)` 닫힘괄호 표기는 회고/예시 텍스트에 더 흔함 (Critique 발견, false positive 차단)
3. **(c) AskUserQuestion 추출**
   - 최근 transcript 에 `tool_use` + `name == "AskUserQuestion"` 발견 시 → `input.questions[]` 를 jq 로 파싱:
     - 각 질문의 `.header` 탭 라벨 (있는 경우 — Critique 발견, 탭 컨텍스트 손실 방지)
     - 각 질문의 `.question` 텍스트
     - 각 질문의 `.options[].label` 라벨 (옵션 description 은 길이 제한으로 생략)
   - 본문 포맷:
     ```
     사용자 질문 대기
     Branch: <branch>

     [질문 N개]
     1. [<header>] <Q1>
        옵션: <opt1.label> / <opt2.label> / ...
     2. [<header>] <Q2>
        옵션: <opt1.label> / <opt2.label> / ...
     ```
   - `header` 가 없으면 라벨 prefix 생략
4. **본문 분기 우선순위** (위에서 아래로):
   1. (c) AskUserQuestion 발견 → 질문/옵션 요약 본문
   2. (b) 텍스트 선택지 패턴 발견 → transcript 발췌 포함 본문 (IS_PERMISSION 무관)
   3. (a) IS_PERMISSION=1 *and* (b)/(c) 모두 미발견 → brief "권한 승인 대기" 본문
   4. 그 외 (일반 입력대기) → 현재대로 transcript 발췌 포함 본문

### Functional Requirements (출력 측 — 에이전트 절차)

5. **CLAUDE.fragment.md §9 신규 섹션 추가**: "사용자 응답 직후 — 진행 시작 알림 (info / accept)"
   - 트리거 케이스 (반드시 발송):
     - 명시적 선택지 응답 (`1`/`2`/`3`/`권장`/`Y`/`N` 등)
     - AskUserQuestion 응답
     - Plan Accept / Critique 게이트 응답
     - Go/No-Go 같은 다이얼로그 의사결정 응답
   - 제외 케이스 (발송 안 함):
     - 일반 대화 / 질문
     - task 완료 / merge signal (이미 `merge` 레벨 알림 있음)
     - 자유 형식 텍스트 응답 (특정 선택지로 매핑 안 됨)
   - 판단 기준: *직전 에이전트 발화가 선택지 제시였는가?* (CLAUDE.fragment.md "선택지 제시 규약" 형식)
   - **호출 명령** (반드시 `[ack]` prefix 포함 — 사후 grep 가능, Critique 발견):
     ```bash
     bash .harness-kit/bin/notify-telegram.sh "✅ [ack] 사용자 응답: <선택지 요약>
     진행: <다음 단계 요약>" info
     ```
   - 레벨: 기존 `info` 재사용 (신규 레벨 추가 안 함 — 노이즈 최소화)
   - **누락 비용 비대칭 자각** (Critique 발견): §9 누락 시 모바일 사용자가 *응답 여부 모름* → 회복 불가. 다른 절차들 (One Task = One Commit 등) 의 누락은 PC 세션에서 회복 가능한 반면 본 절차는 회복 비대칭으로 높음. 따라서 절차 위반 발견 시 walkthrough.md 외에도 RCA 작성 우선 고려.

### Non-Functional Requirements

1. **bash 3.2+ 호환** (`declare -A`, `mapfile` 등 4+ 기능 금지).
2. **jq 의존성 유지** (현재도 사용). jq 미설치 시 fallback 은 현재대로 brief 본문.
3. **메시지 길이 안전** — AskUserQuestion 최대 4 질문 x 4 옵션. 옵션 라벨 평균 30자 + 질문 평균 50자 = 약 1000자. Telegram 4096 한계 내. 추가 제한 불필요.
4. **dedupe / cooldown 메커니즘 유지**. 본 fix 는 본문 구성만 변경.
5. **silent skip 정책 유지** — 헬퍼 / 환경변수 / 네트워크 실패 시 `exit 0` 으로 Claude Code 흐름 무영향.
6. **응답 알림 한국어** (constitution §5.4). 메시지 본문 한국어, 레이블 영어 허용.
7. **응답 알림은 직접 호출 (`notify-telegram.sh`)** — 에이전트 절차이므로 자동 hook 아님. 사용자가 명시적으로 절차 위반 케이스를 발견 시 walkthrough/RCA 로 캡처.

## 🚫 Out of Scope

- Discord 알림 본문 포맷 분기 (`notify-discord.sh` 자체는 dispatcher 가 같은 본문을 받아서 전달 — hook 본문이 통일적 형식이면 양쪽 다 cover).
- 알림 텍스트의 다국어화 (현재 한국어 고정 유지).
- AskUserQuestion 의 option description 포함 (라벨만 — description 까지 넣으면 노이즈).
- 알림 채널 라우팅 / cooldown 정책 변경.
- 응답 알림의 자동화 hook (UserPromptSubmit hook 기반 등) — 현 단계에선 에이전트 절차로 충분. 향후 별도 spec 가능.
- 신규 알림 레벨 추가 (`decided` 등) — 기존 `info` 재사용으로 충분.

## 🔍 Critique 결과 (선택)

- 실행: `/hk-spec-critique` (Opus 1M sub-agent, 2026-05-28)
- 권장안: 현재 spec 유지 + 4 가지 보강 (모두 반영 완료)
- 반영 사항:
  1. (b) 패턴 — `^\d+\)` 제거 + 마지막 단락 5줄 매칭으로 false positive 차단
  2. AskUserQuestion `header` 탭 라벨 파싱 추가
  3. DoD dogfood 시점 모순 수정 — "Plan Accept *직후* 모든 응답부터"
  4. §9 본문에 `[ack]` prefix 추가 + 누락 비용 비대칭 자각 명시
- 전체 결과: `specs/spec-x-notify-choice-context/critique.md`

## 📑 ADR 후보 (Architecture Decision Records)

- [x] ADR 가치 있는 결정 있음 → 후보: `notification-twofold-decision-flow` (type: `convention`)
- 이유: "의사결정 요청 알림 + 응답 ack 알림" 양방향 패턴은 향후 모든 알림 spec (자동화 hook 도입 spec, 새 게이트 추가 spec) 의 컨벤션. fragment 핵심 규약이라 6개월 이상 long-lived.
- 작성 시점: 본 spec 머지 시점에 `docs/decisions/ADR-004-notification-twofold-decision-flow.md` 로 작성.

## ✅ Definition of Done

- [ ] **입력 측**: `sources/hooks/notify-on-input-wait.sh` 본문 분기 로직 갱신 ((a)/(b)/(c) 우선순위 적용)
- [ ] **입력 측**: `.harness-kit/hooks/notify-on-input-wait.sh` 도그푸딩 sync
- [ ] **입력 측**: 수동 smoke test 3 케이스 본문 확인:
  - (a) Bash 도구 권한 요청 → "권한 승인 대기" brief
  - (b) 텍스트 선택지 후 다른 도구 권한 → "사용자 선택 대기" + transcript 발췌
  - (c) AskUserQuestion 호출 → "사용자 질문 대기" + 질문/옵션 요약
- [ ] **출력 측**: `sources/claude-fragments/CLAUDE.fragment.md` 에 §9 신규 섹션 추가 (사용자 응답 직후 — 진행 시작 알림)
- [ ] **출력 측**: `.harness-kit/CLAUDE.fragment.md` 도그푸딩 sync
- [ ] **출력 측**: 본 spec 의 Plan Accept *직후* 모든 응답부터 새 §9 절차를 *본 spec 자체로* dogfood (메타 검증). 즉 §9 가 fragment 에 작성된 *이후* 발생하는 모든 사용자 응답에 적용 — 작성 *전* 의 응답에는 미적용 (시간 순서 명확화)
- [ ] `walkthrough.md` + `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-notify-choice-context` 브랜치 push 완료
- [ ] PR 생성 + 사용자 알림 완료
