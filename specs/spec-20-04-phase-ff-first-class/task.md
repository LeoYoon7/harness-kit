# Task List: spec-20-04

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> docs-only spec — TDD 없음. 검증은 `test-governance-dedup.sh`(sync/일관성). 거버넌스 변경은 sources↔installed **양쪽** 동시 반영.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 업데이트 (phase-20.md SPEC 표 — sdd 자동 갱신됨)
- [x] 사용자 Plan Accept

---

## Task 1: 브랜치 생성 + ADR-009 작성 (FR-1)

### 1-1. 브랜치 생성
- [ ] `git checkout -b spec-20-04-phase-ff-first-class` (base: `phase-20-upstream-parity`)
- [ ] Commit: 없음 (브랜치 생성만 — planning 산출물 커밋과 함께)

### 1-2. ADR-009 작성
- [ ] `.harness-kit/agent/templates/adr.md` 읽고 준수
- [ ] `docs/decisions/ADR-009-phase-ff-first-class.md` 작성 — `type: decision`, upstream ADR-004 참조, fork notify 정합 기술
- [ ] Commit: `docs(spec-20-04): ADR-009 phase-FF 1급 작업 모드`

---

## Task 2: constitution 반영 (FR-2, FR-5) — sources + installed

- [ ] `sources/governance/constitution.md` + `.harness-kit/agent/constitution.md`: §3.1 "In-Phase Work Sizing" 문단 + §2/§10.2 phase-FF 예외(per-item review→phase-ship, 테스트 유지) 간결 추가
- [ ] `diff -q` 로 sources↔installed sync 확인
- [ ] Commit: `docs(spec-20-04): constitution 에 In-Phase Work Sizing (phase-FF 1급) 반영`

---

## Task 3: agent.md §11.4 재구성 (FR-3) — sources + installed

- [ ] `sources/governance/agent.md` + `.harness-kit/agent/agent.md`: §11.4 를 "upfront sizing + phase-FF 1급" 구도로 in-place 재구성 (word 증가 최소)
- [ ] `diff -q` sync 확인
- [ ] Commit: `docs(spec-20-04): agent.md §11.4 upfront sizing + phase-FF 1급 재구성`

---

## Task 4: CLAUDE.fragment 격상 + notify 정합 (FR-4) — sources + installed

- [ ] `sources/claude-fragments/CLAUDE.fragment.md` + `.harness-kit/CLAUDE.fragment.md`: phase-FF 1급 격상 + notify 정합(개별 게이트 미발생) 한 줄
- [ ] `diff -q` sync 확인
- [ ] Commit: `docs(spec-20-04): CLAUDE.fragment phase-FF 1급 + notify 정합`

---

## Task 5: Ship (필수)

- [ ] `bash tests/test-governance-dedup.sh` → Check 1/2/5/6 PASS (Check 3 word count 기존 FAIL — 증가폭 측정·기록)
- [ ] sync 검증: `diff -q` constitution/agent.md/fragment 3쌍 → SYNCED
- [ ] 통독 검증: phase-FF 가 4개 문서에서 "착수 시점 1급"으로 일관되는지
- [ ] **walkthrough.md 작성** (증거 + word-count 증가폭)
- [ ] **pr_description.md 작성**
- [ ] **코드 리뷰 게이트** (§6.3 — 거버넌스 docs 변경. Gemini/Opus/Skip 선택, Skip 시 사유 기록)
- [ ] **Ship Commit**: `docs(spec-20-04): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-20-04-phase-ff-first-class`
- [ ] **PR 생성**: gh api → LeoYoon7/harness-kit (base: `phase-20-upstream-parity`)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 5 |
| **예상 commit 수** | 6 (planning + ADR + constitution + agent.md + fragment + ship) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-04 |
