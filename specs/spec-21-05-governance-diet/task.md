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

### 2-1. §6.7 추출 + §8.4 압축
- [x] `sources/governance/agent.md`: §6.7 native-feature 단락 → stub(규칙+가이드 참조). §8.4 AUQ → **압축**(제거 아님 — 배포 대상엔 AUQ 가이드 유효, fork 의 no-AUQ 는 fragment override. NFR1 의미무변경 정합).
- [x] `.harness-kit/agent/agent.md` 미러 동기화 (cp).
- [x] 측정: agent.md 4696→**4491w (-205w)**, 합계 7289w (still red — 예상, 점진 감소).
- [x] 검증: §6.7 stub 이 `native-feature-usage.md` 참조 — 가이드 상세 보유 확인.
- [x] Commit: `refactor(spec-21-05): extract 6.7 native-feature stub + compress 8.4 AUQ`

---

## Task 3: agent.md 압축

### 3-1. 최대 섹션 prose 압축
- [x] `sources/governance/agent.md`: §4.1(ASCII 트리)/§4.5/§8.1/§8.5/§6.3-8/§6.4 prose·예시·중복 축약. MUST/금지/용어·§6.6/§6.8/§6.1 보존.
- [x] `.harness-kit/agent/agent.md` 미러 동기화 (cp).
- [x] 측정: agent.md 4696→**4121w (-575w)**, 합계 6919w (still red — const 압축이 green 달성).
- [x] 회귀: director-protocol 13/13, context-orchestration PASS, dedup Check 1/2 OK (용어 보존).
- [x] Commit: `refactor(spec-21-05): compress agent.md prose (rules preserved)`

---

## Task 4: constitution 압축

> **옵션-4 재범위 (2026-06-08)**: 안전 압축만으로 <6000 도달 불가 확인(§7 결정) → 사용자 선택 **하이브리드(옵션 4)**: 안전압축 최대 + 상한 6000→**6500** 상향 + ADR. GREEN 은 Task 5(상한)에서 달성.

### 4-1. 최대 섹션 압축
- [x] `sources/governance/constitution.md`: §2.4/§3.1-3.4/§5.2/§5.5/§5.6/§5.7/§6.1-6.5/§9 prose·예시·중복·ASCII 축약. MUST/CRITICAL VIOLATION/식별자/게이트 규칙 보존.
- [x] `.harness-kit/agent/constitution.md` 미러 동기화 (cp).
- [x] 측정: const 2798→**2295w (-503w)**, agent 4696→4096w(-600w), **합계 6391w** (총 -1103w). 상한 6500 대비 ~109w headroom.
- [x] Commit: `refactor(spec-21-05): compress constitution prose`

---

## Task 5: 상한 6500 상향 + ADR-012 — Check 3 GREEN

### 5-1. 상한 변경 + 근거 자산화
- [ ] `tests/test-governance-dedup.sh` Check 3 상한 `6000` → `6500`.
- [ ] `docs/decisions/ADR-012-governance-word-budget.md` 작성 (type: tradeoff) — 6000→6500 재보정, 증거(phase-21 정당한 추가), 비용(anti-bloat 순수성), 대안(extraction friction / 과압축), 21-03 결정 갱신.
- [ ] phase.md 성공기준 4 + spec.md DoD 의 `<6000` → `≤6500` 참조 갱신.
- [ ] 검증: `bash tests/test-governance-dedup.sh` → **Check 3 GREEN(≤6500, 실제 6391)** + Check 1/2/4/5/6 유지.
- [ ] 회귀: director-protocol/role-model-config/director-mode/context-orchestration 무 회귀 + enforcement spot-check(핵심 규칙 grep + cross-ref).
- [ ] Commit: `test(spec-21-05): raise budget cap 6000→6500 + ADR-012`

---

## Task 6: Ship (필수)

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
| **총 Task 수** | 6 (작업 5 + Ship) — 옵션-4 재범위로 Task 5(상한+ADR) 추가 |
| **예상 commit 수** | 6 (planning / extract+stale / agent압축 / const압축 / 상한+ADR-green / ship) |
| **현재 단계** | Execution (Task 4 완료) |
| **마지막 업데이트** | 2026-06-08 |
