# refactor(spec-x-notify-drop-both): drop 'both' channel from notify dispatcher

> 첫 줄은 commit subject 와 정확히 일치해야 합니다.

## 📋 Summary

### 배경 및 목적

`sources/bin/notify.sh` dispatcher 의 `NM_NOTIFY_CHANNEL=both` 라우팅이 ADR-004 Amendment (2026-05-29, channel-coherence) 의 **응답 측 단일 채널 원칙** 과 모순. `both` 로 원본 게이트를 양쪽 채널에 뿌려도 §9/§10 의 ack 는 응답 채널 한쪽에만 도달 → 반대 채널에 *응답 미완* 인상 잔존 → multi-device 상태 동기화 가치 (ADR-004 본문 결정) 가 오히려 깨진다.

본 spec 은 `both` case 분기를 dispatcher 에서 제거하고, fragment §9 의 ack note 표현을 정합 갱신하며, ADR-004 에 amendment 절을 추가한다.

### 주요 변경 사항

- [x] **dispatcher** — `case "$CHANNEL"` 에서 `both` 라벨 제거. `telegram` / `discord` / `none` 만 남기고, 미지정/알 수 없는 값 (과거 `both` 포함) 은 `*)` fallback 으로 telegram 발송 흡수 (backward compatible).
- [x] **헤더 주석** — 라우팅 표를 3가지로 갱신 + "spec-x-notify-drop-both 에서 제거" 추적 주석 추가 + launcher 예시 정정 (`discord-nextmarket-system.sh` → `telegram.sh / discord.sh`).
- [x] **fragment §9 ack note** — `NM_NOTIFY_CHANNEL` (예: `both`) → `NM_NOTIFY_CHANNEL=discord` 로 정합 갱신 (sources + 도그푸딩 동시).
- [x] **ADR-004 Amendment** — `2026-05-29 (spec-x-notify-drop-both)` 절 추가. 배경 / 결정 / 관련 spec / 상태.

### Phase 컨텍스트

- **Phase**: `phase-x` (Solo Spec — 미소속)
- **본 SPEC 의 역할**: ADR-004 양방향 컨벤션의 단일 소스 원칙을 dispatcher 측까지 일관화. channel-coherence + bidirectional-policy 의 후속.

## 🎯 Key Review Points

1. **Backward compatibility — `*)` fallback**: `NM_NOTIFY_CHANNEL=both` 가 설정된 환경이 만약 존재한다면 *알림이 끊기지 않고* telegram 으로 silent fallback. 본 키트 내 launcher 에 `both` export 가 없으므로 영향 범위는 *사용자가 의도적으로 env 로 export 한 경우* 만.
2. **도그푸딩 sync — 두 파일 짝**: `sources/bin/notify.sh` ↔ `.harness-kit/bin/notify.sh`, `sources/claude-fragments/CLAUDE.fragment.md` ↔ `.harness-kit/CLAUDE.fragment.md` 각각 같은 commit 에서 변경. diff 0줄 확인.
3. **archive / merged spec 동결**: `specs/spec-x-notify-channel-coherence/`, `specs/spec-x-notify-bidirectional-policy/`, `archive/specs/*` 의 `both` 언급은 *당시 시점 사실 기록* 으로 미수정 — `specs/CLAUDE.md` 의 immutable 원칙 따름.
4. **ADR amendment vs 신규 ADR**: 신규 ADR (예: ADR-006) 대신 ADR-004 의 Amendments 절에 추가. 양방향 컨벤션 → 단일 소스 원칙 → dispatcher 단일 sink 의 연속 진화 추적성 우선.

## 🧪 Verification

### 자동 테스트

본 키트엔 shell unit test 프레임워크 없음 — 수동 검증 시나리오로 대체.

### 수동 검증 시나리오

| # | 명령 | 기대 동작 | 결과 |
|---|---|---|---|
| 1 | `NM_NOTIFY_CHANNEL=telegram bash .harness-kit/bin/notify.sh "test" info` | telegram 분기 호출, exit 0 | ✅ |
| 2 | `unset NM_NOTIFY_CHANNEL; bash .harness-kit/bin/notify.sh "test" info` | `:-telegram` fallback, exit 0 | ✅ |
| 3 | `NM_NOTIFY_CHANNEL=discord bash .harness-kit/bin/notify.sh "test" info` | discord 분기 호출, exit 0 | ✅ |
| 4 | `NM_NOTIFY_CHANNEL=both bash .harness-kit/bin/notify.sh "test" info` | `*)` fallback → **telegram 만** 호출 (xtrace 확인). 변경 전엔 둘 다, 변경 후엔 telegram 만. | ✅ behavior change 확인 |
| 5 | `NM_NOTIFY_CHANNEL=none bash .harness-kit/bin/notify.sh "test" info` | silent skip, exit 0 | ✅ |

### 동기화 검증

- `diff sources/bin/notify.sh .harness-kit/bin/notify.sh` → 0줄
- `diff sources/claude-fragments/CLAUDE.fragment.md .harness-kit/CLAUDE.fragment.md` → 0줄

## 📦 Files Changed

### 🛠 Modified Files

- `sources/bin/notify.sh` (+9, -8): `both` case 제거 + 주석 갱신
- `.harness-kit/bin/notify.sh` (+9, -8): 도그푸딩 sync
- `sources/claude-fragments/CLAUDE.fragment.md` (+1, -1): §9 ack note 정합 갱신
- `.harness-kit/CLAUDE.fragment.md` (+1, -1): 도그푸딩 sync
- `docs/decisions/ADR-004-notification-twofold-decision-flow.md` (+12, -0): Amendment 절 추가

### 🆕 New Files

- `specs/spec-x-notify-drop-both/spec.md`
- `specs/spec-x-notify-drop-both/plan.md`
- `specs/spec-x-notify-drop-both/task.md`
- `specs/spec-x-notify-drop-both/walkthrough.md`
- `specs/spec-x-notify-drop-both/pr_description.md`

**Total**: 10 files changed (5 modified + 5 new)

## ✅ Definition of Done

- [x] 수동 검증 시나리오 1-5 통과 (자동 단위 테스트 없음 — N/A)
- [x] `walkthrough.md` ship commit 완료
- [x] `pr_description.md` ship commit 완료
- [-] lint / type check — 본 키트 staged-lint 는 shellcheck 미설치로 skip (정상)
- [ ] 사용자 검토 요청 알림 완료 (ship 직후 발송)

## 🔗 관련 자료

- ADR: `docs/decisions/ADR-004-notification-twofold-decision-flow.md` (Amendment 2026-05-29 추가)
- 직전 관련 spec: `specs/spec-x-notify-channel-coherence/`, `specs/spec-x-notify-bidirectional-policy/` (동결, 미수정)
- 키트 launcher: `sources/root/telegram.sh`, `sources/root/discord.sh` (`both` export 없음 — 안전성 확인)
- Walkthrough: `specs/spec-x-notify-drop-both/walkthrough.md`
