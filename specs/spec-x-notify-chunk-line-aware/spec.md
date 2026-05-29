# spec-x-notify-chunk-line-aware: notify helper 청크 분할에 라인 경계 + 코드 펜스 보호 추가

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-notify-chunk-line-aware` |
| **Phase** | `phase-x` |
| **Branch** | `spec-x-notify-chunk-line-aware` |
| **상태** | Planning |
| **타입** | Fix (가독성 결함) |
| **Integration Test Required** | no |
| **작성일** | 2026-05-29 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

`sources/bin/notify-telegram.sh` 와 `sources/bin/notify-discord.sh` (그리고 도그푸딩 결과 `.harness-kit/bin/` 의 동일 파일들) 은 메시지가 채널 길이 제한을 넘으면 `CHUNK_SIZE` 단위 (Discord 1700, Telegram 3800) 로 단순 절단해 청크 분할 전송한다. 분할 알고리즘 핵심:

```bash
CHUNK=$(jq -nr --arg s "$MESSAGE" --argjson a $START --argjson b $END '$s[$a:$b]')
```

`jq` 의 `.[a:b]` 는 unicode code point 단위라 UTF-8 boundary 는 안전하지만, **라인 경계 / 단어 경계 / 코드 펜스 (```` ``` ````)** 는 전혀 고려하지 않는다.

### 문제점

라이브 사례 (사용자 첨부 스크린샷, `nextmarket-api` Discord 채널):

```
... UNION ALL SELECT 'STP_USERS', COUNT()
FR
🛑 [nextmarket-api] [2/2]
OM STP_USERS
...
```

`FROM STP_USERS` 한 단어가 `FR` + `OM STP_USERS` 로 끊겨 청크 헤더가 사이에 끼었다. 결과:

1. **단어/문장 끊김**: `FROM` → `FR` + `OM`. 가독성 크게 손상. SQL/코드 메시지에서 특히 심각.
2. **코드 펜스 손상 (Discord 만)**: ```` ``` ```` 펜스 안에서 청크 경계가 잡히면 양쪽 청크가 모두 *invalid 마크다운 블록* 이 된다. Discord 가 raw 마크다운 렌더링이라 코드 블록이 깨져 보이거나 plain text 로 fallback.
3. **헤더 위치 인지 부담**: 끊긴 라인 사이에 ` [2/2]` 가 끼어 본문 흐름을 끊는다.

Telegram 은 `markdown_simplify` 로 펜스 라벨 (```` ``` ````) 자체를 제거하므로 펜스 손상은 없지만, 라인/단어 끊김은 동일.

### 해결 방안 (요약)

청크 분할 알고리즘을 **라인 경계 우선** 으로 바꾼다: 청크 끝이 라인 중간에 떨어지면 가장 가까운 이전 라인 종결자 (`\n`) 까지 후퇴해 그 다음 라인부터 다음 청크에 포함. Discord 헬퍼는 추가로 **코드 펜스 균형** 을 보장 — 청크가 펜스 열린 상태로 끝나면 끝에 ```` ``` ```` 닫고, 다음 청크는 ```` ``` ```` 로 시작. 두 helper 의 분할 로직을 공통 함수로 추출하지는 않는다 (helper 별 정책 차이 — telegram 은 펜스 없음, discord 는 펜스 보호 — 그대로 유지). 헤더 위치는 leading 그대로.

## 🎯 요구사항

### Functional Requirements

