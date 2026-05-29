# Walkthrough: spec-x-install-ignore-coverage

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 작업 모드 선택 | FF / SDD-x / SDD-P | **SDD-x** | install.sh + uninstall.sh + sdd doctor + README + ADR 변경이라 FF 범위 초과, 단일 PR 완결이라 Phase 불필요 |
| 두 문제 (리뷰 출력 + 컨테이너 컨텍스트) 묶기 | Bundle / 분리 / 컨테이너만 | **Bundle** (1 spec-x) | 같은 "ignore 위생" 카테고리, 본 세션에 두 문제 컨텍스트 적재, ceremony 절감. CLAUDE.md `bundle-before-spec-x` 패턴. |
| `.gitignore` vs `.dockerignore` 정책 | 둘 다 자동 / 둘 다 경고 / 비대칭 | **비대칭** (`.gitignore` 자동 / `.dockerignore` 경고만) | install.sh 가 이미 `.gitignore` 5개 항목 자동 관리 → 패턴 연장. `.dockerignore` 는 Dockerfile 구조 다양성 (`COPY . .` vs 선택적) 으로 자동 침입 위험. Terraform / dockerignore-generate 등 산업 패턴과 정합. |
| critique 발견 — uninstall awk 비대칭 | 무시 / fix / 별도 spec | **본 spec 에서 fix** | critical 위험 (다중 라운드 update 에서 인접 라인 손상). 본 spec 의 직접 동기와 같은 카테고리 — 분리 시 같은 cognitive load 재발. ADR-005 invariant 화로 향후 재발 방지. |
| self-host 시 헤더 정책 | 기존 (skip) 유지 / 강제 추가 | **강제 추가** (정책 전환) | 신규 라인의 고아 라인 위험 차단. 헤더 부재 시 uninstall awk 가 시작점 못 찾아 영원히 잔존 위험 (critique 발견). cosmetic 노이즈는 self-host 의 특수 케이스로 수용. |
| `.dockerignore` 매칭 패턴 엄격성 | 정확 매치만 / 관대 패턴 | **관대 패턴** (`(^\|/)\.harness-kit/?$`) | 정확 매치 강제 시 사용자가 `**/.harness-kit/`, `.harness-kit` (슬래시 없이) 등 일반적 패턴 사용 시 false positive WARN. critique 보강. |
| Containerfile / compose.yml / Earthfile 지원 | 본 spec 에 포함 / Out of Scope | **Out of Scope** | 첫 릴리스는 Dockerfile 한정. README 에 "다른 컨테이너 도구도 동일 설정 권장" 한 줄 안내. 향후 사용자 요청 시 별도 spec. |
| `*.md` 한정 (`code-review*.md`) | 현재 한정 / 우산 패턴 (`code-review*`) | **현재 한정 유지** | 우산 패턴은 사용자 의도와 무관한 파일 (예: `code-review-notes.md` 수동 메모) 까지 잡을 위험. 향후 JSON/HTML/sub-dir 형식 추가 시 별도 spec 으로 명시. |

### ADR 승격 가이드

- [x] **ADR 승격 대상 있음** → 작성됨: `docs/decisions/ADR-005-kit-managed-ignore-line-symmetry-invariant.md`
  - type: `invariant`, status: `accepted`
  - 근거: install.sh ↔ uninstall.sh awk 패턴 대칭성은 *cross-spec / long-lived* 이고, 본 spec 의 critique 가 위반 사례 발견 직후 invariant 박는 가치 명확.
- [x] **추가 후보 (Icebox 등재)**: `tool-output-in-tree-vs-out-of-tree` (type: tradeoff) — 본 spec 외부 작업으로 분리 (`backlog/queue.md` Icebox).

## 💬 사용자 협의

- **주제**: 작업 모드 선택
  - **사용자 의견**: critique 옵션 (2번) 선택 — 보강된 비평 요청
  - **합의**: `/hk-spec-critique` 실행 → critique.md 8개 발견 항목 모두 반영하기로 합의 (사용자 "권장 진행")

- **주제**: 두 문제 bundle 여부
  - **사용자 의견**: Icebox 의 컨테이너 항목과 본 spec 같이 진행 가능한지 검토 요청
  - **합의**: 응집도 + ceremony 절감 가치로 bundle 채택 (옵션 1)

- **주제**: critique 반영 범위
  - **사용자 의견**: 권장 진행 (1~8 모두 반영)
  - **합의**: Critical 보강 4건 + 정밀도 개선 3건 + ADR 분리 1건 모두 반영. README 분리 / `.dockerignore` 분리는 거부 (bundle 응집도 유지).

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트 (본 spec 신규/수정)

