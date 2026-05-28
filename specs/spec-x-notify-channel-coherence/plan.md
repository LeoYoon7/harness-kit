# Implementation Plan: spec-x-notify-channel-coherence

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-notify-channel-coherence`
- 시작 지점: `main` (현재 HEAD: f53949a, spec-x-notify-auq-scope-fix 머지 후)
- PR base: fork main (LeoYoon7/harness-kit)

## 🛑 사용자 검토 필요

> [!IMPORTANT]
> - [ ] **단일 소스 원칙 (조건부)** — AUQ 가 옵션 표현으로 충분한 케이스만 §5 stop 생략. 생략 불가 케이스 (옵션 >4 등) 는 §5 stop + AUQ 옵션 순서 sync (Critique 권장 반영).
> - [ ] **dispatcher 전환** — fragment 11곳 일괄 `notify-telegram.sh` → `notify.sh`. fragment 본문 호환 안내 줄 *추가 안 함* (Critique 권장: fragment 사용자는 LLM).
> - [ ] **Discord 추상 미명시** — Discord MCP reply 패턴은 active 화 시점의 별도 spec. 현재는 `notify.sh` dispatcher 만으로 cover.
> - [ ] **ADR-004 Amendment 절 신설** — 단순 부정 절 추가 X. ADR immutability 관행 유지.

> [!WARNING]
> - [ ] **메타 dogfood timing 수정** (Critique 권장): Plan Accept 응답은 *기존 규칙* 적용 (fragment 미수정 시점). Fragment 수정 task (Task 3-5) 완료 *직후* 응답부터 새 규칙 적용.

## 🎯 핵심 전략 (Core Strategy)

### 단일 소스 원칙 도식

```mermaid
flowchart TD
    Agent[에이전트 의사결정 시점] --> ChannelChoice{어떤 채널로 사용자 응답?}
    ChannelChoice -->|AskUserQuestion 사용| AUQOnly[AUQ 단독<br/>옵션 + 권장 = AUQ 가 단일 소스]
    AUQOnly -->|§5 stop 생략| HookCovers[hook c 분기가 알림 cover]
    ChannelChoice -->|텍스트 선택지 (chat)| TextChoice[fragment §5 stop 발송<br/>예: [선택지]/[권장]]
    TextChoice --> HookB[hook b 분기가 추가 cover]

    User[사용자 응답] --> ResponseRoute{응답 경로?}
    ResponseRoute -->|Telegram/Discord 경유| ChannelReply[채널 reply 도구 사용<br/>본문에 [ack] 포맷 포함]
    ChannelReply -->|§9 ack 생략| NoDup[중복 없음]
    ResponseRoute -->|PC chat 경유| NotifyAck[§9 ack 단독 notify.sh]
```

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **AUQ + §5 stop** | AUQ 사용 시 §5 stop 자동 생략 | 옵션 번호의 단일 소스 = AUQ. 충돌 차단 |
| **reply + §9 ack** | 채널 reply 사용 시 §9 ack 생략. reply 본문에 `[ack]` 포맷 포함 | ack 의 단일 소스 = reply. 중복 차단 |
| **dispatcher 통일** | `notify-telegram.sh` → `notify.sh` 일괄 | Telegram/Discord channel-agnostic |
| **호환성** | fragment 한 줄 안내 (`bash update.sh --yes`) + 에이전트 fallback 없음 | 단순. install.sh 가 `notify.sh` 보장 |
| **ADR 처리** | ADR-004 보충 (Consequences) | 신규 ADR 분산 회피, grep 부담 |

### 📑 ADR 후보

- [x] ADR 가치 있는 결정 있음 → ADR-004 보충 (별도 ADR-005 미생성)

## 📂 Proposed Changes

### [MODIFY] `sources/claude-fragments/CLAUDE.fragment.md`

#### A. §5 Ad-hoc 선택지 절 보강

기존 §5 (line 194-227 부근) 의 텍스트 마지막에 다음 문단 추가:

```markdown
**AUQ 사용 시 §5 stop 조건부 생략 + 옵션 순서 sync 보조 규칙 (단일 소스 원칙)**

