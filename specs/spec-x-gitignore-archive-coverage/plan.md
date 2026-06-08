# Implementation Plan: spec-x-gitignore-archive-coverage

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-gitignore-archive-coverage`
- 시작 지점: `main`
- 첫 task 가 브랜치 생성

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] 패턴 선택 = **`archive/specs/**/code-review*.md` (surgical mirror)**. broad `**/code-review*.md` 는 definition-file 오매칭 위험으로 미채택.
> - [ ] tracked 잔존 3파일(`archive/specs/spec-x-{gemini-review,md-lf-normalize,notify-choice-context}/code-review-gemini.md`)은 **제거하지 않음** (archive immutability + 무해).

> [!WARNING]
> - [ ] 변경은 ADR-005 symmetry 사이트 3곳을 **함께** 수정 (한 곳만 바뀌면 미러 parity / doctor 회귀).

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **패턴** | `archive/specs/**/code-review*.md` 병렬 추가 | broad 통합은 `code-review.md` 정의파일 오매칭 위험. 기존 `specs/**` 의도(보호) 보존 |
| **적용 범위** | `.gitignore` + `install.sh` + `sdd` doctor (+미러) | ADR-005 ignore line symmetry — 세 사이트 동기 필수 |
| **tracked 잔존** | 제거 안 함 | archive immutability + gitignore 가 tracked 를 untrack 안 함 → 무해 |
| **커밋 구조** | symmetry 사이트를 1 commit 으로 원자 변경 | 사이트 간 동기가 불변식 → 분할 시 중간 상태가 회귀 |

### 📑 ADR 후보
- [ ] 있음
- [x] 없음 (ADR-005 적용)

## 📂 Proposed Changes

#### [MODIFY] `.gitignore`
`specs/**/code-review*.md` 아래에 `archive/specs/**/code-review*.md` 추가.

#### [MODIFY] `install.sh` (~552)
`_gi_ensure '^archive/specs/\*\*/code-review\*\.md$' 'archive/specs/**/code-review*.md'` 추가 (기존 specs 라인 다음).

#### [MODIFY] `uninstall.sh` (awk 제거 패턴 enumeration)
신규 `archive/specs/**/code-review*.md` 라인을 uninstall awk 제거 대상에 추가 — install/uninstall 대칭 (ADR-005, test-gitignore-config Scenario J). **실행 중 발견(2026-06-08): plan 초안의 3사이트 → 4사이트로 확정 (사용자 승인).**

#### [MODIFY] `sources/bin/sdd` (~2383 doctor 점검)
archive 패턴 등재 여부 점검 추가 (또는 기존 점검을 두 패턴 모두 확인하도록 확장).

#### [MODIFY] `.harness-kit/bin/sdd` (미러)
위 sdd 변경을 도그푸딩 미러에 동기 (parity 유지).

#### [MODIFY] `tests/test-gitignore-config.sh` / `tests/test-doctor-ignore-coverage.sh`
archive 패턴 커버 가드 케이스 추가 (실행 단계서 정확한 파일 확정).

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
bash tests/test-gitignore-config.sh
bash tests/test-doctor-ignore-coverage.sh
bash tests/test-governance-dedup.sh   # 미러 parity 무회귀 점검 겸
```

### 수동 검증 시나리오
1. `git check-ignore archive/specs/foo/code-review.md` → 매칭(ignore) 반환 (fix 전엔 미매칭) — 기대: 패턴 적용 확인.
2. install fixture 에 적용 후 대상 `.gitignore` 에 archive 라인 존재 — 기대: 타깃 커버.
3. `sdd doctor` 출력에 archive 패턴 점검 항목 — 기대: 등재 시 pass.

## 🔁 Rollback Plan

- 순수 ignore 라인 추가 + doctor 점검 + 테스트 → 가역. 브랜치 폐기로 롤백.
- 런타임/데이터 영향 없음 (ignore 는 미추적 파일 동작만 변경, 기존 tracked 무영향).

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
