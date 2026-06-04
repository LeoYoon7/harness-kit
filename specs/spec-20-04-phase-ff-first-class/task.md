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
- [x] `git checkout -b spec-20-04-phase-ff-first-class` (base: `phase-20-upstream-parity`)
- [x] Commit: planning 산출물 `7cf4011`

### 1-2. ADR-009 작성
- [x] `adr.md` 템플릿 준수
- [x] `docs/decisions/ADR-009-phase-ff-first-class.md` 작성 — `type: decision`, upstream ADR-004 참조, notify 정합 + pre-push 보수 기술
- [x] Commit: `docs(spec-20-04): ADR-009 phase-FF 1급 작업 모드` — `5660f81`

---

## Task 2: constitution 반영 (FR-2, FR-5) — sources + installed

- [x] §3.1 "In-Phase Work Sizing" 문단 + §10.2 phase-FF pre-push 예외(테스트 유지, per-item review→phase-ship) 추가
- [x] `diff -q` → SYNCED
- [x] Commit: `docs(spec-20-04): constitution 에 In-Phase Work Sizing (phase-FF 1급) 반영` — `1c15da3`

---

## Task 3: agent.md §11.4 재구성 (FR-3) — sources + installed

- [x] §11.4 "In-Phase Work Sizing & Re-Adjustment" upfront framing + 표기 통일 (in-place)
- [x] `diff -q` → SYNCED
- [x] Commit: `docs(spec-20-04): agent.md §11.4 upfront sizing + phase-FF 1급 재구성` — `db3e3ae`

---

## Task 4: CLAUDE.fragment 격상 + notify 정합 (FR-4) — sources + installed

- [x] phase-FF 1급 격상(재승인 불요) + notify 정합 + ceremony-over-work fix 갱신
- [x] `diff -q` → SYNCED
- [x] Commit: `docs(spec-20-04): CLAUDE.fragment phase-FF 1급 + notify 정합` — `aa64bf1`

---

## Task 5: Ship (필수)

- [x] `test-governance-dedup.sh` → Check 1/2/4/5/6 PASS (Check 3 기존 FAIL, +212w 기록)
- [x] sync 검증: `diff -q` 3쌍 → ALL SYNCED
- [x] 통독 검증: phase-FF 4개 문서 일관 확인
- [x] **walkthrough.md 작성** (증거 + word-count 증가폭 + 발견)
- [x] **pr_description.md 작성**
- [x] **코드 리뷰 게이트**: Gemini cross-model → Approve (Critical/Major/Minor 0)
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
