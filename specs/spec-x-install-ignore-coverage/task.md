# Task List: spec-x-install-ignore-coverage

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성 (`sdd specx new install-ignore-coverage`)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 업데이트 — sdd 자동 갱신 (queue.md `specx` 마커)
- [x] Critique 반영 (critique.md 8개 항목 → spec/plan/task 갱신, queue.md Icebox 등재 1건)
- [x] 사용자 Plan Accept (2026-05-29)

---

## Task 1: 브랜치 생성

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-install-ignore-coverage`
- [x] Commit: 없음 (브랜치 생성만)

---

## Task 2: install.sh `.gitignore` 항목 확장 + 헤더 강제 (TDD)

### 2-1. 회귀 테스트 케이스 추가 (Red)
- [x] `tests/test-gitignore-config.sh` Scenario A 에 A-4 시나리오 추가 (`specs/**/code-review*.md` 검증)
- [x] Scenario H (self-host) 에 H-3 시나리오 추가 — self-host 시 신규 라인 + 헤더 모두 있음 확인 (critique 보강: 헤더 정책 전환)
- [x] `bash tests/test-gitignore-config.sh` 실행 → A-4, H-2, H-3 FAIL 확인 (3 FAIL / 12 PASS, 헤더 정책 전환으로 H-2 도 expectation 반전)
- [x] Commit: `test(spec-x-install-ignore-coverage): assert review output and forced header in gitignore` (`2a95508`)

### 2-2. install.sh 구현 (Green)
- [x] `install.sh` line 513-517 헤더 처리 조건 완화 — `_hk_self_host` 분기 제거 (self-host 시에도 헤더 강제)
- [x] `install.sh` `.gitignore` 자동 갱신 블록 line 521-525 영역에 `_gi_ensure '^specs/\*\*/code-review\*\.md$' 'specs/**/code-review*.md'` 추가
- [x] 위치: `_hk_self_host` 분기 *밖* (always-apply)
- [x] 한국어 주석 1-2줄 첨부 (의도 + specs/ 한정 이유 + critique 헤더 정책 변경 reference)
- [x] `bash tests/test-gitignore-config.sh` 실행 → 15/15 PASS 확인
- [x] Commit: `chore(spec-x-install-ignore-coverage): add review outputs to gitignore and force header in install.sh` (`f371be4`)

---

## Task 3: uninstall.sh awk 패턴 대칭성 확장 (TDD) [신설 — critique 보강]

### 3-1. uninstall 검증 시나리오 추가 (Red)
- [x] `tests/test-gitignore-config.sh` 에 Scenario J 추가 (J-1: 헤더 제거 / J-2: 신규 라인 제거 / J-3: 기존 5개 라인 회귀 보장)
- [x] 기존 uninstall awk 가 신규 라인 미인지 → J-2 FAIL 확인 (17/18, 1 FAIL)
- [x] Commit: `test(spec-x-install-ignore-coverage): assert uninstall awk removes specs review line` (`256a36a`)

### 3-2. uninstall.sh awk 패턴 추가 (Green)
- [x] `uninstall.sh` line 159-167 awk 블록에 `inblk==1 && /^specs\/\*\*\/code-review\*\.md$/ { next }` 추가
- [x] 18/18 PASS 확인 (J-2 Green 전환)
- [x] Commit: `chore(spec-x-install-ignore-coverage): register specs review line in uninstall awk for symmetry` (`e701433`)

---

## Task 4: 다중 라운드 안정성 시나리오 추가 (TDD) [신설 — critique 보강]

### 4-1. Scenario I (다중 라운드) 추가
- [x] `tests/test-gitignore-config.sh` 의 Scenario H 직전에 Scenario I 추가 (FIX_A 재사용 — update × 3회)
- [x] I-1: `specs/**/code-review*.md` 1개 / I-2: `# harness-kit` 헤더 1개 / I-3: 인접 라인 4개 모두 유지
- [x] `bash tests/test-gitignore-config.sh` → 21/21 PASS (Task 3 의 uninstall awk 등재 선행 → 즉시 Green)
- [x] Commit: `test(spec-x-install-ignore-coverage): add multi-round update stability scenario` (`06af2d7`)

---

## Task 5: sdd doctor `ignore 위생` 섹션 + `.gitignore` 미등재 경고 (TDD)

### 5-1. doctor 점검 테스트 fixture 작성 (Red)
- [x] `tests/test-doctor-ignore-coverage.sh` 신규 작성 — 헤더 + `make_fixture()` 헬퍼 + 3 시나리오 (a-section / a-1 / a-2)
- [x] `bash tests/test-doctor-ignore-coverage.sh` → 0/3 PASS (구현 전 expected Red)
- [x] Commit: `test(spec-x-install-ignore-coverage): add doctor gitignore-coverage assertions` (`492423f`)

### 5-2. sdd doctor 구현 (Green)
- [x] `sources/bin/sdd` `cmd_doctor()` 에 신규 섹션 `ignore 위생` 추가 (기존 `훅 파일` 섹션 직전)
- [x] `.gitignore` 미등재 시 `_doc_warn` 호출 — 메시지에 `bash update.sh .` 안내 포함
- [x] 3/3 PASS 확인
- [x] Commit: `feat(spec-x-install-ignore-coverage): add ignore-hygiene section with gitignore check in sdd doctor` (`6c5c32c`)

