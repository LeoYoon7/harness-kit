# Spec Critique: spec-x-notify-bidirectional-policy

> 독립 시니어 아키텍트 리뷰 (Opus 1M). spec.md / plan.md 의 비판적 검토 — 결론은 권장안 절에 모음.

## 1. 유사 기법 조사

### 발견된 패턴/도구

- **Slack Approval Workflow (block_actions + response_url)**: Slack 의 approval bot 패턴은 message 의 `block_actions` payload 가 도착하면 그것을 *해당 결정의 응답* 으로 처리. payload 안에 `action_id` 가 *어느 결정에 대한 응답인가* 를 명시 (즉 결정 ID 가 메시지에 박혀 있음). — 현재 spec 과의 비교: 본 spec 의 `<channel source="telegram">` 태그는 *경로* 정보만 제공하고 *어느 게이트에 대한 응답인가* 는 "직전 발화가 의사결정 게이트였는가" 로 추론. 결정 ID 가 없어 *모호 케이스 (복수 게이트 사이 응답)* 시 직전 매핑은 휴리스틱. Slack 패턴은 이 모호성이 시스템적으로 사라짐.

- **GitHub PR review-decision via comment (Hubot/Probot)**: bot 이 PR comment 를 reply 로 수신해 `lgtm`/`approve` 키워드 매칭으로 승인 처리. *키워드 매칭* 이 응답 인식의 핵심. — 현재 spec 과의 비교: 본 spec 도 "선택지 매핑" 으로 응답을 처리하지만 *매핑 알고리즘* 이 fragment 에 정의 안 됨 (예: "1" / "1번" / "첫번째" / "분해" 가 모두 옵션 1로 매핑되어야 하는지? 자유 텍스트는 reject 인지?). Hubot 류는 보통 *명시적 키워드 화이트리스트* 로 fail-fast.

- **ChatOps (Lita, errbot, StackStorm)**: 채널 명령을 받아 *backend job* 실행. 권한 검증은 *bot 미들웨어 레이어* (RBAC, ACL) 가 담당. — 현재 spec 과의 비교: spec 은 "Telegram MCP 가 access control 자체 처리" 로 검증을 *위임*. ChatOps 관례상 *bot 미들웨어가 검증 + 명령 매핑* 까지 처리하므로 본 spec 처럼 *MCP 신뢰 + 에이전트 매핑* 의 *책임 분산* 은 약간 이례적. 단 본 spec 의 "응답은 선택지 매핑만, 임의 명령 실행 안 함" 가드는 ChatOps 의 *명령 화이트리스트* 와 등가 정신.

- **n8n / Zapier wait-for-webhook**: workflow 가 *resume token* 을 발급하고 외부 응답으로 resume. resume token 이 *결정 ID* 역할. — 현재 spec 과의 비교: 본 spec 의 양방향 패턴은 *결정 ID 부재* — token 없이 휴리스틱 매핑. 라이브 운영 중 *복수 게이트 인터리브* 시 누락 위험.

- **AWS Step Functions Wait-for-Callback (sendTaskSuccess)**: 외부 ack 가 `taskToken` 으로 *어느 task 의 응답인지* 명시. — 현재 spec 과의 비교: 본 spec 의 모호 케이스 처리 (직전 게이트 매핑) 는 token 부재의 *근본 한계*. 다만 본 프로젝트 규모에서 token 도입은 over-engineering.

- **Probot / GitHub Apps webhook flow**: webhook 응답 도착 시 *event type + ref* 으로 routing. 멱등성은 *delivery_id*. — 현재 spec 과의 비교: spec 의 "같은 게이트에 PC chat + 채널 양쪽 응답 → 먼저 도착한 응답 채택" 은 *수동 멱등성*. delivery_id 없이 race window 가 존재.

### 시사점

