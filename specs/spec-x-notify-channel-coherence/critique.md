# Spec Critique: spec-x-notify-channel-coherence

> 독립 시니어 아키텍트 리뷰 (Opus 1M). 본 spec/plan 의 비판적 검토 — 결론은 권장안 절에 모음.

## 1. 유사 기법 조사

### 발견된 패턴/도구

- **Slack Interactive Components — "single response sink"**: Slack 봇은 한 interaction 에 대해 `response_url` 을 *한 번만* 의도된 응답으로 사용하도록 권고. 추가 follow-up 은 `replace_original=true` 또는 별도 ephemeral. — 현재 spec 과의 비교: spec 의 "단일 소스 원칙" (AUQ vs §5 stop, reply vs §9 ack) 은 정확히 동일한 발상. 단, Slack 은 `response_url` 이 *시스템적으로 한 sink* — 본 spec 은 *에이전트 절차로 sink 통합*. Slack 은 위반 자체가 어려운 반면 본 spec 은 절차 위반 가능.

- **Microsoft Teams Adaptive Cards — "update vs new"**: 같은 대화 컨텍스트의 응답은 *원 카드 업데이트* (update) 만 권고, 새 메시지 발송은 명시적 이유 있을 때만. — 현재 spec 과의 비교: 본 spec 의 reply 단독 / §9 ack 단독 패턴은 *어떤 sink 든 한 번만* 발화 — Teams 의 "update only" 와 동일 정신.

- **PagerDuty Event Aggregation (dedup_key)**: 같은 incident 에 대한 여러 알림은 `dedup_key` 로 합치고 *추가 알림은 update*. 새 incident 만 새 알림. — 현재 spec 과의 비교: spec 의 *옵션 번호 충돌* 사례는 "같은 의사결정" 의 *복수 표현* — 일종의 *논리적 dedup_key* 가 필요. 하지만 본 spec 은 dedup_key 대신 *발화 시점에서 한 채널만 선택* 으로 해결 (더 단순).

- **Discord Interactions (defer + followup)**: Discord 의 slash command 응답은 *3초 내 defer*, 이후 `followup` 으로 최종 응답. follow-up 도 결국 *원 interaction token* 으로 연결되어 채널이 분기되지 않음. — 현재 spec 과의 비교: 본 spec 은 *Discord 가 active 상태가 아닌 환경에서* Discord 패턴을 "원칙만 명시" — 실제 Discord interactions 패턴과 비교하면 *interactive components* 차원이 아니라 *알림 dispatcher* 차원의 합의이므로 패턴 매칭이 살짝 다름.

- **n8n Idempotency Token in Wait Node**: wait node 에 idempotency token 을 두어 *같은 응답 트리거가 중복 들어와도 한 번만 처리*. — 현재 spec 과의 비교: 본 spec 의 "AUQ 발화 시점에 §5 stop 자동 생략" 은 *발송 측 idempotency* — 같은 결정에 대해 발화 sink 를 *하나만 활성화*. 비슷한 영감.

### 시사점

1. **시스템 강제 vs 절차 강제**: 위 4가지 모두 *시스템적으로* 단일 sink 를 강제. 본 spec 은 절차 강제 (에이전트가 매 발화 시점에 자가 점검). 직전 critique (spec-x-notify-choice-context) 에서도 동일 약점이 지적됨 — 절차 의존성. 본 spec 은 *그 위에* 하나 더 절차를 얹는 형국 → 누적 절차 의존도 증가.
2. **단일 sink 선택의 우선순위 명시**: Slack/Discord/Teams 는 모두 "어느 sink 가 *원본* 인가" 가 시스템적으로 자명 (response_url, interaction token). 본 spec 은 두 곳에서 "AUQ 우선 / channel reply 우선" 으로 *우선순위* 를 명시함 — 이 선택은 합리적.
3. **dedup 보조 마커 (idempotency token / dedup_key) 부재**: 본 spec 은 *발송 측 self-discipline* 으로 해결. 만약 절차 누락이 발견되면 사후 dedup 보조 마커 (예: `[ack-id=...]` prefix) 추가 spec 으로 보완 가능 — 현재는 미도입이 합리적 (premature).

