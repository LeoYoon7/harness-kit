# Walkthrough: spec-x-notify-channel-coherence

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| AUQ vs §5 stop 충돌 | A) AUQ 시 §5 stop 무조건 생략 / B) 조건부 생략 + 순서 sync fallback / C) §5 stop 옵션 순서만 sync | B | Critique 권장. 옵션 ≤4 + free-text 미요구 시만 생략. 한계 초과 시 §5 stop + 순서 sync |
| 응답 채널 단일성 | A) reply 단독 / B) primary + fallback / C) 양쪽 발송 (현재) | A | Critique 권장. multi-device 노이즈 제거. fallback 모호성 회피 |
| Discord 처리 | A) channel-agnostic 추상 명시 / B) Discord 절차 미명시 (dispatcher 만) | B | Critique 권장. premature abstraction 회피. active 시점 별도 spec |
| ADR-004 보강 방식 | A) 단순 부정 절 추가 / B) Amendment 절 신설 | B | Critique 권장. ADR immutability 관행 유지 |
| 호환성 안내 | A) fragment 본문에 `update.sh` 안내 / B) 안내 줄 미추가 | B | Critique 권장. fragment 사용자 = LLM, 오해 위험 |
| 역사적 사례 처리 | A) `notify-telegram.sh` 그대로 / B) `notify.sh` 로 일괄 교체 | A (1곳만) | §9 의 PR #9 사례 설명은 당시 코드 기록이라 그대로 유지. dispatcher 교체는 11곳 |

### ADR 승격 가이드

- [x] ADR-004 의 `## 🔄 Amendments` 절 신설 (immutability 관행)
- [ ] 신규 ADR-005 미생성 — premature (Critique 평가)

## 💬 사용자 협의

- **주제**: PR #9 직후 사용자 라이브 발견 — 옵션 번호 충돌 (Telegram=3 Skip / Desktop=1 Skip)
  - **사용자 의견**: 스크린샷 비교 (Telegram msg #3084+#3086) — "3번 선택시 무반응"
  - **합의**: AUQ 와 §5 stop 의 옵션 번호 sync 필요
- **주제**: ack 중복 발견 (mcp reply + §9 ack notify-telegram.sh 둘 다)
  - **사용자 의견**: Telegram msg #3075 — "메시지 중복 하나 제거 필요"
  - **합의**: 단일 채널 원칙
- **주제**: Discord 적용 여부
  - **사용자 의견**: "discord 에는 적용 안하는 것?"
  - **합의**: dispatcher (`notify.sh`) 로 통일 — Discord 자동 cover. Discord MCP reply 패턴은 active 화 시 별도 spec
- **주제**: Critique 권장 6항목 반영
  - **사용자 응답**: "권장 진행" (Telegram msg #3103)
  - **합의**: 1-6 모두 반영. ADR-005 분리는 premature

## 🧪 검증 결과

### 1. 자동화 테스트

해당 없음 (마크다운 + ADR).

### 2. 수동 검증

#### dispatcher 호출
- **Action**: `bash .harness-kit/bin/notify.sh "smoke test" info`
- **Result**: ✓ silent success (Telegram 발송 — NM_NOTIFY_CHANNEL default = telegram)
- Discord active 환경 아니므로 NM_NOTIFY_CHANNEL=both 검증 미실시

#### fragment grep
- **Action**: `grep -c notify-telegram.sh sources/claude-fragments/CLAUDE.fragment.md`
- **사전**: 12 (§1-§8 의 11곳 bash 예시 + §9 의 1곳 역사 사례)
- **사후**: 1 (§9 의 역사 사례만 의도적 유지)
- **Action**: 동일 grep on `.harness-kit/CLAUDE.fragment.md`
- **사후**: 1 (sync 정상)

### 3. 메타 dogfood (timing 명확화 — Critique 권장)

| 응답 시점 | fragment 상태 | 적용 규칙 |
|---|---|---|
| **Plan Accept "1" 응답** | fragment 미수정 | 기존 규칙 (reply + §9 ack notify-telegram.sh 양쪽 발송) |
| **Task 3-5 완료 직후 응답** | fragment 수정 완료 | 새 규칙 (단일 sink) 시작 |
| **Task 6 ADR-004 Amendment 응답** | Amendment 완료 | 새 규칙 + Amendment 참조 |

본 spec Plan Accept 시점에는 fragment 가 아직 미수정 상태라 *기존 규칙 적용*. Task 3-5 commit 직후부터 단일 sink 규칙 적용. timing 모순 제거.

## 🔍 발견 사항

- **§9 역사 사례 처리**: `sed -i` 일괄 교체로 §9 안의 "당시 notify-telegram.sh 사용" 사례 설명도 `notify.sh` 로 바뀜 — 사실 왜곡. Edit 으로 명시적 `notify-telegram.sh` 복원 (당시 코드 시점 보존). 향후 fragment 의 *역사적 사례 설명* 은 별도 마킹 (예: `<!-- historical: notify-telegram.sh -->`) 으로 보호 가치 있을 수 있음.
- **Critique 의 over-promising 식별 정확도**: 본 spec 의 초안은 "AUQ 시 §5 stop 무조건 생략" 으로 over-promising. Critique 가 옵션 한계 / free-text / 동시 의도 등 *생략 불가 케이스* 를 정확히 식별. 보강 후 spec 의 실제 적용 범위가 명확해짐. 직전 PR #9 의 critique 결과 검증 (PR #9 의 stale AUQ 버그가 critique 가설의 실증) 에 이어 Critique 가치가 누적 확인됨.
- **메타 dogfood timing 의 절차적 모순 해소**: 사전엔 "Plan Accept 응답부터 새 규칙 적용" — 그 시점은 fragment 미수정. Critique 권장으로 "Task 3-5 완료 직후부터" 로 수정. timing 명확화 = 다른 spec 의 메타 dogfood 시점 설계의 일반화 가능 패턴.

## 🚧 이월 항목

- **fragment 의 역사 사례 마킹 패턴**: `<!-- historical: ... -->` 같은 명시 마커로 sed 일괄 교체 시 보호 (현재는 수동 복원).
- **Discord MCP reply 패턴 spec**: Discord active 화 시점에 §9 의 Discord 절차 명시. 본 spec 의 `notify.sh` dispatcher 통일은 인프라 준비.
- **README / install.sh 의 `notify.sh` 보장 강조**: 호환 안내 줄을 fragment 에 추가 안 함 (LLM 오해 위험). README 또는 install.sh 의 사용자 문서로 이동.
- **§4 Hard Stop + AUQ 동시 사용 케이스**: 본 spec 의 단일 소스 규칙은 §5 만 적용. §4 + AUQ 케이스 (사용자 즉시 개입 + 모달 옵션) 의 절차 미정의.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Opus 4.7 main) + Leo |
| **작성 기간** | 2026-05-28 ~ 2026-05-29 |
| **최종 commit** | (ship 후 갱신) |
