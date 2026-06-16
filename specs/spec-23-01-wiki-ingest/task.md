# Task List: spec-23-01

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 업데이트 (phase-23.md SPEC 표 — sdd 자동 갱신)
- [x] 사용자 Plan Accept

---

## Task 1: hk-wiki-ingest 슬래시 커맨드 작성

### 1-1. 브랜치 생성
- [ ] `git checkout -b spec-23-01-wiki-ingest`
- [ ] Commit: 없음 (브랜치 생성만)

### 1-2. 커맨드 문서 작성 (docs)
- [ ] `sources/commands/hk-wiki-ingest.md` 신규 — frontmatter `description:` + 4단계 워크플로 (archived walkthrough 읽기 → decisions/patterns 갱신(원문 인용) → log 기록 → index 갱신)
- [ ] 검증: `sources/commands/hk-archive.md` 와 동형 구조 + 4단계 명확성 육안 확인
- [ ] Commit: `feat(spec-23-01): add hk-wiki-ingest slash command`

---

## Task 2: 템플릿 4종 [[wikilink]] Related 정비

### 2-1. spec/walkthrough Related 섹션 신설 + adr/rca 보강 (docs)
- [ ] `sources/templates/spec.md`·`walkthrough.md` 말미에 `## 🔗 관련 문서 (Related)` 추가 (`[[spec-id]]`·`[[ADR-NNN]]`·`[[wiki/page]]` 가이드)
- [ ] `sources/templates/adr.md`·`rca.md` 의 기존 `## 🔗 Related` 에 `[[wikilink]]` 안내 보강 (섹션 신설 금지)
- [ ] 검증: `grep -l '관련 문서' sources/templates/spec.md sources/templates/walkthrough.md` + adr/rca 의 `[[` 안내 존재
- [ ] Commit: `docs(spec-23-01): add [[wikilink]] Related sections to artifact templates`

---

## Task 3: sdd archive 후처리 wiki-ingest 힌트 (TDD)

### 3-1. 테스트 작성 → Fail (TDD Red)
- [ ] `tests/test-sdd-dir-archive.sh` 확장: `docs/wiki/` 존재 fixture → archive 출력에 `/hk-wiki-ingest` 힌트 포함 단언 / 부재 시 미포함 단언
- [ ] `bash tests/test-sdd-dir-archive.sh` → 신규 단언 Fail 확인

### 3-2. 구현 → Pass (TDD Green)
- [ ] `sources/bin/sdd` `cmd_archive` 말미(`ok "...→ archive/"` 직후)에 `[ -d "$SDD_ROOT/docs/wiki" ] && printf "  → %s\n" "/hk-wiki-ingest 로 wiki 갱신 권장"` 추가
- [ ] `bash tests/test-sdd-dir-archive.sh` → 전체 PASS 확인
- [ ] Commit: `feat(spec-23-01): hint /hk-wiki-ingest after archive when wiki exists`

---

## Task 4: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] 코드 품질 점검 — `bash tests/test-sdd-dir-archive.sh` (sdd 변경분)
- [ ] 전체 관련 테스트 실행 → 모두 PASS
- [ ] 코드 리뷰 게이트 (docs-heavy — `/hk-gemini-review` 또는 Skip+사유 기록)
- [ ] **walkthrough.md 작성** (증거 로그)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] **Ship Commit**: `docs(spec-23-01): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-23-01-wiki-ingest`
- [ ] **PR 생성**: `/hk-pr-gh` (base = main, defaultBranch)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 4 (작업 3 + Ship) |
| **예상 commit 수** | 4 (feat/docs/feat/docs-ship) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-16 |
