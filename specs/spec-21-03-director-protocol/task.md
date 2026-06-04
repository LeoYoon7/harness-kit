# Task List: spec-21-03

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성 (`sdd spec new director-protocol`)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 업데이트 (phase-21.md SPEC 표 자동 갱신 + OPEN 결정 2건 해소 + spec-21-06 추가)
- [x] 사용자 Plan Accept

---

## Task 1: 브랜치 + 검증 테스트 (TDD Red)

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-21-03-director-protocol` (시작점 = `phase-21-director-mode` phase base)
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. 테스트 작성 (TDD Red)
- [x] `tests/test-director-protocol.sh` 작성 — upstream fork 적응. Check: (1) §6.8 섹션, (2) 핵심 용어(intent handshake / distilled contract / re-ingestion·full transcript / Plan Accept), (3) §6.1 Director Mode delegation 단락 + artifact files 용어, (4) 이중 미러 parity(agent.md + director-mode.md), (5) `director-mode.md` 존재, (6) ADR-011 존재 + `type: decision`. **단어 예산 체크 미포함**.
- [x] 테스트 실행 → Fail 확인 (PASS=4 FAIL=9 — Red)
- [x] Commit: `test(spec-21-03): add failing test for director mode protocol`

---

## Task 2: ADR-011 작성

> agent.md stub 이 ADR-011 을 참조하므로 참조 대상을 먼저 생성.

### 2-1. ADR-011 작성
- [ ] `docs/decisions/ADR-011-director-mode.md` 작성 — frontmatter `id: ADR-011` / `type: decision` / `status: accepted`. upstream ADR-006 fork 재구현: Context / Decision / Consequences(검증 불변식 포함) / Alternatives / Related(ADR-010 토대, ADR-007·008 게이트 정합, upstream 005/006 참조만).
- [ ] 검증: `grep "type: decision" docs/decisions/ADR-011-director-mode.md` 확인
- [ ] Commit: `docs(spec-21-03): add ADR-011 director-mode`

---

## Task 3: director-mode.md 운영 가이드 (source + 미러)

### 3-1. 가이드 작성
- [ ] `sources/governance/director-mode.md` 작성 (한국어) — 6규칙 운영 절차 / 워커 scoped brief 필수 항목 표 / 검증 체크리스트(전문 재흡수 금지) / over·under-dispatch 경계 예시 / 게이트 보유 원칙(ADR-008·§5/§9 연결).
- [ ] `.harness-kit/agent/director-mode.md` 미러 동기화 (동일 내용 복사)
- [ ] 검증: `diff -q sources/governance/director-mode.md .harness-kit/agent/director-mode.md` → 차이 없음
- [ ] Commit: `feat(spec-21-03): add director-mode.md operational guide`

---

## Task 4: agent.md §6.8 stub + §6.1 delegation (source + 미러) — GREEN

### 4-1. agent.md 수정
- [ ] `sources/governance/agent.md` — §6.7 뒤 §7 앞에 **§6.8 Director Mode Protocol** stub 추가(영어, 6규칙 + 핵심 용어 + 참조), §6.1 Strict Loop 뒤에 **Director Mode delegation** 단락 추가(영어, artifact files 커밋 범위 포함).
- [ ] `.harness-kit/agent/agent.md` 미러 동기화 (동일 내용 반영)
- [ ] 검증: `bash tests/test-director-protocol.sh` → **전체 PASS (GREEN)**
- [ ] 회귀: `bash tests/test-governance-dedup.sh` → Check 1/2/4/5/6 PASS, Check 3 red 유지(예상). `bash tests/test-director-mode.sh` + `bash tests/test-context-orchestration.sh` → 무 회귀
- [ ] 검증: agent.md 순증 ≤ ~150w (NFR2)
- [ ] Commit: `feat(spec-21-03): add §6.8 director protocol stub + §6.1 delegation`

---

## Task 5: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] 전체 테스트 실행 → `test-director-protocol.sh` PASS + 회귀 무 NEW (Check 3 red 예상)
- [ ] 코드 리뷰 게이트 (§6.3 — Gemini cross-model 권장 / Opus / Skip 중 선택)
- [ ] **walkthrough.md 작성** (증거 로그 — 검증 결과, 단어 예산 before/after, 결정 기록)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] **Ship Commit**: `docs(spec-21-03): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-21-03-director-protocol`
- [ ] **PR 생성**: `/hk-pr-gh` — base = `phase-21-director-mode` (phase base)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 5 (작업 4 + Ship) |
| **예상 commit 수** | 5 (test / ADR / 가이드 / agent.md / ship) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-05 |
