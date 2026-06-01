# refactor(spec-x-notify-channel-formatter): 알림 채널별 포맷터 일관화 + Discord 마크다운 가독성 회복

## 📋 Summary

### 배경 및 목적

사용자가 Telegram 대비 Discord 를 채택한 이유는 **마크다운 렌더링 우위 (bold·italic·code block·blockquote·separator)** 이다. 그러나 발신 측 (`notify.sh` 호출하는 곳들 — CLAUDE.md fragment 예시들, `notify-on-input-wait.sh` hook 본문) 이 plain text 위주로 메시지를 작성하여 Discord 마크다운 렌더링 기회가 살려지지 못하고, **Telegram-호환 최저 공통분모로 평준화**되었다 (사용자 보고 2026-05-29, Discord 스크린샷).

본 spec 은 발신 측 일관화 + 인프라 측 표 변환 활성화로 **Discord 가독성을 회복**하되 **Telegram 회귀를 방지**한다. 인프라 진단 결과:
- `notify-discord.sh` 는 이미 raw 마크다운 통과 설계 — 표 처리만 `markdown_to_discord` 함수가 의도적으로 비활성
- `notify-telegram.sh` 의 `markdown_simplify` 는 모든 메타문자 평문화 — 발신 측이 마크다운으로 작성해도 telegram 회귀 없음
- 본질: 인프라 ≠ 문제. **발신 측 일관화 + Discord 표 처리 활성화**가 핵심

### 주요 변경 사항

- [x] **인프라**: `notify-discord.sh` 의 `markdown_to_discord` 함수 awk state machine 으로 구현 + 표 변환 활성화 (link 변환은 비활성 유지, A3)
- [x] **인프라**: `NOTIFY_DRYRUN=1` 모드 추가 (양 채널) — `.env` 검증 우회 + API 호출 대신 청크 본문 NUL 구분자 stdout (테스트 가능성)
- [x] **인프라**: `notify-on-input-wait.sh` 의 NOTIFY_BODY 4 분기 + 일반 분기 마크다운 컨벤션 적용
- [x] **발신 측**: CLAUDE.md fragment §1-§10 알림 예시 12+ 개 마크다운 컨벤션 통일 (라벨 bold, inline code, code-block 표). §9 `[ack]` → `**[ack]**` (A5, grep 호환 유지)
- [x] **컨벤션**: CLAUDE.md fragment 에 "알림 메시지 마크다운 컨벤션" 섹션 신설 (표 6 row + 금지 3 + 한계 4, 모바일 한계 포함)
- [x] **테스트**: 단위 테스트 3종 신규 — `test-notify-discord-format.sh` (9 case) + `test-notify-discord-chunking.sh` (4 case) + `test-notify-telegram-markdown.sh` (12 case) → 총 25/25 PASS

### Phase 컨텍스트

- **Phase**: `phase-x` (spec-x, Phase 비소속)
- **본 SPEC 의 역할**: 사용자가 보고한 가독성 사고 (Discord 스크린샷 2026-05-29) 의 즉시 회복 + 신규 알림 작성 시 따라야 할 컨벤션 자산 + 향후 신규 채널 추가 시 인프라 측 확장 패턴 제공

## 🎯 Key Review Points

1. **`notify-discord.sh:80-184` markdown_to_discord 함수** — awk state machine (outside / seen_header / in_table) 의 표 변환 알고리즘. 셀 폭 = `awk length()` (character count, CJK 보정 없음 — NF6 한계). 좌측 정렬 padding, 헤더-바디 dash separator, escape `\|` placeholder (`\001\002`) 복원, 헤더만 있고 separator 없으면 표 아님 fallback. **A2 결정**: chunking *전* 변환 — 변환으로 생성된 펜스는 기존 fence-balance awk 가 청크 경계에서 자동 처리

2. **`notify-discord.sh` / `notify-telegram.sh` NOTIFY_DRYRUN=1 모드** — `.env` 검증 우회 + API 호출 대신 stdout NUL 출력. 일반 사용 시 미설정 → 기존 동작 유지 (NF1/NF3 무회귀). 테스트 가능성 확보 핵심 인프라

3. **`tests/test-notify-discord-chunking.sh` C1-C4** — NF4 적극 검증. 60행 표 (2622 byte, CHUNK_SIZE=1700 초과) 입력 → 2 청크 분할 + 각 청크 펜스 짝수 균형 + 모든 청크 표 펜스 포함. **표 변환 ↔ chunking 상호작용 정상 동작 증명**

4. **`tests/test-notify-telegram-markdown.sh` edge case E7-E12** — A4 강화. 중첩 (`***strong italic***`) / unbalanced (`**bold ** test`) / unclosed (`**unclosed`) / backtick branch / 언어 hint 펜스 모두 *현재 동작 명시 fixture* 로 박음 — **수정 대상이 아닌 한계 명시**

5. **`CLAUDE.fragment.md` 컨벤션 섹션** — 본 spec 의 거버넌스 자산. 신규 알림 추가 시 발신 측이 따라야 할 단일 컨벤션. *모바일 화면 폭 한계* (실증 2026-05-29) 포함 — 셀 폭 < 20 chars 권장, 긴 식별자는 표 대신 줄별 key:value 나열

6. **Walkthrough.md 의 C13 트레이드오프 기록** — embed/raw/code-block 대안 비교 + 향후 ADR 격상 조건. 본 spec 머지 시점 ADR 미작성 (B7, 문제-실증 기반 원칙). 모바일 한계 실증이 차기 ADR (`discord-table-rendering-policy`) 의 정확한 트리거

## 🧪 Verification

