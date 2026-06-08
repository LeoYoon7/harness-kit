# Spec Critique: spec-x-notify-channel-formatter

> 본 비평은 독립 Opus 서브에이전트가 작성. Plan Accept 전 사용자 검토용.
> 작성일: 2026-05-29

## 1. 유사 기법 조사

### 발견된 패턴/도구

- **Discord 표 미지원 + ASCII code-block 우회**: Discord 는 표준 markdown table 을 렌더링하지 않으며 (`tables, images, footnotes, HTML 미렌더링`), 일반 관행은 *triple-backtick code-block 안에 ASCII 표 작성* 으로 정렬을 시뮬레이션 (출처: macmdviewer, allmarkdowntools). — 현재 spec 의 F2 "code-block ASCII 정렬" 방향이 이 컨센서스와 일치. 차이는 *발신 측이 이미 ASCII 로 작성* 하는지 *인프라가 markdown 표 → ASCII 변환* 하는지로, 본 spec 은 후자 (인프라 변환) 선택.
- **Channel Adapter Pattern (OpenClaw / NotifyGate / Laravel Notifications)**: 단일 도메인 메시지를 *Channel Adapter* 가 채널별 포맷·rate-limit·인증으로 정규화. "*Telegram 은 간결, Discord 는 markdown, Slack 은 bullet*" 같이 채널별 톤 분기가 명시적 dispatcher 책임. — 현재 spec 은 *발신 측 단일 마크다운 + 인프라 측 채널 변환* 으로 adapter 패턴을 *부분 적용*. 단, 산업 패턴은 *구조화 입력* (예: title/sections/options) 을 받지만 본 spec 은 *raw 마크다운 문자열* 을 입력 계약으로 유지.
- **Discord embed (rich message)**: `content` (plain) 와 별개로 `embeds` (구조화 JSON: title/description/fields/color) 지원. 1 메시지당 10 embed, 본문 4096자, field name 256/value 1024자, 총 6000자. *deployment summary, error report, monitoring dashboard* 의 표준 (출처: discordjs.guide, inventivehq). — 본 spec 은 embed 미고려, `content` 본문에 raw 마크다운 송신만 검토. Discord 가독성 회복의 *상한선* 을 placeholder 처럼 남김.
- **CJK East Asian Width (Unicode UAX #11)**: CJK 글자는 monospace 폰트에서 ASCII 의 *2배 폭*. ASCII 정렬 표에 한글이 섞이면 `length()` 만으로는 정렬 깨짐 — Discord/Slack `claude-code` issue #13438 등 다수 실증. (출처: typotheque, unicode tr11) — 본 spec/plan 은 task 2 의 T4 (한글 셀 표) 만 언급, 폭 계산 알고리즘 미명세.
- **n8n / Laravel Notifications**: *단일 Notification 객체* 를 각 채널 driver 가 `toSlack()/toDiscord()/toMail()` 로 렌더링. — 본 spec 의 *대안 C (구조화 컴포저)* 와 정확히 일치하는 산업 패턴.

### 시사점

(1) "code-block ASCII 표" 는 Discord 커뮤니티 컨센서스이므로 방향성 자체는 안전. 단, *변환 시점* 을 발신 측으로 옮기면 인프라 surface 축소 가능 (대안 A). (2) Channel Adapter 패턴의 산업 통념은 *구조화 입력 → 채널별 렌더링* (대안 C) 이며, 본 spec 의 *raw 마크다운 입력* 은 가벼우나 향후 Slack/Kakao 추가 시 발신 측 부담이 증가. (3) Discord embed 는 본 spec 의 가독성 목표를 *훨씬* 잘 달성하지만 surface 가 커서 별도 spec 후보로 분리하는 것이 합리적.

## 2. 요구사항 비판

### 누락

- **CJK 폭 계산 알고리즘 부재 (task 2 T4 모호)**: plan.md:198 "한글 셀 표 입력 → 등폭 정렬 가능한 형태 출력 (한글 폭 보정 또는 단순 padding)" — *또는* 으로 알고리즘이 미정. awk `length()` 는 byte 단위 (UTF-8 한글 = 3 byte) 가 아니라 character 단위지만, Unicode UAX #11 East Asian Width 미고려. 한글 셀과 ASCII 셀이 섞이면 *Discord monospace 폰트의 실제 렌더 폭 (한글 2cw, ASCII 1cw)* 과 awk 의 정렬 padding (1cw 가정) 이 다르므로 정렬이 깨짐. 본 spec 의 §1~§10 알림 예시에 한국어가 다수 포함되므로 *실제 발생 시나리오*. → spec 에 "한글 폭 = 2 ASCII cw 가정 padding" 같은 *명시 결정* 또는 "한글 셀 표는 정렬 보장 미흡 — 평문 통과" 같은 *명시 한계* 가 필요.
- **chunking 경계와 표 변환 상호작용 미명세**: `notify-discord.sh:125` CHUNK_SIZE=1700, awk fence balance 로직과 *신규 markdown_to_discord (표 → code-block)* 가 *입력 순서* 가 결정적. 만약 변환이 chunking *전* 에 일어나면 변환 후 본문이 1700 byte 초과 시 *생성된 펜스 안에서 추가 펜스 균형 로직* 이 발동 → 청크 경계가 표 *중간* 에서 깨질 수 있음. 만약 변환이 chunking *후* 일어나면 표 일부만 받은 청크에서 변환이 시도되어 *separator 행이 없는 헤더 행만 있는 chunk* 는 표로 인식되지 않을 가능성. 본 spec 은 "어느 시점에 변환할지" 결정 미명시. NF4 ("chunking 로직 무회귀") 는 이 상호작용을 *적극 검증* 하라는 요구사항으로 강화 필요.
- **F3 의 inline code `\`$BRANCH\`` ↔ markdown_simplify 처리 검증 누락**: hook 본문이 `` `$BRANCH` `` 로 송신되면 Telegram 측 markdown_simplify (`notify-telegram.sh:91` `s/\`([^`]+)\`/\1/g`) 가 backtick 제거. 그러나 *branch 이름에 backtick 이 포함된 사용자* (희박하지만 가능 — `spec-x-notify\`test`) 면 sed 가 잘못 매칭. F4 회귀 테스트의 "`code` 입력 → code 출력" 만 검증, *입력값 자체가 backtick 포함* 케이스는 미검증.
- **본 spec 의 §9 ack 메시지 영향 미평가**: `[ack]` prefix grep 정책 (fragment §9) 과 `**[ack]**` bold 강화 (task 7 의 "강화 가능 여부 검토") 사이 결정 미루기. *영향: grep 정확도*. `**[ack]**` 면 Telegram 측 markdown_simplify 후 `[ack]` 으로 평문화 되므로 grep 호환은 유지. *하지만* task 7 가 "검토" 로 끝나서 의사결정 미루기.

