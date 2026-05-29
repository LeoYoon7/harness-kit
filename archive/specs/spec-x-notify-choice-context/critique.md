# Spec Critique: spec-x-notify-choice-context

> 독립 시니어 아키텍트 리뷰 (Opus 1M). 본 문서는 spec/plan 의 비판적 검토이며, 결론은 권장안 절에 모음.

## 1. 유사 기법 조사

### 발견된 패턴/도구

- **Slack Interactive Messages (ack() 3초 룰)**: Slack 봇은 버튼 클릭 등 interaction payload 수신 시 3초 내 `ack()` 응답 필수. 별도 데이터 처리는 그 이후. — 현재 spec 과의 비교: hook 측 (계층 1) 에 ack 개념이 없음. 사용자가 "응답함" 을 알리는 ack 알림이 fragment §9 의 *에이전트 수동 호출* 로 위임된 것은 동일한 가치 (multi-device 동기화) 를 노리지만, Slack 은 시스템 레벨에서 강제하는 반면 본 spec 은 에이전트 절차 (휴리스틱) 에 의존.

- **Slack Approval Workflow (response_url + 상태 업데이트)**: 승인 요청 시 봇이 *요청자에게 "pending"* 알림을 추가로 보내고, 응답 후 *원 메시지를 update* 하여 양쪽 모두 최종 상태 반영. — 현재 spec 과의 비교: 본 spec 은 *새 메시지로 응답 알림* 발송. 원 메시지 *수정* 은 시도하지 않음 (Telegram Bot API 의 `editMessageText` 가 가능하나 `notify-telegram.sh` 가 message_id 를 보관하지 않음). Slack 패턴은 "원 메시지 자체에 상태가 박힘" → 스크롤 백 시 헷갈리지 않는 장점.

- **n8n Human-in-the-Loop Wait Node**: 워크플로우가 wait node 에서 멈추고 멀티 채널 (Slack/Telegram/Discord/Email) 로 알림 발송, 응답 후 자동 재개. — 현재 spec 과의 비교: n8n 은 *플랫폼이 wait/resume 을 1차 추상화*. 본 프로젝트는 Claude Code 의 `Notification`/`Stop` hook 이 wait 신호, 사용자 응답은 *PC 키보드 입력*. 응답 ack 알림이 *에이전트 절차로 수동 발송* 인 것은 자연스럽지만, n8n 처럼 "응답 = 자동 재개 신호 = 자동 ack" 처럼 묶이지는 않음.

- **CCGram / ccbot (Claude Code ↔ Telegram bridge)**: AskUserQuestion 의 PreToolUse hook 에서 `updatedInput` 으로 Telegram 답변을 *그대로 Claude 입력에 주입*. JSONL transcript 를 폴링하며 tool_use/tool_result 를 요약 발송. — 현재 spec 과의 비교: 본 프로젝트는 Telegram 을 *원격 제어가 아닌 알림 전용* 으로 명시적 한정 (fragment "보조 채널 — Telegram 답장으로 명령을 수행하지 않음"). CCGram 류는 원격 제어 + AskUserQuestion 양방향 처리를 hook 으로 자동화. 본 spec 의 (c) AskUserQuestion 케이스가 *읽기 전용* 노출에 그치는 것은 의도된 보수적 선택.

- **GitHub Issue #13830 — AskUserQuestion notification hook 요청**: Claude Code 공식 레포에 *AskUserQuestion 전용 hook 이벤트* 추가 요청이 있음. 현재는 PreToolUse 로만 hook 가능. — 시사: 본 spec 의 (c) 분기는 *transcript 후행 분석* 으로 우회. 향후 공식 hook 이 추가되면 transcript tail 분석을 *pre-tool 입력 직접 수신* 으로 대체 가능. 본 spec 의 설계가 향후 마이그레이션 가능한 형태인지 확인 필요.

### 시사점

