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
- [ ] `tests/test-gitignore-config.sh` Scenario A 에 A-4 시나리오 추가 (`specs/**/code-review*.md` 검증)
- [ ] Scenario H (self-host) 에 H-3 시나리오 추가 — self-host 시 신규 라인 + 헤더 모두 있음 확인 (critique 보강: 헤더 정책 전환)
- [ ] `bash tests/test-gitignore-config.sh` 실행 → A-4, H-3 FAIL 확인 (헤더 정책 전환 영향 — H-2 도 PASS → FAIL 로 전환됨, 본 task 에서 H-2 도 같이 수정)
- [ ] Commit: `test(spec-x-install-ignore-coverage): assert review output and forced header in gitignore`

### 2-2. install.sh 구현 (Green)
- [ ] `install.sh` line 513-517 헤더 처리 조건 완화 — `_hk_self_host` 분기 제거 (self-host 시에도 헤더 강제)
- [ ] `install.sh` `.gitignore` 자동 갱신 블록 line 521-525 영역에 `_gi_ensure '^specs/\*\*/code-review\*\.md$' 'specs/**/code-review*.md'` 추가
- [ ] 위치: `_hk_self_host` 분기 *밖* (always-apply)
- [ ] 한국어 주석 1-2줄 첨부 (의도 + specs/ 한정 이유 + critique 헤더 정책 변경 reference)
- [ ] `bash tests/test-gitignore-config.sh` 실행 → 모든 시나리오 PASS 확인 (H-2 의 의미가 `self-host 시 헤더 추가됨` 으로 바뀌므로 테스트 expectation 도 함께 수정)
- [ ] Commit: `chore(spec-x-install-ignore-coverage): add review outputs to gitignore and force header in install.sh`

---

## Task 3: uninstall.sh awk 패턴 대칭성 확장 (TDD) [신설 — critique 보강]

### 3-1. uninstall 검증 시나리오 추가 (Red)
- [ ] `tests/test-gitignore-config.sh` 또는 `tests/test-update-stateful.sh` 에 시나리오 추가:
  - install → `.gitignore` 6개 라인 + 헤더 확인
  - uninstall → `# harness-kit` 블록 전체 제거 (헤더 + 6개 라인 모두 사라짐) 확인
- [ ] 기존 uninstall awk 가 신규 라인 미인지 → FAIL 확인
- [ ] Commit: `test(spec-x-install-ignore-coverage): assert uninstall awk removes specs review line`

### 3-2. uninstall.sh awk 패턴 추가 (Green)
- [ ] `uninstall.sh` line 159-167 awk 블록에 추가:
  ```awk
  inblk==1 && /^specs\/\*\*\/code-review\*\.md$/ { next }
  ```
- [ ] 위 시나리오 PASS 확인 + 회귀 테스트 (test-update.sh, test-update-stateful.sh) PASS 확인
- [ ] Commit: `chore(spec-x-install-ignore-coverage): register specs review line in uninstall awk for symmetry`

---

## Task 4: 다중 라운드 안정성 시나리오 추가 (TDD) [신설 — critique 보강]

### 4-1. Scenario I (다중 라운드) 추가
- [ ] `tests/test-gitignore-config.sh` 의 Scenario E (update 후 보존) 직후 Scenario I 추가:
  - update × 3회 반복
  - I-1: `specs/**/code-review*.md` 라인 1개 (멱등)
  - I-2: `# harness-kit` 헤더 1개 (멱등)
  - I-3: 인접 라인 (`.harness-backup-*/`, `.claude/state/`, `.env.telegram`, `.env.discord`) 모두 유지 (awk 조기 종료 부작용 차단 검증)
- [ ] `bash tests/test-gitignore-config.sh` → I-1, I-2, I-3 모두 PASS 확인 (Task 3 가 완료된 후이므로 PASS 가 기대됨)
- [ ] Commit: `test(spec-x-install-ignore-coverage): add multi-round update stability scenario`

---

## Task 5: sdd doctor `ignore 위생` 섹션 + `.gitignore` 미등재 경고 (TDD)

### 5-1. doctor 점검 테스트 fixture 작성 (Red)
- [ ] `tests/test-doctor-ignore-coverage.sh` 신규 작성 — 헤더 + `make_fixture()` 헬퍼 + `.gitignore` 등재/미등재 2 시나리오
- [ ] 시나리오: (1) install 후 .gitignore 등재 → `ignore 위생` 섹션 출력 + PASS 라인 grep, (2) `.gitignore` 에서 항목 제거 → WARN 라인 grep
- [ ] `bash tests/test-doctor-ignore-coverage.sh` → 미구현 점검이므로 시나리오 (2) FAIL 확인
- [ ] Commit: `test(spec-x-install-ignore-coverage): add doctor gitignore-coverage assertions`

### 5-2. sdd doctor 구현 (Green)
- [ ] `sources/bin/sdd` `cmd_doctor()` 에 신규 섹션 `ignore 위생` 추가 (기존 `훅 파일` 섹션 직전 또는 직후)
- [ ] `.gitignore` 미등재 시 `_doc_warn` 호출 — 메시지에 `bash update.sh .` 안내 포함
- [ ] 시나리오 2종 PASS 확인
- [ ] Commit: `feat(spec-x-install-ignore-coverage): add ignore-hygiene section with gitignore check in sdd doctor`

---

## Task 6: sdd doctor `.dockerignore` 미등재 경고 (TDD)

