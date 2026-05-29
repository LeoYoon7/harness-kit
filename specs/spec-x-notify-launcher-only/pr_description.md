# refactor(spec-x-notify-launcher-only): silent-skip notify dispatcher when launcher omits channel

> 첫 줄은 commit subject 와 정확히 일치해야 합니다.

## 📋 Summary

### 배경 및 목적

`sources/bin/notify.sh` dispatcher 는 `NM_NOTIFY_CHANNEL` 미설정 시 `telegram` fallback 으로 동작했다. launcher (`./telegram.sh` / `./discord.sh`) 는 이 변수를 명시 export 하지만, 직접 `claude` 로 시작한 세션은 변수가 미설정 → `.env.telegram` 만 있으면 사용자가 launcher 를 선택하지 *않았는데도* 알림이 발송된다. 사용자 의도 (launcher 선택) 가 발송 결과에 반영되지 않는 비대칭.

본 spec 은 dispatcher 의 default 와 unknown 값 fallback 을 silent skip 으로 전환한다. launcher 가 `NM_NOTIFY_CHANNEL` 을 명시 export 한 경우에만 발송. 발송 측 의도 표현이 환경변수 명시 설정 한 가지로 좁혀진다. ADR-004 의 응답 측 단일 소스 원칙과 *대칭* 되는 발송 측 명시성 원칙으로 amendment 기록.

### 주요 변경 사항

- [x] **dispatcher default** — `${NM_NOTIFY_CHANNEL:-telegram}` → `:-none}`. 미설정 시 silent skip.
- [x] **dispatcher unknown fallback** — `*) call_helper "notify-telegram.sh"` → `*) : ;;` (silent skip). 알 수 없는 값도 launcher 미명시와 동일 취급.
- [x] **헤더 주석** — 라우팅 표를 3가지 (telegram / discord / silent skip) 로 갱신 + "발송 측 명시성 원칙" 명문화 + "직접 claude 실행 시 → silent skip" 추적 주석 추가.
- [x] **도그푸딩 sync** — `sources/bin/notify.sh` ↔ `.harness-kit/bin/notify.sh` 한 commit 내 동시 변경. diff 0줄 확인.
- [x] **ADR-004 Amendment** — `2026-05-29 (spec-x-notify-launcher-only)` 절 추가. 배경 / 결정 / 긍정·부정 Consequences / 관련 spec / 상태.

### Phase 컨텍스트

- **Phase**: `phase-x` (Solo Spec — 미소속)
- **본 SPEC 의 역할**: ADR-004 양방향 컨벤션의 발송 측 명시성 원칙을 dispatcher 측에 일관화. drop-both (응답 측 단일 채널) + 본 spec (발송 측 launcher 명시성) 으로 양방향 대칭 완성.

## 🎯 Key Review Points

1. **Behavior break (의도됨)**: `.env.telegram` 만 있고 직접 `claude` 실행하던 사용자는 본 변경 이후 알림 끊김. 마이그레이션은 `./telegram.sh` / `./discord.sh` 사용. 사용자의 명시 요청 ("claude로 시작하면 메시지 X") 이 의도된 break 의 근거.
2. **Unknown 값 silent skip — 트레이드오프**: 오타/잘못된 launcher 설정도 silent 로 사라진다. 변경 전엔 telegram fallback 으로 *의도와 다른 채널* 로 흘러갔던 것보다 silent skip 이 사용자 의도 보호에 우선한다는 판단.
3. **도그푸딩 sync — 두 파일 짝**: `sources/bin/notify.sh` ↔ `.harness-kit/bin/notify.sh` 한 commit 에서 변경. diff 0줄 확인.
4. **launcher 영향 없음**: `sources/root/telegram.sh` 와 `sources/root/discord.sh` 가 이미 line 34 에 `export NM_NOTIFY_CHANNEL=telegram` / `=discord` 를 그대로 가지고 있어 본 변경의 전제가 깨지지 않음 (검증 완료).
5. **ADR amendment vs 신규 ADR**: ADR-004 Amendments 절에 추가. drop-both (응답 측 단일 채널) → launcher-only (발송 측 명시성) 의 *대칭 원칙 진화* 가 같은 ADR 의 연속 amendment 로 보존됨.

## 🧪 Verification

### 자동 테스트

본 키트엔 shell unit test 프레임워크 없음 — 수동 검증 시나리오로 대체.

### 수동 검증 시나리오

`bash -x` 로 dispatcher 분기 트레이스 확인.

| # | 명령 | 기대 동작 | 결과 |
|---|---|---|---|
| 1 | `NM_NOTIFY_CHANNEL=telegram bash -x .harness-kit/bin/notify.sh "test" info` | telegram helper 호출, exit 0 | ✅ |
| 2 | `NM_NOTIFY_CHANNEL=discord bash -x .harness-kit/bin/notify.sh "test" info` | discord helper 호출, exit 0 | ✅ |
| 3 | `NM_NOTIFY_CHANNEL=none bash -x .harness-kit/bin/notify.sh "test" info` | silent skip (`+ :`), exit 0 | ✅ |
| 4 | `unset NM_NOTIFY_CHANNEL; bash -x .harness-kit/bin/notify.sh "test" info` | silent skip (`+ CHANNEL=none` → `+ :`), exit 0 | ✅ behavior change 확인 |
| 5 | `NM_NOTIFY_CHANNEL=unknown bash -x .harness-kit/bin/notify.sh "test" info` | silent skip (`+ CHANNEL=unknown` → `+ :`), exit 0 | ✅ behavior change 확인 |
| 6 | launcher 회귀 — `grep "export NM_NOTIFY_CHANNEL" telegram.sh discord.sh sources/root/*.sh` | 4 곳 모두 line 34 그대로 | ✅ |

### 동기화 검증

- `diff sources/bin/notify.sh .harness-kit/bin/notify.sh` → 0줄

## 📦 Files Changed

### 🛠 Modified Files

- `sources/bin/notify.sh` (+10, -11): default + unknown fallback silent skip + 헤더 주석 갱신
- `.harness-kit/bin/notify.sh` (+10, -11): 도그푸딩 sync
- `docs/decisions/ADR-004-notification-twofold-decision-flow.md` (+19, -0): Amendment 절 추가

### 🆕 New Files

- `specs/spec-x-notify-launcher-only/spec.md`
- `specs/spec-x-notify-launcher-only/plan.md`
- `specs/spec-x-notify-launcher-only/task.md`
- `specs/spec-x-notify-launcher-only/walkthrough.md`
- `specs/spec-x-notify-launcher-only/pr_description.md`

**Total**: 8 files changed (3 modified + 5 new)

## ✅ Definition of Done

- [x] 수동 검증 시나리오 1-6 통과 (자동 단위 테스트 없음 — N/A)
- [x] `walkthrough.md` ship commit 완료
- [x] `pr_description.md` ship commit 완료
- [-] lint / type check — 본 키트 staged-lint 는 shellcheck 미설치로 skip (정상)
- [ ] 사용자 검토 요청 알림 완료 (ship 직후 발송)

## 🔗 관련 자료

- ADR: `docs/decisions/ADR-004-notification-twofold-decision-flow.md` (Amendment 2026-05-29 추가)
- 직전 관련 spec: `specs/spec-x-notify-drop-both/` (응답 측 단일 채널 — 본 spec 과 대칭 쌍)
- 키트 launcher: `sources/root/telegram.sh`, `sources/root/discord.sh` (line 34 `export NM_NOTIFY_CHANNEL` 그대로)
- Walkthrough: `specs/spec-x-notify-launcher-only/walkthrough.md`
