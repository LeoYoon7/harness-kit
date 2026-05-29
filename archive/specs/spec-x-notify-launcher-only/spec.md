# spec-x-notify-launcher-only: notify dispatcher 의 기본 fallback 제거 — launcher 로 시작했을 때만 발송

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-notify-launcher-only` |
| **Phase** | `phase-x` |
| **Branch** | `spec-x-notify-launcher-only` |
| **상태** | Planning |
| **타입** | Refactor |
| **Integration Test Required** | no |
| **작성일** | 2026-05-29 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

`sources/bin/notify.sh` 및 도그푸딩 결과 `.harness-kit/bin/notify.sh` 의 dispatcher 는 환경변수 `NM_NOTIFY_CHANNEL` 값으로 라우팅한다.

| 값 | 동작 |
|---|---|
| `telegram` / **미설정** | `notify-telegram.sh` 호출 |
| `discord` | `notify-discord.sh` 호출 |
| `none` | silent skip |
| 알 수 없는 값 | telegram fallback |

launcher 스크립트 `sources/root/telegram.sh` / `sources/root/discord.sh` 는 시작 시 `NM_NOTIFY_CHANNEL=telegram` / `discord` 를 export 한다. 직접 `claude` 명령으로 시작한 세션에서는 변수가 미설정 → 현재 정책상 **telegram fallback** → `.env.telegram` 이 존재하면 알림이 발송된다.

### 문제점

1. **암시적 발송**: 사용자가 `./telegram.sh` 같은 launcher 를 명시적으로 선택하지 않았는데도 `.env.telegram` 만 있으면 telegram 으로 알림이 발송된다. *"메신저 채널을 켤 의도"* 와 *"보조 토큰 파일 존재"* 가 동일시되어 의도가 불투명.
2. **알 수 없는 값 침묵 fallback**: 오타나 잘못된 launcher 설정으로 `NM_NOTIFY_CHANNEL` 에 의도하지 않은 값이 들어가도 telegram 으로 흘러간다. 사용자는 자기 의도와 다른 채널로 알림이 갔다는 사실을 모른다.
3. **발송 측 명시성 부재**: ADR-004 Amendment 가 *응답 측* 에 단일 소스 원칙을 세웠으나, *발송 측* 에는 "launcher 가 명시적으로 채널을 선언했을 때만 발송" 같은 대칭 원칙이 없다. 발송 측 의도가 환경변수 부재 (fallback) 로도 표현될 수 있는 비대칭.

### 해결 방안 (요약)

`notify.sh` 의 `NM_NOTIFY_CHANNEL` 기본값을 `telegram` → `none` 으로 전환하고, 알 수 없는 값 fallback 도 silent skip 으로 바꾼다. 결과: launcher (`./telegram.sh` / `./discord.sh`) 가 명시적으로 `NM_NOTIFY_CHANNEL=telegram` / `discord` 를 export 한 경우에만 알림 발송. 직접 `claude` 실행 시는 silent skip. 발송 측 의도 표현이 환경변수 명시 설정 한 가지로 좁혀진다.

## 🎯 요구사항

### Functional Requirements

1. `sources/bin/notify.sh` 와 `.harness-kit/bin/notify.sh` 가 `NM_NOTIFY_CHANNEL` 미설정 입력 시 silent skip (helper 호출 없음, exit 0) 해야 한다.
2. dispatcher 가 `NM_NOTIFY_CHANNEL` 알 수 없는 값 입력 시 silent skip 해야 한다 (이전: telegram fallback).
3. 명시적 `telegram` / `discord` / `none` 값은 기존 동작 그대로 유지한다.
4. dispatcher 의 주석에서 라우팅 표가 정정되어야 한다 — 미설정 = none = silent skip, 알 수 없는 값 = silent skip.
5. `docs/decisions/ADR-004-notification-twofold-decision-flow.md` 에 amendment 절이 추가되어 발송 측 명시성 원칙과 결정 근거가 기록되어야 한다.

### Non-Functional Requirements

1. **도그푸딩 동기화**: `sources/` 와 `.harness-kit/` 의 동일 의도 파일은 *한 commit* 내에서 함께 변경되어야 한다 (분리 commit 금지 — drift 방지).
2. **launcher 영향 없음**: `sources/root/telegram.sh` / `sources/root/discord.sh` 는 이미 `NM_NOTIFY_CHANNEL` 을 명시 export 하므로 본 변경의 영향 받지 않는다 (검증만).
3. **호환성 — Breaking 의도**: `.env.telegram` 만 있고 직접 `claude` 실행하던 사용자는 본 변경 이후 알림이 끊긴다. *이는 의도된 break* — 사용자가 launcher 선택을 명시하지 않았다면 알림 발송도 명시되지 않은 것으로 해석. 마이그레이션은 `./telegram.sh` / `./discord.sh` 사용으로 전환.

## 🚫 Out of Scope

- launcher 스크립트 (`sources/root/telegram.sh` / `sources/root/discord.sh`) 자체 동작 변경.
- `notify-telegram.sh` / `notify-discord.sh` helper 동작 변경.
- 직접 `claude` 실행 시 자동으로 launcher 로 전환하는 wrapper 신규 도입 (사용자가 launcher 선택을 *명시적으로* 표현해야 한다는 원칙과 충돌).
- `.env.{telegram,discord}` 파일 포맷 변경.
- `archive/specs/*` 및 머지된 spec 의 telegram fallback 언급 — *당시 시점 사실 기록* 으로 동결.

## 📑 ADR 후보 (Architecture Decision Records)

- [x] ADR 가치 있는 결정 있음 → 후보 한 줄 요약: 기존 **ADR-004 의 Amendment 절에 추가** (type: convention) — 응답 측 단일 소스 원칙과 대칭이 되는 *발송 측 명시성 원칙* 으로 양방향 컨벤션 진화 기록
- [ ] 없음

## 🔍 Critique 결과 (선택)

미실행. 사용자 명시 요청 ("메신저 스크립트로 시작한 경우에만 메시지 발송") 이 의도가 명확하고 변경 범위가 좁아 비평 단계 불필요.

## ✅ Definition of Done

- [ ] `notify.sh` (sources + .harness-kit) default 가 `none` 으로 전환 + unknown 값 fallback 도 silent skip + 주석 정정
- [ ] ADR-004 amendment 추가 (2026-05-29, `launcher-only dispatch`)
- [ ] 수동 검증: `unset NM_NOTIFY_CHANNEL; bash .harness-kit/bin/notify.sh "..." info` 가 silent skip
- [ ] 수동 검증: `NM_NOTIFY_CHANNEL=telegram bash .harness-kit/bin/notify.sh "..." info` 가 telegram helper 로 라우팅됨
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-notify-launcher-only` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
