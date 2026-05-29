# Walkthrough: spec-x-notify-chunk-line-aware

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 분할 알고리즘 sentinel | NUL byte vs unit-separator (0x1F) vs unique 문자열 | NUL byte | bash `read -r -d ''` 가 NUL 종결자를 native 지원. 임시 파일 경유 시 NUL byte 도 보존됨. 견고성 + 단순성. |
| chunk emit 통신 | awk → bash pipe vs 임시 파일 | 임시 파일 | bash 의 NUL byte 변수 저장은 깨질 수 있음 (C-string 종결자). 임시 파일 + `read -d '' < file` 이 bash 3.2+ 에서 안정 동작. |
| 한 라인 > CHUNK_SIZE fallback | 라인 단위 분할 시도 (word break) vs 단순 byte 절단 | 단순 byte 절단 | 본 spec 의 Out-of-Scope. 단어 경계 보호는 별도 spec. 현 동작은 라인 1줄이 1700+ byte 인 매우 드문 케이스에서만 발동. |
| 공통 라이브러리 추출 | 두 helper 공통 함수로 → lib/chunk.sh | 인라인 유지 | helper 별 정책 차이 (telegram=펜스 없음, discord=펜스 보호) 명확화. lib 추출은 *세 번째 helper 추가 시* 평가. |
| 펜스 카운트 패턴 | 코드 펜스 매칭 정규식 | `/^[[:space:]]*```/` | telegram 의 `markdown_simplify` 가 펜스 라인 제거에 쓰는 패턴과 동일. helper 간 일관성. |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — helper 내부 구현 디테일, cross-spec 의존성 없음. ADR-004 의 양방향 / 단일 소스 / 발송 측 명시성 원칙과 직교.

## 💬 사용자 협의

- **주제**: notify helper chunk 분할이 문장/코드 블록 중간을 끊는 결함
  - **사용자 의견**: Discord 스크린샷 첨부 — nextmarket-api 채널의 SQL 청크에서 `FROM STP_USERS` 가 `FR` + `OM` 으로 끊김. 본 키트에서 수정 요청 (선택지 1).
  - **합의**: spec-x 정식 ceremony 로 수정. 스코프 1 (라인 경계 + 코드 펜스 보호, 헤더 leading 유지). 두 helper (telegram + discord) 동시 수정.

- **주제**: Plan Accept
  - **사용자 의견**: "1" — Plan Accept (Critique 생략)
  - **합의**: 즉시 Strict Loop 진입.

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: 본 키트엔 shell unit test 프레임워크 없음. plan.md 의 "수동 검증 시나리오" 1~7 을 stub harness (`/tmp/test-chunk-telegram.sh`, `/tmp/test-chunk-discord.sh`) 로 helper awk 블록만 분리 실행.

#### 통합 테스트
- **결과**: Integration Test Required = no. 미실시.

### 2. 수동 검증

#### Telegram helper

1. **시나리오 1 — 단일 청크 회귀**: `"안녕하세요 짧은 메시지입니다." 100` → 1 청크 17 byte ✅
2. **시나리오 2 — 라인 경계 후퇴**: 5라인 본문, CS=25 → 3 청크 (각 24/24/12 byte). 라인 경계로만 분할, 단어 끊김 없음 ✅
3. **시나리오 6 — 한 라인 fallback**: 80자 라인 + 짧은 라인 둘, CS=30 → 4 청크 (short1 / 긴 라인 절단 ×2 / 잔여+short2). fallback 정상 동작 ✅
4. **시나리오 7 — 1라인**: `"한줄" 100` → 1 청크 ✅

#### Discord helper

1. **시나리오 1 — 단일 청크 회귀**: `"짧은 디스코드 메시지." 100` → 1 청크 ✅
2. **시나리오 3 — 펜스 없는 라인 경계 후퇴**: 4라인 본문, CS=35 → 2 청크 (라인 경계) ✅
3. **시나리오 4 — 펜스 보호 (핵심)**: SQL 본문 (TRUNCATE + ` ```sql ... ``` ` + 후속 텍스트), CS=200 → 3 청크. 결과:
   - CHUNK 1: `TRUNCATE...` + 본문 + ` ```sql SELECT ... ` + 자동 추가된 ` ``` ` (닫음)
   - CHUNK 2: 자동 추가된 ` ``` ` (재오픈) + `UNION ALL ...` + ` ``` ` (닫음)
   - CHUNK 3: ` ``` ` (재오픈) + 마지막 SQL + ` ``` ` + 후속 텍스트
   - **각 청크가 그 자체로 valid 마크다운 코드 블록.** 스크린샷 사례 (FROM STP_USERS 끊김) 완전 해소 ✅
4. **시나리오 7 — 1라인**: `"한줄짜리" 100` → 1 청크 ✅

### 3. 동기화 검증

- `diff sources/bin/notify-telegram.sh .harness-kit/bin/notify-telegram.sh` → 0 줄 ✅
- `diff sources/bin/notify-discord.sh .harness-kit/bin/notify-discord.sh` → 0 줄 ✅

## 🔍 발견 사항

- awk 의 `length()` 가 byte 단위인지 chars 단위인지는 awk 구현 의존. GNU awk 의 `LC_ALL=C` 면 byte, UTF-8 locale 면 chars 인 케이스가 있음. 본 키트는 안전 마진 (Discord 1700/2000, Telegram 3800/4096) 이 한글 UTF-8 byte 팽창 (1.5~3x) 을 충분히 흡수하므로 mismatch 시에도 안전.
- bash `read -r -d ''` 는 *NUL terminator 가 도달할 때까지* 읽음. 마지막 청크에 NUL terminator 가 있으면 모든 청크가 정확히 read 됨. awk 의 `END` 절에서 마지막 acc 도 NUL 로 종결시켜 일관성 보장.
- Discord 펜스 카운트는 단순 toggle (`fence_open = !fence_open`). 펜스 라벨 (` ```sql `) 도 같은 패턴 매칭이므로 정확. 만약 *백틱 4개 이상* 의 nested 펜스가 들어오면 toggle 이 깨질 수 있으나 실사용 빈도 매우 낮아 본 spec 범위 외.

## 🚧 이월 항목

- (잠재) 한 라인 > CHUNK_SIZE 의 fallback 에서 *단어 경계* 보호 — 현재는 byte 절단. 한국어 1700+ byte 한 줄은 매우 드물어 우선순위 낮음. Icebox 후보.
- (잠재) 두 helper 의 awk 블록 공통화 (lib/chunk-line-aware.sh) — 세 번째 helper 추가 시 평가.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Opus 4.7) + Leo |
| **작성 기간** | 2026-05-29 |
| **최종 commit** | `792d1b6` (discord helper) |