## 2. 요구사항 비판

### 누락

- **AUQ "옵션 없는" 케이스 (free-text only)**: AUQ 가 `multiSelect=false`, options 비어있거나 `Other` 만 있는 free-text 케이스. 본 spec 의 §5 stop 자동 생략 규칙이 이때도 적용되는가? 옵션 번호 충돌은 *없는데* spec 은 "AUQ 호출이 있으면 §5 stop 생략" 으로 무조건 생략으로 표현됨 → 이 경우 사용자는 *AUQ 모달* 만 보고 컨텍스트 부족 위험. 명시 필요.
- **AUQ 4 옵션 한계 vs §5 stop 의 무제한 옵션**: AUQ 는 옵션 최대 4개. 사용자에게 5개 이상 선택지가 필요할 때 §5 stop 의 자유로운 텍스트 옵션이 *유일한 경로*. 이 케이스에서 AUQ + §5 stop 동시 발화가 *불가피* — spec 의 "AUQ 호출 시 §5 stop 생략" 이 이 케이스를 *어떻게 다루는지* (예: AUQ 호출하지 않고 §5 stop 만? 부분 옵션을 AUQ + 나머지를 §5? 의도적 중복 허용?) 명시 없음.
- **transcript race condition 미언급**: hook (c) 분기는 *transcript 의 마지막 AUQ tool_use 를 jq 추출*. 에이전트가 AUQ tool_use 를 emit 한 후 *transcript 가 flush 되기 전* 에 hook 이 발화할 가능성. 실제로는 Claude Code 가 tool_use 를 emit 후 transcript 에 즉시 write → Notification/Stop hook 발화 순서이지만 *spec 이 이 timing 을 가정하고 있음* 을 명시 안 함. 만약 race 발생 시 hook 이 AUQ 를 못 보고 (b) 분기로 fallback → 사용자 알림 없는 침묵 케이스.
- **"hook (c) 분기가 단독 cover" 의 가정 검증**: 본 spec 은 hook (c) 분기 동작을 *가정*. 하지만 직전 critique 에서 "AUQ 의 `header` 필드 미사용", "(c) 분기 발화 못 한 케이스에서 (a) brief 분기 fallback" 같은 hook 측 잠재 결함이 지적됨. 이 결함이 *해결되었다고 가정* 하고 §5 stop 을 생략한다면, hook 결함이 *조용히* §5 stop 부재와 결합되어 사용자가 알림을 못 받는 cascade 가 가능. 본 spec 의 DoD 에 "(c) 분기 실측 검증" 미포함.
- **Discord channel reply 도구 미존재 시점의 절차**: §9 가 "채널 reply 도구 사용 가능 → reply 단독, §9 ack 생략" 으로 분기. Discord MCP reply 도구가 *없는* 현재 상태에서 Discord 사용자가 채널을 통해 응답하면? Spec 은 "Discord MCP reply 도구 실제 구현 (본 세션엔 active 아님)" 을 Out-of-Scope 로 두지만, *Discord 채널 응답 자체* 가 발생할 수 있는지 (예: 사용자가 Discord 봇에 답장 작성) 명시 없음. 만약 채널 응답이 도착하지만 reply 도구가 없다면 *에이전트는 §9 ack 만 발송* 인지 *§9 ack + 무언가 보완* 인지 모호.
- **메타 dogfood 시점의 절차적 timing 모순 (질문에서 명시)**: 본 spec Plan Accept 응답부터 새 규칙 적용 — 하지만 *그 응답 시점에는 fragment 가 아직 수정 안 됨*. 사용자가 fragment 를 확인하면 "전부 notify-telegram.sh 인데 에이전트는 notify.sh 호출하네?" 라는 불일치 시각화. spec 작성자가 *부분 적용* (응답 측 단일 sink 만 dogfood, dispatcher 교체는 task 진행 후) 의도임이 명확하지 않음.
- **§5 stop 생략의 *완전성* (질문에서 명시)**: fragment §5 자체가 광범위 — "Strict Loop 진행 중 plan 에 없는 선택지" 모두 포함. AUQ 호출만이 그 트리거가 아님. 본 spec 의 "AUQ 호출 시 §5 stop 생략" 은 *AUQ 호출이 있는 부분집합* 만 다룸. AUQ 없는 §5 stop (예: chat-only 선택지) 은 그대로 유지인데, *AUQ 와 chat-only 가 혼재하는 같은 turn* 에서는 어떻게? 그리고 §5 stop 이 다른 케이스 (Hard Stop §4) 와 *같은 레벨 (`stop`)* 을 공유 — 생략 규칙이 §5 만 적용되는지 §4 도 포함되는지 spec 에서 명시적으로 §5 만 분리되어 있지 않음.

