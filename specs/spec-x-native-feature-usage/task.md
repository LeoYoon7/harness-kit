# Task List: spec-x-native-feature-usage

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.
> 본 spec 은 **docs-only** — 단위 테스트 없음 (constitution §9.1 justified). TDD Red/Green 대신 *문서 작성 → 정본 대조*.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 phase.md 표 없음
- [ ] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

### 1-1. 브랜치 생성
- [ ] `git checkout -b spec-x-native-feature-usage` (브랜치 이름 = spec 디렉토리 이름)
- [ ] 계획 산출물(spec/plan/task + queue 등록분) 초기 커밋 `docs(spec-x-native-feature-usage): spec/plan/task 계획 산출물 작성`

---

## Task 2: 사용 playbook 작성 + ADR 링크

> 핵심 작업. ADR-007 / report 의 등급·조건을 정본으로 삼아 상황-우선 playbook 합성.

### 2-1. `docs/native-feature-usage.md` 작성 + ADR-007 포인터
- [ ] `docs/native-feature-usage.md` 작성 — §1 tier 정의 + 단일출처 원칙 / §2 상황-우선 표 / §3 tier 2·3 조건 요약 / §4 경계 각주
- [ ] 정본 대조: 1·2·3단계 + 보류 + N-A 전 기능 수록 + ADR-007 조건 일치 확인
- [ ] `docs/decisions/ADR-007-native-feature-adoption-policy.md` Related 절에 본 문서 포인터 추가
- [ ] Commit: `docs(spec-x-native-feature-usage): 네이티브 기능 사용 playbook 신설 + ADR-007 링크`

---

## Task 3: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [-] 코드 품질 점검 (lint / type check) — 해당 없음 (docs-only)
- [-] 전체 테스트 실행 — 단위 테스트 없음 (docs-only). agent.md 미편집 → governance 테스트 회귀 무관
- [-] 통합 테스트 — Integration Test Required = no
- [ ] **walkthrough.md 작성** (결정·검증·발견 로그)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] **코드 리뷰 게이트** — docs-only → walkthrough 코드 리뷰 필드에 `docs-only` 기록 (agent.md §6.3.8)
- [ ] **Ship Commit**: `docs(spec-x-native-feature-usage): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-native-feature-usage`
- [ ] **PR 생성**: `gh pr create` (base = fork main, ASCII title + --body-file)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 3 (Ship 포함) |
| **예상 commit 수** | 계획(1) + Task 2(1) + ship(1) = 3 |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-02 |
