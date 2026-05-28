# spec-x-notify-bidirectional-policy: 의사결정 알림 양방향 정책 전환 + 채널 중립화 + AUQ 사용 제거

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-notify-bidirectional-policy` |
| **Phase** | (없음 — Solo Spec) |
| **Branch** | `spec-x-notify-bidirectional-policy` |
| **상태** | Planning |
| **타입** | Refactor (정책 전환 + 절차 정합화) |
| **Integration Test Required** | no |
| **작성일** | 2026-05-29 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

PR #8/9/10 으로 의사결정 알림 protocol 이 점진적으로 발전:
- PR #8: §9 응답 ack protocol 도입 (양방향 컨벤션)
- PR #9: hook (c) AUQ scope 좁힘
- PR #10: 단일 sink + dispatcher 통일

그런데 라이브 운영 중 사용자가 *fragment 의 내부 모순* 식별:

**모순 1 — 알림 정책 표 (line 379) vs 섹션 서두 (line 93)**:
- 서두 (line 93): "사용자가 PC 앞에 없을 때도 진행 상황을 파악하고 **원격 판단을 내릴 수 있도록** 지원"
- 정책 표 (line 379): "**보조 채널** — 알림은 정보 전달용. Telegram 답장으로 명령을 수행하지 않음."
- → 서두는 *원격 판단 (response) 지원* 의도, 정책 표는 *응답 비활성화* — 정면 모순

**모순 2 — 제목 (line 91) vs 키트 실제 (dispatcher 통일)**:
- 제목: `## Telegram 의사결정 알림 프로토콜`
- 실제: PR #10 에서 `notify.sh` dispatcher 가 Telegram + Discord 분기. 본 키트는 Discord 도 *정식 지원*
- → 제목이 *Telegram 만* 명시 = 현실 미반영