### 모순

- **hook (c) 분기 cover 가정 vs transcript 후행 분석의 본질**: hook 은 transcript JSONL 을 *후행 분석*. AUQ tool_use 가 transcript 에 기록되는 시점은 *Claude 가 tool_use 를 emit 하고 Claude Code 가 그것을 transcript 에 write 한 후*. Notification hook 은 *Claude 가 사용자 입력을 대기할 때* 발화. 일반적으로 tool_use write → user wait → Notification hook 순이지만, *AUQ 가 같은 turn 의 마지막 tool 이 아닐 경우* (예: AUQ 후 Read 호출 → AUQ 응답이 필요 없는 케이스 — 가설) 분석이 빗나갈 수 있음. 또한 hook 의 jq 가 "마지막 AUQ" 를 찾는데, 직전 turn 의 AUQ 가 마지막일 수도. 실제 race 가능성은 낮지만 *spec 이 보장 가정* 으로 다루고 있어 모순적.
- **"Telegram/Discord 경유 응답" 의 판단 시점 모순**: 사용자가 chat 으로 응답 → 에이전트가 *그 시점에* 채널 응답이 아닌 chat 응답이라 판정 → §9 ack 단독 발송 → 사용자가 *그 후* Telegram 으로 추가 메시지 → 두 번째 응답은 채널 응답이라 판정 → reply 단독. 이때 *동일 의사결정* 의 ack 가 두 채널로 나뉘어 발산. spec 은 이 케이스를 정의 안 함.
- **"채널 reply 도구 사용 가능" 의 판단 부담 vs 에이전트 능력**: §9 가 "도구 사용 가능 → reply, 미사용 → §9 ack" 로 분기하는데, 에이전트가 *이 시점에 reply 도구를 사용할 수 있는지* 판정하려면 MCP 가용성 확인 절차 필요. 본 spec 은 "사용자가 채널 경유 응답이면 자동으로 reply 사용 가능" 으로 가정 — 하지만 Telegram 으로 들어온 message 의 chat_id 와 reply 도구 가용성이 분리된 정보. 일반적으로는 정합이지만 *channel 메시지가 들어왔지만 MCP 가 disconnect* edge case 미정의.

### 과잉 설계 (YAGNI)