1. **결정 ID 부재의 본질적 한계 인지**: Slack action_id / Step Functions taskToken / n8n resume_token 모두 *시스템 강제 결정 ID*. 본 spec 은 결정 ID 가 없으므로 *모호 케이스 처리는 본질적으로 휴리스틱* — 이를 spec 이 "직전 게이트 매핑" 으로 정의하지만 *완전한 해결은 아님*. ADR 의 부정 절에 "결정 ID 부재로 모호 케이스는 휴리스틱" 명시 가치 있음.
2. **응답 매핑 알고리즘의 명문화 필요**: ChatOps / Hubot 의 *키워드 화이트리스트* 패턴이 본 spec 의 §10 모호 케이스 처리 (자유 텍스트 변형 응답) 를 더 결정론적으로 만들 수 있음. 현재 spec 의 "사용자에게 명시적 확인 요청" 은 안전하지만 *추가 round trip* 비용. 매핑 규칙 (예: "1"/"1번"/"첫번째" 만 옵션 1, 그 외는 확인 요청) 을 §10 에 한 줄 추가 권장.
3. **권한 검증의 위임 명시 가치**: ChatOps 관례에서 *권한은 bot 미들웨어가 처리* 가 분명. 본 spec 은 Out-of-Scope 에 "telegram MCP 가 access control" 로 명시 — 이 자체는 합리적이지만 *Discord MCP active 시점에 동일 가정이 유효한지* 의 sanity check 가 향후 spec 의 trigger.

## 2. 요구사항 비판

### 누락

- **응답 매핑 알고리즘 부재**: §10 의 "선택지 매핑" 이 구체화 안 됨. "1" / "1번" / "첫번째" / "옵션 1" / 키워드 ("분해" 등) 가 모두 옵션 1 로 매핑되는가? 매핑 실패 시 "사용자에게 명시적 확인 요청" 으로 fallback 하지만 매핑 *시도* 의 우선순위/허용 변형이 정의 안 됨. 에이전트마다 다르게 해석할 위험.
- **`<channel source="...">` 태그의 *contract* 미정의**: §10 의 트리거 신호로 명시되지만 (a) 태그 schema (attributes 필수/선택), (b) 태그 발행 주체 (telegram MCP plugin 의 보장 동작), (c) 태그 부재 시 fallback (e.g. MCP 가 태그 안 박는 버전이면?) 이 spec/plan 에 없음. plugin 변경 시 silent break.
- **응답 *권한* 의 spec 본문 명시 부재**: Out-of-Scope 에 "telegram MCP 가 access control 자체 처리" 로 위임. 그러나 fragment §10 본문에는 *권한 검증을 위임함* 이 명시 안 됨. fragment 만 본 에이전트는 *모든 채널 응답을 신뢰* 로 해석 가능. "MCP access control 전제" 한 줄 §10 본문에 필요.
- **응답 형식 모호 케이스의 더 깊은 정의**: spec §10 의 "자유 텍스트 변형 응답 → 명시적 확인 요청" 만 명시. 다른 변형:
  - "잘 모르겠어" / "취소" / "나중에" 같은 *비결정* 표명
  - 옵션 외 *제3의 제안* ("이건 어때?")
  - 부분 응답 ("1번이긴 한데...")
  → 각 케이스의 처리 (특히 "취소" 는 게이트를 *닫고* 다시 열어야 하는지) 가 정의 안 됨.
