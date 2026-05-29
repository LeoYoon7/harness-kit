# Task List: spec-x-notify-drop-both

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
- [x] `git checkout -b spec-x-notify-drop-both`
- [x] Commit: 없음 (브랜치 생성만)

---

## Task 2: dispatcher 에서 `both` case 제거

### 2-1. dispatcher 변경 (sources + 도그푸딩 동기화)
- [x] `sources/bin/notify.sh` — `both` case 라벨 제거 + 헤더 주석 라우팅 표 갱신
- [x] `.harness-kit/bin/notify.sh` — 동일 변경 (도그푸딩 sync)
- [x] `diff sources/bin/notify.sh .harness-kit/bin/notify.sh` → 0 줄 확인
- [x] 수동 검증 — plan.md "수동 검증 시나리오" 1~5 수행 + xtrace 로 `both` → telegram fallback 확인 (notify-discord.sh 호출 없음)
- [x] Commit: `refactor(spec-x-notify-drop-both): drop 'both' channel from notify dispatcher`

---

## Task 3: fragment §9 ack note 정합 갱신

### 3-1. fragment 변경 (sources + 도그푸딩 동기화)
- [x] `sources/claude-fragments/CLAUDE.fragment.md` line 318 — "(예: `both`)" → `NM_NOTIFY_CHANNEL=discord` 표현으로 정합 갱신
- [x] `.harness-kit/CLAUDE.fragment.md` 동일 변경 (도그푸딩 sync)
- [x] `diff sources/claude-fragments/CLAUDE.fragment.md .harness-kit/CLAUDE.fragment.md` → 0 줄 확인
- [x] Commit: `docs(spec-x-notify-drop-both): drop 'both' mention from fragment §9 ack note`

---

## Task 4: ADR-004 amendment 추가

### 4-1. ADR-004 amendment
- [x] `docs/decisions/ADR-004-notification-twofold-decision-flow.md` 의 Amendments 절 끝에 `### 2026-05-29 (spec-x-notify-drop-both)` 추가 (plan.md 의 본문 사용)
- [x] Commit: `docs(spec-x-notify-drop-both): add ADR-004 amendment for dropping 'both' channel`

---

## Task 5: Ship

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [-] 코드 품질 점검 (lint / type check) — bash 스크립트 + markdown 만 변경. shellcheck 미강제 (본 키트 unit test 없음).
- [-] 전체 테스트 실행 → 자동 unit test 없음. plan.md 의 수동 검증 시나리오를 walkthrough.md 에 기록.
- [-] (Integration Test Required = no) 통합 테스트 생략
- [x] **walkthrough.md 작성** — 결정 근거 + 수동 검증 결과 + sources/.harness-kit diff 0 줄 증거
- [x] **pr_description.md 작성** — 템플릿 준수 (요약 / 변경 / 검증 / 리스크)
- [x] **Ship Commit**: `docs(spec-x-notify-drop-both): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-notify-drop-both`
- [ ] **PR 생성**: `/hk-pr-gh` (no-confirm 모드 — Plan Accept 후 자동)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고 (`notify.sh ... ship` 레벨)

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 5 (브랜치 + dispatcher + fragment + ADR + Ship) |
| **예상 commit 수** | 4 (각 변경 task = 1 commit, 브랜치는 commit 없음) + 1 ship commit = **5** |
| **현재 단계** | Ship |
| **마지막 업데이트** | 2026-05-29 |
