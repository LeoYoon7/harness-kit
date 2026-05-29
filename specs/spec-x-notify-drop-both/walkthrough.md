# Walkthrough: spec-x-notify-drop-both

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| `both` 채널 분기를 어떻게 제거할까 — case 자체 삭제 vs deprecation 경고 한 release 후 삭제 | A. case 자체 즉시 삭제 (fallback 흡수) / B. case 유지하되 stderr 경고 후 다음 release 에 삭제 | A | 본 키트 surface 내에는 `both` 를 export 하는 launcher 가 존재하지 않음 (`telegram.sh` / `discord.sh` 만 존재). 즉 *키트 사용자가 의도적으로 환경변수로 `both` 를 export 한 경우만* 영향. 그 경우조차 `*)` fallback 으로 telegram 발송이 유지되므로 silent 가 아닌 *알림 채널 1개 감소*. bash 스크립트 단순성 우선 + ADR-004 amendment 기록으로 추적성 확보 → 즉시 삭제 채택. |
| ADR 신규 작성 vs ADR-004 amendment | A. 새 ADR (예: ADR-006) / B. 기존 ADR-004 의 Amendments 절에 추가 | B | ADR-004 자체가 *양방향 컨벤션* 이고 channel-coherence Amendment 가 *단일 소스 원칙* 을 명시. 본 변경은 그 원칙의 연속 진화 (dispatcher 측 단일 sink) 라 같은 ADR 의 연속 amendment 가 추적성 우수. |
| archive/ + 이미 merged 된 spec 문서 (`channel-coherence`, `bidirectional-policy`) 의 `both` 언급 처리 | A. 사후 수정 / B. 동결 (당시 시점 사실 기록) | B | `specs/CLAUDE.md` 의 머지 후 immutable 원칙. archive/ 는 grep false-positive 보존소 (정합성 검사 시 건너뛰기 대상). 사후 수정은 *역사 기록* 가치를 깨고 surface 만 늘림. |
| Pre-flight (spec/plan/task 원본 작성) commit 분리 vs 첫 작업 commit 에 흡수 | A. 별도 docs commit / B. 첫 refactor commit 에 묶기 | A | history 의도 분리 — *PLANNING 산출물* 과 *코드 변경* 은 서로 다른 의도. 향후 PR squash 시 본문 표시 단위 분리. task.md 의 Task 1·2 체크박스는 dispatcher commit 으로 묶음 (One Task = One Commit 원칙 위반 아님 — Task 1 자체가 "브랜치 생성, commit 없음"). |

### ADR 승격 가이드

- [x] ADR 승격 대상 있음 → 작성됨: `docs/decisions/ADR-004-notification-twofold-decision-flow.md` (amendment 절)
- [ ] 없음

## 💬 사용자 협의

- **주제**: `claude` 명령 직접 실행 시 telegram/discord 알림 발송 여부
  - **사용자 의견**: launcher (`telegram.sh` / `discord.sh`) 가 아닌 `claude` 명령 직접 실행 시 둘 다 발송 안 되는가? 라는 질문에서 시작.
  - **합의**: dispatcher 의 라우팅 로직 분석 결과 — `NM_NOTIFY_CHANNEL` 미설정 시 telegram 역호환 fallback 이라 "둘 다 안 가는 게 아니라 telegram 만 간다" 로 정리.

- **주제**: `both` 옵션의 유의미성
  - **사용자 의견**: 의미 있는지 검토 요청.
  - **합의**: 양방향 ack 비대칭 + 단일 소스 원칙 위반 + 노이즈 2배 → *거의 의미 없다* 결론. → "분기 자체 제거가 나을 것 같음" 사용자 결정.

- **주제**: 진행 방식 — spec-x 정식 vs phase-FF 확장 해석 vs dispatcher + ADR amendment 한정
  - **사용자 의견**: 3번 (dispatcher + ADR-004 amendment 만, channel-coherence spec 의 `both` 언급은 *당시 시점 기록* 으로 보존, spec-x 정식 ceremony)
  - **합의**: `spec-x-notify-drop-both` 으로 SDD-x 진행. Plan Accept 후 Strict Loop 실행.

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: 본 spec 은 bash dispatcher 의 case 분기 제거. 본 키트엔 shell unit test 프레임워크 없음.
- **결과**: N/A — 수동 검증 시나리오로 대체.

#### 통합 테스트
- **명령**: Integration Test Required = no.
- **결과**: N/A.

### 2. 수동 검증

> dispatcher 의 5개 라우팅 시나리오 확인. helper 가 `.env.{telegram,discord}` 부재 시 silent skip 이어도 dispatcher exit 0 이면 정상 (helper 분기 자체가 의도대로 호출됨).

1. **Action**: `NM_NOTIFY_CHANNEL=telegram bash .harness-kit/bin/notify.sh "test" info`
   - **Result**: exit 0. telegram 분기 호출.
2. **Action**: `unset NM_NOTIFY_CHANNEL; bash .harness-kit/bin/notify.sh "test" info`
   - **Result**: exit 0. 미설정 → `${NM_NOTIFY_CHANNEL:-telegram}` 으로 telegram fallback.
3. **Action**: `NM_NOTIFY_CHANNEL=discord bash .harness-kit/bin/notify.sh "test" info`
   - **Result**: exit 0. discord 분기 호출.
4. **Action**: `NM_NOTIFY_CHANNEL=both bash .harness-kit/bin/notify.sh "test" info`
   - **Result**: exit 0. `*)` fallback 분기 → telegram 만. **xtrace 로 확인** — `+ call_helper notify-telegram.sh` 만 발생, `notify-discord.sh` 호출 없음. 변경 전 동작 (둘 다 발송) 과 명확한 차이.
5. **Action**: `NM_NOTIFY_CHANNEL=none bash .harness-kit/bin/notify.sh "test" info`
   - **Result**: exit 0. `none) : ;;` 로 silent skip.

### 동기화 검증

- `diff sources/bin/notify.sh .harness-kit/bin/notify.sh` → 0줄 (도그푸딩 sync OK).
- `diff sources/claude-fragments/CLAUDE.fragment.md .harness-kit/CLAUDE.fragment.md` → 0줄 (도그푸딩 sync OK).

## 🔍 발견 사항

- **launcher 정합성 OK**: `sources/root/telegram.sh` (line 34) 와 `sources/root/discord.sh` (line 34) 모두 명시적으로 `telegram` / `discord` 만 export. 본 키트 내에 `both` 를 export 하는 곳 없음 — 즉시 case 제거의 안전성 보장.
- **dispatcher 주석 갱신 시 부수 정정**: 헤더 주석 line 17 의 `launcher 예시: discord-nextmarket-system.sh` 가 현재 키트엔 존재하지 않는 외부 프로젝트 launcher 이름이었음. `telegram.sh / discord.sh` (실제 키트 내 launcher) 로 정정. 본 spec 범위와 인접한 surgical cleanup.
- **archive 내 `both` 언급 보존**: `archive/specs/spec-17-04-governance-test-coherence/` 외 다수에 `both` 가 등장하나 immutable 원칙으로 미수정 — 향후 grep 시 false-positive 가능성 인지.

## 🚧 이월 항목 (Optional)

- 없음 — 본 spec 범위 내 완결.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Opus 4.7) + Leo |
| **작성 기간** | 2026-05-29 |
| **최종 commit** | `8c26d0a` (ship commit 직전) |