### 모순

- **F1 (발신 측 일관화) ↔ F4 (Telegram 회귀 방지)의 edge case 상충**: 발신 측이 `**bold**` 작성 시 markdown_simplify 의 sed (`notify-telegram.sh:89`) `s/\*\*([^*]+)\*\*/\1/g` 는 *별표 안에 별표 없음* 만 매칭. *중첩* (`***strong italic***`) 또는 *unbalanced* (`**bold ** test`) 시 메타문자 잔존. 본 spec 의 §1~§10 예시는 단순 `**[라벨]**` 위주여서 *현재* 는 안전하지만, 컨벤션이 강제되면 *향후 작성자가 강조 중첩* 시 회귀. F4 회귀 테스트는 "**bold** → bold" 만 명시 (plan.md:93), nested/unbalanced 미커버.
- **F2 의 "표 변환부만 활성화" ↔ 기존 코드의 통합 함수 구조**: `notify-discord.sh:80-99` 주석 블록은 *표 변환 + `[text](url)` 평문화* 두 변환을 하나의 함수 (`markdown_to_discord`) 로 묶음. spec 은 "표 부분만 활성화, `[text](url)` 변환은 보류" (F2) 라 함수 분리 또는 부분 주석 처리 필요. plan.md 는 *함수 분리 / 부분 활성화* 의 구체 방법을 task 3 의 TDD 단계에 위임 — 함수 디자인 결정이 spec 레벨이 아닌 implementation detail 로 빠짐.

### 과잉 설계

- **Task 9 (agent.md grep)**: spec.md 본문은 §1~§10 알림 예시를 *fragment* 에 집중. agent.md 의 notify.sh 호출 사례는 *추정상 거의 없음* (실제로 sources/governance/agent.md 의 메인 호출 사례는 §8.5 의 Choice Presentation 인용 정도). 한 commit 을 잡아둘 ROI 가 낮음. *조건부 pass* 로 task 에 남기느니, "pre-flight 에 grep 1회 + 발견 시만 spec 의 task 추가" 가 더 적절.
- **Task 12 (ADR-006 작성)**: "발신 측 단일 마크다운, 인프라 채널별 변환" 은 본질적으로 *Channel Adapter Pattern* 의 잘 알려진 적용이며, *프로젝트 고유 트레이드오프* 보다는 *산업 표준 patten 채택*. type=convention 의 ADR 가 적절한지 의문. 후술 §4 에서 대안 제시. 또한 ADR-005 직후 ADR-006 을 같은 spec 안에서 작성하면 ADR 인플레이션 우려. *본 spec 머지 직후가 아닌 신규 채널 추가 시점* 에 작성하는 게 *문제-실증 기반 ADR* 원칙에 부합.
- **F6 (도그푸딩 동기화) 의 *task 10* 별도 commit**: ADR-003 (dogfood-sync-policy) 가 이미 정책으로 존재할 텐데, 본 spec 만의 특별 처리가 필요한지 불분명. 표준 `update.sh --self` 가 있으면 한 줄 명령으로 충분하며 별도 task 분리 ROI 낮음.