**모순 3 — AUQ 사용 vs multi-device 가치**:
- 본 프로젝트의 *multi-device 가치* (PC + 모바일 동시 사용, 원격 판단)
- AUQ 는 *PC 모달 전용* — 모바일 응답 불가
- 라이브 사례 (Telegram msg #3054): "이런경우 상호작용 안됨"
- 라이브 사례 (Telegram msg #3113): "리뷰 선택지에서 선택항목 노출 안됨" — hook (c) 분기 발화 실패 + AUQ 의 modal 특성으로 사용자 무력감 누적
- → AUQ 사용 자체가 multi-device 가치와 충돌

### 문제점

**현재 정책의 *반쪽 솔루션* 상태**:
- 알림 발송 = 가능 ✓
- 알림 수신 (모바일) = 가능 ✓
- 응답 발송 (모바일) = *정책상 차단* ✗
- 응답 수신 (LLM/에이전트) = *기술적으로 가능 (mcp_telegram_reply)*, *절차적으로 명문화 부재* ✗

→ 사용자의 *외부 지속 작업* 시나리오 (원래 의도) 가 좌초.

**현실과 fragment 간 누적 격차**:
- 제목 "Telegram 의사결정..." vs Discord 병행 현실 — 18곳 Telegram 명시
- 정책 표의 "보조 채널" 라인 — 서두의 원래 의도와 모순
- AUQ 사용 (§1.5 등) 과 모바일 응답 불가의 *암묵 모순*

### 해결 방안 (요약)

**정합성 회복 — 7 layer 동시 수정** (Critique 반영 — Layer 5 축소 + Layer 7 추가):

1. **제목 채널 중립화**: `## Telegram 의사결정 알림 프로토콜` → `## 의사결정 알림 프로토콜 (Telegram/Discord)`
2. **정책 표 line 379 교체**: "보조 채널 (응답 비활성)" → "**양방향 채널** (알림 + 응답 인식)"
3. **신규 §10 (§9 직후)**: 채널 답장을 의사결정 응답으로 처리하는 절차 명문화 (Critique 권장 #10 — 위치 통일)
4. **AUQ 사용 제거**: 모든 게이트를 텍스트 형식으로 통일 (Plan Accept 패턴). PC 모달 lock 제거.
5. **fragment 의 Telegram 명시 *축소 적용*** (Critique 권장 #1): 정책 표/제목/§10 + line 122 모순 줄만 (약 7-8곳). 환경변수 예시/.env.telegram 안내는 보호 (Discord active 시점 별도 spec)
6. **ADR 처리**: 정책 전환은 ADR-004 Amendment + 부정 절 보강 (결정 ID 부재 휴리스틱 한계)
7. **신규 Layer 7 — governance/agent.md 영문 출처 정합** (Critique 권장 #8): L401 의 "Telegram notifications" → "remote channel notifications (Telegram/Discord)"

## 🎯 요구사항

### Functional Requirements

1. **제목 채널 중립화** (line 91)
   - `## Telegram 의사결정 알림 프로토콜` → `## 의사결정 알림 프로토콜 (Telegram/Discord)`

2. **정책 표 line 379 교체**
   - 기존: `| **보조 채널** | 알림은 정보 전달용. Telegram 답장으로 명령을 수행하지 않음. |`
   - 신규: `| **양방향 채널** | 알림 발송 + 응답 인식. Telegram/Discord 답장을 의사결정 응답으로 처리 (§10). |`

3. **신규 §10 (응답 채널 인식 절차)**: 채널 답장 → 의사결정 응답 처리 절차 명문화
   - 트리거: `<channel source="telegram" ...>` 또는 `<channel source="discord" ...>` 태그가 사용자 메시지에 포함
   - 처리: 그 메시지 본문을 *해당 의사결정 게이트의 응답* 으로 처리. PC chat 응답과 동일 자격
   - §9 ack 응답: 같은 채널 reply 도구 사용 (단일 소스 원칙 유지)
   - 모호 케이스: 채널 응답이 *복수 의사결정 사이* 에 도착하면 *직전 게이트* 에 매핑. 모호 시 사용자에게 명시적 확인 요청

4. **AUQ 사용 제거**
   - 에이전트 절차에서 `AskUserQuestion` 도구 호출 *금지*. 모든 게이트를 텍스트 형식 (`[선택지] 1. ... 2. ... [권장] N번`) 통일
   - hook 의 (c) AUQ 분기 *코드는 유지* — defensive (다른 sub-agent / 외부 도구 가 AUQ 사용 시 cover)
   - fragment §5 의 AUQ 조건부 생략 규칙 (PR #10 도입) 은 *그대로 유지* — AUQ 가 없으면 자동 *해당 없음*. 규칙 자체는 legacy hook (c) 와 함께 보존

5. **fragment 내 Telegram 명시 — *축소 적용* (Critique 권장 #1)**
   - **변경 대상 (7-8곳)**:
     - 제목 (Layer 1)
     - 정책 표 라인 (Layer 2)
     - §10 신규 절차 (Layer 3)
     - 계층 1 자동 알림 묘사 (line 120, 122 등 — 본질적으로 모순/오해 유발하는 줄만)
   - **보호 (변경 안 함)** — 안내성 텍스트는 Discord active 시점의 별도 spec 에서 다룸:
     - `.env.telegram` 환경변수 예시 (line 102-107)
     - dedupe config 안내 (line 373)
     - 비활성화 안내 (line 389-392)
     - PR #8/9/10 의 *역사 사례* 줄 (line 233, 316)
     - `mcp__plugin_telegram_telegram__reply` 도구명

5a. **fragment line 122 모순 해소 (Critique 권장 #4)**: "에이전트는 이 알림에 대해 아무것도 하지 않아도 됩니다" → 양방향 정책 후 응답 처리는 §10 책임. 줄 수정 또는 단서 추가.

6. **ADR 처리**
   - ADR-004 의 Amendment 절에 *정책 전환* 추가 — "보조 채널 → 양방향 채널" 의 결정과 trade-off 명시
   - **부정 절 보강 (Critique 권장 #9)**: "결정 ID 부재로 복수 게이트 사이 응답은 휴리스틱 매핑 — 동시 활성 게이트 다수 시 누락 위험. 본 프로젝트 규모에서 trade-off 수용 (Slack action_id / Step Functions taskToken 패턴 미도입)"

7. **신규 Layer 7 — governance/agent.md L401 영문 출처 정합 (Critique 권장 #8)**
   - 기존: "The User often reviews these decisions on mobile (via Telegram notifications or Remote Control)"
   - 수정: "The User often reviews these decisions on mobile (via remote channel notifications — Telegram/Discord — or Remote Control)"
   - 이유: cross-document 정합성. fragment 만 손대면 영문 governance 출처 stale

8. **AUQ 사용 제거 적용 범위 명시 (Critique 권장 #7)**
   - 적용: 본 에이전트 (Claude Code main 세션) + sub-agent (Opus critique, code review 등)
   - **OOS**: 외부 도구 (Gemini CLI 모달, Codex 자체 UI 등) — 본 키트 통제 밖
   - sub-agent 도 *동일 절차* 권장하나 프롬프트로 명시 안 함 → 자율 판단 (sub-agent 가 본 fragment 를 직접 안 받음)

9. **§10 응답 매핑 알고리즘 한 줄 명시 (Critique 권장 #5)**
   - 옵션 매핑 규칙: 숫자 (`1`, `1번`, `첫번째`) + 권장 키워드 (`권장`, `recommended`) → 옵션 번호 매핑
   - 그 외 자유 텍스트 변형 (`"분해"`, `"빠른 fix"` 등) → 라벨 substring 매칭 시도
   - 매핑 실패 또는 모호 → 사용자에게 명시적 확인 요청 (사용자 round trip)
   - 이유: ChatOps / Hubot 의 키워드 화이트리스트 패턴. 에이전트별 해석 차이 차단

10. **AUQ 코드 dead branch 인지 (Critique 권장 #2/#3)**
    - hook 의 (c) AUQ 분기 + §5 의 AUQ 조건부 생략 규칙 = 본 에이전트가 AUQ 사용 안 함 → *이론상 발화 불가*
    - "legacy 보호" 가 아니라 *솔직한 dead branch/text 인지* — Amendment 의 부정 절에 명시
    - 향후 spec 의 트리거: dead branch 가 6개월 누적 시 *완전 제거* 재평가 (별도 spec)

### Non-Functional Requirements

1. **bash 3.2+ 호환** (마크다운 + ADR 변경. bash 영향 없음).
2. **dispatcher 일관**: notify.sh 호출은 PR #10 의 통일된 상태 유지.
3. **메타 dogfood**: 본 spec 의 모든 의사결정 게이트 응답에 *AUQ 사용 안 함*. 텍스트 형식 통일.
4. **회귀 보장**: PR #8/9/10 의 §5/§9 단일 소스 원칙 보존. 정책 전환은 *확장* 이지 *기존 규칙 폐기* 아님.

## 🚫 Out of Scope

- Discord MCP reply 도구 (`mcp__plugin_discord__...` 등) 의 *구현* — 본 spec 은 *절차 명문화* 만. 실제 도구 사용은 Discord MCP 가 active 화되는 시점.
- 채널 답장의 *권한 검증* (예: 화이트리스트 chat_id) — telegram MCP 가 access control 자체 처리.
- 채널 메시지 *내용 검증* (예: 명령 injection 방지) — 의사결정 응답은 *선택지 매핑* 만 수행, 임의 명령 실행 안 함.
- hook 의 (c) AUQ 분기 *코드 제거* — defensive 유지.
- `notify.sh` dispatcher 자체 변경 — PR #10 상태 그대로.

## 📑 ADR 후보 (Architecture Decision Records)

- [x] **ADR-004 Amendment 추가** (권장) — 정책 전환은 ADR-004 의 양방향 컨벤션의 *완전한 활성화*
- [ ] **ADR-005 신규** (대안) — 정책 변경은 *결정* 이므로 분리 ADR 가치 있음. 단 ADR-004 와 *주제 중복* (parent/child 구조)
- **결정**: ADR-004 Amendment 로 처리 (PR #10 의 Amendment 와 같은 위치). ADR-005 분리는 *premature*. 단일 ADR 의 history 가 추적성 더 깨끗.

## ✅ Definition of Done

- [ ] Fragment line 91 제목 채널 중립화
- [ ] Fragment line 379 정책 표 라인 교체 (보조 → 양방향)
- [ ] Fragment 신규 §10 (응답 채널 인식 절차) 추가
- [ ] Fragment 내 18곳 Telegram 명시 검사 — 일괄 채널 중립화 (역사 사례 보호)
- [ ] AUQ 사용 제거 — fragment 의 AUQ 관련 절차 명시 (§5 의 AUQ 조건부 생략 규칙은 보존)
- [ ] ADR-004 Amendment 추가 (정책 전환)
- [ ] 도그푸딩 sync (`.harness-kit/CLAUDE.fragment.md`)
- [ ] walkthrough + pr_description ship commit
- [ ] PR 생성 + 사용자 알림 완료
- [ ] 메타 dogfood — 본 spec 의 모든 의사결정 응답에 AUQ 미사용. 텍스트만 사용. (부수적)
- [ ] **메타 dogfood — 본질**: 본 spec 의 *한 게이트* (예: 항목 선택 또는 Plan Accept) 를 *실제 Telegram 답장* 으로 응답하여 §10 절차 실증 검증 (Critique 권장 #6)
- [ ] Layer 7: `sources/governance/agent.md` L401 영문 출처 채널 중립화