---

## Task 6: sdd doctor `.dockerignore` 미등재 경고 (TDD)

### 6-1. .dockerignore 매트릭스 테스트 추가 (Red)
- [x] `tests/test-doctor-ignore-coverage.sh` 에 6 시나리오 매트릭스 추가 (b-1 ~ b-4c)
- [x] `bash tests/test-doctor-ignore-coverage.sh` → 5 FAIL 확인 (4/9 PASS, b-1 만 negative grep 으로 자동 통과)
- [x] Commit: `test(spec-x-install-ignore-coverage): add doctor dockerignore matrix with permissive patterns` (`dddf58c`)

### 6-2. sdd doctor `.dockerignore` 점검 구현 (Green)
- [x] `cmd_doctor()` 의 `ignore 위생` 섹션에 Dockerfile 조건부 `.dockerignore` 점검 추가
- [x] 매칭 패턴 `(^|/)\.harness-kit/?$` 사용 (관대성 보장)
- [x] WARN 메시지에 "README '컨테이너 빌드 가이드' 참조" 안내 포함
- [x] 9/9 PASS 확인
- [x] Commit: `feat(spec-x-install-ignore-coverage): add permissive dockerignore check in sdd doctor` (`3bf5240`)

---

## Task 7: README 컨테이너 빌드 가이드 섹션 추가

### 7-1. README 섹션 작성
- [x] `README.md` 의 "설치" 섹션 직후에 "## 🐳 컨테이너 빌드 컨텍스트 (Dockerfile 사용자)" 섹션 추가
- [x] 권장 `.dockerignore` 항목 + 다른 컨테이너 도구 안내 + `sdd doctor` 자동 감지 안내
- [x] Commit: `docs(spec-x-install-ignore-coverage): add container build context guide to README` (`47c80b9`)

---

## Task 8: ADR-005 invariant 작성 [신설 — critique 보강]

### 8-1. ADR 작성
- [x] `docs/decisions/ADR-005-kit-managed-ignore-line-symmetry-invariant.md` 작성 (`577d284`)
- [x] 템플릿 준수 (Context / Decision / Consequences / Alternatives / Status / Related)
- [x] frontmatter `type: invariant`, status `accepted`
- [x] 본문 한국어, critique §1 인용 + 적용 commit 해시 참조
- [x] Commit: `docs(spec-x-install-ignore-coverage): add ADR-005 ignore-line-symmetry invariant` (`577d284`)

---

## Task 9: self-host 적용 검증

### 9-1. 본 저장소에 update 적용
- [x] `bash update.sh --yes .` 실행
- [x] `.gitignore` 멱등 확인 — `specs/**/code-review*.md` 라인 1개 유지 (직전 spec-x 가 hand-add 한 라인, 중복 없음)
- [x] `# harness-kit` 헤더 append 됨 (self-host 정책 전환 — orphan 상태이나 uninstall 동작 무해)
- [x] `bash .harness-kit/bin/sdd doctor` → `ignore 위생` 섹션 PASS 확인 (.dockerignore 점검은 Dockerfile 부재로 silent skip — 의도된 동작)
- [x] update.sh 가 갱신한 자산 commit (.gitignore + .harness-kit/installed.json + .harness-kit/bin/sdd)
- [x] Commit: `chore(spec-x-install-ignore-coverage): apply update.sh to self-host` (`d9eec1c`)

---

## Task 10: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [x] 전체 회귀 테스트 실행:
  - `bash tests/test-gitignore-config.sh` → 21/21 PASS
  - `bash tests/test-doctor-ignore-coverage.sh` → 9/9 PASS
  - `bash tests/test-hk-doctor.sh` → 7/7 PASS
  - `bash tests/test-install-layout.sh` → 15/15 PASS
  - `bash tests/test-update.sh` → 11/11 PASS
  - `bash tests/test-update-stateful.sh` → 16/17 PASS (S4 "Icebox 메모 손실" **pre-existing FAIL** — main 에서도 동일 발생 확인, 본 spec 무관, walkthrough.md §검증결과에 기록)
- [x] **walkthrough.md 작성** (결정 8건 + 사용자 협의 3건 + 검증 결과 + 발견 사항 + 이월 항목)
- [x] **pr_description.md 작성** (Summary / Key Review Points / Verification / Files Changed / DoD)
- [ ] **Ship Commit**: `docs(spec-x-install-ignore-coverage): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-install-ignore-coverage`
- [ ] **PR 생성**: `/hk-pr-gh` (사용자 승인 후)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 10 (Pre-flight 제외) |
| **예상 commit 수** | 10-11 (Task 9 가 skip 되면 10) |
| **현재 단계** | Planning (Critique 반영 완료) |
| **마지막 업데이트** | 2026-05-29 |
| **Critique 반영** | 8/8 항목 (Items 1-7 spec/plan/task 반영, Item 8 queue.md Icebox 등재) |
