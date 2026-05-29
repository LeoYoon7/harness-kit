# Walkthrough: spec-x-notify-bidirectional-policy

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 정책 전환 방식 | A) 보조 채널 유지 / B) 양방향 채널 전환 | B | 서두 (원격 판단 지원) 와 정책 표 (응답 차단) 모순 해소. multi-device 원래 가치 정상화 |
| AUQ 사용 처리 | A) 사용 유지 + hook fix / B) 사용 제거 + 코드 유지 / C) 사용/코드 모두 제거 | B | PC 모달 전용 → 모바일 응답 불가. dead branch 솔직 인지, 6개월 후 완전 제거 재평가 |
| Layer 5 범위 | A) 18곳 일괄 / B) 핵심 7곳만 (Critique 권장) | B | 안내성 텍스트 (.env.telegram 등) 는 Discord active 시점 별도 spec |
| Layer 7 추가 | A) fragment 만 / B) governance/agent.md L401 도 (Critique 권장) | B | cross-document 정합. 한 줄 추가로 stale 해소 |
| ADR 처리 | A) Amendment / B) ADR-005 신규 분리 | A | ADR-004 의 *완성형*. ADR-005 분리는 parent/child 부담 (Critique 평가) |
| dead branch 표현 | A) "legacy 보호" / B) "이론상 발화 불가" (솔직) | B | 외부 도구는 fragment 안 읽음. legacy 보호 실효성 0 (Critique 평가) |
| 응답 매핑 알고리즘 | A) 미명시 / B) ChatOps 패턴 한 줄 명시 | B | 에이전트별 해석 차이 차단. Hubot 패턴 차용 |

### ADR 승격 가이드

- [x] ADR-004 Amendment 추가 (2026-05-29) — 정책 전환 + 부정 절 보강
- [ ] ADR-005 신규 분리 — premature

## 💬 사용자 협의

- **주제**: §1.5 AUQ 리뷰 게이트의 알림 누락
  - **사용자 의견**: Telegram msg #3113 — "리뷰 선택지에서 선택항목 노출 안됨"
  - **합의**: 진단 → 본 spec 의 트리거
- **주제**: AUQ 발화 주체 / sdd vs LLM 책임
  - **사용자 의견**: "auq event 를 llm 에서 생성하는거야 sdd 가 생성하는거야?", "plan accept 는 auq 로 발화 안하잖아"
  - **합의**: 책임 분리 명확 — LLM (Claude) 이 emit, Claude Code 가 modal render, sdd 무관
- **주제**: 알림 정책 검토
  - **사용자 의견**: "알림정책은 누가 정한거야? 상호 작용이 안되는 알림은 크게 의미는 없음"
  - **합의**: 보조 채널 정책 anomaly 식별 → 양방향 전환
- **주제**: fragment 내부 모순 직접 지적
  - **사용자 의견**: line 93 (원격 판단 지원) vs line 379 (보조 채널) 모순 + Discord 병행에 Telegram 만 명시 제목
  - **합의**: 6 layer 정합화 + 채널 중립화
- **주제**: Critique 권장 반영
  - **사용자 응답**: "all" (Opus 권장 10항목 모두 반영)
  - **합의**: Layer 5 축소 + Layer 7 추가 + dogfood 본질 보강 등 10항목

## 🧪 검증 결과

### 1. 자동화 테스트

해당 없음 (마크다운 + ADR).

### 2. 수동 검증

#### grep
- `grep -ci "telegram" fragment` = 19 (사전 18 + §10 신규 mentions — 의도)
- `grep -c "보조 채널" fragment` = **0** ✓ (line 379 + line 136 모두 정합화)
- `grep -c "양방향 채널" fragment` = **3** ✓ (line 136 + line 379 + §10)
- `grep -c "Telegram notifications" agent.md` = **0** ✓ (Layer 7 검증)

#### 검증 중 추가 발견 — line 136
- 사전 검사에서 line 122 만 식별. 검증 단계에서 *line 136 도 "보조 채널 / 최종 의사결정은 여전히 PC/CLI 에서"* 로 양방향 정책과 모순 발견
- 추가 commit 으로 정합화 — *모순 검사가 한 번 누락된 학습 사례*

### 3. 메타 dogfood (Critique #6 — 본질 보강)

**본 spec 진행 자체가 §10 dogfood — 2회 실증**:
- msg #3130 (Telegram "2", Critique 선택) → §10 응답 인식 + mcp reply ack
- msg #3136 (Telegram "1", Plan Accept) → §10 응답 인식 + mcp reply ack

**모든 게이트 텍스트 형식** (AUQ 미사용 ✓):
- Plan Accept 게이트 — 텍스트 `1) Accept / 2) Critique`
- Critique 항목 선택 — 텍스트 (10항목 / all / none)
- 추가 게이트들 — 모두 텍스트

**채널별 응답 처리 패턴 확인**:
- Telegram 답장 → mcp reply 단독 (`mcp__plugin_telegram_telegram__reply` + `[ack]` 포맷)
- PC chat 응답 → notify.sh 단독 (`bash .harness-kit/bin/notify.sh ... info`)
- PR #10 의 단일 sink 원칙 보존 (Critique 검증: 정합)

## 🔍 발견 사항

- **모순 검사의 *완전성* 한계**: 사전엔 line 122 만 식별, 검증에서 line 136 추가 발견. fragment 가 비대해질수록 "grep + Edit" 만으로 *모든 모순* 식별 어려움. 향후 spec 의 *모순 검사* 는 *전체 본문 통독* 추가 권장.
- **§10 의 모호 케이스 처리 — 라이브 검증 데이터 누적 필요**: 본 spec 의 dogfood 2회는 *깔끔한* 케이스 (Telegram 응답, 명확한 매핑). 실제 모호 케이스 (자유 텍스트, 복수 게이트 사이) 의 처리는 6개월 운영 후 RCA 검토 가치 있음.
- **Discord MCP active 화 시점의 별도 spec 트리거**: 본 spec 은 Discord 절차 미명시. NM_NOTIFY_CHANNEL=both / Discord MCP reply 도구 active 시점에 §10 의 Discord 처리 명문화 필요.
- **AUQ dead branch 의 6개월 후 트리거**: hook (c) 분기 + §5 AUQ 조건부 생략 규칙 = 본 에이전트 사용 안 함 정책 하 dead. 6개월 누적 후 *완전 제거* spec-x 트리거 (ADR Amendment 명시).

## 🚧 이월 항목

- **Discord MCP reply 패턴 명문화** — Discord active 시점의 spec
- **AUQ 코드 완전 제거** — 6개월 dead 누적 후 spec-x
- **fragment 모순 검사 도구화** — 정책 vs 본문 sentence-level 모순 자동 검출 (현재는 사람이 grep)
- **`.env.telegram` 환경변수 예시 채널 중립화** — Discord active 시점 (현재 보호)
- **install.sh 의 README 한 줄 안내** — "notify.sh dispatcher 사용 권장" (현재 fragment 안 추가 안 함, 외부 문서로 이동)

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Opus 4.7 main) + Leo |
| **작성 기간** | 2026-05-29 |
| **최종 commit** | (ship 후 갱신) |