- **timeout / 응답 기대 만료**: 채널 응답이 *언제까지 유효*? 게이트 발화 후 1시간 뒤 채널 응답이 도착하면 처리? 그 사이 다른 게이트가 열렸으면? spec 은 게이트 활성 시간을 무한대로 가정 — 비현실적.
- **양방향 채널에서 `[ack]` *수신측* prefix 의 의미**: PR #10 에서 `[ack]` 는 *발송측 마커* (사후 grep). 채널 reply 로 ack 발송 시 *수신자 (사용자)* 가 모바일에서 보는 텍스트. 이 텍스트의 *사용자 가독성* 검토 부재. `✅ [ack] 사용자 응답: ...` 는 grep 용으로 좋지만 사용자에겐 *prefix 노이즈*.
- **메타 dogfood 가 *진짜 새 규칙* 을 검증하지 못함**: spec 의 dogfood 항목 (DoD 마지막) 은 "본 spec 의 모든 의사결정 응답에 AUQ 미사용" 만 명시. 그러나 §10 의 *핵심 가치* 는 *채널 reply 응답 처리* — Plan Accept 같은 게이트를 *실제로 Telegram 으로 응답* 해서 §10 절차가 동작하는지 dogfood 안 함. AUQ 미사용은 *부수적* dogfood. 본질적 dogfood (채널 reply 응답) 가 plan 의 검증 시나리오에 없음.
- **AUQ 코드 제거 미평가**: "사용 제거" 와 "코드 유지 (defensive)" 가 동시 결정. 그러나 AUQ 코드를 *완전히 제거* 했을 때의 비용 (외부 sub-agent 사용 가능성) 이 평가 안 됨. 하나의 결정 (defensive 유지) 만 채택 — 대안 (제거) 의 트레이드오프가 spec 에 없음.
- **fragment 외 *영문 출처* (governance/agent.md L401) 누락**: `sources/governance/agent.md` L401 의 "The User often reviews these decisions on mobile (via Telegram notifications or Remote Control)" 영문 문장이 *Telegram 만* 명시. 본 spec 의 채널 중립화 범위가 *fragment 안* 만 → 영문 governance 출처는 *손대지 않음* → cross-document 비정합 잔존.

### 모순

- **AUQ 사용 제거 vs §5 의 AUQ 조건부 생략 규칙 유지** (질문에서 명시): plan.md Layer 4 가 "§5 의 AUQ 조건부 생략 규칙은 legacy 보존". 그런데 *에이전트가 AUQ 를 사용 안 함* 이라면 §5 의 "AUQ 호출 시 §5 stop 생략" 분기는 *영원히 활성화 안 됨* — *dead code 인 규칙*. legacy 보호 (외부 도구) 이유도 fragment 가 *본 에이전트의 절차서* 이지 *외부 도구의 절차서* 가 아님. 외부 도구는 fragment 를 읽지 않음 → legacy 보호의 *실효성 없음*. 차라리 §5 의 AUQ 조건부 생략 규칙을 *완전 제거* 가 단순하고 정합. plan 의 "legacy 보호" 는 *심리적 안전망* 일 뿐 기능적 가치 없음.
- **"양방향 채널" 정책 vs §5 자동 알림의 "에이전트는 아무것도 안 함"** (line 122): 정책 표가 "양방향 채널 (알림 + 응답 인식)" 로 바뀌지만 fragment 의 계층 1 자동 감지 절 (line 122) 은 여전히 "에이전트는 이 알림에 대해 아무것도 하지 않아도 됩니다 — 시스템이 자동으로 처리". 양방향이 되면 *응답 도착 후 에이전트가 처리해야* 함 → 계층 1 의 "아무것도 안 함" 진술과 정면 모순. 본 spec 의 변경 범위에 이 줄이 안 들어 있음.
- **hook (c) AUQ 분기 보존 vs AUQ 사용 제거의 *시스템적 일관성***: AUQ 를 *에이전트가 사용 안 함* 이라면 hook (c) 분기는 사실상 *발화 안 됨* → defensive 라는 명분이 *외부 도구* 인데, 외부 도구가 *본 프로젝트의 hook 을 사용* 한다는 가정이 어디서 유효한지 spec 미정의. 결국 (c) 분기는 *실측 검증 불가능한 dead branch* 가 될 가능성 — 이는 직전 critique 가 이미 지적한 "hook (c) 분기 cover 가정의 실측 부재" 의 *심화*.
- **spec line 91 vs plan line 50** (§10 위치 모순): spec 본문은 "신규 §10 (또는 §9 확장)" 으로 *§9 확장* 가능성 열어둠. plan 은 "§9 직후 §10 삽입" 으로 결정. 양자 결정이 다름 — spec 본문도 §9 직후 §10 으로 통일 필요.
- **메타 dogfood 의 timing 모순 (직전 critique 와 동일)**: spec 은 dogfood 항목을 DoD 끝에 둠 — "본 spec 의 모든 의사결정 응답에 AUQ 미사용". Plan Accept 시점부터인가, fragment 수정 후인가? 직전 spec critique 가 이미 동일 모순 지적했고 그 권장 (fragment 수정 task 후부터 dogfood) 이 본 spec 에 반영 안 됨. 직전 critique 의 *학습 불 전수*.

