# Walkthrough: spec-x-notify-channel-formatter

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 발신 측 vs 인프라 측 변환 책임 분담 | (A) 발신 측이 채널별 분기 / (B) 인프라가 채널별 변환 / (C) 구조화 컴포저 | **B** | 발신 측 surface 최소화 + 향후 신규 채널 추가 시 인프라만 확장. 산업의 Channel Adapter 패턴 부분 적용 |
| Discord 표 변환 방식 | (A) 셀 ` — ` join / (B) code-block 정렬 ASCII / (C) embed fields | **B** | 등폭 폰트 렌더링으로 정렬 보존. 셀 join 은 행 다수 시 가독성 급감. embed 는 surface 폭증 (별도 spec) |
| `markdown_to_discord` 함수 디자인 (A3) | (A) 함수 분리 / (B) 통합 함수 + 부분 활성화 | **B** | `[text](url)` 변환 도입 시 awk pipeline 한 단계 추가가 분리보다 cohesion 높음. 표만 활성화, 링크 비활성 유지 |
| 표 변환 ↔ chunking 순서 (A2) | (A) chunking 전 변환 / (B) chunking 후 변환 | **A** | 변환 후 본문이 청크 한도 초과 시 기존 fence-balance awk 가 자동 처리. 후처리는 표 일부 청크에서 변환 실패 위험 |
| CJK 한글 폭 보정 (NF6) | (A) UAX #11 적용 / (B) character count + 한계 명시 | **B** | UAX #11 awk surface 가 본 spec 범위 초과. 한글 셀 빈도 낮음. 별도 spec (`spec-x-notify-cjk-width-padding`) 후보 |
| Telegram 인프라 변경 (F4) | (A) `markdown_simplify` 강화 / (B) 무변경 + 회귀 테스트 | **B** | 기존 함수 충분. edge case 는 *현재 동작 명시 fixture* 로 박음 |
| 도그푸딩 동기화 (B8) | (A) ADR-003 SSOT `update.sh` / (B) 수동 cp | **A** (시도) → 실패 → pass | `update.sh` line 85 `0-leo` arithmetic 버그. Critique B8 합의 적용 — Icebox 등록 |
| ADR-006 작성 타이밍 (B7) | (A) 본 spec 머지 시점 / (B) 신규 채널 spec 트리거 시 | **B** | 문제-실증 기반 ADR 원칙. ADR-005 직후 인플레이션 회피. C13 만 본 walkthrough 에 단락 기록 |
| 모바일 가독성 한계 (실증) | (A) Ship + 한계 명시 / (B) embed 본 spec 안 구현 / (C) revert | **A** | 데스크탑 가독성 / 짧은 셀 / 컨벤션 / 인프라 기반 회수. 모바일 한계는 *실증 기반 후속 spec* 트리거 |

### Discord 표 처리 트레이드오프 기록 (C13 ADR 후보 → walkthrough 기록)

**Type**: tradeoff
**Slug 후보**: `discord-table-rendering-policy`

**선택**: code-block 안 정렬 ASCII 표

**기각된 대안**:
- **embed fields**: title/description/fields 분리로 모바일 가독성 *최상*. 기각 사유:
  - surface 폭증 — `notify-discord.sh` 의 `content` → `embeds` JSON 전환
  - chunking 재설계 (embed 본문 4096자 / field 1024자 / 총 6000자 한도)
  - 본 spec 의 minor refactor 범위 초과
- **raw 마크다운 표 통과**: Discord 가 표 미지원 → plain text 처럼 보임. 기각 사유: 본 spec 의 목적 (가독성 회복) 미달성

**향후 격상 조건**: embed 도입 spec (`spec-x-notify-discord-embed`) 트리거 시 본 결정을 ADR-NNN 으로 격상. *직전 spec 의 한계가 다음 spec 의 트리거* — 모바일 가독성 실증 (2026-05-29) 이 정확한 트리거 사건.

### ADR 승격 가이드

- [x] **트리거 대기**: `notify-channel-adapter-responsibility` (type: invariant) — 신규 채널 추가 spec 트리거 시 작성
- [x] **트리거 대기**: `discord-table-rendering-policy` (type: tradeoff) — embed 도입 spec 트리거 시 작성
- [ ] 본 spec 머지 시점에 ADR 작성 없음 (B7 결정, 문제-실증 기반 ADR 원칙)

## 💬 사용자 협의

- **주제**: 발신 측 vs 인프라 측 변환 책임 분담
  - **사용자 의견**: spec slug `notify-channel-formatter` (범용 적용 가능)
  - **합의**: 인프라가 채널별 변환, 발신 측은 단일 마크다운 컨벤션

- **주제**: Critique 13건 반영 범위
  - **사용자 의견**: 1번 (all 반영)
  - **합의**: A (요구사항 5) + B (실행 계획 6) + C (ADR 2) 모두 반영

- **주제**: Plan Accept 결정
  - **사용자 의견**: 1번 (Plan Accept)
  - **합의**: Task 1 부터 Strict Loop 자동 진행