- **Discord channel-agnostic 원칙 명시 (질문에서 명시)**: Discord 가 본 세션에서 inactive. dispatcher `notify.sh` 는 *이미* channel-agnostic 이며 fragment 의 binary 이름만 교체하면 Discord 자동 cover. 그런데 spec 은 §9 본문에서 *Discord MCP reply 도구 등가물* 같은 *추상화* 까지 명시. 이는 Discord 가 active 화되는 시점의 spec 에서 다뤄도 충분 — premature abstraction. 본 spec 의 가치는 *Telegram-only 하드코드 제거* 이지 *Discord 미래 패턴 명시* 가 아님.
- **fragment 한 줄 호환성 안내 ("`bash update.sh --yes`")**: 본 spec 이 install/update 영향을 받는 *옛 install* 의 *fragment 사용자* 를 가정. 그런데 fragment 의 사용자는 *에이전트* (LLM) 이지 인간이 아님. 에이전트는 fragment 를 읽어 절차를 따를 뿐 — `update.sh` 안내 줄은 에이전트가 "이걸 실행하자" 라고 *오해* 할 위험. 안내가 *진짜 누구를 향한지* 모호. 차라리 install.sh 의 `notify.sh` 보장만 강조하고 fragment 본문엔 안내 줄 제외.
- **§5 stop 자동 생략 규칙의 *별도 명문화***: 본 spec 의 결함 (2) (옵션 번호 충돌) 의 근본 원인은 "에이전트가 같은 결정에 대해 *순서가 다른* 두 표현을 만들었다" 는 점. 가장 단순한 해법은 *§5 stop 의 옵션 순서를 AUQ 와 동일하게* 강제하면 충돌 없음. spec 은 §5 stop 자체를 *생략* 으로 강수 — 더 큰 변경. *옵션 순서 일관화* 라는 더 작은 fix 가 가능한데 그것을 평가 안 함.

### 모호함

- **"AUQ 호출이 있으면" 의 시점**: 같은 turn 의 *어느 시점* 에 AUQ 호출이 있어야 §5 stop 생략? Spec 은 "같은 turn 안" 으로 명시했지만, 에이전트가 *§5 stop 을 먼저 발송한 후 AUQ 를 호출* 한다면? 또는 *AUQ 를 먼저 호출하고 §5 stop 을 발송* 한다면? Spec 은 시간 순서 미명시 — 에이전트가 AUQ 의도가 있으면 *§5 stop 부터 skip* 인지 명확하지 않음.
- **"Telegram/Discord 경유 응답" 의 판단 신호**: 에이전트는 어떻게 "이 응답이 채널 경유" 인지 판정? Telegram MCP 가 incoming message 를 `<channel source="telegram" ...>` 태그로 전달한다는 fragment 외부 컨벤션이 있는데, spec/plan 은 이 판정 신호를 명시 안 함. PC chat 경유와 Telegram 경유의 *구분 알고리즘* 이 모호.

### 특별 주의 항목 검토 (질문에서 명시된 3가지)

**1. 메타 dogfood 시점의 모순**

본 spec 은 "Plan Accept 응답부터 새 규칙 적용" 을 dogfood 로 명시 (DoD 마지막 항목, plan.md WARNING 박스). 하지만 그 시점의 *실제 상태*:

- fragment 는 아직 *notify-telegram.sh* 하드코드 (task 진행 전).
- §5 stop 자동 생략 규칙은 *spec/plan 에만* 존재 — fragment 에 미반영.
- §9 가 "단일 채널" 로 갱신되기 전 — 현재 §9 는 "필수 발송" 으로 적혀 있음.

따라서 에이전트가 Plan Accept 응답 시점에 "단일 sink" 를 실천하려고 하면 *fragment 가 가리키는 절차 (§9 ack 발송)* 와 *spec 의 dogfood 의도 (reply 단독)* 가 충돌. 사용자가 fragment 를 확인하면 "spec 의 의도와 다른 행동" 으로 보일 수 있음.

이 모순을 해결하는 옵션 3 가지:
- (a) Dogfood 시점을 *fragment 수정 task 완료 후* 로 미루기 (예: §9 갱신 task 이후).
- (b) Dogfood 를 *예시 / 시뮬레이션* 으로 명시 — "이 spec 의 응답은 새 규칙 *시연*. 정식 적용은 fragment 수정 후."
- (c) 현재대로 진행하고 walkthrough 에 *과도기 모순* 명시.

가장 깨끗한 건 (a) — fragment 수정이 spec 의 첫 task 라면 첫 task 후부터 적용. 본 spec 의 plan 은 fragment 수정이 task 1-3 — 그 후부터 dogfood 시작이 timing 합리적.