### 과잉 설계 (YAGNI)

- **18곳 *전부* 일괄 중립화** (질문에서 명시): 일부는 *실제로 Telegram 만* 의미하므로 보호가 합리적. 본 spec/plan 도 mcp 도구명 (`mcp__plugin_telegram_telegram__reply`) 과 PR #9 역사 사례 (line 233, 316) 는 보호함. 그러나 더 미세한 검토 시:
  - **line 102-107 환경변수 예시** (TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID): Discord 의 등가 env 변수가 *현재 .env.discord 가 active 화 안 됨* 이므로 *병기 안내가 헛것*. 차라리 *Telegram 예시 유지 + "Discord 설정은 별도 spec" 한 줄* 이 더 단순.
  - **line 373 `.env.telegram` dedupe config 안내**: 미래 미지원 기능 ("향후 지원 예정"). 채널 중립화는 이 줄 자체가 *향후 미정* 인 부분이라 *지금 손대도 미래에 다시 손대야 할 가능성*. 굳이 지금 다중 채널 표기로 변경할 가치 적음.
  - **line 389-392 비활성화 안내**: `mv .env.telegram .env.telegram.disabled` 만 예시. Discord 사용자는 *둘 다* 비활성화해야 하는지 *Discord 만* 인지 정의 안 됨. 양쪽 병기보다 *"각 채널 .env.*** 파일을 .disabled 로 이동"* 한 줄 일반화가 더 단순.
  → "18곳 전부 중립화" 보다 *fragment 의 정책 표 + 제목 + §10* 만 신규화하고 *나머지 안내성 텍스트는 보호* 가 변경 표면 절감.
- **§10 본문의 "보안/신뢰 가정" 절**: spec/plan 에서 응답 권한 검증을 *Out-of-Scope* 로 두면서 동시에 §10 본문에 *MCP 신뢰 가정* 을 명시 — 이중 안내. spec 의 Out-of-Scope 가 *진실 출처* 가 되고 §10 본문은 *한 줄로 압축* (e.g. "권한 검증은 MCP 가 담당") 이 적합.
- **§10 의 "모호 케이스 처리" 4 가지 케이스 명시**: 복수 게이트 사이 응답 / 매핑 실패 / 양쪽 응답 / Discord 미명시. 4 케이스 모두 명시하면 §10 본문 비대화. *원칙 한 줄 + 모호 케이스는 사용자 확인* 만 적으면 spec 의 의도 (양방향 컨벤션) 가 더 명료.
- **ADR-004 Amendment 의 부정 절 *추가***: 본 spec 의 Amendment 가 AUQ native UI 장점 상실, 채널 응답 race 등을 *부정 절에 추가*. 그러나 이는 *Amendment* 가 아니라 *원 결정의 trade-off* — ADR-004 의 원 부정 절은 "응답 측이 에이전트 절차 의존" 이 핵심이며 본 Amendment 의 추가 부정 절은 *그 trade-off 의 심화*. 분리 명시보다 *원 부정 절을 보완* 만 한 줄 추가가 깔끔.

### 모호함

