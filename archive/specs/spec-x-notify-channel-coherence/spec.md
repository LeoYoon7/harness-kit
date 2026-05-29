# spec-x-notify-channel-coherence: 응답 알림 채널 일관성 (dispatcher 통일 + 중복/번호 충돌 제거)

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-notify-channel-coherence` |
| **Phase** | (없음 — Solo Spec) |
| **Branch** | `spec-x-notify-channel-coherence` |
| **상태** | Planning |
| **타입** | Fix (PR #8 도입 protocol 보강) |
| **Integration Test Required** | no |
| **작성일** | 2026-05-29 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

PR #8 (spec-x-notify-choice-context) 가 fragment §1-§8 (요청 측 자동 알림 protocol) 와 §9 (응답 측 ack protocol) 를 도입. 라이브 운영 결과 3가지 결함 발견:

1. **응답 ack 중복 발송** (Telegram msg #3075):
   - 사용자가 Telegram 경유 응답 → 에이전트가 (a) `mcp_telegram_reply` (예: "Plan Accepted. Strict Loop 시작...") + (b) `[ack]` notify-telegram.sh 둘 다 발송
   - 결과: 한 응답에 모바일 알림 2건 — 노이즈

2. **§5 stop notification 과 AskUserQuestion 옵션 번호 불일치** (Telegram msg #3084+#3086):
   - 에이전트가 동일 의사결정에 대해 (a) §5 stop notification 을 사람-작성 순서로 발송 (예: 1.Gemini/2.Opus/3.Skip, 권장 3번) + (b) AUQ 호출 시 권장안을 첫 번째에 배치 (1.Skip(권장)/2.Gemini/3.Opus)
   - 결과: 같은 Skip 이 Telegram=3, Desktop=1 — 사용자가 Telegram 의 "3번" 보고 Desktop 에서 3 누르면 Opus 가 선택됨

3. **Fragment 가 Telegram-only 하드코드** (사용자 추가 지적):
   - Fragment §1-§9 모든 예시가 `notify-telegram.sh` 직접 호출
   - 본 키트의 dispatcher (`sources/bin/notify.sh`) 가 `NM_NOTIFY_CHANNEL` 에 따라 telegram/discord/both 라우팅 가능하나, fragment 가 이를 사용 안 함
   - 결과: Discord 사용자는 fragment §1-§9 의 응답 측 알림을 받지 못함 (입력 측 hook 은 dispatcher 사용으로 정상 cover)

### 문제점

세 결함이 **응답 측 알림의 단일 소스 부재** 라는 공통 원인. fragment 가 응답 시점 알림을 *복수 채널* (mcp reply + notify-telegram + §5 stop) 로 발산시키고, 채널 간 sync 가 없음.

### 해결 방안 (요약)

**단일 소스 원칙** 도입:

- (b) 번호 충돌: AUQ 호출 시 §5 stop notification 을 *자동 생략* — hook (c) 분기가 단독 cover. AUQ 가 옵션 번호의 *유일한 소스*.
- (a) ack 중복: Telegram/Discord 경유 응답일 때 mcp reply 와 §9 ack 중 *하나만* 사용. 채널 reply 가 있으면 reply 단독, 없으면 §9 ack 단독.
- (3) Telegram-only: fragment §1-§8 의 `notify-telegram.sh` 호출을 모두 `notify.sh` (dispatcher) 로 교체 → Discord 자동 cover.

## 🎯 요구사항

### Functional Requirements

1. **Fragment §5 갱신 — AUQ 가 옵션 표현으로 *충분한 케이스* 에만 §5 stop 조건부 생략**
   - **조건부 생략** (Critique 권장 반영): `AskUserQuestion` 도구 호출이 의사결정 발산의 *유일한 경로* 이고 *옵션이 4개 이하 + free-text 미요구* 일 때만 §5 stop notification 을 자동 생략.
   - **생략 불가 케이스 — §5 stop 발송 + 옵션 순서 sync 필수**:
     - 옵션 5개 이상 (AUQ 의 4 옵션 한계 초과)
     - free-text 자유 응답이 옵션 일부로 포함되는 경우
     - 같은 turn 의 AUQ + §5 stop 동시 의도 (예: 텍스트 선택지 + 모달 confirm)
   - **옵션 순서 sync 보조 규칙 (fallback)**: §5 stop 발송 시 옵션 순서를 AUQ 와 *동일* (권장-첫번째 관행) 으로 강제. 단일 sink 원칙이 *주*, 순서 sync 가 *fallback* — 이중화로 번호 충돌 차단.
   - 판단 기준: 같은 turn 안에 `AskUserQuestion` tool_use 가 포함되어 있고 AUQ 가 옵션을 *충분히* 표현할 때만 §5 stop 생략.
   - 이유: hook (c) 분기가 AUQ 옵션을 노출하나 AUQ 의 *구조적 제약* (옵션 ≤4) 으로 인해 모든 케이스를 대체 못 함. 생략 불가 케이스에 *번호 sync 강제* 가 안전망.
   - Textual 선택지 ([선택지] 형식) 만 제시할 때는 §5 stop 발송 유지.

   > **범위 한정 (Critique 권장 반영)**: 본 규칙은 fragment **§5 Ad-hoc 선택지** 만 적용. **§4 Hard Stop** 은 *그대로 유지* — Hard Stop 은 사용자 *즉시 개입 요청* 이며 AUQ + Hard Stop 동시 사용 케이스는 본 spec 범위 외.

2. **Fragment §9 갱신 — 응답 시 단일 채널 사용 (Telegram 우선, Discord 절차는 미명시)**
   - 사용자가 **Telegram 경유** 응답일 때 (`<channel source="telegram" ...>` 태그 인식):
     - `mcp__plugin_telegram_telegram__reply` 사용 가능 → reply 단독, `notify.sh` 호출 생략
     - reply 본문에 `✅ [ack] 사용자 응답: ... / 진행: ...` 포맷 포함하여 *단일 메시지로 ack 역할 겸함*
   - **PC chat 경유** 응답일 때 (채널 태그 없음):
     - `notify.sh` 로 §9 ack 단독 발송
   - **Discord 의 절차** (Critique 권장 반영 — 추상 표현 축소): 본 spec 미명시. Discord MCP reply 도구가 active 화되는 시점의 별도 spec 에서 다룸. 현재는 `notify.sh` dispatcher 가 NM_NOTIFY_CHANNEL 에 따라 자동 분기하므로 Discord 사용자도 §9 ack 도달 보장.

3. **Fragment §1-§8 모든 예시 — `notify-telegram.sh` → `notify.sh` 통일**
   - 11개 예시 (실측: `grep -c notify-telegram.sh CLAUDE.fragment.md` = 11) 일괄 교체.
   - 본문 / 호출 매개변수 / level 인자 동일 — 변경은 binary 이름만.
   - 효과: `NM_NOTIFY_CHANNEL=both` 환경에서 Telegram + Discord 양쪽 동시 발송. `telegram` 단독 / `discord` 단독도 정상 라우팅.

4. **호환성 — dispatcher 보장은 install.sh / README 에서** (Critique 권장 반영)
   - 본 키트 `install.sh` 가 `sources/bin/.` 전체를 `.harness-kit/bin/` 으로 복사하므로 신규/최신 install 은 `notify.sh` 존재 보장 (확인: `install.sh:343`).
   - 매우 옛 버전 install 의 `notify.sh` 누락은 *README / install.sh 의 강조 사항*. **Fragment 본문에 안내 줄 추가하지 않음** — fragment 의 사용자는 에이전트 (LLM) 이며 안내가 "이걸 실행하자" 로 오해 위험.
   - 에이전트 절차 자체에 fallback bash 추가 안 함 (코드 복잡도 회피, ROI 낮음).

### Non-Functional Requirements

1. **bash 3.2+ 호환** 유지 (이번 spec 은 fragment 마크다운 변경이라 bash 영향 없음).
2. **기존 (a)/(b)/(c) hook 본문 분기 무변경** — 본 spec 은 *응답 측 fragment 절차* 만.
3. **dispatcher 호환** — `notify.sh` 가 `notify-telegram.sh` / `notify-discord.sh` 와 동일한 인터페이스 (`message`, `level`). 변경 호환.
4. **메타 dogfood** — 본 spec Plan Accept 응답부터 새 규칙 적용. 응답 알림 1건만 발송 (mcp reply 단독 OR `notify.sh` 단독).

## 🚫 Out of Scope

- Discord MCP reply 도구 실제 구현 (본 세션엔 active 아님) — Discord 도 telegram 과 동일 패턴 따른다는 *원칙* 만 명시.
- `notify.sh` dispatcher 자체 개선 (level 추가, retry, etc.) — 변경 무관.
- `NM_NOTIFY_CHANNEL=both` 운영 시의 dedupe 정책 — 본 spec 은 fragment 절차만, dispatcher 동작 무변경.
- 기존 PR (#6~#9) 의 fragment §1-§9 예시 *내용* 변경 — 본문은 동일, binary 이름만 교체.

## 📑 ADR 후보

- [x] ADR-004 의 **Amendment 절** 신설 (Critique 권장 반영, ADR 관행상 *immutability* 유지)
- **방식**: ADR-004 본문 끝에 `## 🔄 Amendments` 절 추가:
  ```markdown
  ## 🔄 Amendments

  ### 2026-05-29 (spec-x-notify-channel-coherence)

  **단일 소스 위반 위험 식별 + 보조 규칙 도입**:
  - PR #9 직후 실증 사례: §5 stop 옵션 순서와 AUQ 옵션 순서 불일치로 Telegram=3 Skip / Desktop=1 Skip → 사용자 혼동.
  - 결정: 양방향 컨벤션의 *발화 sink 단일성* 보강.
    - (1) AUQ 가 옵션 표현으로 충분한 케이스에서만 §5 stop 자동 생략
    - (2) §5 stop 발송 시 옵션 순서를 AUQ 와 동일 (권장-첫번째) 강제 (fallback 이중화)
    - (3) Telegram 경유 응답 시 mcp reply 단독, §9 ack 생략
  - Consequences/부정 절 추가: "단일 소스 위반 시 번호/내용 충돌 위험 — 회복 어려움".
  ```
