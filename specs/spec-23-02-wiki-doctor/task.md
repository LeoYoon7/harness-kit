# Task List: spec-23-02

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

## Task 1: test-wiki.sh 신설 + governance 단어수 점검 (c)

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-23-02-wiki-doctor`
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. 테스트 작성 → Fail (TDD Red)
- [x] `tests/test-wiki.sh` 신설 — governance 단어수 6500 초과 fixture → doctor 경고 단언 + 템플릿 Related 회귀 검증
- [x] `bash tests/test-wiki.sh` → 단어수 단언 Fail 확인 (4/7, c-section/c-1/c-2 FAIL)

### 1-3. 구현 → Pass (TDD Green)
- [x] `sources/bin/sdd` `cmd_doctor` 에 "wiki/문서 건강" 섹션 + 단어수 점검(`.harness-kit/agent/{constitution,agent}.md` `wc -w` 합 > 6500 경고)
- [x] `bash tests/test-wiki.sh` → 7/7 PASS
- [x] Commit: `feat(spec-23-02): add governance word-count doctor check + test-wiki.sh`

---

## Task 2: 고아 [[wikilink]] 점검 (a)

### 2-1. 테스트 작성 → Fail (TDD Red)
- [x] `tests/test-wiki.sh` 확장 — 깨진 `[[wiki/nonexistent]]` 고아 경고 / 정상 링크 무경고 / silent skip / placeholder 오탐 없음 (a-1~a-4)
- [x] `bash tests/test-wiki.sh` → a-1 Fail 확인

### 2-2. 구현 → Pass (TDD Green)
- [x] `cmd_doctor` 고아 링크 점검 (`[[...]]` 추출 → prefix glob 해석, spec archive fallback). **오탐 처리**: purpose.md(컨벤션 문서) 제외 + concrete 포맷(ADR-숫자 등)만 검증 — A1 교훈
- [x] `bash tests/test-wiki.sh` → 11/11 PASS, 실제 레포 고아 0 확인
- [x] Commit: `feat(spec-23-02): detect orphan [[wikilink]] in sdd doctor`

---

## Task 3: 90일+ stale ADR/RCA 점검 (b)

### 3-1. 테스트 작성 → Fail (TDD Red)
- [ ] `tests/test-wiki.sh` 확장 — 오래된 frontmatter date(>90d) ADR fixture → stale 경고 단언 / 최근 → 무경고
- [ ] `bash tests/test-wiki.sh` → Fail 확인

### 3-2. 구현 → Pass (TDD Green)
- [ ] `cmd_doctor` 에 stale 점검 (frontmatter `updated:`→`date:` vs `_cutoff_90d` 이식성 분기, YYYY-MM-DD 비교)
- [ ] `bash tests/test-wiki.sh` → PASS
- [ ] Commit: `feat(spec-23-02): warn stale ADR/RCA (90d+) in sdd doctor`

---

## Task 4: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] 코드 품질 점검 — `bash tests/test-wiki.sh` + `bash tests/test-hk-doctor.sh`(doctor 회귀)
- [ ] 전체 관련 테스트 실행 → 모두 PASS
- [ ] (Integration Test Required = yes) `tests/test-wiki.sh` phase 시나리오 PASS
- [ ] 코드 리뷰 게이트 (`/hk-gemini-review` 권장 — bash 로직 + 이식성)
- [ ] **walkthrough.md 작성** (증거 로그)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] **Ship Commit**: `docs(spec-23-02): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-23-02-wiki-doctor`
- [ ] **PR 생성**: `/hk-pr-gh` (base = main)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 4 (점검 3 + Ship) |
| **예상 commit 수** | 4 |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-16 |
