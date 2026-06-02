# Task List: spec-x-native-session-feature-verify

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.
> 본 spec 은 **Research/docs** 성격 — 단위 테스트 없음 (constitution §9.1 justified). TDD Red/Green 대신 *문서 조사 → report 작성 → 정책 반영* 흐름.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 phase.md 표 없음 (queue.md 는 정책 반영 task 에서 갱신)
- [ ] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

### 1-1. 브랜치 생성
- [ ] `git checkout -b spec-x-native-session-feature-verify` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- [ ] Commit: 없음 (브랜치 생성만)

---

## Task 2: `/background` 검증 + report 골격

> 검증 방법: claude-code-guide 에이전트 / 공식 docs 로 `/background` 동작 조사 + `notify-on-input-wait.sh` 와 settings.json hook 등록 정적 분석.

### 2-1. report.md 골격 작성 + `/background` 판정
- [ ] `report.md` 골격 작성 (메타 / 검증 프레임 / 기능별 판정 섹션)
- [ ] `/background` 의 세션 분리 모델 + input-wait 알림(축 B) 도달성 + 공유 config 제약(축 E) 판정 작성
- [ ] Commit: `docs(spec-x-native-session-feature-verify): /background 알림·세션 동작 검증`

---

## Task 3: `/branch` 검증

> 검증 방법: 공식 docs 로 `/branch`(`/fork`) + `CLAUDE_CODE_FORK_SUBAGENT` 동작 조사 + check-branch hook / §8.5 / 멀티모델(§6.6) 승계 정적 분석.

### 3-1. `/branch` 판정 작성
- [ ] fork 세션의 게이트(축 A)·git hook(축 F)·멀티모델(축 C) 승계 판정 작성 (`CLAUDE_CODE_FORK_SUBAGENT` 유무별 차이 포함)
- [ ] Commit: `docs(spec-x-native-session-feature-verify): /branch fork 세션 상태 승계 검증`

---

## Task 4: Go/No-Go 종합 + 사용자 확인 체크리스트

### 4-1. 종합 결론 작성
- [ ] 두 기능 각각 ≥2 선택지(조건부 채택 vs 보류) trade-off + Go/No-Go/조건부 Go 판정 + 조건 (§9.1)
- [ ] 선택적 사용자 실행 라이브 확인 체크리스트 (Done 조건 아님) 부록 작성
- [ ] Commit: `docs(spec-x-native-session-feature-verify): Go/No-Go 종합 결론 + 사용자 확인 체크리스트`

---

## Task 5: 정책 반영 (판정 결과 종속)

### 5-1. 판정에 따른 정책 반영
- [ ] **조건부 Go 결론 시**: `sources/governance/agent.md` + `.harness-kit/agent/agent.md` §6.7 갱신 (게이트 보존 조건 추가) + `docs/decisions/ADR-007-native-feature-adoption-policy.md` amendment + `backlog/queue.md` Icebox 항목 갱신/제거
- [ ] **보류 결론 시**: `backlog/queue.md` Icebox 항목에 보류 근거 기록 (3단계 잔류)
- [ ] (거버넌스 문서 편집한 경우) `bash tests/test-governance-dedup.sh` 로 동기화(Check 2) 회귀 확인
- [ ] Commit: `docs(spec-x-native-session-feature-verify): 검증 판정을 정책에 반영`

---

## Task 6: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [-] 코드 품질 점검 (lint / type check) — 해당 없음 (docs-only)
- [-] 전체 테스트 실행 — 단위 테스트 없음 (Research/docs). 거버넌스 편집 시 Task 5 에서 test-governance-dedup.sh 회귀 확인 완료
- [-] 통합 테스트 — Integration Test Required = no
- [ ] **walkthrough.md 작성** (결정·검증·발견 로그)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] **코드 리뷰 게이트** — docs-only 이므로 walkthrough 코드 리뷰 필드에 `docs-only` 기록 (agent.md §6.3.8)
- [ ] **Ship Commit**: `docs(spec-x-native-session-feature-verify): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-native-session-feature-verify`
- [ ] **PR 생성**: `/hk-pr-gh` 로 생성 (base = fork main)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 6 (Ship 포함) |
| **예상 commit 수** | 4 (Task 2·3·4·5) + ship commit |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-02 |
