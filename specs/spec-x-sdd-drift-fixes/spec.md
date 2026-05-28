# spec-x-sdd-drift-fixes: sdd status 의 drift 진단 두 fix bundle (dogfood-sync 감지 + ADR stale 정확도)

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-sdd-drift-fixes` |
| **Phase** | (없음 — spec-x) |
| **Branch** | `spec-x-sdd-drift-fixes` |
| **상태** | Planning |
| **타입** | Fix |
| **Integration Test Required** | no |
| **작성일** | 2026-05-28 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

`sdd status` 의 `🔄 동기화 상태` 섹션은 6개 drift 검사로 구성: kit-version / remote / worktree / consistency / install / stale-adr.

본 spec 은 두 개의 정확도 이슈를 fix 한다.

### 문제점 1 — dogfood-sync drift 미감지 (False Negative)

`spec-x-check-secrets-docs-context` (PR #4) 작업에서 *직접* 비용 발생:
- `sources/hooks/check-secrets.sh` 가 PR #3 머지 후에도 `.harness-kit/hooks/check-secrets.sh` 와 비동기 상태로 main 에 잔존.
- `update.sh` 호출이 누락된 상태를 sdd status 가 알리지 않아 다음 Ship 시점까지 발견 미뤄짐 → Hard Stop 1회 + main chore 1개 + spec chore 1개 추가 발생.

기존 `_drift_install` 은 *untracked* `.harness-kit/{hooks,agent/templates}/*` 와 `.claude/commands/*` 만 다룬다. *tracked* 파일이 `sources/` 대응본과 다른 경우 (dogfood-sync drift 의 전형) 는 검출 안 됨.

### 문제점 2 — ADR stale-path 진단 False Positive

`docs/decisions/ADR-003-dogfood-sync-policy.md` 의 line 34 에 *비채택 link 모델* 을 설명하는 인용:

```text
**link 모델 (`.harness-kit/agent/agent.md` → `../../sources/governance/agent.md` symlink)**: drift 가 원천적으로 0. 비채택 이유: ...
```

`_drift_stale_adr` 는 backtick 토큰 (`../../sources/governance/agent.md`) 을 *프로젝트 루트 기준* 으로 존재 검사 → MISSING. 그러나 본문 컨텍스트는 *심볼릭 링크 가설 표기 인용* 이고 실재 path 가 아니다.

매 `sdd status` 호출마다 `stale ADR: 1 (missing-path) — docs/decisions/ADR-003-...md` 노이즈 1줄 출력.

### 해결 방안 (요약)

두 fix 모두 `.harness-kit/bin/sdd` 1개 파일에 적용:

1. 새 함수 `_drift_dogfood_sync` 추가 → `_status_drift()` 에 등록. `sources/` 디렉토리 존재 시 (= 본 프로젝트 dogfood 환경) tracked `.harness-kit/hooks/*` / `.harness-kit/agent/templates/*` / `.claude/commands/*` 가 대응 `sources/*` 와 `diff -q` 로 다르면 mismatch count 증가. 메시지: `도그푸딩 sync: N 파일 sources/와 비동기 — bash update.sh --yes 권장`.
2. `_drift_stale_adr` 의 token 필터에 *상대경로 토큰 제외 한 줄* 추가 (`^\.\./` 시작 시 skip). false positive 해소.

## 📊 개념도

```text
sdd status
  └─ _status_drift()
       ├─ _drift_kit_version
       ├─ _drift_remote
       ├─ _drift_worktree
       ├─ _drift_consistency
       ├─ _drift_install        (untracked .harness-kit/* 만)
       ├─ _drift_dogfood_sync   ← NEW (tracked .harness-kit/* vs sources/* mismatch)
       └─ _drift_stale_adr      ← 보강 (../ 시작 token 제외)
```

## 🎯 요구사항

### Functional Requirements

1. **dogfood-sync 감지**: `sources/` 디렉토리 존재 시, tracked `.harness-kit/hooks/*` / `.harness-kit/agent/templates/*` / `.claude/commands/*` 각 파일이 대응 `sources/{hooks|templates|commands}/*` 와 `diff -q` 로 다르면 mismatch 로 카운트. 메시지에 N 표시 + `bash update.sh --yes` 안내.
2. **외부 target 무영향**: `sources/` 디렉토리 없는 target 프로젝트 (외부 사용자) 에서는 `_drift_dogfood_sync` 가 0 카운트로 return — 정상 동작.
3. **ADR stale-path 정확도**: `../` 로 시작하는 backtick path 토큰은 진단에서 제외. 기존 다른 missing-path 검출은 유지 (실제로 존재해야 할 path 가 missing 이면 계속 잡힘).

### Non-Functional Requirements

1. bash 3.2+ 호환. `diff -q` 는 POSIX. 기존 `_drift_install` 과 동일 기법.
2. 성능: `.harness-kit/{hooks,agent/templates}/*` + `.claude/commands/*` 합산 ~30 파일. 매 `sdd status` 호출에서 30회 `diff -q` 추가 — 미체감.
3. 테스트 신규 최소 4건 (sync 일치 시 보고 없음 / mismatch 시 보고 / sources/ 없는 환경 무영향 / ADR `../` token 제외 false positive 해소).

## 🚫 Out of Scope

- **자동 `update.sh` 호출** — 안내만 추가, 사용자 명시 호출이 SSOT. 자동화는 향후 별 spec 후보 (ADR 영역).
- **외부 target 의 .harness-kit/ ↔ kit origin 의 sources/ 비교** — origin remote 조회는 `_drift_kit_version` 이 담당. 본 fix 는 *local sources/* 와의 비교만 (self-host dogfood 한정).
- **ADR token 의 일반 false positive 보강** — `*` glob, repo reference, anchor 등 다른 false positive 패턴은 별 spec. 본 spec 은 *관찰된* `../` 케이스 한 줄 fix.

## 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — sdd 의 drift 검사 정확도 보강. 단발 fix.

## ✅ Definition of Done

- [ ] `.harness-kit/bin/sdd` 에 `_drift_dogfood_sync` 함수 추가 + `_status_drift()` 에 등록
- [ ] `.harness-kit/bin/sdd` 의 `_drift_stale_adr` 에 `../` 시작 token 제외 한 줄 추가
- [ ] 신규 테스트 4건 추가 (정확한 위치는 plan.md 에서 결정)
  - Test A: `_drift_dogfood_sync` — sync 일치 시 보고 없음
  - Test B: `_drift_dogfood_sync` — mismatch 시 N 카운트 + 메시지
  - Test C: `_drift_dogfood_sync` — `sources/` 없는 임시 환경 무영향
  - Test D: `_drift_stale_adr` — ADR 본문에 `../` token 만 있으면 stale 카운트 0 (false positive 해소)
- [ ] 본 프로젝트에서 `bash .harness-kit/bin/sdd status` 실행 → `stale ADR` 줄 사라짐 + `🔄 동기화 상태` 가 `깔끔` 출력 (워킹트리 변경만 있을 시)
- [ ] `walkthrough.md` / `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-sdd-drift-fixes` 브랜치 push + fork main PR