### 모호함

- **"code-block 안 정렬된 ASCII 표" 의 알고리즘 명세 미완**:
  - 셀 폭 측정 기준 (byte / character / display width)?
  - 한글/이모지 폭 (CJK 2cw 보정 여부)?
  - 표 헤더 separator 행 (`|---|---|`) 처리 (제거 / 단순 dash 라인 / 별도 처리)?
  - 셀 데이터 내 `|` literal (escaped `\|`) 처리?
  - 헤더와 바디 사이 separator dash 라인 출력 여부 (가독성)?
  - plan.md 는 task 3 의 TDD red 단계에서 fixture 로 명세한다고 위임. *spec 단계에서 결정해야 할* 사항을 task 단계로 미루는 것은 *Plan Accept 시점에 결정된 적이 없는* 결과로 이어짐.
- **F5 의 컨벤션 표가 `markdown_simplify` 실제 동작과 일치하는지 미검증**:
  - 표의 "Telegram 렌더링" 컬럼 (plan.md:162-170): `**값**` → 평문, `` `값` `` → 평문, ``` ```...``` ``` → "펜스 제거, 본문 보존". 그러나 `notify-telegram.sh:74` `/^[[:space:]]*```/ { next }` 는 *펜스 라인 자체를 다음 라인으로 스킵*. 본문은 보존되나 *언어 hint* (예: ``` ```bash ```) 도 함께 제거됨 — 컨벤션 표는 이 디테일 미언급.
- **"별도 commit" / "별도 task 로 작성" 의 *모든* 의미**: plan.md 의 "본 spec 의 task 14" (line 55) 는 task.md 의 *Task 12* 와 번호 불일치. task.md 는 13 개 task (1~13), plan.md 는 14 개를 시사. *번호 mismatch* 는 사소하나 plan/task 간 일관성 문제.

## 3. 대안 제안

### 대안 A: 발신 측 ASCII 표 직접 작성 + 인프라 raw 통과

- **아이디어**: `notify-discord.sh` 의 `markdown_to_discord` 함수를 *영구 비활성* 유지. 발신 측 (CLAUDE.md fragment, hook, agent.md) 이 처음부터 ``` ```\n| a | b |\n``` ``` 가 아닌 `` ```text\n항목  값\nspec-id  ...\n``` `` 같은 *이미 정렬된 ASCII 표* 를 작성. 인프라는 raw 통과만.
- **장점**:
  - 인프라 surface 축소 (awk 표 변환 + CJK 폭 계산 + chunking 상호작용 모두 회피).
  - F4 의 markdown_simplify 회귀 위험 낮음 (표 변환 awk 분기가 입력에 없음 = 변경 없음).
  - 한글 폭 보정을 *작성자가 시각적으로 정렬* 해서 해결 (실용적).
- **단점**:
  - 발신 측 일관성 부담 증가 — 컨벤션이 "마크다운 표 금지, ASCII code-block 강제" 로 더 강해짐. 신규 알림 작성 시 가독성 부담.
  - Telegram 측 표 셀 join (markdown_simplify 의 `|` 라인 셀 join) 효과 *상실* — 발신 측이 ASCII 로 쓰면 Telegram 도 raw ASCII 받음 (등폭 폰트가 아니라 미관 떨어짐).

### 대안 B: Discord embed 도입 (`content` → `embeds` JSON)

- **아이디어**: notify-discord.sh 가 `LEVEL`/`MESSAGE` 를 받아 *embed JSON* 구성. title=레벨+repo, fields[]=섹션 (라벨, 본문), color=레벨별. Telegram 측은 변경 없음. 발신 측은 *마크다운* 그대로 송신, 인프라가 *섹션 파싱 → fields 변환*.
- **장점**:
  - Discord 가독성 *최상* — color band, field 정렬, title/description 분리. ASCII 표 정렬 문제 *우회*.
  - Telegram 무영향 (NF1 자동 충족).
  - 신규 알림 추가 시 *마크다운 작성* 만 하면 발신 측 부담 없음.
