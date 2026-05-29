# Task List: spec-x-notify-channel-formatter

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.
> Critique (`critique.md`) all 반영 (2026-05-29): B6 (Task 9 축소·통합), B7 (Task 12 ADR 작성 제거), B8 (Task 10 표준 명령 단일화), B11 (번호 정합성).

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성 + Critique 반영 (A1-A5, C12-C13)
- [x] plan.md 작성 + Critique 반영 (알고리즘 명세, 결정 표 강화)
- [x] task.md 작성 (이 파일) + Critique 반영 (B6-B8, B11)
- [ ] 백로그 업데이트 (`backlog/queue.md` 의 specx 마커에 자동 등록 완료 — sdd specx new 가 처리함)
- [ ] **agent.md grep 수행** (B6): `grep -nE 'notify\.sh|notify-(telegram|discord)' sources/governance/agent.md` → 발견 결과 본 파일 task 6 의 분기 결정에 사용
- [ ] **`update.sh --self` (또는 동등) 표준 명령 확인** (B8): ADR-003 절차 검토, 명령 가용성 확인
- [ ] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

### 1-1. feature 브랜치 생성
- [x] `git checkout -b spec-x-notify-channel-formatter`
- [x] 현재 브랜치 확인 (`git branch --show-current`)
- [x] Commit: 없음 (브랜치 생성만)

---

## Task 2: notify-discord.sh 표 변환 — TDD Red (dry-run 인프라 포함)

### 2-1. notify-discord.sh dry-run 모드 추가 (테스트 인프라)
- [ ] `NOTIFY_DRYRUN=1` 환경변수 시 API 호출 (curl) 대신 변환·청킹된 본문을 stdout 출력 후 종료
- [ ] plan.md F 절의 "function isolation 또는 환경변수로 dry-run 모드" 옵션 채택
- [ ] dry-run 진입은 `[ -n "${NOTIFY_DRYRUN:-}" ]` 체크 — 환경변수 미설정 시 기존 동작 유지 (NF1·NF3 무회귀)

### 2-2. 테스트 케이스 작성
- [ ] `tests/test-notify-discord-format.sh` 신규 작성
- [ ] 테스트 케이스 (plan.md 알고리즘 명세 기반):
  - T1. 표 없는 입력 (bold/code/quote 만) → raw 그대로
  - T2. 마크다운 표 입력 → code-block 안 정렬 ASCII 표 (헤더 + dash separator + 데이터, 좌측 정렬)
  - T3. 표 + bold 혼합 → 표만 변환, 그 외 raw 통과
  - T4. ASCII 전용 표 → 정렬 보존
  - T5. 한글 전용 표 → 정렬 보존
  - T6. 한글 + ASCII 혼합 표 → **정렬 깨짐 허용** (현재 동작 명시, NF6 한계)
  - T7. Edge cases: 빈 표 (헤더만), 한 셀 표, 셀 폭 불균형 (컬럼 수 다름)
  - T8. 셀 데이터 내 escape `\|` → `|` 복원
- [ ] 테스트 실행 → Fail 확인 (markdown_to_discord 비활성 상태이므로 표가 raw 로 통과되어 기대값 mismatch)
- [ ] Commit: `test(spec-x-notify-channel-formatter): add failing test for discord table conversion`

---

## Task 3: notify-discord.sh 표 변환 — TDD Green

### 3-1. markdown_to_discord 표 변환부 구현 + 활성화
- [ ] `sources/bin/notify-discord.sh` 의 `markdown_to_discord` 함수 awk 부분 구현 (표 블록 감지 + 정렬 ASCII 출력)
- [ ] **A3 결정 반영**: 함수 분리 안 함. `[text](url)` sed 호출 라인만 주석 처리 유지. awk 호출은 활성화.
- [ ] **A2 결정 반영**: `MESSAGE=$(... | markdown_to_discord)` 호출은 chunking *전* 위치 (변환 → chunking 순서). 변환으로 생성된 펜스는 기존 fence-balance awk 가 처리.
- [ ] 알고리즘 (plan.md 명세):
  - 헤더 + separator + 데이터 블록 감지
  - 셀 폭 측정 (awk `length()`)
  - 좌측 정렬 padding (`printf "%-Ns"`)
  - 헤더 다음에 dash separator 라인 출력
  - `\|` placeholder 치환 후 복원
- [ ] `bash tests/test-notify-discord-format.sh` → 모두 Pass 확인
- [ ] Commit: `feat(spec-x-notify-channel-formatter): enable discord table conversion as code-block`

---

## Task 4: 표 변환 ↔ chunking 상호작용 통합 테스트 (NF4)