1. **Ack 의 시스템화 vs 절차화**: Slack/n8n 은 ack 를 시스템 레벨에서 강제. 본 spec 의 §9 는 *에이전트 의지에 의존*. agent.md §6.4 "단일 명령 원칙" 과 fragment "권장안 누락은 반복 실수" 의 정황을 보면, *에이전트 절차 의존* 은 통계적으로 누락 위험이 존재 — 본 spec 자체가 "절차 위반 시 walkthrough 캡처" 라는 사후 학습 메커니즘만 제공.
2. **원 메시지 update 의 대안**: 새 메시지를 보내는 대신 원 알림을 edit 하면 "스크롤 백 시 어떤 선택지가 처리됐는지" 시각적으로 분명. 단, 구현 비용 (message_id 보관 + edit API) 이 본 spec 의 "절차로 충분" 보수성과 trade-off.
3. **CCGram 류의 자동화 가능성**: 입력 측 hook 만으로 *AskUserQuestion 의 question/options 파싱 + Telegram 응답 → updatedInput 주입* 가 이미 OSS 로 입증됨. 본 spec 의 (c) 케이스는 *읽기 전용 노출* 까지만 수행 — 의도된 한정이지만 추후 확장 여지를 spec 어딘가에 명시하는 것이 좋음.

## 2. 요구사항 비판

### 누락

- **응답 알림 트리거의 *자동* 식별 불가**: §9 의 "직전 에이전트 발화가 선택지 제시였는가" 판단 기준이 *에이전트의 자기 인식* 에 의존. 멀티턴 대화 후 에이전트가 직전 발화를 기억 못 하거나 잘못 판단하는 케이스 fallback 없음. 최소한 *발송 조건 자체를 알림에 마킹* (예: `[ack]` prefix) 하여 사용자가 사후 grep 가능하도록 하는 정도의 가시성 필요.
- **응답 알림의 dedupe 영향**: §9 응답 알림이 직후 발송되는데, 같은 본문이 30초 내 다른 hook 알림과 fingerprint 충돌 시 어떻게 처리되는지 명시 없음. `notify-telegram.sh` 가 explicit 호출이라 hook dedupe TTL 영향 안 받는 것으로 보이지만, plan.md 에 명시되지 않음.
- **(b) 패턴 false positive 시나리오**: `^[0-9]+\)` (`1)`, `2)` 줄 시작) 은 일반 텍스트 — 예시 코드, 변경 로그, 번호 리스트 등 — 에서 흔히 등장. transcript 마지막 assistant text 가 "1) X 를 했고 2) Y 를 했다" 류 회고일 때 (b) 분기로 잘못 판정될 위험. spec 에 "발견 시" 만 적혀 있고 *얼마나 좁은 컨텍스트로 매칭하는지* 명시 없음.
- **AskUserQuestion 의 `header` 필드 미사용**: 실제 AskUserQuestion 스키마는 각 질문에 `header` (탭 라벨) 필드도 가짐. plan.md 의 jq 쿼리는 `.question` 만 추출. 탭 라벨 정보를 잃으면 사용자가 "어떤 컨텍스트의 질문인지" 알기 어려움.
- **transcript 비어있을 때 / tool_use 만 있는 turn 처리**: 새 세션 시작 직후 첫 권한 요청이면 transcript 에 assistant text 가 없음. `last // ""` fallback 으로 빈 문자열이 되어 (b) 미감지 → (a) brief 분기. 이건 의도된 동작이지만 spec 에 명시 없음. 명시하지 않으면 추후 "왜 첫 권한 알림에 context 없냐" 가 버그 리포트로 옴.
- **응답 알림 실패 시 retry / log**: silent skip 이 일관된 정책이지만, multi-device 동기화가 §9 의 *유일한 가치* 이므로 *실패 시 사용자가 모름 = 동기화 깨짐*. 최소한 로컬 로그 파일 (예: `.harness-kit/state/notify.log`) 에 발송 시도 기록 정도는 가치 있음. 현재 spec 은 명시적 미포함.
- **dogfood 검증 시점 모순**: DoD 의 "본 spec 의 Plan Accept 응답 시점부터 새 §9 절차를 본 spec 자체로 dogfood" — Plan Accept 시점은 *spec/plan 작성 완료 직후* 이며 *§9 가 fragment 에 아직 작성되지 않음* (작성은 task 의 하위 항목). 즉 Plan Accept 응답 시 §9 절차를 따른다는 건 spec 작성 *전의* 응답에 미적용. 시간 순서가 어긋남.