**2. §5 stop 생략의 *완전성***

Fragment §5 의 *내용* 검토 결과 (1.fragment.md line 194-227):

- §5 의 정확한 이름: "Ad-hoc 선택지 제시 — 중간 의사결정 (stop)"
- 사용 범위: "Strict Loop 진행 중 plan 에 없는 선택지가 발생해 사용자 의사결정이 필요한 경우. 예: Task 분해 제안, 구현 방식 A/B 선택, 예상 못한 edge case 처리 방향"
- 레벨: `stop`

본 spec 의 "AUQ 호출 시 §5 stop 생략" 은 *§5 만 분리* 되는가 검증:

- §4 Hard Stop notification 도 `stop` 레벨. 본 spec 은 §4 를 *그대로 유지*. 이는 *§4 는 AUQ 사용 안 함* (Hard Stop 은 사용자에게 *즉시 개입 요청*) 이라는 암묵 가정에 의존. 그러나 Hard Stop 후 *복구 옵션 제시* 시 AUQ 사용 가능 — 그 경우 §4 + AUQ → §4 stop 생략? Spec 미정의.
- §5 stop 자체가 *광범위* — Task 분해, 구현 방식 분기, edge case 등 *옵션 형태* 의사결정 전부. 이들 중 *AUQ 로 옮길 수 없는 옵션 5개 이상* 케이스, *§5 stop 만 사용 + AUQ 미사용* 케이스, *AUQ 만 사용 + §5 stop 미사용* 케이스, *AUQ + §5 stop 동시 사용* 케이스 — spec 은 마지막 케이스에 대해서만 규칙 명시. 다른 케이스의 절차는 *그대로 유지* 로 봄.

결론: §5 stop 생략의 *범위* 가 spec 에 명시되지 않아 *AUQ 가 옵션 표현의 충분한 대체인가* 라는 더 큰 질문을 회피. AUQ 의 4 옵션 제약을 고려하면 §5 stop 의 *완전한 대체* 는 불가능 → 본 spec 은 *동시 발화 케이스의 충돌만* 해결, 다른 케이스는 손대지 않음. 이를 spec 에 명시하는 것이 정확.

**3. ADR-004 보충 vs ADR-005 분리 (질문에서 명시)**

ADR 의 *Consequences/부정* 절을 *사후 보충* 하는 것은 ADR 관행상 어색:

- ADR 의 통상 관행: *accepted* 후에는 *immutable*. 보완은 새 ADR ("supersedes" 또는 "amends") 로 처리.
- 그러나 본 spec 의 "단일 소스 위반 위험" 은 ADR-004 의 *결과* 가 아니라 ADR-004 의 *부정 결과* — 즉 ADR-004 가 도입한 패턴의 *기존 단점* 을 더 명확히 드러내는 것일 뿐. ADR-004 가 *잘못된 결정* 임을 주장하지 않음.
- *Amendment* 처리는 합리적. ADR-004 본문 끝에 `## 🔄 Amendments` 절을 추가하고 "spec-x-notify-channel-coherence (2026-05-29): 단일 소스 위반 위험 식별, 부정 절에 추가" 형태로 추적성 유지가 더 깨끗.
- 반면 ADR-005 분리는:
  - 장점: 단일 소스 원칙이 *향후 모든 알림 결정* 의 컨벤션이 되므로 *별도 ADR 가치* 가 있음.
  - 단점: ADR-004 와 *주제 중복* — 양방향 컨벤션 안에 단일 소스가 포함된 형태이므로 *parent/child* ADR 구조가 됨. grep 시 두 ADR 모두 등장 — 부담.

권장: ADR-004 본문에 *Amendment 절* 추가 (단순 *부정 절 추가* 가 아님). ADR-005 분리는 *premature* — 데이터가 쌓인 후 (단일 소스 원칙이 더 많은 게이트에 적용되면) 분리하는 것이 자연스러움.