### 4-1. 청크 분할 + fence balance 검증
- [ ] `tests/test-notify-discord-chunking.sh` 신규 작성 (또는 기존 chunking 테스트 확장)
- [ ] 테스트 케이스:
  - 3000+ byte 표 입력 (CHUNK_SIZE=1700 초과) → 2개 이상 청크 분할
  - 각 청크가 valid 마크다운 (펜스 균형 유지)
  - 청크 경계가 표 중간이면 양쪽 청크 모두 ` ``` ` 포함
  - 표 변환 후 본문이 CHUNK_SIZE 이하면 단일 청크
- [ ] 테스트 실행 → Pass 확인
- [ ] Commit: `test(spec-x-notify-channel-formatter): verify table conversion and chunking interaction`

---

## Task 5: notify-telegram.sh markdown_simplify 회귀 테스트 (A4 강화)

### 5-1. 회귀 + edge case 테스트
- [ ] `tests/test-notify-telegram-markdown.sh` 신규 작성 (또는 기존 확장)
- [ ] 기본 케이스: bold / code / heading / 표 / 펜스 / link (plan.md B 절 1-6)
- [ ] Edge case (A4):
  - `***strong italic***` → `strong italic`
  - `___strong___` → `strong`
  - `**bold ** test` → 현재 동작 명시 (메타문자 잔존 fixture)
  - `**unclosed` → 현재 동작 명시 (메타문자 잔존 fixture)
  - `` `spec-x-notify\`test` `` (backtick 포함 branch) → 현재 동작 명시 (sed 매칭 한계 fixture)
  - ` ```bash\n...\n``` ` → 본문만 보존, 언어 hint 제거
- [ ] 테스트 실행 → 현재 `markdown_simplify` 로 Pass 확인 (edge case 는 *현재 동작 명시 fixture* — 수정 대상 아님)
- [ ] Commit: `test(spec-x-notify-channel-formatter): regression test for telegram markdown_simplify with edge cases`

---

## Task 6: notify-on-input-wait.sh 본문 마크다운화

### 6-1. (a)/(b)/(c) 본문 분기에 bold 라벨 적용
- [ ] `sources/hooks/notify-on-input-wait.sh` 의 NOTIFY_BODY 분기 수정:
  - (a) 권한 승인: `**권한 승인 대기**` + `**Branch:** \`$BRANCH\``
  - (b) 텍스트 선택지: `**사용자 선택 대기**` + `**[최근 Claude 메시지]**`
  - (c) AskUserQuestion (legacy): `**사용자 질문 대기**`
  - 일반: `**사용자 입력 대기 중**` + `**[최근 Claude 메시지 일부]**`
- [ ] 본 hook 자체는 단위 테스트 없음 (Task 10 통합 테스트에서 시각 검증)
- [ ] Commit: `refactor(spec-x-notify-channel-formatter): apply markdown labels to hook notification body`

---

## Task 7: CLAUDE.md fragment §1~§5 알림 예시 마크다운화

### 7-1. §1 align / §2 plan / §3 accept / §4 stop / §5 ad-hoc 예시 본문 수정
- [ ] `sources/claude-fragments/CLAUDE.md` 의 §1~§5 알림 예시들에서:
  - 라벨 → `**[라벨]**`
  - 선택지 본문 정렬 유지
  - 표가 있는 경우 (없을 것으로 추정) code-block 으로 변환
- [ ] 기존 plain 텍스트와 일관 유지 (기능적 의미 변경 금지, 가독성 강화만)
- [ ] Commit: `refactor(spec-x-notify-channel-formatter): markdown conventions for notify examples 1-5`

---

## Task 8: CLAUDE.md fragment §6~§10 알림 예시 마크다운화 (A5 포함)

### 8-1. §6 ship / §7 merge / §8 phase / §9 ack / §10 채널 응답 예시 본문 수정
- [ ] `sources/claude-fragments/CLAUDE.md` 의 §6~§10 알림 예시 통일:
  - `[권장]`, `[선택지]`, `[상황]` 라벨 일괄 bold
  - **A5 결정 반영**: §9 의 `[ack]` 모두 `**[ack]**` 채택 (grep 호환 유지)
  - mcp telegram reply 본문의 `[ack]` 도 동일 컨벤션
- [ ] Commit: `refactor(spec-x-notify-channel-formatter): markdown conventions for notify examples 6-10 with ack bold`

---

## Task 9: CLAUDE.md fragment 컨벤션 섹션 신설 (B10 디테일 포함)

### 9-1. "알림 메시지 마크다운 컨벤션" 섹션 추가
- [ ] `sources/claude-fragments/CLAUDE.md` 의 적절한 위치 (§10 직후 또는 "알림 정책" 표 직전) 에 신설
- [ ] 컨벤션 표 (요소 / 마크다운 / Discord 렌더링 / Telegram 렌더링) — plan.md D 절 정확 복사
- [ ] **B10 반영**: 코드 블록 row 의 Telegram 렌더링 컬럼에 "펜스 제거, 본문 보존, **언어 hint 도 제거**" 명시
- [ ] **NF6 한계 반영**: 표 row 에 "CJK 혼합 시 정렬 깨짐 허용"
- [ ] 금지 항목 + 한계 항목 (한글 셀, nested 메타문자, backtick branch) 명시
- [ ] 기존 "알림 정책" 표와 중복 없는지 검토
- [ ] Commit: `docs(spec-x-notify-channel-formatter): add notification markdown convention section`