1. **라인 경계 우선 분할**: `notify-telegram.sh` 와 `notify-discord.sh` 가 본문을 청크 단위로 자를 때, 자른 위치가 `\n` 직후가 되도록 후퇴 (즉 한 라인이 두 청크에 걸치지 않음). 단 한 라인이 `CHUNK_SIZE` 를 넘는 예외 케이스에서는 *그 라인만* 단순 절단 (현 동작 fallback).
2. **코드 펜스 균형 (Discord 만)**: `notify-discord.sh` 가 청크 끝 시점에 *열린 코드 펜스* 가 있으면 청크 끝에 자동으로 ```` ``` ```` 를 닫고, 다음 청크 시작에 ```` ``` ```` 를 열어 두 청크 모두 valid 마크다운이 되게 한다. 펜스 카운트는 청크 내부 라인 중 `^\s*` + ` ``` ` 시작 패턴 매칭으로 계산 (telegram 의 `markdown_simplify` 가 펜스 라인 제거 패턴과 동일 규칙).
3. **헤더 위치는 leading 유지**: `${PREFIX} [${REPO_NAME}] [N/M]\n` 를 각 청크 본문 앞에 prepend 하는 현 동작 유지. trailing 으로 옮기지 않음.
4. **싱글 청크 동작 보존**: 본문이 `CHUNK_SIZE` 이하라 분할 불필요한 경우 기존 동작 (헤더 1줄 + 본문) 그대로.
5. **도그푸딩 동기**: `sources/` 와 `.harness-kit/` 의 helper 짝을 한 commit 에서 함께 변경 (drift 방지).

### Non-Functional Requirements

1. **bash 3.2+ 호환** (`declare -A` / `mapfile` / `coproc` 금지 — `sources/CLAUDE.md`).
2. **jq 의존 유지** — 본문 슬라이싱과 JSON body 생성 모두 jq 사용. 신규 의존 추가 없음.
3. **`telegram` chunk 동작 회귀 없음**: 단일 청크 짧은 메시지 + 펜스 없는 긴 청크는 변경 전과 *동일 출력*.
4. **`discord` chunk 동작 회귀 없음**: 펜스 없는 본문은 라인 경계 후퇴만 적용. 펜스 보호는 펜스가 실제로 열려 있을 때만 발동.

## 🚫 Out of Scope

- 청크 헤더 위치 (leading → trailing) 변경.
- 두 helper 의 분할 로직을 공통 모듈로 추출 (helper 별 정책 차이 유지).
- 마크다운 *내부* 의 인라인 강조 (`**bold**`) 가 청크 경계에 걸리는 보호 — 라인 경계 후퇴로 자연 해소되는 케이스만 부산물로 처리.
- `markdown_simplify` (telegram) 의 펜스 라인 제거 로직 변경.
- 첨부 이미지 / 파일 전송 경로 변경.
- 한 라인이 `CHUNK_SIZE` 를 넘는 예외에서의 *단어 경계* 추가 보호 (현 단순 절단 그대로 fallback).
- `archive/` 및 머지된 spec 의 chunk-related 언급 — 동결.

## 📑 ADR 후보 (Architecture Decision Records)

- [ ] ADR 가치 있는 결정 있음 — chunk 분할 알고리즘은 helper 내부 구현 디테일이고 cross-spec 의존성 없음. ADR-004 의 양방향 컨벤션 / 단일 소스 / 발송 측 명시성 원칙과 직교.
- [x] 없음

## 🔍 Critique 결과 (선택)

미실행. 결함 패턴 명확 (스크린샷으로 입증) + 해결 방향 좁음 (라인 경계 + 펜스 보호) + 사용자 명시 요청. 비평 가치 작음.

## ✅ Definition of Done

- [ ] `notify-telegram.sh` (sources + .harness-kit) 가 라인 경계 후퇴 청크 분할 사용
- [ ] `notify-discord.sh` (sources + .harness-kit) 가 라인 경계 후퇴 + 코드 펜스 균형 사용
- [ ] 수동 검증: 펜스 안 SQL 메시지를 `CHUNK_SIZE` 초과 길이로 전송 시 양쪽 청크 모두 valid 마크다운 + 라인 끊김 없음
- [ ] 수동 검증: 펜스 없는 긴 메시지가 라인 경계로만 끊김
- [ ] 수동 검증: 짧은 메시지 (단일 청크) 회귀 없음
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-notify-chunk-line-aware` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