### 모순

- **§5 Ad-hoc 선택지 (기존)** 와 **§9 응답 알림 (신규)** 의 의도 충돌: §5 는 "에이전트가 선택지 제시 시 발송", §9 는 "사용자가 선택지에 응답 시 발송". 합치면 의사결정 1건당 *최소 2건 알림* (요청+응답). plan accept / hard stop / phase-ship 같은 무거운 게이트에서는 +1 알림이 자연스럽지만 *task 분해 같은 가벼운 결정* 에서도 동일하게 작동하면 노이즈 증가. spec 은 "노이즈 최소화" 를 명시하면서 (info 레벨 재사용) 트리거 조건의 *경량 케이스 제외* 는 정의 안 함.

### 과잉 설계 (YAGNI)

- **(b) 패턴의 후보군이 과도**: `[선택지]`, `[권장]`, `[Recommendation]`, `[의사결정 요청]`, `[Decision Request]`, `[Y/n]`, `[y/N]`, `^\d+\)` — 7가지. 본 프로젝트 *fragment 가 강제하는 규약* 은 `[선택지]` + `[권장]` 두 라벨이 핵심. 다국어 변형 (`[Recommendation]`, `[Decision Request]`) 은 현 시점 본 프로젝트에서 미사용. 첫 cut 으로는 `[선택지]` 단독으로도 충분 — false positive 위험을 줄이는 보수적 선택.
- **`^\d+\)` 패턴 자체가 모호**: 본 fragment 는 `1.`, `2.` 점 표기를 사용. `1)` 닫힘괄호 표기는 본 프로젝트 안에서 *오히려 회고/예시 텍스트* 에 더 흔함. 패턴 추가 가치보다 false positive 비용이 클 수 있음.
- **응답 알림의 "다음 단계 요약" 구성 부담**: 매 응답 알림에 "진행: <다음 단계>" 를 에이전트가 직접 생성. 단순 yes/no 응답에서는 "Task 1 진행" 같은 짧은 한 줄이지만, 매번 의미 있는 한 줄을 생성하려는 부담 자체가 절차 누락의 원인이 될 수 있음. 최소 *선택 결과만* 보내는 형태도 가치 있음.

### 모호함

- **"선택지 패턴" 의 정확한 정의**: spec 은 정규식 후보를 나열했지만 *우선순위와 매칭 범위 (전체 text vs 마지막 N 줄 vs 마지막 단락)* 미명시. plan.md 의 grep -E 는 전체 CONTEXT (`tail -100` transcript 의 마지막 assistant text 발췌, 3000자 cap) 를 대상으로 함 → 회고 텍스트 false positive 의 직접 원인.
- **§9 의 "사용자 응답이 의사결정 응답인지" 판단 시점**: 에이전트가 *응답을 받은 직후* (사용자 발화 직후 첫 턴 처음) 발송이라는 것이 명시적이지 않음. plan.md 예시에서 "Plan Accept 응답 후" 라는 표현이 있는데, 응답 처리 (예: 코드 편집 시작) 의 *전* 인지 *후* 인지 모호. "코드 편집 전 즉시 발송 → 그 후 첫 task 진행" 의 ordering 이 명시되어야 다른 알림 (accept 레벨) 과의 순서 보장.
- **"명시적 선택지 응답" 의 경계**: 사용자가 "1번 좋은데, 하지만 이렇게 하면 어떻겠어?" 류 *변형 응답* 을 했을 때 응답 알림 발송 여부 미정의. plan.md 예시는 깔끔한 케이스만 — 실전은 변형이 흔함.