에이전트가 동일 의사결정을 AskUserQuestion 도구로 발산할 때:

**조건부 생략 (§5 stop 미발송)**: 다음 모든 조건 충족 시 §5 stop 생략.
- 옵션 ≤ 4개 (AUQ 한계 내)
- free-text 자유 응답 미요구
- 같은 turn 의 AUQ + §5 stop 동시 의도 없음
- AUQ 가 의사결정 발산의 *유일한 경로*

생략 시 hook (c) 분기가 AUQ 의 `header`/`question`/`options.label` 을 자동 노출 → 채널에 알림 도달.

**생략 불가 케이스 — §5 stop 발송 + 옵션 순서 sync 필수**:
- 옵션 5개 이상 (AUQ 한계 초과)
- free-text 응답 포함
- AUQ + §5 stop 동시 의도 (예: 텍스트 선택지 + 모달 confirm)
- 이 경우 §5 stop 의 옵션 순서를 AUQ 와 동일 (권장-첫번째) 으로 강제. *단일 sink 원칙이 주, 옵션 순서 sync 가 fallback 이중화*. 번호 충돌 차단.

**범위 한정**: 본 규칙은 fragment §5 (Ad-hoc 선택지) 만 적용. §4 (Hard Stop) 은 그대로 유지 — Hard Stop 은 사용자 즉시 개입 요청이며 AUQ 동반 케이스는 본 규칙 범위 외.

텍스트 선택지 ([선택지]/[권장] 형식, AUQ 미사용) 만 제시할 때는 §5 stop 발송 유지.
```

#### B. §9 응답 시 알림 절 갱신

기존 §9 본문을 *Telegram 경유 reply 단독 / PC chat 경유 §9 ack 단독* 패턴으로 갱신 (Critique 권장: Discord 추상 표현 축소):

```markdown
사용자 응답 후 에이전트는 *단일 ack 메시지* 만 발송한다 (단일 소스 원칙).

**응답 경로별 분기**:

- **Telegram 경유 응답** (`<channel source="telegram" ...>` 태그가 사용자 메시지에 포함):
  → `mcp__plugin_telegram_telegram__reply` 사용. reply 본문에 §9 의 `[ack]` 포맷 포함:
    ```
    ✅ [ack] 사용자 응답: <선택지 요약>
    진행: <다음 단계 요약>
    ```
  → `notify.sh` 별도 발송 *생략*.

- **PC chat 경유 응답** (채널 태그 없음):
  → `notify.sh` 로 §9 ack 발송:
    ```bash
    bash .harness-kit/bin/notify.sh "✅ [ack] 사용자 응답: <선택지 요약>
    진행: <다음 단계 요약>" info
    ```

**근거**: 이중 발송 시 같은 ack 가 reply + notify-telegram 양쪽 채널로 도달 → 노이즈. 단일 소스가 multi-device 일관성을 더 확실히 보장.

**Discord 의 절차**: 본 spec 미명시. Discord MCP reply 도구가 active 화되는 시점의 별도 spec 에서 다룸. 현재는 `notify.sh` dispatcher 가 `NM_NOTIFY_CHANNEL=both` 등 설정 시 Discord 도 §9 ack 도달 보장.
```

#### C. §1-§8 의 `notify-telegram.sh` → `notify.sh` 일괄 교체

`grep -c notify-telegram.sh CLAUDE.fragment.md` 결과 11개 일치. 모두 `notify.sh` 로 교체. 본문 / 매개변수 / level 동일.

**호환성 안내 줄 — fragment 에 추가하지 않음** (Critique 권장):
- fragment 의 사용자는 *에이전트 (LLM)* — 안내가 "이걸 실행하자" 로 오해 위험.
- 대신 README / install.sh 의 `notify.sh` 보장 강조로 이동 (본 spec 범위 외, 후속 spec 가능).

### [MODIFY] `docs/decisions/ADR-004-notification-twofold-decision-flow.md`

ADR immutability 관행 유지 — Amendment 절 신설 (Critique 권장):

```markdown
## 🔄 Amendments

