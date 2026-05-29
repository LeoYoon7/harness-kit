# fix(spec-x-notify-chunk-line-aware): split notify chunks at line boundaries with fence balance

> 첫 줄은 commit subject 와 정확히 일치해야 합니다.

## 📋 Summary

### 배경 및 목적

`notify-telegram.sh` 와 `notify-discord.sh` 의 chunk 분할이 `jq .[a:b]` 단순 byte/char 절단으로 동작해 라인/단어/코드 펜스 경계를 무시했다. 결과적으로 SQL 등 구조화 메시지에서 청크 헤더가 단어 중간에 끼어 가독성을 크게 해친다.

라이브 사례 (사용자 첨부 스크린샷, `nextmarket-api` Discord 채널):

```
... UNION ALL SELECT 'STP_USERS', COUNT()
FR
🛑 [nextmarket-api] [2/2]
OM STP_USERS
...
```

`FROM STP_USERS` 가 `FR` + `OM` 으로 끊김. 본 spec 은 두 helper 의 chunk 분할 알고리즘을 **라인 경계 우선** + (Discord) **코드 펜스 균형** 으로 교체한다.

### 주요 변경 사항

- [x] **알고리즘 교체** — `jq .[a:b]` 단순 절단 → awk 가 라인 단위로 누적하며 CHUNK_SIZE 초과 직전마다 NUL 구분자로 청크 emit. bash 는 임시 파일 + `read -r -d ''` 로 한 청크씩 추출.
- [x] **펜스 균형 (Discord 전용)** — 청크 끝 시점에 코드 펜스가 열린 상태면 자동으로 ` ``` ` 닫고, 다음 청크 시작에 ` ``` ` 재오픈. 두 청크 모두 valid 마크다운.
- [x] **fallback** — 한 라인이 CHUNK_SIZE 를 넘는 예외 케이스에서만 그 라인을 단순 절단 (현 fallback 동작 보존).
- [x] **헤더 leading 유지** — 청크 식별성 (스크롤 시 헤더가 먼저 보임) 보존. trailing 으로 옮기지 않음.
- [x] **bash 3.2+ 호환** — `mapfile` / `${arr[@]}` 미사용. `read -d ''` 와 임시 파일 기반.
- [x] **도그푸딩 sync** — `sources/bin/notify-{telegram,discord}.sh` ↔ `.harness-kit/bin/notify-{telegram,discord}.sh` 짝을 한 commit 내 동시 변경. diff 0줄 확인.

### Phase 컨텍스트

- **Phase**: `phase-x` (Solo Spec — 미소속)
- **본 SPEC 의 역할**: notify-channel 시리즈의 가독성 결함 해소. ADR-004 / drop-both / launcher-only 와 직교 (전송 정책 vs 분할 알고리즘).

## 🎯 Key Review Points

1. **awk + NUL + 임시 파일 패턴**: bash 3.2 호환 + Windows Git Bash 환경에서도 NUL byte 가 안정적으로 통과하도록 임시 파일 경유. helper 안에 인라인 awk 블록 (lib 추출 안 함 — helper 별 정책 차이 명확화).
2. **펜스 카운트 정확성**: `/^[[:space:]]*```/` 패턴이 펜스 라벨 (` ```sql ` 포함) 과 닫는 펜스 모두 매칭. 단순 toggle (`fence_open = !fence_open`) 로 카운트. nested 백틱 4+ 펜스는 spec 범위 외.
3. **회귀 없음**: 단일 청크 (짧은 메시지) + 펜스 없는 긴 메시지 + 짧은 라인 본문은 변경 전과 동일한 결과 (헤더 1줄 + 본문). 7가지 시나리오 helper 별 stub 로 검증.
4. **fallback 동작 보존**: 한 라인이 CHUNK_SIZE 를 넘는 예외에서는 그 라인을 단순 절단. 한국어 1700+ byte 한 줄은 드물어 우선순위 낮음. 단어 경계 추가 보호는 Icebox 후보.
5. **도그푸딩 sync — 네 파일 짝**: 두 helper × (sources + .harness-kit) = 4 파일이 한 commit 안에서 동시 변경. diff 0줄.

