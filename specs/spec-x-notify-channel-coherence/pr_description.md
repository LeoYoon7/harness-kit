# docs(spec-x-notify-channel-coherence): 응답 알림 채널 일관성 (dispatcher 통일 + 단일 소스 원칙)

## 📋 Summary

### 배경 및 목적

PR #8 (spec-x-notify-choice-context) 도입 후 *3가지 라이브 결함* 식별:

1. **응답 ack 중복 발송** (Telegram msg #3075): 사용자가 Telegram 경유 응답 → 에이전트가 `mcp_telegram_reply` + `notify-telegram.sh` `[ack]` 둘 다 발송 → 노이즈
2. **§5 stop / AUQ 옵션 번호 불일치** (Telegram msg #3084+#3086): §5 stop 의 사람-작성 순서 (1.Gemini/2.Opus/3.Skip) 와 AUQ 의 권장-첫번째 (1.Skip(권장)/2.Gemini/3.Opus) → 같은 Skip 이 Telegram=3, Desktop=1 → 사용자가 3 누르면 Desktop 에서 Opus 선택 → 혼동
3. **Fragment 가 Telegram-only 하드코드** (사용자 추가 지적): §1-§9 의 11곳 `notify-telegram.sh` 직접 호출. dispatcher (`notify.sh`) 미사용 → Discord 사용자 미도달

세 결함의 공통 원인: **응답 측 알림의 단일 소스 부재**. 본 PR 은 *단일 소스 원칙* 도입.

### 주요 변경 사항

- [x] `sources/claude-fragments/CLAUDE.fragment.md` §5 — AUQ 조건부 생략 + 옵션 순서 sync 보조 규칙 추가
- [x] `sources/claude-fragments/CLAUDE.fragment.md` §9 — Telegram 단일 채널 (reply 본문에 `[ack]` 포함) / PC chat 시 `notify.sh` 단독
- [x] `sources/claude-fragments/CLAUDE.fragment.md` §1-§8 — `notify-telegram.sh` 11곳 → `notify.sh` 일괄 (§9 의 역사 사례 1곳만 보존)
- [x] `docs/decisions/ADR-004-notification-twofold-decision-flow.md` — `## 🔄 Amendments` 절 신설 (immutability 관행 유지)
- [x] 도그푸딩 sync — `.harness-kit/CLAUDE.fragment.md`

### Phase 컨텍스트

- **Phase**: 없음 (spec-x — Solo Spec)
- **본 SPEC 의 역할**: PR #8/9 의 응답 측 결함 통합 fix + 양방향 컨벤션 완성형

## 🎯 Key Review Points

1. **조건부 생략 (over-promising 완화)** — Critique 권장. AUQ 가 옵션 표현으로 *충분한* 케이스 (≤4 + free-text 미요구) 에만 §5 stop 생략. 생략 불가 케이스 (옵션 >4 등) 는 §5 stop 발송 + 순서 sync. 단일 sink = 주, 옵션 순서 sync = fallback 이중화.
2. **dispatcher 통일** — fragment §1-§8 의 11곳 `notify-telegram.sh` → `notify.sh`. `NM_NOTIFY_CHANNEL` 라우팅으로 Telegram/Discord 자동 분기. §9 안의 *역사 사례 1곳* 은 의도적 `notify-telegram.sh` 유지 (당시 시점 사실 기록).
3. **Discord 추상 표현 축소** — Critique 권장. §9 본문에서 Discord MCP reply 추상 표현 제거. Discord active 화 시점의 별도 spec 에서 다룸. 현재는 dispatcher 만으로 cover.
4. **ADR-004 Amendment 절 신설** — 단순 부정 절 추가 X. ADR immutability 관행 유지 + 단일 소스 원칙 추적성 확보.
5. **메타 dogfood timing 명확화** — Plan Accept 응답은 fragment 미수정 시점이라 *기존 규칙* 적용. Task 3-5 commit 직후부터 새 규칙 적용. timing 모순 제거.

## 🧪 Verification

### dispatcher 호출 검증
- `bash .harness-kit/bin/notify.sh "smoke test" info` → ✓ silent success
- Discord active 환경 아님 — `NM_NOTIFY_CHANNEL=both` 검증 미실시

### fragment grep
- 사전: `grep -c notify-telegram.sh CLAUDE.fragment.md` = 12
- 사후: 1 (§9 의 PR #9 시점 역사 사례 의도 보존)

### 메타 dogfood (timing 별)
- Plan Accept "1" 응답: 기존 규칙 (양쪽 발송)
- Task 3-5 commit 직후: 새 규칙 (단일 sink) 시작
- Task 6 Amendment 응답: 새 규칙 + Amendment 참조

## 📦 Files Changed

### 🛠 Modified Files

- `sources/claude-fragments/CLAUDE.fragment.md` (+64, -22): §5 + §9 + §1-§8 dispatcher 통일
- `.harness-kit/CLAUDE.fragment.md` (+64, -22): 도그푸딩 sync
- `docs/decisions/ADR-004-notification-twofold-decision-flow.md` (+24): Amendments 절 신설
- `backlog/queue.md` (+1): spec-x 등록

### 🆕 New Files

- `specs/spec-x-notify-channel-coherence/{spec,plan,task,walkthrough,pr_description,critique}.md`

## ✅ Definition of Done

- [x] Fragment §5 갱신 — 조건부 생략 + 옵션 순서 sync 보조 규칙
- [x] Fragment §9 갱신 — Telegram 단일 채널 + Discord 추상 축소
- [x] Fragment §1-§8 dispatcher 통일 (역사 사례 1곳 보존)
- [x] ADR-004 Amendment 절 신설
- [x] 도그푸딩 sync 완료
- [x] 메타 dogfood timing 적용 (Task 3-5 직후부터)
- [x] walkthrough + pr_description ship commit
- [x] (예정) push + PR 생성 + 사용자 알림

## 🔗 관련 자료

- Spec: `specs/spec-x-notify-channel-coherence/spec.md`
- Plan: `specs/spec-x-notify-channel-coherence/plan.md`
- Walkthrough: `specs/spec-x-notify-channel-coherence/walkthrough.md`
- Critique: `specs/spec-x-notify-channel-coherence/critique.md` — Opus 권장 6항목 모두 반영
- 직전 PR (라이브 결함 발견): #8 `spec-x-notify-choice-context` + #9 `spec-x-notify-auq-scope-fix`
- 사용자 보고: Telegram msg #3075 (ack 중복), #3084+#3086 (번호 불일치)
- ADR-004 Amendment: `docs/decisions/ADR-004-notification-twofold-decision-flow.md` `## 🔄 Amendments`