### 자동 테스트

```bash
bash tests/test-notify-discord-format.sh
bash tests/test-notify-discord-chunking.sh
bash tests/test-notify-telegram-markdown.sh
```

**결과 요약**: ✅ **25/25 PASS**
- `test-notify-discord-format.sh`: 9/9 (raw 통과 / 표 변환 / ASCII / 한글 전용 / 혼합 NF6 / edge cases / escape `\|`)
- `test-notify-discord-chunking.sh`: 4/4 (다중 청크 / 펜스 균형 / 양쪽 청크 펜스 / 단일 청크)
- `test-notify-telegram-markdown.sh`: 12/12 (기본 6 + edge 6 — nested/unbalanced/backtick/언어 hint 한계 fixture)

### 통합 테스트

`sources/bin/notify.sh` 직접 호출 (Task 11 도그푸딩 pass 대응):

```bash
NM_NOTIFY_CHANNEL=discord  bash sources/bin/notify.sh "$MSG" info
NM_NOTIFY_CHANNEL=telegram bash sources/bin/notify.sh "$MSG" info
```

**결과**:
- Discord 데스크탑 / 짧은 셀 표: **가독성 회복 ✓** (bold + inline code + 정렬 ASCII 표)
- Discord 모바일 / 긴 셀 표 (31 chars): **모바일 word wrap 한계 발견** — `spec-x-notify-discord-embed` Icebox 등록 (본 spec surface 외)
- Telegram: **평문 도달 ✓** (메타문자 미노출, 표 ` — ` join 평문화)

### 수동 검증 시나리오

1. **TDD red → green**: markdown_to_discord 비활성 → 8/9 fail → 함수 활성화 후 9/9 PASS
2. **chunking 무회귀**: 60행 표 입력 → 2 청크 분할 + 양쪽 valid markdown
3. **Telegram edge case 한계 fixture**: nested / unbalanced 등 *현재 동작 명시* — 회귀 감지 base 로 박음
4. **모바일 가독성 실증**: 데스크탑 ✓ / 모바일 긴 셀 한계 → walkthrough + Icebox 등록

## 📦 Files Changed

### 🆕 New Files
- `specs/spec-x-notify-channel-formatter/spec.md` — 요구사항 + NF + Out of Scope + ADR 후보
- `specs/spec-x-notify-channel-formatter/plan.md` — 결정 표 + 변경 + 알고리즘 명세 (B9)
- `specs/spec-x-notify-channel-formatter/task.md` — 13개 task
- `specs/spec-x-notify-channel-formatter/critique.md` — Opus sub-agent 비평 (13건 발견, all 반영)
- `specs/spec-x-notify-channel-formatter/walkthrough.md` — 작업 기록 + C13 tradeoff
- `specs/spec-x-notify-channel-formatter/pr_description.md` — 본 PR 본문
- `tests/test-notify-discord-format.sh` — 표 변환 9 case
- `tests/test-notify-discord-chunking.sh` — chunking 상호작용 4 case
- `tests/test-notify-telegram-markdown.sh` — markdown_simplify 회귀 12 case

### 🛠 Modified Files
- `sources/bin/notify-discord.sh` (+~130, -28) — markdown_to_discord awk 표 변환 활성화 + NOTIFY_DRYRUN 모드
- `sources/bin/notify-telegram.sh` (+10, -7) — NOTIFY_DRYRUN 모드
- `sources/hooks/notify-on-input-wait.sh` (+8, -5) — NOTIFY_BODY 4 분기 + 일반 분기 마크다운 컨벤션
- `sources/claude-fragments/CLAUDE.fragment.md` (+~60, -28) — §1-§10 알림 예시 마크다운 통일 + 컨벤션 섹션 신설 + 알림 정책 표 row 추가
- `backlog/queue.md` — Icebox 4개 등록 (Discord 마크다운 / AUQ / update.sh semver / discord-embed)

### 🗑 Deleted Files
- 없음

**Total**: 9 new + 5 modified = 14 files changed

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과 (25/25 PASS)
- [x] 통합 테스트 통과 (양 채널 발송 + 시각 검증 — 데스크탑/짧은 셀 가독성 회복, 모바일/긴 셀 한계 Icebox)
- [x] `walkthrough.md` 작성 (결정 기록 + 사용자 협의 + 검증 + 발견 + 이월)
- [x] `pr_description.md` 작성 (본 파일)
- [x] lint / type check 통과 (shellcheck 미설치 경고만 — 환경 한계)
- [x] 사용자 검토 요청 알림 (Telegram/Discord §9 ack)

## 🔗 관련 자료

- Spec: `specs/spec-x-notify-channel-formatter/spec.md`
- Critique: `specs/spec-x-notify-channel-formatter/critique.md` (Opus sub-agent, 13건 발견)
- Walkthrough: `specs/spec-x-notify-channel-formatter/walkthrough.md` (C13 tradeoff 기록)
- 관련 Icebox (별도 spec 후보):
  - `spec-x-update-semver-suffix-fix` — ADR-003 SSOT `update.sh` 의 leo suffix arithmetic 버그
  - `spec-x-notify-discord-embed` — Discord embed 기반 구조화 메시지 (모바일 가독성 결정적 해결책 + ADR-006 `discord-table-rendering-policy` 트리거)
  - `spec-x-notify-cjk-width-padding` — UAX #11 한글 폭 보정
- 향후 ADR (트리거 대기):
  - `notify-channel-adapter-responsibility` (type: invariant) — 신규 채널 추가 spec 트리거 시
  - `discord-table-rendering-policy` (type: tradeoff) — embed 도입 spec 트리거 시
