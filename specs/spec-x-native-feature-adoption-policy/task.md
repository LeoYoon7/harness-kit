# Task List: spec-x-native-feature-adoption-policy

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> docs(거버넌스) 작업이므로 TDD 대신 "문서 작성/동기화 → commit" 단위로 구성합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 phase.md 표 갱신 — spec-x 는 phase 비소속이라 해당 없음
- [x] 사용자 Plan Accept (전파 범위 안 A 전파 — Discord 채널 응답)

---

## Task 1: 브랜치 생성 + ADR-007 작성

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-native-feature-adoption-policy`
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. ADR-007 작성
- [x] `docs/decisions/ADR-007-native-feature-adoption-policy.md` — 7종 게이트 보존 조건 + 근거(축 충돌) + 대안 (type: convention, status: accepted)
- [x] Commit: `docs(spec-x-native-feature-adoption-policy): add ADR-007 native feature adoption policy`

---

## Task 2: agent.md 정책 요지 추가 (전파, 안 A)

- [x] `sources/governance/agent.md` §6.7 에 "네이티브 기능 게이트 보존" 항목 1개 추가 — 자족 요지 + ADR-007 근거 참조
- [x] Commit: `docs(spec-x-native-feature-adoption-policy): add native feature gate-preservation note to agent.md`

---

## Task 3: 도그푸딩 동기화 + 단어 수 검증

- [ ] `sources/governance/agent.md` → `.harness-kit/agent/agent.md` 직접 cp (단방향 동기화)
- [ ] `bash tests/test-governance-dedup.sh` 실행 → 단어 수 악화 여부 확인 (이미 초과 상태이므로 추가분 최소 확인)
- [ ] Commit: `chore(spec-x-native-feature-adoption-policy): sync agent.md to dogfood install`

---

## Task 4: Ship (필수)

- [-] 코드 품질 점검 (lint / type check) — docs-only 라 해당 없음
- [ ] 거버넌스 단어 수 테스트 결과 walkthrough 기록 (PASS/기존 초과 유지)
- [ ] **walkthrough.md 작성** (결정·검증 기록)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] **Ship Commit**: `docs(spec-x-native-feature-adoption-policy): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-native-feature-adoption-policy`
- [ ] **코드 리뷰 게이트** — `docs-only` 사유로 skip 가능 (agent.md §6.3.8). 단 거버넌스 변경이라 사용자 검토 권장
- [ ] **PR 생성**: `/hk-pr-gh` (base = fork main)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 4 |
| **예상 commit 수** | 4 (ADR + agent.md + 동기화 + ship) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-02 |