- **`bash tests/test-gitignore-config.sh`**: ✅ 21/21 PASS
  - A-4: `.gitignore` 에 `specs/**/code-review*.md` 등재
  - H-2: self-host 시 `# harness-kit` 헤더 강제 추가 (정책 전환 검증)
  - H-3: self-host 시 신규 라인 always-apply
  - I-1/2/3: update × 3회 다중 라운드 안정성 (라인 멱등 + 헤더 멱등 + 인접 라인 유지)
  - J-1/2/3: uninstall awk 대칭성 (헤더 제거 + 신규 라인 제거 + 기존 5개 라인 회귀 보장)

- **`bash tests/test-doctor-ignore-coverage.sh`**: ✅ 9/9 PASS
  - a-section / a-1 / a-2: `ignore 위생` 섹션 + `.gitignore` 등재/미등재 점검
  - b-1: Dockerfile 없음 → silent skip
  - b-2: Dockerfile + `.dockerignore` 없음 → WARN
  - b-3: Dockerfile + `.dockerignore` 에 `.harness-kit` 없음 → WARN
  - b-4a/b/c: `.harness-kit/` 정확 매치 / `**/.harness-kit/` 와일드카드 / `.harness-kit` 슬래시 없이 → 3종 모두 PASS (관대성 검증)

#### 회귀 테스트

- **`bash tests/test-hk-doctor.sh`**: ✅ PASS (cmd_doctor 출력 형식 회귀 없음)
- **`bash tests/test-install-layout.sh`**: ✅ PASS (install.sh 멱등성 회귀 없음)
- **`bash tests/test-update.sh`**: ✅ PASS (update.sh 후 `.gitignore` 보존)
- **`bash tests/test-update-stateful.sh`**: 16/17 PASS (1 **pre-existing FAIL** — 본 spec 무관)
  - S4 "Icebox 메모 손실" FAIL 은 main 브랜치 (`e7b61ec`, 본 spec 의 base) 에서도 동일 발생 확인 (git stash + checkout main + 재실행으로 검증). 본 spec 의 install.sh / uninstall.sh / sdd 변경과 무관 — update.sh 의 queue.md Icebox 보존 로직에 별도 버그 (queue.md install 시점 overwrite 로 추정). 본 PR 범위 외, 별도 spec-x 후보로 Icebox 등재 권장.

### 2. 수동 검증

1. **Action**: `bash update.sh --yes .` (self-host 적용)
   - **Result**: `.gitignore` 멱등 유지 (`specs/**/code-review*.md` 라인 1개), `# harness-kit` 헤더 append (self-host orphan state, uninstall 무해), `.harness-kit/bin/sdd` sources 동기화 완료

2. **Action**: `bash .harness-kit/bin/sdd doctor` (self-host 검증)
   - **Result**: `ignore 위생` 섹션 출력 + `.gitignore PASS` + `.dockerignore` Dockerfile 부재로 silent skip (의도된 동작)

3. **Action**: critique 반영 후 spec/plan/task 갱신 + queue.md Icebox 추가 (Item 8)
   - **Result**: 8/8 항목 반영 (Critical 4 + 정밀도 3 + Icebox 1)

## 🔍 발견 사항

- **self-host 의 cosmetic 부작용**: `# harness-kit` 헤더 강제 추가 정책으로 self-host 저장소에 *orphan 헤더* 가 생김 (이전 spec-x 의 hand-added 라인이 헤더 부재 상태였기 때문). 기능적 무해 (uninstall awk 가 빈 블록을 EOF 로 자연 종료). 신규 fresh install / 외부 사용자 update 에는 영향 없음.

- **critique 의 ROI**: critique 가 발견한 critical 누락 (uninstall awk 대칭성) 은 단순 반영으로 끝나지 않고 ADR-005 invariant 까지 박는 결과로 이어짐. 향후 신규 ignore 라인 추가 시 self-check 비용 절감. critique 도입 ROI 검증 사례.

- **bundle 패턴의 유효성**: 두 문제 (review drift + container 비대칭) 가 같은 "install.sh ignore 위생" 카테고리라 bundle 응집도 컸음. PR 1개로 10 commit + ADR 1건 + README 섹션 묶음 처리 — 분리 시 ceremony 2배.

## 🚧 이월 항목

- **ADR-tool-output-in-tree-vs-out-of-tree** (type: tradeoff) → `backlog/queue.md` Icebox 등재. 본 spec 의 critique 대안 A (출력 경로 격리 — `.harness-kit/cache/reviews/`) 의 근본 방향성을 별도 ADR 또는 spec 으로 분리 결정.

- **sdd doctor self-check 자동화** (long-term TODO, ADR-005 §Consequences 명시): self-host 시 install.sh 의 `_gi_ensure` 호출 목록과 uninstall.sh awk 패턴의 일치성을 자동 검증하는 doctor 점검 추가. 본 spec 범위 외 — 향후 spec-x 후보.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Opus 4.7) + Leo |
| **작성 기간** | 2026-05-29 |
| **최종 commit** | ship commit 직후 갱신 |
