# Task List: spec-x-goal-verify-gate

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.
> docs-only spec — 단위 테스트 대신 governance 일관성 검증 (헌법 §9.1 문서 변경 예외).

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 phase.md 불필요 (queue.md specx 섹션은 sdd 자동 등록 완료)
- [x] 사용자 Plan Accept

---

## Task 1: ADR-007 Amendment — `/goal` 검증 강제 정책

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-goal-verify-gate`
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. ADR-007 Amendment 절 추가
- [x] `docs/decisions/ADR-007-native-feature-adoption-policy.md` 에 Amendment 절 추가 (정책 6요소: 검증강제 / 검증≠승인 / hard-stop 2개 / launch-ritual / §11.2 임계 / Q1-a 채택·Q1-b Icebox)
- [x] Commit: `docs(spec-x-goal-verify-gate): ADR-007 에 /goal 검증 강제 정책 Amendment 추가`

---

## Task 2: `agent.md §6.7` `/goal` 요지 갱신 + 설치본 sync

### 2-1. 요지 갱신 (두 복사본 동일 편집)
- [x] `sources/governance/agent.md` §6.7 `/goal` 절에 검증 강제 요지 1줄 + ADR-007 Amendment 포인터
- [x] `.harness-kit/agent/agent.md` 동일 편집 (dogfood sync)
- [x] `git diff` 로 양쪽 동일 변경 확인 (blob 4a4399c→980b529 일치)
- [x] Commit: `docs(spec-x-goal-verify-gate): agent.md §6.7 /goal 검증 요지 + 설치본 sync`

---

## Task 3: 플레이북 `/goal` 행 갱신 + 설치본 sync

### 3-1. 플레이북 갱신 (두 복사본 동일 편집)
- [x] `sources/governance/native-feature-usage.md` §2 상황표 + §3 2단계 조건표 `/goal` 행에 검증 조건 추가
- [x] `.harness-kit/agent/native-feature-usage.md` 동일 편집 (dogfood sync)
- [x] `git diff` 로 양쪽 동일 변경 확인 (--no-index exit=0, byte-identical)
- [x] Commit: `docs(spec-x-goal-verify-gate): native-feature-usage /goal 검증 조건 + 설치본 sync`

---

## Task 4: Ship (필수)

- [x] governance 일관성 검증: `bash tests/test-governance-dedup.sh` (Check 2 sync PASS; Check 3 단어수 사전존재 — 무 NEW 회귀)
- [x] 3자 일관성 + sources↔installed diff 육안 확인 (blob 동일 / `--no-index` exit=0)
- [x] **walkthrough.md 작성** (결정·검증·발견 로그)
- [x] **pr_description.md 작성** (템플릿 준수)
- [x] **Ship Commit**: `docs(spec-x-goal-verify-gate): ship walkthrough and pr description`
- [x] **Push**: `git push -u origin spec-x-goal-verify-gate`
- [x] **코드 리뷰 게이트** — `docs-only` skip (walkthrough 기록)
- [x] **PR 생성**: `/hk-pr-gh`
- [x] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 3 (+ Ship) |
| **예상 commit 수** | 3 (+ ship commit) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-04 |
