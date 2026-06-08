# spec-x-gitignore-archive-coverage: archive 리뷰 산출물 ignore 커버리지

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-gitignore-archive-coverage` |
| **Phase** | 없음 (spec-x) |
| **Branch** | `spec-x-gitignore-archive-coverage` |
| **상태** | Planning |
| **타입** | Fix |
| **Integration Test Required** | no (키트 단위 테스트로 검증) |
| **작성일** | 2026-06-08 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

리뷰 도구 출력물(`code-review*.md`)은 per-spec 로컬 아티팩트로 git 미추적이 정책이며, ignore 규칙이 **3곳에 symmetry 로 존재**한다 (ADR-005 kit-managed ignore line 불변식):
- `.gitignore:45` — `specs/**/code-review*.md`
- `install.sh:552` — `_gi_ensure` (install 대상에 동일 라인 주입)
- `sources/bin/sdd` doctor — 해당 라인 등재 여부 점검 (+ `.harness-kit/bin/sdd` 미러)
- `uninstall.sh` — awk 제거 패턴 enumeration (install/uninstall 대칭 제거 — 실행 중 발견, 4번째 사이트)

### 문제점

세 규칙 모두 `specs/**` 로 경로가 한정되어 **`archive/specs/` 를 매칭하지 못한다.** `sdd archive` 가 spec 디렉토리를 `archive/specs/` 로 옮기면, 그동안 ignore 되던 `code-review*.md` 가 **untracked 로 드러나** 워킹트리가 더러워진다 (phase-21 archive 에서 10개 실증, 수동 삭제로 우회 — 2026-06-08). install 대상 프로젝트도 `sdd archive` 사용 시 동일 갭에 노출된다.

> 부수 관찰: 일부 옛 archived spec 3개(spec-x-gemini-review / md-lf-normalize / notify-choice-context)는 ignore 규칙 도입 *전*이라 `code-review-gemini.md` 가 *tracked* 상태 — 추적/미추적 혼재. 단 gitignore 는 이미 tracked 파일을 untrack 하지 않으므로, 본 fix(신규 ignore 라인)는 이들에 영향 없음.

### 해결 방안 (요약)

`archive/specs/**/code-review*.md` 패턴을 세 symmetry 사이트(`.gitignore` / `install.sh` / `sdd` doctor + 미러)에 **함께** 추가해 archive 이동 후에도 리뷰 산출물이 ignore 되도록 한다. 가드 테스트로 회귀를 박는다.

## 🎯 요구사항

### Functional Requirements

1. `.gitignore` 가 `archive/specs/**/code-review*.md` 를 ignore (이 repo).
2. `install.sh` 가 install 대상 `.gitignore` 에 동일 라인을 멱등 주입 (`_gi_ensure`).
3. `sdd` doctor (sources + `.harness-kit` 미러)가 archive 패턴 등재 여부도 점검.
4. 가드 테스트: archive 경로 리뷰 산출물이 ignore 됨 + 세 사이트 symmetry 확인 (회귀 방지).

### Non-Functional Requirements

1. **ADR-005 symmetry 유지** — 세 사이트가 동기 (한 곳만 바뀌면 안 됨).
2. **definition-file 보호 유지** — 기존 `specs/**` 한정이 `code-review.md` 류 정의 파일 오매칭을 피하던 의도를 보존 (→ broad `**/code-review*.md` 미채택, surgical mirror 채택).
3. `sources/bin/sdd` ↔ `.harness-kit/bin/sdd` 미러 parity 무회귀.

## 🚫 Out of Scope

- **tracked 잔존 3파일 제거** — archive immutability(specs/CLAUDE.md) 존중 + 무해(이미 tracked). 본 fix 영향 없음 → 문서화만, 제거 안 함.
- **broad `**/code-review*.md` 로 통합** — definition-file 오매칭 위험으로 미채택 (surgical mirror).
- `sdd archive` 의 이동 로직 변경 — 근본 원인은 ignore 패턴 한정이지 archive 로직 아님.

## 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 (ADR-005 의 기존 symmetry 불변식 *적용*일 뿐 신규 결정 아님. surgical vs broad 선택은 plan 결정 기록으로 충분)

## 🔍 Critique 결과 (선택)

<!-- 미실행 (소규모 fix). 필요 시 Plan Accept 전 /hk-spec-critique 가능. -->

## ✅ Definition of Done

- [ ] 가드 테스트 PASS (archive 패턴 커버 + symmetry)
- [ ] 기존 gitignore/doctor 테스트 무회귀 + 미러 parity 무회귀
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-gitignore-archive-coverage` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