- 신규 ADR-005 미생성 — Critique 평가: *premature*. 단일 소스 원칙이 더 많은 게이트에 적용되는 시점에 ADR-004 superseding ADR 로 분리 검토.

## ✅ Definition of Done

- [ ] Fragment §5 갱신 — AUQ 호출 시 §5 stop 자동 생략 규칙 명시
- [ ] Fragment §9 갱신 — 응답 시 단일 채널 (reply OR §9 ack) 규칙 + Telegram/Discord channel-agnostic 표현
- [ ] Fragment §1-§8 의 `notify-telegram.sh` 11곳 → `notify.sh` 일괄 교체
- [ ] Fragment 에 한 줄 호환성 안내 추가 — "구버전 install 은 `bash update.sh --yes` 후 사용"
- [ ] ADR-004 의 Consequences 절에 "단일 소스 위반 위험" 추가
- [ ] 도그푸딩 sync — `.harness-kit/CLAUDE.fragment.md`, `docs/decisions/ADR-004-*.md`
- [ ] walkthrough + pr_description ship commit
- [ ] PR 생성 + 사용자 알림 완료
- [ ] 메타 dogfood — **fragment 수정 task (Task 3-5) 완료 *직후* 응답부터** 새 규칙 적용 (Critique 권장 반영, timing 모순 제거). Plan Accept 응답은 아직 *fragment 미수정* 시점이라 *기존 규칙* (notify-telegram.sh + mcp reply) 적용. fragment 수정 commit 이후 발생하는 응답에 단일 소스 규칙 적용.
