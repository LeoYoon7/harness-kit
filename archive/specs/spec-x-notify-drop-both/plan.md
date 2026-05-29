# Implementation Plan: spec-x-notify-drop-both

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-notify-drop-both` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> 본 Plan 을 Accept 하기 전에 사용자가 명시적으로 확인해야 할 항목들.

> [!IMPORTANT]
> - [ ] `NM_NOTIFY_CHANNEL=both` 가 설정된 기존 환경 (만약 존재한다면) 은 변경 후 **telegram fallback** 으로 자동 전환됨 — 의도된 redundancy 사용자는 `NM_NOTIFY_CHANNEL` 을 명시적으로 *다른 방식* 으로 다시 설정해야 함 (예: 두 helper 를 외부 wrapper 로 호출). 본 키트 내에는 `both` 를 export 하는 곳이 없음 (`telegram.sh`/`discord.sh` 만 존재).
> - [ ] 이미 merged 된 spec 문서 (`spec-x-notify-channel-coherence`, `spec-x-notify-bidirectional-policy`) 와 `archive/` 의 `both` 언급은 *동결* — 사후 수정 금지 (specs/CLAUDE.md 원칙).

> [!WARNING]
> - [ ] 본 변경은 **behavior change**: `NM_NOTIFY_CHANNEL=both` → 이전엔 양쪽 발송, 이후엔 telegram 만. 잠재적 redundancy 의존 사용자에게 silent drop 발생.
> - [ ] 변경된 동작에 대한 신호는 ADR-004 amendment + walkthrough 문서로만 제공 (코드 상 deprecation 경고 없음 — bash 스크립트 단순성 우선).

## 🎯 핵심 전략 (Core Strategy)

### 아키텍처 컨텍스트

```mermaid
flowchart LR
    A[caller] --> N[notify.sh]
    N -->|telegram or unset| T[notify-telegram.sh]
    N -->|discord| D[notify-discord.sh]
    N -->|none| X[silent skip]
    N -.x.- B[~~both branch~~ removed]
```

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **`notify.sh` case 분기** | `both` case 제거. `case` 라벨에서 `both` 자체 삭제 (line 46-49). | 단일 소스 원칙 (ADR-004 Amendment) 일관성. `both` 유지 시 fragment §9/§10 의 단일 ack 채널과 모순. |
| **미지정 / 알 수 없는 값 fallback** | 기존 `*) telegram` 유지. `both` 입력은 이 fallback 으로 자동 흡수. | Backward compatibility 보장 — `NM_NOTIFY_CHANNEL=both` 가 설정된 환경에서 알림이 *끊기지 않음*. |
| **dispatcher 헤더 주석** | 라우팅 표에서 `both` 라인 제거 + "spec-x-notify-drop-both 에서 제거" 한 줄 추가. | 향후 코드 리딩 시 *왜 없는지* 즉시 추적 가능. |
| **Fragment §9 ack note** | line 318 의 "(예: `both`)" 만 정확히 제거. 주변 문장 구조 유지. | 사후 수정 surface 최소화 — channel-coherence 의 다른 표현과 충돌 없음. |
| **ADR-004 Amendment** | 기존 양방향 컨벤션의 후속 진화 기록으로 한 절 추가 (3-5줄). 새 ADR 생성 안 함. | ADR-004 가 양방향 컨벤션 자체. `both` 제거는 같은 컨벤션의 단일 sink 원칙 강화 — 같은 ADR 의 연속 amendment 가 자연스러움. |
| **`archive/` + merged spec 문서** | 미수정 (동결). | specs/CLAUDE.md 의 머지 후 immutable 원칙 + grep false-positive 보존소 정책. |

### 📑 ADR 후보

- [x] ADR 가치 있는 결정 있음 → 후보 한 줄 요약: 기존 **ADR-004 의 Amendment 절에 추가** (type: convention)
- [ ] 없음

## 📂 Proposed Changes

### dispatcher (도그푸딩 동기화 단위)

#### [MODIFY] `sources/bin/notify.sh` + `.harness-kit/bin/notify.sh`

`both` case 라벨 제거 + 헤더 주석의 라우팅 표 갱신.

```text
# 변경 전 (notify.sh:43-55)
case "$CHANNEL" in
    telegram) call_helper "notify-telegram.sh" ;;
    discord)  call_helper "notify-discord.sh" ;;
    both)
        call_helper "notify-telegram.sh"
        call_helper "notify-discord.sh"
        ;;
    none)     : ;;
    *)
        call_helper "notify-telegram.sh"
        ;;
esac

# 변경 후
case "$CHANNEL" in
    telegram) call_helper "notify-telegram.sh" ;;
    discord)  call_helper "notify-discord.sh" ;;
    none)     : ;;
    *)
        call_helper "notify-telegram.sh"
        ;;
esac
```

헤더 주석 (line 11-15):

```text
# 변경 전
# 채널 라우팅 (환경변수 NM_NOTIFY_CHANNEL):
#   미설정 또는 telegram  → notify-telegram.sh 만 호출
#   discord               → notify-discord.sh  만 호출
#   both                  → 둘 다 호출
#   none                  → 발송 안 함 (silent skip)