- **단점**:
  - 섹션 파싱 알고리즘 (예: `**[라벨]**\n본문\n\n**[다음]**\n...`) 이 *발신 측 컨벤션 강제* 와 결합. 비정형 본문 fallback 필요.
  - chunking 로직 재설계 — embed 본문 4096자 / field value 1024자 / 총 6000자 한도. 기존 line-aware chunking 무력화.
  - 1700 byte 본문 chunking 보다 surface 큼 — task 분량이 본 spec 의 2배 이상.

### 대안 C: 메시지 컴포저 (구조화 입력)

- **아이디어**: `notify.sh` API 를 *raw 문자열* 에서 *구조화 입력* (제목 / 섹션[] / 옵션[]) 으로 확장. 발신 측은 `notify.sh --title "..." --section "[선택지]" --content "1. ..." --recommend "1번"` 또는 JSON stdin. dispatcher 가 채널별 렌더링.
- **장점**:
  - 산업 표준 Channel Adapter 패턴과 일치 (n8n, Laravel, OpenClaw).
  - 신규 채널 (Slack, Kakao) 추가 시 *렌더러만 추가*. 발신 측 무변경.
  - Discord 측은 embed 사용, Telegram 측은 평문 generator, Slack 측은 Block Kit — 채널 native 가독성 최대화.
- **단점**:
  - **NF (Out-of-Scope)** 의 "notify.sh API 변경" 과 정면 충돌. spec.md:117 명시 위반.
  - 현재 spec 의 *minor refactor* 성격에서 *API redesign* 으로 격상 — surface 폭증.
  - 발신 측 *11곳* (fragment §1-§10 + hook + agent.md) 전부 호출 시그니처 변경. 도그푸딩 동기화 부담 ↑.

## 권장안

**현재 spec 유지 + 대안 A 의 *한글 폭 케이스만* 절충 반영** 을 권장합니다 (혼합).

근거: (1) 본 프로젝트는 "도그푸딩 가능성·컨텍스트 비용 0 우선" (CLAUDE.md) 이며 1차 사용처는 NestJS. 산업 패턴 (대안 C) 의 ROI 는 단일 발신처 (Claude) 환경에서 낮음. (2) 대안 B (embed) 는 가독성 상한선이지만 surface 가 본 spec 의 *minor refactor* 범위를 넘어 별도 spec 후보로 분리하는 게 책임 분담 명확. (3) 대안 A 의 "ASCII 표 직접 작성" 은 fragment §1-§10 의 *실제 표 사용 빈도* 가 낮으므로 (대부분 선택지 번호 나열) 실용적 — 단 인프라 측에 `markdown_to_discord` 함수를 *완전 폐기* 까지는 가지 말고 *표 변환만 활성화* 라는 본 spec 결정 유지. (4) **모호함 항의 "CJK 폭 계산 알고리즘"** 만 *spec 결정으로 격상* 해서 task 2 T4 의 기대 출력을 명시 (권장: "한글 셀이 섞인 표는 padding 보장 미흡 — 정렬 깨짐 허용 + Discord 등폭 렌더 의존" 같은 *명시 한계*). (5) ADR-006 작성은 **본 spec 외부로 분리** — 신규 채널 추가 spec 이 트리거되는 시점에 작성 (대안 C 의 미래 트리거 = 자연스러운 ADR 타이밍).

## 4. ADR 후보 추출

- [x] **후보 발견**: `notify-channel-adapter-responsibility` — type: **invariant** (convention 보다 강함) — 이유: "발신 측은 단일 마크다운, 인프라가 채널별 변환" 은 *향후 모든 채널 확장의 전제* 인 invariant 이지 협의 가능한 convention 이 아님. ADR-004 (`type: convention`) 과 같은 level 로 두지 말고 *invariant* 로 격상해 surface 외 채널이 추가될 때 *위반 시 즉시 reject* 되도록 함.
- [x] **후보 추가**: `discord-table-rendering-policy` — type: **tradeoff** — 이유: "Discord 표 처리는 code-block ASCII 정렬 vs embed fields vs raw 통과" 의 트레이드오프가 본 spec 의 결정으로 *code-block ASCII* 가 선택됨. embed 대안 (대안 B) 의 명시적 *기각 근거* (surface 증가, chunking 재설계) 를 박아두면 *향후 embed 도입 spec* 이 *기각 사유의 반박* 으로 시작할 수 있어 의사결정 audit trail 보존. **단**, 본 spec 의 작은 surface 대비 ADR 2개 작성은 인플레이션 우려 — *둘 중 하나만* (권장: `notify-channel-adapter-responsibility` 만 invariant 으로 작성, tradeoff 는 walkthrough.md 에 기록) 채택 권장.