- **"채널 답장을 의사결정 응답으로 처리" 의 *발동 조건***: §10 트리거가 "직전 에이전트 발화가 의사결정 게이트" + "채널 태그 포함". 그러나 *의사결정 게이트* 의 정의가 모호. fragment §1-§8 의 모든 알림이 게이트인가? 알림 발화 (`info` 레벨) 도 게이트인가? "선택지 ≥ 2" 만 게이트인가? spec 의 §10 본문이 결정 criteria 를 명시 안 함.
- **"같은 채널 reply 도구" 의 미래 가용성**: §10 처리 절차의 §9 ack 발송이 "같은 채널 reply 도구 사용 (단일 소스 원칙 유지)". Discord MCP reply 도구가 *없는* 현재 (Out-of-Scope) 상태에서 Discord 채널 응답이 들어오면 *§9 ack 가 어디로* 가는가? Spec 은 "Discord MCP active 시점의 spec" 으로 미룸 — 그러나 *현재 Discord 가 NM_NOTIFY_CHANNEL=both 로 notify.sh 경유 cover* 라는 직전 spec 의 결정이 §10 의 "같은 채널 reply 도구" 와 정합하지 않음. Discord 가 active 한 환경의 첫 응답 시 *fragment 가 어떤 절차를 가리키는가* 불명.
- **"Telegram/Discord 답장을 의사결정 응답으로 처리" — Discord 의 *답장* 정의**: Telegram 의 *답장* 은 message reply quote. Discord 의 *답장* 은 thread reply / DM / @mention 등 여러 변형. 본 spec 이 Discord 의 어느 변형을 답장으로 보는지 정의 안 됨. Discord active 시점의 spec 으로 미룬다 해도 *현재 spec 본문에는 Discord 답장 처리도 정책에 포함* 되어 있어 read-time 에 모호.

### 특별 주의 항목 검토 (질문에서 명시된 3가지)