---

## Task 10: agent.md 알림 호출 라인 처리 (B6 조건부)

### 10-1. Pre-flight grep 결과에 따른 분기
- [ ] Pre-flight 의 grep 결과 확인:
  - **발견 없음 → 본 task pass (`[-]`)**: 한 줄 사유 task.md 에 기록 — *agent.md 는 알림 호출이 §8.5 인용에 한정*
  - **발견 있음**: 컨벤션에 맞춰 수정 + Commit: `refactor(spec-x-notify-channel-formatter): align agent.md notify examples`

---

## Task 11: 도그푸딩 동기화 (B8 표준 명령)

### 11-1. 표준 명령 단일 실행
- [ ] Pre-flight 의 표준 명령 확인 결과:
  - **`update.sh --self` 가용**: `bash update.sh --self` 단일 실행
  - **미가용**: ADR-003 의 대체 절차 (확인된 표준) 단일 실행
- [ ] 동기화 후 본 레포 자체에 컨벤션 적용된 알림이 동작하는지 sanity check
- [ ] Commit: `chore(spec-x-notify-channel-formatter): dogfood sync notify changes per ADR-003`

---

## Task 12: 통합 테스트 — 실제 채널 발송 + 시각 검증

### 12-1. Discord 채널 발송 + 검증
- [ ] 본 레포 `.env.discord` 활성 확인 (또는 임시 launcher 사용)
- [ ] plan.md 의 통합 테스트 명령으로 샘플 알림 발송 (표 + 선택지 + 한글 셀 포함)
- [ ] Discord 시각 확인:
  - bold 라벨 굵게 보임
  - 표가 code-block 안 정렬 ASCII (ASCII 전용 부분)
  - 한글 셀 부분은 정렬 깨짐 허용 (NF6 명시 한계 — fixture 와 일치)
  - 선택지 번호 정상
- [ ] 스크린샷 캡처 → walkthrough.md 첨부 예정

### 12-2. Telegram 채널 발송 + 검증
- [ ] 동일 메시지를 `NM_NOTIFY_CHANNEL=telegram` 으로 발송
- [ ] Telegram 시각 확인:
  - `**`, `` ` `` 메타문자 미노출 (단순 `**[라벨]**` 한정)
  - 표가 `a — b` 셀 join 으로 평문화
  - `[ack]` substring 보존 (grep 호환)
- [ ] 스크린샷 캡처 → walkthrough.md 첨부 예정

### 12-3. 회귀 검증
- [ ] 단위 테스트 전체 실행:
  - `bash tests/test-notify-discord-format.sh`
  - `bash tests/test-notify-discord-chunking.sh`
  - `bash tests/test-notify-telegram-markdown.sh`
- [ ] 모두 PASS
- [ ] `sdd status` 정상 동작 확인 (인프라 회귀 없음)
- [ ] Commit: 본 task 는 검증만, commit 없음 (`[-]` 또는 단순 마킹)

---

## Task 13: Ship (필수, ADR 작성 제거 — B7)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.
> **B7 결정**: 본 spec 머지 시점에 ADR-006 작성하지 않음. C12 / C13 후보는 spec.md ADR 섹션 + walkthrough.md "주요 결정" 섹션에 기록만.

- [ ] 코드 품질 점검 (bash 스크립트는 `shellcheck` 또는 syntax 확인)
- [ ] 전체 테스트 실행 → 모두 PASS
- [ ] 통합 테스트 결과 (스크린샷) walkthrough.md 첨부 완료
- [ ] **walkthrough.md 작성** (`.harness-kit/agent/templates/walkthrough.md` 준수)
  - **주요 결정 섹션에 C13 (discord-table-rendering-policy) 한 단락 기록** — embed/raw/code-block 트레이드오프 audit trail
- [ ] **pr_description.md 작성** (`.harness-kit/agent/templates/pr_description.md` 준수)
- [ ] **Ship Commit**: `docs(spec-x-notify-channel-formatter): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-notify-channel-formatter`
- [ ] **PR 생성**: `/hk-pr-gh` 로 생성 (base: fork main — 메모리 [[harness-kit-pr-target-fork]] 참조)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고 (`notify.sh ... ship`)

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 13 (Task 1~13) + Pre-flight |
| **예상 commit 수** | 9~11 (Task 1 브랜치만, Task 10 조건부 pass, Task 12 검증만 commit 없음) |
| **변경 요약 vs 이전 버전** | B7 (ADR-006 작성 task 제거 → walkthrough.md 기록) / B8 (도그푸딩 동기화 표준 명령으로 축소) / B6 (agent.md grep 조건부) / Task 4 신설 (NF4 적극 검증) / B11 (번호 정합성: plan.md "task 14" 표현 정정) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-05-29 (Critique all 반영) |
