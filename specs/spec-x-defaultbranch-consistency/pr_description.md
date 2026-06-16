# refactor(spec-x-defaultbranch-consistency): unify base branch resolution to defaultBranch chain

## 📋 Summary

### 배경 및 목적

base 브랜치를 하드코딩 `main` 으로 가정하는 경로(sdd 머지 감지 2곳, hk-ship PR 타깃, constitution §3.2/§3.3, hk-cleanup)가 남아 있어, `defaultBranch`≠main 형상(fork 운영·nextmarket 라이브)에서 머지 감지·PR 타깃·정리 점검이 어긋났다. 이미 존재하는 `defaultBranch` 인프라(installed.json, `sdd config default-branch`)를 누락 경로에 전파하고, base 해석을 단일 체인으로 자산화(ADR-015)한다.

### 주요 변경 사항
- [x] `sources/bin/sdd` 에 `_resolve_base_branch()` 신설 — 체인 `state.baseBranch → defaultBranch → main` + **2단 ref-실재 fallback** (gemini-review.sh 패턴). 하드코딩 2곳(머지 감지/phase-done cross-check) 대체.
- [x] `hk-ship.md` — base/PR_BASE 결정에 defaultBranch 반영 (phase-base-mode 감지 보존하며 별도 `default_branch` 추출).
- [x] `hk-cleanup.md` — defaultBranch 오설정(실재) 점검 추가.
- [x] `constitution §3.2/§3.3` — `main` 리터럴 → `defaultBranch` (기본 `main`).
- [x] `ADR-015-review-base-resolution-chain` (type: tradeoff) + 회귀 테스트.

### Phase 컨텍스트
- **Phase**: 없음 (bundled spec-x). spec-x-review-base-config 후속.

## 🎯 Key Review Points

1. **`_resolve_base_branch()` 의 2단 ref-fallback** (`sources/bin/sdd`): base-branch 모드 phase 의 첫 spec 은 base 브랜치가 JIT 생성이라 작업 중 미존재 → 값-체인만 만들면 `git log <미존재>` 무음 실패. Opus critique 가 잡아 ref-실재 확인을 추가 (회귀 방지).
2. **hk-ship 정정**: plan/critique 의 "line 139 병합" 을 그대로 적용하면 phase-base-mode if/else 가 깨져, 별도 `default_branch` 추출로 정정 (walkthrough 결정 기록).
3. **하위호환**: defaultBranch 미설정 → main 폴백. dogfood(defaultBranch=main) 무영향.

## 🧪 Verification

```bash
bash tests/test-sdd-base-resolution.sh   # 6/6 — 체인 + JIT 회귀 케이스
bash tests/test-sdd-base-branch.sh       # 4/4 회귀 없음
bash tests/test-governance-dedup.sh      # 8/8 (sync + 예산 6400w≤6500)
bash -n sources/bin/sdd                  # 문법 OK
```

> 사전 존재 실패 2건(`test-sdd-status-cross-check`·`test-sdd-phase-done-accuracy`)은 `git stash` 비교로 본 PR 무관 확정 (fixture-on-master + "(미구현)" placeholder).

## 📦 Files Changed

### 🆕 New
- `docs/decisions/ADR-015-review-base-resolution-chain.md` (type: tradeoff)
- `tests/test-sdd-base-resolution.sh` (체인 단위 테스트)

### 🛠 Modified
- `sources/bin/sdd` (+`_resolve_base_branch()`, 하드코딩 2곳 대체)
- `sources/commands/hk-ship.md` · `sources/commands/hk-cleanup.md`
- `sources/governance/constitution.md` (§3.2/§3.3)
- 설치본 동기화: `.harness-kit/bin/sdd`, `.harness-kit/agent/constitution.md`, `.claude/commands/hk-ship.md`·`hk-cleanup.md`

## ✅ Definition of Done

- [x] 회귀 테스트 + 기존 영향 테스트 PASS
- [x] ADR-015 작성 (type: tradeoff)
- [x] 설치본 동기화 (drift 깔끔)
- [x] walkthrough / pr_description ship commit
- [x] 사용자 검토 요청 알림

## 🔗 관련 자료
- Spec/Plan/Critique: `specs/spec-x-defaultbranch-consistency/`
- ADR: `docs/decisions/ADR-015-review-base-resolution-chain.md`
- 후속: spec-x-review-base-config