### 특별 주의 항목 검토 (질문에서 명시된 3가지)

1. **에이전트 절차 의존성 (fallback 없음) 의 신뢰성**:
   - fragment 가 강제하는 다른 절차들 (One Task = One Commit, 권장안 포함, telegram align 알림 등) 도 동일한 *절차 의존*. 실제 운영 데이터 (walkthrough 캡처 빈도) 가 누락률을 보여줘야 신뢰 평가 가능.
   - 그러나 §9 는 *multi-device 사용자 시나리오* 가 유일한 가치 — 절차 위반 시 가치 0. 본 spec 의 다른 알림은 일부 누락되어도 PC 세션에서 회복 가능하지만 §9 누락은 *모바일 사용자가 자기가 응답한 줄 모름* → 회복 불가. **이 비대칭은 누락 비용이 다른 절차보다 높음을 의미**. 자동화로 옮기는 것을 추후 별도 spec 으로 두는 것이 spec 의 Out-of-Scope 에 명시됨 — 합리적이나 누락 위험이 다른 절차와 동급이 아니라는 자각이 spec/plan 에 없음.

2. **§9 의 트리거 자동 식별 모호성**:
   - "직전 에이전트 발화" 정의 자체가 모호. 사용자 메시지 직전의 *시스템 메시지 + 에이전트 발화 + 사용자 발화* 의 시간 흐름 중 *어느 에이전트 발화* 인가? 에이전트가 직전에 *여러 메시지* 를 보냈을 때는?
   - 실용적 휴리스틱: "본 세션에서 fragment §1-§8 의 알림을 *직전에 발송했는가*" 가 더 명확한 트리거 (계층 2 알림은 ID-able). 본 spec 은 이런 명시적 트리거를 명시 안 함.

3. **hook 의 jq -rs 메모리 사용량 (tail -100 충분성)**:
   - tail -100 은 *transcript 의 마지막 100 줄* — 일반적 turn 은 4~10 줄 (assistant text + tool_use 분리) 이므로 10~25 turn 정도 커버. 직전 1~2 turn 만 필요한 본 spec 용도로는 충분.
   - 그러나 *AskUserQuestion 추출* 은 `select(.type == "assistant") | .message.content[]? | select(.type == "tool_use" and .name == "AskUserQuestion")] | last` — *마지막 발견* 을 찾으므로 100 줄 내 가장 최근 AUQ. AUQ 후 다른 tool 이 끼면 그 사이 거리가 100 줄 넘으면 누락 가능. 실전에서 자주 발생할 시나리오는 아니나 edge case 로 식별 필요.
   - 메모리: 100 줄 * 평균 turn 크기 (~2KB) = 200KB. `jq -rs` 가 전체를 메모리 적재 — 무시할 수준. 단 `-rs` (slurp) 는 stream 처리 안 함 — 향후 transcript 가 더 커져도 tail 으로 cap 되어 OK.
   - **사소한 발견**: plan.md 의 jq 쿼리 (AUQ 추출) 와 그 다음 줄 (context 추출) 가 `tail -100 "$TRANSCRIPT" | jq -rs ...` 를 *두 번 수행*. 동일 입력을 두 번 파싱 — 비용은 미미하지만 단일 jq 호출로 묶을 수 있음 (구조화 출력 후 awk/sed 로 split). 단일 호출의 가독성 비용이 크니 두 호출 유지가 합리적일 수 있음 — plan 에서 trade-off 명시 없음.

## 3. 대안 제안

### 대안 A: 입력 측만 정교화 (응답 측 §9 보류, hook subagent_id 마킹)