# 변경 후
# 채널 라우팅 (환경변수 NM_NOTIFY_CHANNEL):
#   미설정 또는 telegram  → notify-telegram.sh 만 호출
#   discord               → notify-discord.sh  만 호출
#   none                  → 발송 안 함 (silent skip)
#   기타 값 (예: 과거 'both')  → telegram fallback (역호환)
#
# 'both' 는 spec-x-notify-drop-both 에서 제거 — ADR-004 의 단일 소스 원칙과 충돌.
```

### Fragment §9 ack note

#### [MODIFY] `sources/claude-fragments/CLAUDE.fragment.md` + `.harness-kit/CLAUDE.fragment.md`

line 318 의 한 표현만 정확히 제거.

```text
# 변경 전 (line 318)
**Discord 의 절차**: 본 protocol 미명시. Discord MCP reply 도구가 active 화되는 시점의 별도 spec 에서 다룸. 현재는 `notify.sh` dispatcher 가 `NM_NOTIFY_CHANNEL` (예: `both`) 설정 시 Discord 도 §9 ack 도달 보장.

# 변경 후
**Discord 의 절차**: 본 protocol 미명시. Discord MCP reply 도구가 active 화되는 시점의 별도 spec 에서 다룸. 현재는 `notify.sh` dispatcher 가 `NM_NOTIFY_CHANNEL=discord` 설정 시 Discord 도 §9 ack 도달 보장.
```

### ADR 갱신

#### [MODIFY] `docs/decisions/ADR-004-notification-twofold-decision-flow.md`

기존 Amendments 절 끝에 새 amendment 추가 (3-5줄):

```text
### 2026-05-29 (spec-x-notify-drop-both)

**`both` 채널 라우팅 제거 — 단일 소스 원칙 일관화**

**배경**: Amendment (2026-05-29, channel-coherence) 의 "응답 측 단일 채널" 결정과 dispatcher 의 `both` 라우팅이 모순. `both` 로 원본 게이트를 양쪽 채널에 뿌려도 §9/§10 의 ack 는 응답 채널 한쪽에만 도달 → 반대 채널에 "응답 미완" 인상 잔존 → multi-device 상태 동기화 가치 (ADR-004 본문 결정) 가 오히려 깨짐.

**결정**: `notify.sh` 의 `both` case 제거. 라우팅은 `telegram` / `discord` / `none` 만 남기고, 미지정/알 수 없는 값 (과거 `both` 포함) 은 `telegram` fallback 으로 흡수 (backward compatible). fragment §9 ack note 의 "예: `both`" 표현도 정합 갱신. Redundancy 가 필요한 경우 외부 wrapper 로 두 helper 를 직접 호출 (본 키트 surface 외).

**상태**: Accepted (2026-05-29, spec-x-notify-drop-both 머지 시점).
```

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)

본 변경은 bash dispatcher 의 case 분기 제거. 별도 단위 테스트 프레임워크 없음 — *수동 검증 시나리오* (아래) 로 대체.

### 통합 테스트

Required = no. 통합 테스트 미실시.

### 수동 검증 시나리오

각 시나리오는 sources/ 와 .harness-kit/ 양쪽에서 동일하게 동작해야 함.

1. **telegram 라우팅 (기본)** — `NM_NOTIFY_CHANNEL=telegram bash .harness-kit/bin/notify.sh "test" info` → `notify-telegram.sh` 만 호출 (helper 내부에서 .env.telegram 부재 시 silent skip 이어도 OK)
   - 기대 결과: telegram helper 만 실행. helper 가 silent skip 이어도 exit 0.
2. **미설정 (역호환)** — `unset NM_NOTIFY_CHANNEL; bash .harness-kit/bin/notify.sh "test" info`
   - 기대 결과: telegram fallback. 1번과 동일.
3. **discord 라우팅** — `NM_NOTIFY_CHANNEL=discord bash .harness-kit/bin/notify.sh "test" info`
   - 기대 결과: `notify-discord.sh` 만 호출.
4. **`both` → telegram fallback (behavior change)** — `NM_NOTIFY_CHANNEL=both bash .harness-kit/bin/notify.sh "test" info`
   - 기대 결과: `*)` fallback 분기를 통해 `notify-telegram.sh` 만 호출. 변경 전엔 두 helper 모두 호출, 변경 후엔 telegram 만.
5. **none silent skip** — `NM_NOTIFY_CHANNEL=none bash .harness-kit/bin/notify.sh "test" info`
   - 기대 결과: 어느 helper 도 호출되지 않음. exit 0.
6. **launcher 회귀** — `bash telegram.sh -p ""` (실행 직전 export 확인용 `echo` 만 — 실제 claude 기동 안 함) → `NM_NOTIFY_CHANNEL=telegram` 이 set 됨을 확인.

### 동기화 검증

`diff sources/bin/notify.sh .harness-kit/bin/notify.sh` → 0 줄 (동일). 마찬가지로 fragment 짝.

## 🔁 Rollback Plan

- 모든 변경은 단순 텍스트 / case 분기 제거. `git revert <commit>` 로 즉시 복원 가능.
- ADR-004 amendment 만 잘못된 경우 amendment 절만 별도 revert / 정정 PR.
- `both` 의존 외부 사용자 (본 키트 surface 내엔 없음) 가 발견되면, 본 키트 외부 wrapper 로 두 helper 를 직접 호출하도록 가이드.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
