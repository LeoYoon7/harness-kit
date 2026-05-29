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
- [x] `NOTIFY_DRYRUN=1` 환경변수 시 API 호출 (curl) 대신 변환·청킹된 본문을 stdout 출력 후 종료
- [x] plan.md F 절의 "function isolation 또는 환경변수로 dry-run 모드" 옵션 채택
- [x] dry-run 진입은 `[ -n "${NOTIFY_DRYRUN:-}" ]` 체크 — 환경변수 미설정 시 기존 동작 유지 (NF1·NF3 무회귀)

### 2-2. 테스트 케이스 작성
- [x] `tests/test-notify-discord-format.sh` 신규 작성
- [x] 테스트 케이스 9개 (T1, T2, T3, T4, T5, T6, T7a, T7b, T8)
- [x] 테스트 실행 → PASS=1 FAIL=8 (T1 회귀 PASS, T2-T8 표 변환 FAIL = TDD red 만족)
- [x] Commit: `test(spec-x-notify-channel-formatter): add failing test for discord table conversion` (e141cdc)

---

## Task 3: notify-discord.sh 표 변환 — TDD Green

### 3-1. markdown_to_discord 표 변환부 구현 + 활성화
- [x] `sources/bin/notify-discord.sh` 의 `markdown_to_discord` 함수 awk 구현 — state machine (outside / seen_header / in_table) + flush_table
- [x] **A3 결정 반영**: 단일 함수 유지, `[text](url)` sed 변환은 비활성 (현재 사례 영향 없음)
- [x] **A2 결정 반영**: 호출 위치는 chunking *전* — `MESSAGE=$(... | markdown_to_discord)`. 변환으로 생성된 펜스는 기존 fence-balance awk 가 청크 경계에서 처리
- [x] 알고리즘:
  - PIPE_PH `\001\002` placeholder 로 escape `\|` 보호 → 출력 시 `|` 복원
  - 셀 폭 = awk `length()` (character count, CJK 보정 없음 — NF6 한계)
  - 좌측 정렬 `sprintf "%-Ws"`
  - 헤더 다음 dash separator 라인 출력
  - 헤더만 있고 separator 없으면 표 아닌 일반 텍스트로 fallback
- [x] `bash tests/test-notify-discord-format.sh` → 9/9 PASS (T5/T6 fixture 를 character count 기반으로 정정 후)
- [x] Commit (다음)

---

## Task 4: 표 변환 ↔ chunking 상호작용 통합 테스트 (NF4)

### 4-1. 청크 분할 + fence balance 검증
- [x] `tests/test-notify-discord-chunking.sh` 신규 작성
- [x] 테스트 케이스 C1-C4: 다중 청크 분할 / 펜스 균형 / 양쪽 청크 펜스 포함 / 작은 표 단일 청크
- [x] 테스트 실행 → 4/4 PASS (2622 byte 입력 → 2 청크, 청크별 펜스 2개씩)
- [x] Commit (다음)

---

## Task 5: notify-telegram.sh markdown_simplify 회귀 테스트 (A4 강화)

### 5-1. 회귀 + edge case 테스트
- [x] notify-telegram.sh 에 NOTIFY_DRYRUN=1 모드 추가 (discord 와 대칭)
- [x] `tests/test-notify-telegram-markdown.sh` 신규 작성
- [x] 기본 6 케이스 (B1-B6): bold / code / heading / 표 / 펜스 / link
- [x] Edge case 6 (E7-E12): 별표/밑줄 3겹 중첩 → 모두 제거 / unbalanced → 현재 동작 명시 / unclosed → 메타 잔존 / backtick branch → 한계 fixture / 언어 hint → 본문만 보존
- [x] 테스트 실행 → 12/12 PASS
- [x] Discord 회귀 재실행 → 9/9 + 4/4 PASS (회귀 없음)
- [x] Commit (다음)

---

## Task 6: notify-on-input-wait.sh 본문 마크다운화

### 6-1. (a)/(b)/(c) 본문 분기에 bold 라벨 적용
- [x] `sources/hooks/notify-on-input-wait.sh` 의 NOTIFY_BODY 분기 수정 — 4 분기 + 일반 분기 모두 마크다운 컨벤션 적용
- [x] 상태 라벨 (`**사용자 ... 대기**`, `**권한 승인 대기**`) bold
- [x] Branch 값 inline code (`` `$BRANCH` ``)
- [x] 섹션 라벨 (`**[최근 Claude 메시지]**`, `**[최근 Claude 메시지 일부]**`) bold
- [x] 본 hook 자체는 단위 테스트 없음 (Task 12 통합 테스트에서 시각 검증)
- [x] Commit (다음)

---

## Task 7: CLAUDE.md fragment §1~§5 알림 예시 마크다운화

### 7-1. §1 align / §2 plan / §3 accept / §4 stop / §5 ad-hoc 예시 본문 수정
- [x] `sources/claude-fragments/CLAUDE.fragment.md` 의 §1~§5 알림 예시 6개 모두 마크다운 컨벤션 적용
  - §1 align: **세션 시작** 라벨 + **Phase/Spec/Branch/Plan Accept** bold + Branch 값 inline code
  - §2 plan: **<spec-id>** bold + Spec/Plan/Task 경로 inline code + **[선택지]** / **[권장]** bold
  - §3 accept: **<spec-id> Plan Accepted** bold + **첫 Task** bold
  - §4 stop: **<spec-id> HARD STOP** bold + **사유/상세/Branch** bold + Branch inline code
  - §5 ad-hoc (2 예시): **<spec-id> 의사결정 요청** bold + **[상황]/[선택지]/[권장]** bold
- [x] 기능적 의미 무변경, 가독성 강화만
- [x] Commit (다음)

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