## 3. 대안 제안

### 대안 A: 옵션 순서 일관화 (§5 stop 생략 대신)

- **아이디어**: 결함 (2) (옵션 번호 충돌) 의 근본 원인은 "에이전트가 같은 결정에 *순서가 다른* 두 표현 생성". 해법은 *§5 stop 의 옵션 순서를 AUQ 와 동일* 로 강제. AUQ 가 권장-첫번째 관행이면 §5 stop 도 권장-첫번째. §5 stop *생략하지 않음*.
- **장점**:
  - 더 작은 변경 — fragment §5 의 "옵션 작성 시 권장안을 1번에" 정도의 한 줄 추가만.
  - §5 stop 의 *구조화 메시지 가치* (사용자에게 컨텍스트 +권장 강조) 가 유지됨. Spec 은 hook (c) 가 *AUQ 의 question/options.label* 만 노출한다고 가정하나, 실제 hook 메시지는 종종 brief — 구조화된 §5 stop 이 더 풍부.
  - AUQ 의 4 옵션 한계 케이스에도 자연스럽게 적용.
- **단점**:
  - 알림 노이즈는 유지 — 같은 결정에 두 채널 발화.
  - 옵션 순서 일관성을 *에이전트 절차* 로 강제 — 누락 위험은 본 spec 의 §5 stop 생략 절차와 동일 수준.
  - 직전 critique 의 "절차 의존 누적" 우려를 줄이지 않음.

### 대안 B: dispatcher 통일만 (단일 sink 규칙은 보류)

- **아이디어**: 본 spec 의 결함 3 가지 중 *(3) Telegram-only 하드코드* 만 fix — 11곳 dispatcher 교체. 결함 (1)/(2) (ack 중복, 옵션 번호 충돌) 은 *별도 spec 으로 분리*. 이유: (3) 은 *문법적/기계적* 교체 (전혀 위험 없음), (1)/(2) 는 *행동 규약* 변경 (절차 의존 누적).
- **장점**:
  - PR 이 작고 검토 빠름. Discord 대칭성 즉시 확보.
  - (1)/(2) 의 단일 소스 원칙은 *추가 실증 데이터* (몇 개 의사결정 게이트를 더 거치며 패턴 확인) 후 별도 spec.
  - 본 spec 의 dogfood timing 모순 제거 — dispatcher 교체 task 만 있고 *응답 측 규칙 변경 없음* 이라 dogfood 도 자명.
- **단점**:
  - 결함 (1)/(2) 의 라이브 문제가 *남음*. 사용자 noise 지속.
  - 두 spec 분리 = ceremony 증가. 본 프로젝트의 *bundle-before-spec-x* 패턴과 충돌.

### 대안 C: 응답 측은 reply *우선* 만, §9 ack 보존

- **아이디어**: §9 갱신을 더 보수적으로 — "Telegram/Discord 경유 응답일 때 reply *선호*, 단 reply 실패 시 §9 ack fallback". 즉 single sink 가 아니라 *primary + fallback*. 결함 (1) 의 즉시 해결을 위해 reply 가 성공하면 §9 ack 생략, 실패하면 §9 ack.
- **장점**:
  - reply 도구 실패/미존재 케이스 (Discord 등) 자동 cover.
  - 절차 모호성 감소 — 에이전트 판단 부담 줄어듬 (reply 시도 → 실패 시 ack).
  - reply 실패도 사용자에게 도달 보장.
- **단점**:
  - "reply 성공/실패" 를 에이전트가 판정해야 함 — MCP tool 결과 확인 → 추가 절차.
  - 본 spec 의 *단일 소스 원칙* 의 명료성이 흐려짐.
  - 결과적으로 reply 가 거의 항상 성공하므로 §9 ack 호출 자체가 *사문화* — 보존 의의 적음.

## 권장안

**현재 spec 일부 수정 + 부분 채택**. 구체적으로:

1. **대안 A 의 *부분 적용***: AUQ 호출 시 §5 stop 생략이 *모든 케이스를 cover 못 함* (4옵션 한계, 같은 turn 의 AUQ + §5 stop 동시 의도, hook 발화 불가 케이스) → 본 spec 의 "AUQ 시 §5 stop 자동 생략" 규칙을 *조건부 생략* 으로 완화. 또는 §5 stop 의 옵션 순서를 *AUQ 와 동일하게* 강제하는 보조 규칙 추가. 단일 sink 가 *원칙*, 옵션 순서 일관성이 *fallback* 으로 이중화.
2. **§5 stop 생략의 명확한 범위 정의**: spec 본문에 "§5 stop 자동 생략은 *AUQ 가 옵션 표현으로 충분한 케이스* 에만 적용. AUQ + §5 stop 동시 의도가 있으면 (옵션 >4 등) §5 stop 발송 + AUQ 옵션 순서 동기화 필수" 명시.
3. **메타 dogfood timing 명확화**: Plan Accept 응답 시점이 아니라 *fragment 수정 task 완료 직후 응답부터* 적용. plan 의 WARNING 박스 명시 수정.
4. **ADR-004 보충 방식 변경**: 단순 *부정 절 추가* 가 아니라 *Amendment 절* 추가. ADR immutability 관행 유지하면서 단일 소스 원칙 추적성 확보.
5. **Discord 대칭성 표현 축소**: §9 본문에서 "Discord 등가물" 같은 *추상 표현* 제거. Spec 의 핵심 가치는 *Telegram-only 하드코드 제거* 이지 *Discord 미래 패턴 명시* 가 아님. Discord 가 active 화되는 시점의 별도 spec 에서 다룸.
6. **호환성 안내 줄 재고**: fragment 의 `bash update.sh --yes` 안내가 *에이전트* 를 혼동시킬 수 있음 — 안내 줄 제외하고 *키트 README* 또는 *install.sh 보장 강조* 로 이동.

근거:
- 결함 3 가지 통합 fix 의 *bundling 가치* 는 유지 — 대안 B (분리) 는 ceremony 증가로 안 맞음.
- 단일 소스 원칙 자체는 옳음 — 대안 C (primary + fallback) 의 모호성 회피.
- 그러나 본 spec 의 *over-promising* (AUQ 가 모든 케이스에서 §5 stop 대체) 과 *under-specifying* (timing, 범위, Discord) 을 보완하여 *방어적 spec* 으로 변환.

## 4. ADR 후보 추출

- [x] **후보 검토 결과 — ADR-004 Amendment 권장 (ADR-005 분리 안 함)**: type: `convention`
- **이유**: 단일 소스 원칙은 ADR-004 의 양방향 컨벤션의 *완성형* — 별도 ADR 로 분리하면 두 ADR 이 항상 *함께 인용되어야 하는* 의존성이 생김. ADR-004 의 Amendment 로 통합하는 것이 컨벤션 grep 부담 감소.
- **방식**: ADR-004 본문 끝에 `## 🔄 Amendments` 절 신설:
  - "2026-05-29 (spec-x-notify-channel-coherence): 단일 소스 위반 위험 식별. AUQ 호출 시 §5 stop 자동 생략, 채널 reply 사용 시 §9 ack 생략의 보조 규칙으로 양방향 컨벤션의 *발화 sink 단일성* 보강. Consequences/부정 절에 '단일 소스 위반 시 번호/내용 충돌 위험' 추가."

- [ ] **(제외) ADR-005 단일 소스 원칙 분리**: 현 시점 *premature*. 단일 소스 원칙이 더 많은 게이트에 적용되거나 (e.g. archive 단계 신규 알림) 자동화 spec 으로 진화할 때 *그 시점에* ADR-004 superseding ADR 로 분리 검토.

- [ ] **(제외) dispatcher 통일 자체** — 본 spec 의 dispatcher 교체는 *기계적 fix*. ADR 가치 없음.