- **아이디어**: hook 만 (a)/(b)/(c) 분기로 정교화하고, §9 응답 알림은 *별도 spec 으로 분리*. 대신 hook 본문에 *세션/턴 식별자* 마킹 (예: `[turn=42][session=abc12]`) 을 prefix 로 추가하여 사용자가 sticky scroll-back 시 같은 의사결정 응답 여부를 *수동 식별* 가능하게 함.
- **장점**:
  - 절차 의존도 0 — hook 자동 발화만 신뢰.
  - §9 의 트리거 모호성·자동 식별 어려움·dogfood 시점 모순 모두 제거.
  - hook 측 (a)(b)(c) 정교화의 가치만 빠르게 검증 (smaller surface area).
  - 응답 측이 정말 필요한지 *데이터 (walkthrough 누적)* 로 판단 후 별도 spec 으로 진행.
- **단점**:
  - multi-device 사용자의 *원래 pain point* (PC 응답 후 모바일 추측) 가 미해결.
  - 사용자가 spec 결정 직후 §9 만 부분 적용 (수동) 으로 보완 가능하지만 그건 spec 화 안 된 상태.

### 대안 B: 응답 측을 hook 자동화 (UserPromptSubmit hook + state 마커)

- **아이디어**: §9 를 에이전트 절차가 아닌 *hook* 으로 옮김. 구조:
  1. 계층 1 의 hook 이 발화할 때 (a/b/c 분기 결정) 결정 종류와 timestamp 를 state 파일에 마킹 (예: `.harness-kit/state/last-decision-prompt.json`).
  2. 새 `UserPromptSubmit` hook 추가 — 사용자 prompt 가 들어올 때 state 파일을 읽어 *직전이 의사결정 요청이었는지* 판정. 그렇다면 ack 알림 자동 발송.
  3. 본문은 사용자 prompt 의 첫 200자 + "응답 처리 중" 포맷.
- **장점**:
  - 에이전트 절차 의존성 제거 — multi-device 가치를 자동화로 확보.
  - state 파일이 *입력 측 hook 의 dedupe/cooldown 마커와 동일 패턴* → 일관성.
  - 사용자가 *변형 응답* 했어도 prompt 텍스트 그대로 노출 → "어떻게 응답했는지" 가시성.
- **단점**:
  - UserPromptSubmit hook 의 *모든 prompt* 가 트리거 — 명시적으로 응답이 아닌 일반 대화에서도 발화. state 마커로 거르지만 *마커 없는 케이스* (PC 재시작, state 파일 손실 등) edge case 존재.
  - hook 자동 발화 비용 (특히 매 prompt 마다 dispatcher 호출) 이 dedupe 로직 통과 후에도 미미하지만 0 은 아님.
  - hook 신규 추가는 settings.json 머지 + install/update 영향 — 작은 PR 이 아님.
  - 본 spec 의 Out-of-Scope ("응답 알림의 자동화 hook (UserPromptSubmit hook 기반 등) — 현 단계에선 에이전트 절차로 충분") 와 정면 충돌.

### 대안 C: 원 메시지 edit (Telegram editMessageText) 로 ack

- **아이디어**: §9 *대신* 입력 측 hook 알림 시 발송한 message_id 를 state 파일에 저장. 사용자가 응답하면 에이전트 (또는 hook) 이 *그 message 를 edit* 하여 "✅ 응답됨 — 진행 중" 을 append. 새 메시지 발송 안 함.
- **장점**:
  - Slack 패턴 (response_url 로 원 메시지 update) 의 Telegram 등가물.
  - 노이즈 0 — 알림 개수 증가 없음.
  - 스크롤 백 시 *어떤 결정이 처리됐는지* 시각적으로 분명.
