# fix(spec-x-review-base-config): make review gate base branch configurable

## 📋 Summary

### 배경 및 목적

코드 리뷰 게이트 2종 (`gemini-review.sh`, `/hk-code-review`) 이 리뷰 diff 의 base 를 **리터럴 `main` 으로 하드코딩**하고 있어, 통합 base 가 `main` 이 아닌 install 대상 (예: `develop` 통합 후 주기 승격 — nextmarket 라이브 실증, 2026-06-12) 에서 `main...HEAD` diff 가 미승격 백로그 전체를 끌어와 리뷰 입력이 오염되는 문제를 해결합니다.

`installed.json` 에 `defaultBranch` 키를 도입하고 (부재 시 `main` — 기존 동작 100% 보존), base 해석 체인을 `phase baseBranch → defaultBranch → main` 으로 교체했습니다.

### 주요 변경 사항
- [x] `sdd config default-branch [<branch>]` — 조회/설정 (형식 검증 거부 + 부재 브랜치 경고)
- [x] `sdd status --json` 에 `defaultBranch` 동봉 — LLM 절차 (hk-code-review) 가 jq 한 번으로 base 결정 (단일 소스)
- [x] `sdd doctor` 에 defaultBranch 한 줄 노출 (진단 가시성)
- [x] `gemini-review.sh` base 해석 체인 + 2단 fallback 종착 (defaultBranch 부재 시 리터럴 main, 무한 체인 없음)
- [x] `hk-code-review.md` 하드코딩 3곳 → `${REVIEW_BASE}`, `hk-gemini-review.md` base 서술 갱신
- [x] 도그푸딩 동기 (`.harness-kit/bin/*`, `.claude/commands/*`)

### Phase 컨텍스트
- **Phase**: 없음 (spec-x — Solo Spec)
- **본 SPEC 의 역할**: 리뷰 게이트의 "통합 base = main" 하드코딩 제거. 멀티레포 리뷰 / sdd 내부 fallback / PR base 정책은 Out of Scope → Icebox 4건 등록

## 🎯 Key Review Points

1. **base 해석 체인 (`sources/bin/gemini-review.sh:64-92`)**: phase baseBranch → defaultBranch → 리터럴 main 의 2단 fallback 종착. ref 부재 단계별 경고 메시지와 무한 체인 차단 로직.
2. **status --json 스키마 추가 (`sources/bin/sdd` cmd_status)**: `state_dump | jq '. + {defaultBranch: ...}'` — additive 필드라 기존 파서 영향 없음. state 부재 fallback JSON 에도 포함.
3. **기존 동작 보존**: `defaultBranch` 미설정 시 모든 경로가 종전과 동일 (T1~T7 회귀 + 신규 T9 종착 가드).

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-sdd-config.sh          # 14/14 PASS (T7~T10 신규)
bash tests/test-gemini-review-guard.sh # 20/20 PASS (T8/T9 신규)
bash tests/test-sdd-base-branch.sh     # 4/4
bash tests/test-review-b1.sh           # 18/18
bash tests/test-install-manifest-sync.sh # 6/6
bash tests/test-hk-doctor.sh           # 7/7 checks
```

**결과 요약**:
- ✅ `test-sdd-config` T7~T10: 미설정 조회 main / 설정 + 부재 경고 / 형식 위반 거부 / status --json 노출
- ✅ `test-gemini-review-guard` T8: `defaultBranch=develop` → `Diff (develop...HEAD)` 반영
- ✅ `test-gemini-review-guard` T9: `defaultBranch=no-such-branch` → main 종착 fallback 으로 정상 진행
- ✅ TDD Red 증거: T7~T10 사전 FAIL=6 (`9e0ecde`), T8 사전 FAIL=1 (`c7e3c58`)

### 수동 검증 시나리오
1. **미설정 조회**: `sdd config default-branch` → `defaultBranch: main`
2. **부재 브랜치 설정**: `develop` (로컬 부재) → ⚠ 경고 + 설정 진행, 조회 일치
3. **형식 위반**: `"bad name"` → ✗ 거부 (exit 1)
4. **doctor**: `✅ defaultBranch: main (리뷰 diff 기준 — sdd config default-branch)` 표기
5. **도그푸딩 라이브**: 본 PR 의 Gemini 리뷰 자체가 새 체인으로 실행 (`base=main` 해석) → Approve

## 📦 Files Changed

### 🛠 Modified Files
- `sources/bin/sdd` (+43, -7): `_config_default_branch()` + cmd_config 분기 + usage + status --json 동봉 + doctor 노출
- `sources/bin/gemini-review.sh` (+21, -9): base 해석 체인 + 2단 fallback 종착
- `sources/commands/hk-code-review.md` (+11, -3): `${REVIEW_BASE}` 단일 소스 결정 절차
- `sources/commands/hk-gemini-review.md` (+2, -2): base 서술 새 체인 반영
- `.harness-kit/bin/sdd`, `.harness-kit/bin/gemini-review.sh`, `.claude/commands/hk-code-review.md`, `.claude/commands/hk-gemini-review.md`: 도그푸딩 동기 (sources 와 동일)
- `tests/test-sdd-config.sh` (+92): T7~T10
- `tests/test-gemini-review-guard.sh` (+35): T8/T9
- `backlog/queue.md` (+5): Icebox 4건 (멀티레포 리뷰 / sdd 내부 fallback + deferred ADR / hk-ship PR_BASE / hk-cleanup 검사)

### 🆕 New Files
- `specs/spec-x-review-base-config/` — spec/plan/task/critique/walkthrough/pr_description

**Total**: 13 files changed

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과
- [x] `walkthrough.md` ship commit 완료
- [x] `pr_description.md` ship commit 완료
- [x] 코드 리뷰 게이트: Gemini cross-model **Approve** (Critical 0 / Major 0 / Minor 2 — 관찰성 코멘트, walkthrough 에 처리 기록)
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Walkthrough: `specs/spec-x-review-base-config/walkthrough.md`
- Critique: `specs/spec-x-review-base-config/critique.md` (Opus 독립 비평 — 대안 C 채택, 7건 반영)
- 관련 Icebox: `backlog/queue.md` — deferred ADR `review-base-resolution-chain` (type: tradeoff)