### 2026-05-29 (spec-x-notify-channel-coherence)

**단일 소스 위반 위험 식별 + 보조 규칙 도입**:

PR #9 직후 라이브 실증 사례: §5 stop 의 사람-작성 옵션 순서 (1.Gemini/2.Opus/3.Skip, 권장 3번) 와 AUQ 의 권장-첫번째 관행 (1.Skip(권장)/2.Gemini/3.Opus) 이 *번호 충돌* → Telegram=3 Skip / Desktop=1 Skip → 사용자 혼동.

ADR-004 의 양방향 컨벤션의 *발화 sink 단일성* 보강:

1. **AUQ 옵션 충분성 조건부 생략**: AUQ 가 옵션 표현으로 충분한 케이스 (옵션 ≤4 + free-text 미요구) 에서만 §5 stop 자동 생략. 옵션 5개 이상 등 생략 불가 케이스는 §5 stop 발송 + AUQ 와 옵션 순서 sync (권장-첫번째 강제).
2. **응답 측 단일 채널**: Telegram 경유 응답일 때 `mcp__plugin_telegram_telegram__reply` 단독, §9 ack 생략. PC chat 경유 응답일 때 `notify.sh` 단독.
3. **Discord 절차 미명시 — channel-agnostic dispatcher 만**: 현재 fragment 의 `notify.sh` 호출이 `NM_NOTIFY_CHANNEL` 라우팅으로 Discord 자동 cover. Discord MCP reply 패턴은 active 화 시점의 별도 spec.

**Consequences 부정 절 추가**:
- 단일 소스 위반 시 *번호/내용 충돌 위험* — 모바일 사용자가 본 라벨과 다른 선택 의도를 가져 잘못된 응답 → 회복 어려움 (multi-device 상태 격차).

**관련 spec**: `specs/spec-x-notify-channel-coherence/` — fragment §5/§9 갱신, §1-§8 의 dispatcher 통일 (`notify-telegram.sh` → `notify.sh` 11곳 교체).
```

### [SYNC] `.harness-kit/CLAUDE.fragment.md` + `.harness-kit/agent/` 경유 ADR-004

cp sources → installed 동기화.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (해당 없음)

Fragment 마크다운 + ADR 변경. 자동 테스트 미적용.

### 수동 검증

1. **dispatcher 동작**: `bash .harness-kit/bin/notify.sh "test" info` → `NM_NOTIFY_CHANNEL` 미설정 (= telegram default) 으로 Telegram 발송. 변경 무관 회귀.
2. **메타 dogfood**:
   - 본 spec Plan Accept 응답 직후 — mcp reply 단독 OR `notify.sh` 단독 사용 (양쪽 발송 안 함).
   - 이후 의사결정 게이트마다 동일 규칙 적용.
3. **AUQ 호출 시 §5 stop 자동 생략**:
   - 본 spec Ship pre-flight §1.5 — AUQ 사용. §5 stop 발송 *생략* 확인.
   - hook (c) 분기가 AUQ 옵션 자동 노출 — 추가 §5 stop 없이도 사용자가 옵션 확인 가능.
4. **fragment 의 `notify.sh` 교체 확인** — `grep -c notify-telegram.sh CLAUDE.fragment.md` 결과 = 0.

### Lint / Format

- 마크다운 lint 미적용 (본 repo 도입 안 됨).

## 🔁 Rollback Plan

- 본 PR revert 로 fragment 변경 + ADR-004 변경 일괄 되돌리기. 변경 가역적.

## 📦 Deliverables 체크

- [x] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