### 6-1. .dockerignore 매트릭스 테스트 추가 (Red)
- [ ] `tests/test-doctor-ignore-coverage.sh` 에 4 시나리오 매트릭스 추가 (Dockerfile 유/무 × `.dockerignore` 유/무 × `.harness-kit` 항목 유/무)
- [ ] 시나리오 1 (Dockerfile 없음) → 경고 발화 안 함 (negative grep)
- [ ] 시나리오 2 (Dockerfile 있음, `.dockerignore` 없음) → WARN
- [ ] 시나리오 3 (Dockerfile 있음, `.dockerignore` 에 `.harness-kit` 없음) → WARN
- [ ] 시나리오 4a (Dockerfile 있음, `.dockerignore` 에 `.harness-kit/` 정확 매치) → PASS
- [ ] 시나리오 4b (Dockerfile 있음, `.dockerignore` 에 `**/.harness-kit/` 와일드카드) → PASS (관대성 검증, critique 보강)
- [ ] 시나리오 4c (Dockerfile 있음, `.dockerignore` 에 `.harness-kit` 슬래시 없이) → PASS (관대성 검증)
- [ ] `bash tests/test-doctor-ignore-coverage.sh` → 시나리오 2-3 FAIL 확인
- [ ] Commit: `test(spec-x-install-ignore-coverage): add doctor dockerignore matrix with permissive patterns`

### 6-2. sdd doctor `.dockerignore` 점검 구현 (Green)
- [ ] `cmd_doctor()` 의 `ignore 위생` 섹션에 Dockerfile 조건부 `.dockerignore` 점검 추가
- [ ] `if [ -f "$SDD_ROOT/Dockerfile" ]; then ...` 분기 — Dockerfile 없으면 silent skip
- [ ] 매칭 패턴 `(^|/)\.harness-kit/?$` 사용 (사용자 자유도 보장, critique 보강)
- [ ] WARN 메시지에 "README '컨테이너 빌드 가이드' 참조" 안내 포함
- [ ] 6 시나리오 PASS 확인
- [ ] Commit: `feat(spec-x-install-ignore-coverage): add permissive dockerignore check in sdd doctor`

---

## Task 7: README 컨테이너 빌드 가이드 섹션 추가

### 7-1. README 섹션 작성
- [ ] `README.md` 의 "설치" 섹션 직후 또는 적절한 위치에 "## 컨테이너 빌드 컨텍스트 (Dockerfile 사용자)" 섹션 추가
- [ ] 권장 `.dockerignore` 항목 코드블록 (`.harness-kit/`, `.claude/`, `backlog/`, `specs/`, `archive/`)
- [ ] 다른 컨테이너 도구 (Containerfile / compose.yml / Earthfile) 한 줄 안내
- [ ] `sdd doctor` 자동 감지 안내 한 줄
- [ ] (테스트 없음 — 문서 변경)
- [ ] Commit: `docs(spec-x-install-ignore-coverage): add container build context guide to README`

---

## Task 8: ADR-005 invariant 작성 [신설 — critique 보강]

### 8-1. ADR 작성
- [ ] `docs/decisions/ADR-005-kit-managed-ignore-line-symmetry-invariant.md` 신규 작성
- [ ] 템플릿: `.harness-kit/agent/templates/adr.md` 준수 (constitution §6.3)
- [ ] frontmatter `type: invariant` 명시 (constitution §6.4 어휘)
- [ ] 5 섹션: Statement / Why / Reproduction / Prevention / Adopted by
- [ ] 본문 한국어 (constitution §5.4)
- [ ] 본 spec critique.md 의 §1 (uninstall 대칭성 누락 Critical 발견) 을 *Adopted by reasoning* 의 evidence 로 인용
- [ ] Commit: `docs(spec-x-install-ignore-coverage): add ADR-005 ignore-line-symmetry invariant`

---

## Task 9: self-host 적용 검증

### 9-1. 본 저장소에 update 적용
- [ ] `bash update.sh .` 실행
- [ ] `.gitignore` 에 `specs/**/code-review*.md` 신규 라인 추가 확인 (수동 검증)
- [ ] 기존 self-host 한정 패턴 (직전 spec-x 가 추가한 `.gitignore` 라인) 과 멱등 확인 — `grep -c 'code-review' .gitignore` 결과가 예상치와 일치
- [ ] `bash .harness-kit/bin/sdd doctor` → 신규 `ignore 위생` 섹션 PASS 확인
- [ ] update.sh 가 생성한 변경 (있다면) commit
- [ ] Commit: `chore(spec-x-install-ignore-coverage): apply update.sh to self-host` (필요 시)
- [ ] **참고**: update.sh 가 변경 없으면 이 task 는 [-] 로 마킹

---

## Task 10: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] 전체 회귀 테스트 실행 → 모두 PASS
  - `bash tests/test-gitignore-config.sh` (Scenario A-4, H-3, I-1/2/3)
  - `bash tests/test-doctor-ignore-coverage.sh` (.gitignore 2 + .dockerignore 6 시나리오)
  - `bash tests/test-hk-doctor.sh`
  - `bash tests/test-install-layout.sh`
  - `bash tests/test-update.sh`
  - `bash tests/test-update-stateful.sh`
- [ ] **walkthrough.md 작성** (증거 로그 — critique 발견 + 정책 비대칭 + uninstall 대칭성 invariant 포함)
- [ ] **pr_description.md 작성** (템플릿 준수)
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
