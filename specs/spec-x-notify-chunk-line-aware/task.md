# Task List: spec-x-notify-chunk-line-aware

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 phase 미소속이므로 phase.md 갱신 불필요 (constitution §5.1)
- [ ] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-notify-chunk-line-aware`
- [x] Commit: 없음 (브랜치 생성만)

---

## Task 2: notify-telegram.sh 라인 경계 후퇴 분할

### 2-1. telegram helper 변경 (sources + 도그푸딩 동기화)
- [x] `sources/bin/notify-telegram.sh` — chunk 분할 loop 를 awk 라인 누적 + NUL 구분자 출력으로 교체. bash 측은 임시 파일 + `read -d ''` 로 청크 본문 추출.
- [x] `.harness-kit/bin/notify-telegram.sh` — 동일 변경 (도그푸딩 sync)
- [x] `diff sources/bin/notify-telegram.sh .harness-kit/bin/notify-telegram.sh` → 0 줄 확인
- [x] 수동 검증 — 시나리오 1 (단일 청크 회귀), 2 (라인 경계 후퇴 5라인→3청크), 6 (한 라인 > CHUNK_SIZE fallback 4청크), 7 (1라인)
- [ ] Commit: `fix(spec-x-notify-chunk-line-aware): split telegram chunks at line boundaries`

---

## Task 3: notify-discord.sh 라인 경계 후퇴 + 코드 펜스 균형

### 3-1. discord helper 변경 (sources + 도그푸딩 동기화)
- [ ] `sources/bin/notify-discord.sh` — chunk 분할 loop 를 awk 라인 누적 + 펜스 카운트 + 펜스 균형 자동 ` ``` ` 추가로 교체
- [ ] `.harness-kit/bin/notify-discord.sh` — 동일 변경 (도그푸딩 sync)
- [ ] `diff sources/bin/notify-discord.sh .harness-kit/bin/notify-discord.sh` → 0 줄 확인
- [ ] 수동 검증 — 시나리오 1, 3 (라인 경계 후퇴 discord), 4 (펜스 보호), 6, 7
- [ ] Commit: `fix(spec-x-notify-chunk-line-aware): split discord chunks at line boundaries with fence balance`

---

## Task 4: Ship

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [-] 코드 품질 점검 (lint / type check) — bash 스크립트 + markdown. shellcheck 미강제.
- [-] 전체 테스트 실행 → 자동 unit test 없음. plan.md 수동 검증 시나리오를 walkthrough.md 에 기록.
- [-] (Integration Test Required = no) 통합 테스트 생략
- [ ] **walkthrough.md 작성** — 결정 근거 + 수동 검증 결과 + sources/.harness-kit diff 0 줄 증거 + 라이브 사례 (스크린샷) 참조
- [ ] **pr_description.md 작성** — 템플릿 준수 (요약 / 변경 / 검증 / 리스크)
- [ ] **Ship Commit**: `docs(spec-x-notify-chunk-line-aware): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-notify-chunk-line-aware`
- [ ] **PR 생성**: `gh pr create`
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고 (`notify.sh ... ship` 레벨)

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 4 (브랜치 + telegram + discord + Ship) |
| **예상 commit 수** | 3 (각 변경 task = 1 commit, 브랜치는 commit 없음) + 1 ship commit = **4** (+ scaffold + finalize = 6) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-05-29 |