**1. 정책 전환의 *back-compat* — 기존 PR (#6~#10) 의 mcp reply + notify.sh ack 패턴**

기존 PR #10 (spec-x-notify-channel-coherence) 의 결정:
- Telegram 경유 응답 → `mcp_telegram_reply` *단독* (notify.sh 생략, reply 본문에 `[ack]` 포맷)
- PC chat 경유 응답 → `notify.sh` 단독

본 spec 의 §10 신규 절차:
- 채널 답장을 *해당 게이트의 응답으로 처리* (응답 인식)
- ack 는 *같은 채널 reply 도구 사용* (단일 소스 원칙 유지)

→ **정합**. PR #10 의 "응답 측 단일 채널" 결정이 본 spec 의 "양방향 정책" 의 *전제* 그대로 보존. 본 spec 은 *입력 측 (응답 수신)* 만 추가 — 출력 측 (ack 발송) 은 PR #10 그대로.

다만 한 가지 잠재 깨짐:
- PR #10 은 "PC chat 경유 응답일 때 notify.sh 단독" 으로 *발화 sink 통일* 을 절차 강제. 본 spec 의 §10 은 *입력 측만* 새 규칙 — PC chat 응답의 출력 처리는 변동 없음.
- 그러나 §10 본문이 "PC chat 응답과 *동일 자격*" 으로 채널 응답을 처리 — 이는 *입력 동일성* 이지 *출력 동일성* 이 아님. 출력은 §9 의 분기 (PC vs 채널) 가 유지. spec 본문에 *출력은 §9 분기 유지* 명시 가치 있음.

**라이브 사례 깨짐 점검**:
- PR #10 의 라이브 사례 (line 233): "§5 stop 의 사람-작성 순서 (1.Gemini/2.Opus/3.Skip, 권장 3번) 와 AUQ 의 권장-첫번째 (1.Skip(권장)/2.Gemini/3.Opus) 가 번호 충돌". 본 spec 이 *AUQ 사용 제거* 하면 *AUQ 의 권장-첫번째 관행* 이 *발생 안 함* → 옵션 순서 sync 규칙 (PR #10 도입) 도 *결과적으로 dead*. 이는 "back-compat 깨짐" 이 아니라 *규칙의 자연 소멸* — 그러나 fragment 의 §5 옵션 순서 sync 절차 텍스트는 *그대로 유지* (plan Layer 4). dead text 잔존.

**결론**: 정책 전환은 PR #10 패턴과 *정합*. 단 dead text (옵션 순서 sync, AUQ 조건부 생략) 가 fragment 에 잔존하는 것이 *역사적 노이즈* — 본 spec 권장으로 *제거* 가 단순.

**2. "AUQ 사용 제거" 의 *적용 범위***

- **본 에이전트 (Claude Code main 세션)**: 명백히 적용. spec 의 핵심 결정.
- **Sub-agent (Opus critique, Gemini review 등)**: 본 critique 작성자도 sub-agent. 만약 sub-agent 가 *작업 중* AUQ 를 사용하면? 본 spec 은 *fragment 가 본 에이전트의 절차서* 라는 암묵 가정 — sub-agent 가 fragment 를 *프롬프트에 포함받지 않음* 이면 AUQ 사용 가능. 그러나 sub-agent 도 *동일 절차 따르기 권장* 이 합리적.
- **외부 도구 (Gemini CLI 모달 등)**: AUQ 와 무관. Gemini CLI 가 *자기 모달* 을 쓰는 것은 본 spec 의 통제 밖. Out-of-Scope 명시 필요.

spec 본문에 *적용 범위가 "본 에이전트 + sub-agent" 까지* 명시 권장. 외부 도구는 OOS.

**3. channel-neutral 표현의 *영어 출처***

확인 결과:
- `sources/governance/agent.md` L401 (영문): "The User often reviews these decisions on mobile (via Telegram notifications or Remote Control)" — Telegram 만 명시.
- 본 spec 의 변경 범위는 *fragment 안* 만 → governance/agent.md 영문 줄은 *그대로 유지* → cross-document 비정합 잔존.

이는 *fragment 의 자체 모순* (본 spec 의 트리거) 이 cross-document 모순으로 확장된 케이스. 본 spec 의 6 layer 가 "fragment 정합성 회복" 만 다루므로 governance/agent.md 는 별도 spec / 별도 layer 가 필요.

권장:
- (a) 본 spec 에 Layer 7 추가: governance/agent.md L401 의 "Telegram notifications" → "remote channel notifications (Telegram/Discord)".
- (b) 별도 spec 으로 분리: 거버넌스 영문 출처는 별개 변경 표면.

(a) 가 *bundle-before-spec-x* 원칙에 부합. 한 줄 추가로 cross-document 정합성 확보. 변경 표면 거의 0.

README / install 관련 파일에는 telegram 표현 없음 (grep 결과). install.sh / .env.telegram.example heredoc 은 *키트 인프라* 라 channel-neutral 의 대상 아님 (의도된 Telegram-specific).

## 3. 대안 제안

### 대안 A: 최소 정책 전환 + AUQ 코드 제거

- **아이디어**: spec 의 6 layer 중 핵심만 — **(1) 제목 + (2) 정책 표 + (3) 신규 §10 + (4) AUQ 코드 완전 제거 + (6) ADR Amendment**. 18곳 일괄 채널 중립화 (5) 는 *축소* — 정책 표/제목/§10 에서만 적용, 나머지 안내성 텍스트 (.env.telegram, 환경변수 예시, 비활성화 안내) 는 보호. AUQ 코드 *제거* 로 §5 의 조건부 생략 규칙 + hook (c) 분기 *모두 dead* → 자연스럽게 *삭제 가능*. 외부 sub-agent 보호는 *프로젝트 README* 에 한 줄 (e.g. "본 키트는 AUQ 미사용 — 외부 도구는 자체 모달 사용 가능").
- **장점**:
  - 변경 표면 최소화 — 18곳 → 5-6곳.
  - dead code/text 일소 — fragment 의 정합성 회복이 *더 깨끗*.
  - "legacy 보호" 의 *심리적 안전망* 제거.
  - sub-agent / 외부 도구 영향 *명시적으로 OOS*.
- **단점**:
  - AUQ 코드 제거는 *되돌리기 더 어려움* — 다시 도입 시 hook 본문 추가 작업.
  - 채널 중립화의 *완전성* 이 spec 의 한 가치인데 부분 적용은 일관성 손상.
  - 일부 사용자가 "왜 환경변수 예시가 Telegram 만?" 질문 가능 → 한 줄 주석 필요.

### 대안 B: 정책 전환만 분리 (Layer 1/2/3/6) + AUQ 제거는 별도 spec

- **아이디어**: 본 spec 을 *정책 전환 only* 로 축소. "보조 → 양방향" + §10 신규 + ADR Amendment + 제목 중립화. AUQ 사용 제거 (Layer 4) 와 18곳 채널 중립화 (Layer 5) 는 *별도 spec*. 정책 전환은 *원칙 변경* 이고 AUQ 제거는 *절차 단순화* — 분리하면 PR 검토 명확.
- **장점**:
  - 정책 ADR Amendment 의 가치가 *분리* — 정책 결정만 한 PR.
  - AUQ 제거의 *trade-off* (모달 UX 손실) 가 별도 spec 의 명시적 결정.
  - 분리하면 *revert* 도 단위별 — Layer 4 만 되돌리는 시나리오 가능.
- **단점**:
  - bundle-before-spec-x 패턴 위반 — 3개의 spec 분할이 ceremony 증가.
  - 정책 전환의 *실효* (양방향 적용) 가 AUQ 사용 제거와 함께 와야 *multi-device 가치* 가 완성. 분리하면 *Phase 의 중간 상태* 가 미완성.
  - 직전 spec critique 도 *bundle 유지* 권고 (대안 B 거부).

### 대안 C: 결정 ID 도입 (resume_token 패턴)

- **아이디어**: 채널 응답 모호성의 근본 해결 — 각 게이트 발화 시 짧은 *결정 ID* (`gate-id=abc123`) 를 메시지에 박음. 채널 reply 가 ID 를 포함하면 명확히 매핑. ID 없으면 직전 게이트 휴리스틱.
- **장점**:
  - 복수 게이트 사이 응답의 *시스템적* 해결.
  - 결정 ID 가 sub-agent / 외부 도구로 확장 가능 (e.g. resume_token).
  - Step Functions / n8n 의 표준 패턴.
- **단점**:
  - over-engineering — 본 프로젝트의 *동시 활성 게이트* 사례 부재.
  - 사용자가 응답 시 ID 를 *입력해야* — UX 부담 (단, "1번 abc123" 형식이면 무리 없음).
  - 본 spec 의 정책 전환과 *독립* — 향후 spec 으로 분리 가능.

## 권장안

**현재 spec 일부 수정 + 대안 A 의 *부분 수용*** + 직전 critique 학습 반영.

구체적으로 다음 수정 적용:

1. **Layer 5 (18곳 중립화) 축소** — 정책 표 + 제목 + §10 + §5 의 채널 중립 부분 (계층 1 자동 알림 묘사) 만 변경. *환경변수 예시 / .env.telegram 비활성화 안내 / dedupe config* 등 안내성 텍스트는 *보호* — Discord active 시점의 별도 spec 에서 다룸. 변경 표면 18 → 약 7-8 곳.
2. **AUQ 코드 처리 결정 명시** — 본 spec 은 "사용 제거 + 코드 유지 (defensive)" 채택. 그러나 *dead branch* 위험을 spec/Amendment 에 명시. Phase ship 시점 또는 별도 spec 에서 *완전 제거* 재평가.
3. **§5 의 AUQ 조건부 생략 규칙 처리** — plan Layer 4 의 "legacy 보호" 표현 대신 *"본 에이전트는 AUQ 미사용 — 본 규칙은 이론상 발화 불가"* 명시. 더 솔직하고 *dead text 인지* 가 명확.
4. **fragment line 122 ("에이전트는 아무것도 안 함") 모순 해소** — 양방향 정책 전환 후엔 *응답 도착 시 에이전트가 처리* 함. 이 줄을 *"입력 대기 시점의 알림 발화는 시스템 자동 — 응답 처리는 §10 절차"* 로 수정. (Layer 5 의 부분 적용 안에서 처리)
5. **응답 매핑 알고리즘 한 줄 명시** — §10 에 "옵션 매핑: 옵션 번호 (1/1번/첫번째) + 권장 키워드 (`권장`) 인식. 그 외 자유 텍스트는 모호 케이스 처리 (사용자 확인 요청)". ChatOps 패턴 차용.
6. **메타 dogfood 본질 강화** — DoD 마지막에 "본 spec 의 *Plan Accept 또는 한 게이트* 를 Telegram 답장으로 응답 — §10 절차 dogfood 검증" 추가. AUQ 미사용은 *부수적 dogfood*.
7. **AUQ 사용 제거의 적용 범위 명시** — spec 본문에 "본 에이전트 + sub-agent. 외부 도구 (Gemini CLI, Codex 등) 는 OOS".
8. **Layer 7 추가 (governance/agent.md L401)** — 영문 출처의 "Telegram notifications" → "remote channel notifications (Telegram/Discord)". cross-document 정합성 확보.
9. **ADR Amendment 의 부정 절 보강** — "결정 ID 부재로 복수 게이트 사이 응답은 휴리스틱 매핑 — 동시 활성 게이트 다수 시 누락 위험. 본 프로젝트 규모에서 trade-off 수용".
10. **spec 본문의 §10 위치 통일** — "§9 직후 §10" 으로 명시. plan 과 정합.

근거:
- 본 spec 의 *bundling 가치* 는 유지 (대안 B 거부).
- 결정 ID (대안 C) 는 premature — 본 프로젝트의 동시 게이트 사례 부재.
- 대안 A 의 *축소 적용* 이 over-engineering 방지에 가장 효과적.
- 직전 critique 의 학습 (timing 명확화, ADR Amendment 방식) 을 본 spec 에 *반영* — 동일 실수 반복 차단.
- *방어적 spec* 으로 변환 — 결정 ID 부재 한계, dead code/text 인지, cross-document 정합 누락을 모두 명시.

## 4. ADR 후보 추출

- [x] **ADR-004 Amendment 권장** (본 spec 의 결정 그대로) — type: `convention`
  - **이유**: 본 spec 의 정책 전환 ("보조 → 양방향") 은 ADR-004 의 양방향 컨벤션 *완성* — ADR-004 가 *요청+응답* 양방향을 정의했지만 정책 표가 "보조 채널" 로 응답을 차단해 *불완전* 했음. 본 결정은 그 *불일치 해소* 이므로 ADR-004 와 *주제 단일* — 분리 ADR-005 는 *parent/child* 부담.
  - **방식**: ADR-004 의 `## 🔄 Amendments` 절에 2026-05-29 entry 추가 (PR #10 Amendment 직후). 정책 전환 + AUQ 사용 제거 + 채널 중립화 + §10 절차 동시 명시. plan.md 의 Amendment 초안이 이미 합리적 — *결정 ID 부재 부정 절 추가* 와 *dead code/text 인지* 만 보강 권장.

- [ ] **(검토 결과 — 비판자 관점에서 ADR-005 분리가 합리적인 케이스 있는가?)**: **없음**. 정책 전환이 ADR-004 의 *완성형* 이라 분리 시 항상 *함께 인용* 되어야 함 — 의존성 부담. 직전 PR #10 Amendment 와 동일 패턴 유지가 추적성 우월.
  - 단 예외 시나리오: 만약 향후 "양방향 정책의 *cancellation* (양방향 → 단방향 회귀)" 같은 *반대 결정* 이 발생하면 그 시점에 ADR-005 ("ADR-004 supersede") 가 자연스러움. 현재는 premature.

- [ ] **(제외) AUQ 사용 제거 자체** — type: `convention` 후보 가능하나, 정책 전환의 *수단* 이므로 ADR-004 Amendment 안에 통합. 분리 가치 적음.

- [ ] **(제외) 18곳 채널 중립화** — *기계적 fix* . ADR 가치 없음.
