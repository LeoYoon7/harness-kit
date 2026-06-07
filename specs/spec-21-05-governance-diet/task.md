# Task List: spec-21-05

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성 (`sdd spec new governance-diet` → spec-21-05)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 업데이트 (phase.md SPEC 표 자동 갱신 + narrative 번호 정정 swap)
- [x] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

### 1-1. 브랜치
- [x] `git checkout -b spec-21-05-governance-diet` (시작점 = `phase-21-director-mode`)
- [x] Commit: 없음

> "test" 는 신규 작성이 아니라 기존 `test-governance-dedup.sh` Check 3 (현재 RED). 각 다이어트 task 후 Check 3 추적, 최종 GREEN.

---

## Task 2: agent.md 추출 + stale 제거

### 2-1. §6.7 추출 + §8.4 제거
- [ ] `sources/governance/agent.md`: §6.7 native-feature 단락 → stub(규칙+가이드 참조), §8.4 AskUserQuestion → 1줄 stub.
- [ ] `.harness-kit/agent/agent.md` 미러 동기화 (cp).
- [ ] 측정: `wc -w` + `test-governance-dedup.sh` Check 3 추적 (아직 red 가능).
- [ ] 검증: §6.7 stub 이 참조하는 `native-feature-usage.md` 가 상세 보유 확인 (빈 참조 방지).
- [ ] Commit: `refactor(spec-21-05): extract 6.7 native-feature + drop stale 8.4 AUQ`

---

## Task 3: agent.md 압축

### 3-1. 최대 섹션 prose 압축
- [ ] `sources/governance/agent.md`: §6/§11/§4/§3/§8.5 의 prose·예시·중복 축약. **MUST/금지/용어(intent handshake·distilled contract·models.*·orchestrator/worker)·§6.6/§6.8/§6.1 보존**.
- [ ] `.harness-kit/agent/agent.md` 미러 동기화 (cp).
- [ ] 측정: `wc -w` + Check 3 추적.
- [ ] Commit: `refactor(spec-21-05): compress agent.md prose (rules preserved)`

---

## Task 4: constitution 압축 — Check 3 GREEN

### 4-1. 최대 섹션 압축
- [ ] `sources/governance/constitution.md`: §5/§3/§6/§2 prose·예시·중복 축약. **MUST/CRITICAL VIOLATION/식별자 포맷/게이트 규칙 보존**.
- [ ] `.harness-kit/agent/constitution.md` 미러 동기화 (cp).
- [ ] 검증: `bash tests/test-governance-dedup.sh` → **Check 3 GREEN(<6000w)** + Check 1/2/4/5/6 유지.
- [ ] 회귀: `test-director-protocol.sh`/`test-role-model-config.sh`/`test-director-mode.sh`/`test-context-orchestration.sh` 무 회귀.
- [ ] enforcement spot-check: 핵심 규칙 grep 잔존 + cross-ref 무결성.
- [ ] Commit: `refactor(spec-21-05): compress constitution prose → budget green`

---

## Task 5: Ship (필수)

- [ ] 전체 테스트 → Check 3 GREEN + 전 governance/director/role/context 테스트 무 회귀
- [ ] 코드 리뷰 게이트 — **Opus** (phase base 에 gemini fix 미반영 + 규칙 보존 검증에 Opus 적합)
- [ ] **walkthrough.md 작성** (단어수 before/after, 보존 규칙 증빙, 결정 기록)
- [ ] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-21-05): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-21-05-governance-diet`
- [ ] **PR 생성**: `/hk-pr-gh` — base = `phase-21-director-mode`
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 5 (작업 4 + Ship) |
| **예상 commit 수** | 5 (planning / extract+stale / agent압축 / const압축-green / ship) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-08 |