- **단점**:
  - `notify-telegram.sh` 가 현재 message_id 를 반환·저장 안 함 — 헬퍼 변경 필요.
  - Discord 등 다른 채널 dispatcher 도 동일하게 edit API 지원 + 헬퍼 변경 필요 — surface area 큼.
  - "edit 이 push notification 트리거 안 함" — 모바일 사용자가 알림 *못 받음*. multi-device 가치 (PC 응답을 모바일에 알림) 와 정면 모순 — Telegram MCP instructions 에 명시.
  - 결국 *edit + new* 둘 다 필요 → 대안 B 보다 복잡.

## 권장안

**현재 spec 유지 (대안 채택 안 함)**. 단 누락/모호함 절의 다음 4 가지를 spec/plan 에 반영 후 진행 권장.

근거:
1. 본 프로젝트의 거버넌스 원칙 (`bash 스크립트 > Slash > Skill > MCP`, "도그푸딩 가능성", "No Over-engineering") 에 비추어 *대안 B (hook 자동화)* 는 surface area 가 크고, 본 spec 의 Out-of-Scope 와 직접 충돌. *대안 C (edit)* 는 Telegram edit 의 push 미발생으로 multi-device 가치를 잃음. *대안 A (응답 측 보류)* 는 사용자가 명시적으로 요청한 multi-device 동기화를 무시.
2. 현재 spec 의 §9 절차 의존은 다른 fragment 절차와 동일 신뢰 모델 — 누락 비용이 비대칭으로 높지만, 그것은 *데이터 (walkthrough 누적)* 가 쌓인 후 자동화로 옮기는 다음 spec 의 트리거가 됨. 본 spec 은 의도적으로 작은 cut.
3. 단 다음 4 가지는 반영 권장:
   - **요구사항 보강**: (b) 패턴에서 `^\d+\)` 제거 또는 *마지막 단락 (직전 5 줄) 만 매칭* 으로 false positive 차단.
   - **요구사항 보강**: AskUserQuestion 의 `header` 필드도 jq 쿼리에 포함 (탭 라벨 손실 방지).
   - **DoD 수정**: "본 spec 의 Plan Accept 응답 시점부터 dogfood" 의 시간 순서 모순 제거 — "본 spec 의 *Plan Accept 직후 모든 응답* 부터 §9 절차 적용" 으로 명확화.
   - **plan.md 보강**: §9 호출 본문에 `[ack]` 또는 비슷한 *식별 가능 prefix* 추가하여 사후 grep 가능. 절차 누락 사례 수집을 walkthrough/RCA 에 의존하지만 prefix 가 있어야 자동 grep 가능.

## 4. ADR 후보 추출

- [x] **후보 발견**: `notification-twofold-decision-flow` — type: `convention` — 이유: "의사결정 요청 알림 + 응답 ack 알림" 의 양방향 패턴은 *모든 fragment 알림 규약을 관통하는 컨벤션* 이며, 향후 새 게이트 (예: hk-archive 단계 신규) 추가 시 동일 패턴을 따라야 함. 본 spec 의 §9 는 *입력측 자동화 / 응답측 절차* 분리 결정도 포함 — 자동화 spec 으로 옮길 때 트레이드오프 근거가 필요.

판단 근거:
- cross-spec: 향후 알림 관련 모든 spec (자동화 hook 도입 spec, 새 게이트 추가 spec) 이 이 결정에 의존.
- long-lived: 알림 프로토콜 자체가 fragment 의 핵심 규약 — 6개월 이상 유지.
- type: `convention` (양방향 알림이 약속된 패턴) 또는 `tradeoff` (자동화 미선택의 근거 보존). 둘 다 합리적이나 `convention` 이 약간 더 적합 — 트레이드오프 자체보다 *향후 spec 이 따라야 할 형태* 가 핵심 자산.

- [ ] (제외) 본 spec 의 hook 본문 분기 로직 자체는 ADR 미가치 — spec 이 plan/task 로 충분히 캡처. ADR 은 *알림 양방향 컨벤션* 만.
