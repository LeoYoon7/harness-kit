# Walkthrough: spec-x-notify-launcher-only

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 작업 mode 분류 | spec-x ceremony vs FF | spec-x | notify-channels/bidirectional/coherence/drop-both 시리즈와 일관된 누적. 발송 측 명시성은 정책 전환 (역호환 깨짐) 이라 PR 본문/walkthrough 흔적이 향후 회고·신규 사용자 onboarding 자료로 가치 있음. |
| unknown 값 처리 | telegram fallback 유지 vs silent skip 통합 | silent skip 통합 | "발송 측 명시성" 원칙 일관성. fallback 유지 시 오타/잘못된 launcher 설정이 *사용자 의도와 다른 채널* 로 흘러감. silent skip 은 사용자가 발송 실패를 알아채야 한다는 비용을 명시 의도 표현 비용보다 작다고 본 트레이드오프. |
| ADR 처리 | 신규 ADR vs ADR-004 amendment | ADR-004 amendment | 본 변경은 ADR-004 의 양방향 알림 컨벤션과 직교가 아니라 *발송 측 대칭 원칙*. 직전 amendment (drop-both) 가 응답 측 단일 소스를 세웠고, 본 변경이 발송 측 명시성을 세움 — 같은 ADR 의 연속 amendment 가 자연스러움. |

### ADR 승격 가이드

- [x] ADR 승격 대상 있음 → 작성됨: `docs/decisions/ADR-004-notification-twofold-decision-flow.md` 의 `### 2026-05-29 (spec-x-notify-launcher-only)` amendment
- [ ] 없음

## 💬 사용자 협의

- **주제**: 직접 `claude` 실행 시 알림 발송 여부
  - **사용자 의견**: "메신저 스크립트로 시작한 경우에만 해당 메시지 발송되도록 수정해줘. 즉 claude로 시작하면 메시지 X"
  - **합의**: launcher (`./telegram.sh` / `./discord.sh`) 가 명시적으로 `NM_NOTIFY_CHANNEL` 을 export 한 경우에만 발송. 직접 `claude` 실행 시는 silent skip. `.env.telegram` 존재가 발송 의도 표현을 대신하지 않음.

- **주제**: 작업 mode 선택
  - **사용자 의견**: (선택지 제시) "1" — spec-x
  - **합의**: spec-x 정식 ceremony 로 진행. walkthrough/PR 흔적 남김.

- **주제**: Plan Accept
  - **사용자 의견**: "1" — Plan Accept (Critique 생략)
  - **합의**: 즉시 Strict Loop 진입.

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: 본 키트는 dispatcher 단위 테스트 프레임워크 없음. plan.md 의 "수동 검증 시나리오" 1~6 으로 대체.

#### 통합 테스트
- **결과**: Integration Test Required = no. 미실시.

### 2. 수동 검증

각 시나리오는 `bash -x` 로 dispatcher 분기 트레이스 확인.

1. **Action**: `NM_NOTIFY_CHANNEL=telegram bash -x .harness-kit/bin/notify.sh "test-telegram" info`
   - **Result**: `+ CHANNEL=telegram` → `+ call_helper notify-telegram.sh` → `+ bash .../notify-telegram.sh test-telegram info`. ✅ telegram helper 호출.
2. **Action**: `NM_NOTIFY_CHANNEL=discord bash -x .harness-kit/bin/notify.sh "test-discord" info`
   - **Result**: `+ CHANNEL=discord` → `+ call_helper notify-discord.sh` → `+ bash .../notify-discord.sh test-discord info`. ✅ discord helper 호출.
3. **Action**: `NM_NOTIFY_CHANNEL=none bash -x .harness-kit/bin/notify.sh "test-none" info`
   - **Result**: `+ CHANNEL=none` → `+ case` → `+ :` → `+ exit 0`. ✅ 어느 helper 도 호출되지 않음 (silent skip).
4. **Action**: `unset NM_NOTIFY_CHANNEL; bash -x .harness-kit/bin/notify.sh "test-unset" info`
   - **Result**: `+ CHANNEL=none` (default 적용) → `+ :` → `+ exit 0`. ✅ silent skip. **behavior change 검증** — 변경 전엔 telegram fallback 이었음.
5. **Action**: `NM_NOTIFY_CHANNEL=unknown bash -x .harness-kit/bin/notify.sh "test-unknown" info`
   - **Result**: `+ CHANNEL=unknown` → `+ case` → `+ :` → `+ exit 0`. ✅ silent skip. **behavior change 검증** — 변경 전엔 telegram fallback 이었음.
6. **Action**: launcher 회귀 — `grep "export NM_NOTIFY_CHANNEL" telegram.sh discord.sh sources/root/*.sh`
   - **Result**: 4 곳 모두 line 34 에 `export NM_NOTIFY_CHANNEL=telegram` / `=discord` 그대로 존재. 본 변경의 *전제* 깨지지 않음 확인.

### 3. 동기화 검증

- **Action**: `diff sources/bin/notify.sh .harness-kit/bin/notify.sh`
- **Result**: 0 줄 (동일). ✅ sources/ ↔ .harness-kit/ drift 없음.

## 🔍 발견 사항

- `notify.sh` 의 `set -uo pipefail` 가 `set -e` 를 의도적으로 빼고 있음 — helper 호출 실패가 dispatcher 종료로 전파되지 않게 하는 의도 (silent failure 정책). 본 변경 영향 없음.
- launcher 가 `--dangerously-skip-permissions` 를 켜고 있음 — 본 변경과 무관하지만 향후 launcher 가 *책임 있게* 시작되어야 한다는 의도와 정합.

## 🚧 이월 항목

없음.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Opus 4.7) + Leo |
| **작성 기간** | 2026-05-29 |
| **최종 commit** | `3153aec` (ADR-004 amendment) |