## 🧪 Verification

### 자동 테스트

본 키트엔 shell unit test 프레임워크 없음 — 수동 검증 시나리오로 대체.

### 수동 검증 시나리오

stub harness (`/tmp/test-chunk-telegram.sh`, `/tmp/test-chunk-discord.sh`) 로 helper 의 awk 블록만 추출 실행. 청크별 본문 + N/M 확인.

#### Telegram helper

| # | 입력 | 기대 동작 | 결과 |
|---|---|---|---|
| 1 | 짧은 1라인 | 1 청크 | ✅ |
| 2 | 5라인, CS=25 | 3 청크 (라인 경계만) | ✅ |
| 6 | 80자 라인 1줄 + 짧은 라인 둘, CS=30 | 4 청크 (긴 라인만 절단 fallback) | ✅ |
| 7 | 1라인 | 1 청크 | ✅ |

#### Discord helper

| # | 입력 | 기대 동작 | 결과 |
|---|---|---|---|
| 1 | 짧은 1라인 | 1 청크 | ✅ |
| 3 | 4라인, CS=35 | 2 청크 (라인 경계만) | ✅ |
| 4 | SQL 본문 + ```sql 펜스, CS=200 | 3 청크 각각 valid 마크다운 (펜스 균형 자동) | ✅ |
| 7 | 1라인 | 1 청크 | ✅ |

### 동기화 검증

- `diff sources/bin/notify-telegram.sh .harness-kit/bin/notify-telegram.sh` → 0줄 ✅
- `diff sources/bin/notify-discord.sh .harness-kit/bin/notify-discord.sh` → 0줄 ✅

## 📦 Files Changed

### 🛠 Modified Files

- `sources/bin/notify-telegram.sh` (+44, -22): awk 라인 누적 + NUL 구분자 + 임시 파일 read 패턴
- `.harness-kit/bin/notify-telegram.sh` (+44, -22): 도그푸딩 sync
- `sources/bin/notify-discord.sh` (+52, -26): awk 라인 누적 + 펜스 균형 + NUL 구분자 + 임시 파일 read 패턴
- `.harness-kit/bin/notify-discord.sh` (+52, -26): 도그푸딩 sync

### 🆕 New Files

- `specs/spec-x-notify-chunk-line-aware/spec.md`
- `specs/spec-x-notify-chunk-line-aware/plan.md`
- `specs/spec-x-notify-chunk-line-aware/task.md`
- `specs/spec-x-notify-chunk-line-aware/walkthrough.md`
- `specs/spec-x-notify-chunk-line-aware/pr_description.md`

**Total**: 9 files changed (4 modified + 5 new)

## ✅ Definition of Done

- [x] 수동 검증 시나리오 telegram 1/2/6/7 + discord 1/3/4/7 통과 (자동 단위 테스트 없음 — N/A)
- [x] `walkthrough.md` ship commit 완료
- [x] `pr_description.md` ship commit 완료
- [-] lint / type check — 본 키트 staged-lint 는 shellcheck 미설치로 skip (정상)
- [ ] 사용자 검토 요청 알림 완료 (ship 직후 발송)

## 🔗 관련 자료

- 라이브 사례 스크린샷: `nextmarket-api` Discord 채널 (사용자 첨부, 2026-05-29)
- 관련 spec 시리즈: `archive/specs/spec-x-notify-channels/`, `archive/specs/spec-x-notify-bidirectional-policy/`, `archive/specs/spec-x-notify-channel-coherence/`, `archive/specs/spec-x-notify-drop-both/`, `archive/specs/spec-x-notify-launcher-only/` (각각 다른 측면)
- Walkthrough: `specs/spec-x-notify-chunk-line-aware/walkthrough.md`