- **주제**: Discord 모바일 가독성 (시각 검증 2026-05-29)
  - **사용자 의견**: "텍스트처럼 보임. 마크다운은 적용됐지만 표 가독성은 변화없음."
  - **합의**: 1번 (Ship + walkthrough.md 에 실증 증거 + Icebox 등록 + 컨벤션에 모바일 한계 추가). embed 대안은 별도 spec (`spec-x-notify-discord-embed`)

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트

- **명령**:
  ```bash
  bash tests/test-notify-discord-format.sh
  bash tests/test-notify-discord-chunking.sh
  bash tests/test-notify-telegram-markdown.sh
  ```
- **결과**: ✅ **25/25 PASS** (format 9 + chunking 4 + telegram 12)
- **로그 요약**:
  ```text
  test-notify-discord-format.sh:     PASS=9  FAIL=0
  test-notify-discord-chunking.sh:   PASS=4  FAIL=0
  test-notify-telegram-markdown.sh:  PASS=12 FAIL=0
  ```

#### 통합 테스트 (Integration Test Required = yes)

- **명령**: `sources/bin/notify.sh` 직접 호출 (Task 11 pass 대응 — `.harness-kit/` 미동기화 우회)
  ```bash
  NM_NOTIFY_CHANNEL=discord  bash sources/bin/notify.sh "$MSG" info
  NM_NOTIFY_CHANNEL=telegram bash sources/bin/notify.sh "$MSG" info
  ```
- **결과**: ✅ Sent (Discord + Telegram). 시각 검증 — 데스크탑/짧은 셀 표 가독성 회복 확인, 모바일/긴 셀 표 한계 실증

### 2. 수동 검증

1. **Action**: TDD red — `tests/test-notify-discord-format.sh` 작성 (markdown_to_discord 비활성 상태)
   - **Result**: 9 케이스 중 T1 (raw 통과 회귀 보호) 만 PASS, T2-T8 FAIL = TDD red 만족

2. **Action**: TDD green — `markdown_to_discord` awk state machine 구현 + 활성화
   - **Result**: 9/9 PASS (T5/T6 fixture 를 character count 기반으로 정정 — NF6 명시 한계)

3. **Action**: chunking 상호작용 검증 — 60행 표 (2622 byte) 입력
   - **Result**: 2 청크 분할 + 각 청크 펜스 짝수 균형 + 모든 청크 표 펜스 포함 (C1-C4 PASS)

4. **Action**: Telegram 회귀 + edge case — 12 케이스 (기본 6 + edge 6)
   - **Result**: 12/12 PASS. nested/unbalanced/backtick branch/언어 hint 모두 *현재 동작 명시 fixture* 로 박음

5. **Action**: Discord 실제 발송 시각 검증 (모바일 클라이언트)
   - **Result**: bold + inline code + 표 변환 정상 (code-block 안 등폭). 단 *긴 셀 (31 chars) 이 좁은 모바일 화면에서 word wrap → 정렬 시각 손실*. 본 spec 범위 외 한계 — `spec-x-notify-discord-embed` Icebox 등록

6. **Action**: 도그푸딩 동기화 — `bash update.sh --yes`
   - **Result**: ❌ line 85 `semver_lt` unbound variable (`0-leo` arithmetic 비숫자). Critique B8 합의대로 별도 spec 후보 `spec-x-update-semver-suffix-fix` Icebox 등록 + 본 task pass

## 🔍 발견 사항

- **`update.sh` semver_lt 버그**: `0.15.0-leo.1` 같은 pre-release suffix arithmetic 처리 실패. ADR-003 SSOT (도그푸딩 sync) 가 leo fork 환경에서 호출 불가. 본 사건이 발견 트리거. `spec-x-update-semver-suffix-fix` 후보 Icebox 등록
- **Discord 모바일 word wrap 한계**: 본 spec 의 변환은 *데스크탑 / 짧은 셀* 가독성 회복에 효과. *모바일 좁은 화면 + 긴 셀* 표는 자동 줄바꿈으로 정렬 시각 손실. Critique 대안 B (embed) 가 결정적 해결책 — `spec-x-notify-discord-embed` 후보 Icebox 등록
- **CJK 폭 보정 별도 spec 후보**: 한글 + ASCII 혼합 표의 정렬 보장. UAX #11 적용은 awk surface 부담 큼 — `spec-x-notify-cjk-width-padding` 후보

## 🚧 이월 항목

본 spec 의 surface 외 발견은 모두 `backlog/queue.md` Icebox 에 등록:

- **`spec-x-update-semver-suffix-fix`** — ADR-003 SSOT `update.sh` 의 leo suffix 처리 버그
- **`spec-x-notify-discord-embed`** — Discord embed 기반 구조화 메시지 (모바일 가독성 결정적 해결책, ADR-006 `discord-table-rendering-policy` 트리거)
- **`spec-x-notify-cjk-width-padding`** — UAX #11 한글 폭 보정 (선택적)
- **`notify-channel-adapter-responsibility` ADR** — 신규 채널 추가 spec 트리거 시 작성

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Claude Opus 4.7) + Leo |
| **작성 기간** | 2026-05-29 |
| **최종 commit** | (Ship 후 갱신) |
| **Task** | 13개 (11 완료 + 2 `[-]` pass: Task 10 agent.md grep / Task 11 update.sh 버그) |
| **Commit 수** | 9 (브랜치/pass 제외) |
| **Test PASS** | 25/25 |
