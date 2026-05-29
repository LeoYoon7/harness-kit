# spec-x-notify-drop-both: notify dispatcher 의 `both` 채널 분기 제거

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-notify-drop-both` |
| **Phase** | `phase-x` |
| **Branch** | `spec-x-notify-drop-both` |
| **상태** | Planning |
| **타입** | Refactor |
| **Integration Test Required** | no |
| **작성일** | 2026-05-29 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

`sources/bin/notify.sh` 및 도그푸딩 결과 `.harness-kit/bin/notify.sh` 의 dispatcher 는 환경변수 `NM_NOTIFY_CHANNEL` 값으로 4가지 라우팅을 지원한다.

| 값 | 동작 |
|---|---|
| `telegram` / 미설정 | `notify-telegram.sh` 만 호출 |
| `discord` | `notify-discord.sh` 만 호출 |
| `both` | 두 helper 모두 호출 |
| `none` | silent skip |

`both` 는 spec-x-notify-channels 도입 시점부터 *redundancy 시나리오* 를 위해 마련된 옵션이며, fragment §9 의 ack note (line 318) 에 "현재는 `notify.sh` dispatcher 가 `NM_NOTIFY_CHANNEL` (예: `both`) 설정 시 Discord 도 §9 ack 도달 보장" 로 노출된다. ADR-004 / fragment §10 의 **양방향 응답 채널** 전환 (spec-x-notify-bidirectional-policy) 이후 `both` 가 단일 소스 원칙과 정면 충돌하는 상태가 되었다.

### 문제점

1. **양방향 ack 비대칭**: §9/§10 절차는 사용자가 응답한 채널로만 `[ack]` 를 발송한다. `both` 로 원본 게이트를 양쪽에 뿌려도 응답은 한쪽에만 도달한다. → Telegram 응답 시 Discord 에는 ack 없이 원본 gate 만 떠 있어 *모바일 사용자가 "응답 미완"으로 오인*. 이는 §9 의 핵심 가치 (multi-device 상태 동기화) 를 *오히려 깬다*.
2. **단일 소스 원칙 위배**: ADR-004 Amendment (2026-05-29) 의 "응답 측 단일 채널" 결정이 `both` 와 모순. dispatcher 가 발화 측 다중 sink 를 허용하면 원칙이 일관되지 않다.
3. **노이즈**: 의도된 redundancy 가 아닌데 `both` 가 설정될 경우 모든 게이트가 두 번 알림되어 사용자 피로 누적.
4. **운영 부담**: `.env.telegram` + `.env.discord` 두 파일 + 두 helper + dispatcher 의 `both` 분기 = 운영 surface 확장. redundancy 가 실제로 필요한 빈도 대비 비용 비대칭.

### 해결 방안 (요약)

`notify.sh` 에서 `both` case 자체를 제거한다. `NM_NOTIFY_CHANNEL` 라우팅은 `telegram` / `discord` / `none` (silent skip) 만 남기고, 미설정/알 수 없는 값은 `telegram` fallback 을 유지한다. fragment §9 ack note (line 318) 에서 "예: `both`" 표현을 제거하고, ADR-004 에 짧은 amendment 로 결정을 기록한다. archive/ 및 이미 merged 된 spec 문서 (`spec-x-notify-channel-coherence`, `spec-x-notify-bidirectional-policy`) 의 `both` 언급은 *당시 시점의 사실 기록* 으로 동결한다.

## 🎯 요구사항

### Functional Requirements

1. `sources/bin/notify.sh` 와 `.harness-kit/bin/notify.sh` 가 `NM_NOTIFY_CHANNEL=both` 입력 시 `telegram` fallback (알 수 없는 값과 동일한 경로) 로 동작해야 한다.
2. dispatcher 의 주석에서 `both` 옵션 안내가 제거되고, 라우팅 표가 3가지 (telegram/discord/none + 미설정→telegram fallback) 로 정정되어야 한다.
3. `sources/claude-fragments/CLAUDE.fragment.md` 및 `.harness-kit/CLAUDE.fragment.md` 의 line 318 ack note 에서 "예: `both`" 표현이 제거되어야 한다.
4. `docs/decisions/ADR-004-notification-twofold-decision-flow.md` 에 amendment 절이 추가되어 `both` 채널 제거 결정과 근거가 기록되어야 한다.

### Non-Functional Requirements

1. **도그푸딩 동기화**: `sources/` 와 `.harness-kit/` 의 동일 의도 파일은 *한 commit* 내에서 함께 변경되어야 한다 (분리 commit 금지 — drift 방지).
2. **Backward compatibility**: `NM_NOTIFY_CHANNEL=both` 가 설정된 기존 환경에서 *알림이 끊기지 않아야* 한다 (telegram fallback 으로 자동 흡수).
3. **launcher 영향 없음**: `sources/root/telegram.sh` 와 `sources/root/discord.sh` 는 각각 `telegram` / `discord` 를 export 하므로 본 변경 영향 없음 (검증만).

## 🚫 Out of Scope

- `archive/specs/*` 내 `both` 언급 — *immutable 보존소* 원칙 (specs/CLAUDE.md). 미수정.
- 이미 merged 된 `specs/spec-x-notify-channel-coherence/` 및 `specs/spec-x-notify-bidirectional-policy/` 의 `both` 언급 — *당시 시점 사실 기록* 으로 동결. 미수정.
- `notify-telegram.sh` / `notify-discord.sh` helper 자체의 동작 변경.
- `.env.{telegram,discord}` 파일 포맷 변경.
- `both` 와 별개의 redundancy 메커니즘 (예: 채널 fallback chain) 신규 도입.

## 📑 ADR 후보 (Architecture Decision Records)

- [x] ADR 가치 있는 결정 있음 → 후보 한 줄 요약: 기존 **ADR-004 의 Amendment 절에 추가** (type: convention) — 새 ADR 생성보다 양방향 컨벤션 진화 기록으로 보존이 자연스러움
- [ ] 없음

## 🔍 Critique 결과 (선택)

미실행. 결정 자체가 직전 대화에서 ADR-004 Amendment 의 단일 소스 원칙과의 모순을 식별하고 사용자 명시 승인으로 진행한 것이라, 비평 단계 불필요.

## ✅ Definition of Done

- [ ] `notify.sh` (sources + .harness-kit) 에서 `both` case 제거 + 주석 정정
- [ ] fragment (sources + .harness-kit) line 318 의 "예: `both`" 표현 제거
- [ ] ADR-004 amendment 추가 (2026-05-29, `drop 'both' channel`)
- [ ] 수동 검증: `NM_NOTIFY_CHANNEL=both bash .harness-kit/bin/notify.sh "..." info` 가 `notify-telegram.sh` 로 라우팅됨
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-notify-drop-both` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
