# refactor(spec-x-fragment-two-tier-restore): slim fragment to restore two-tier loading

## 📋 Summary

### 배경 및 목적

`CLAUDE.fragment.md` (tier-1, 매 세션 상시 로딩) 에 알림 프로토콜·선택지 제시 규약·패턴이 누적되어 **3095w 로 비대화** → `test-two-tier-loading.sh` Check 4 (≤150w) 가 main 에서 상존 FAIL. 약 3000w 운영 상세가 항상 로딩되어 프로젝트 1차 원칙(컨텍스트 비용 0)을 위배. 본 PR 은 fragment 를 핵심 규칙 요약(113w)만 남기고 상세를 tier-2 로 이전해 **2단계 로딩 구조를 원 의도대로 복원**한다.

### 주요 변경 사항
- [x] `CLAUDE.fragment.md` 3095w → **113w** (핵심 규칙 요약 + tier-2 위치 포인터)
- [x] 신규 tier-2 `sources/governance/notify.md` — 선택지 제시 규약 + 의사결정 알림 프로토콜 §1~§10 + 마크다운 컨벤션 (§번호 보존, verbatim 이전)
- [x] 검증된 패턴/안티패턴 → `sources/governance/align.md` 로 이전
- [x] `hk-align.md` 로더에 `@.harness-kit/agent/notify.md` import 추가
- [x] `test-two-tier-loading.sh` 에 이전 검증 단언 3개 추가 (notify.md 존재/import/fragment 비보유)
- [x] 도그푸딩 설치본 4종 동기화

### Phase 컨텍스트
- **Phase**: 없음 (spec-x, Phase 비소속)
- **본 SPEC 의 역할**: main 상존 테스트 실패 해소 + 거버넌스 로딩 구조 복원

## 🎯 Key Review Points

1. **Verbatim relocation**: 내용 재작성 없이 *위치만* 이동 (fragment line 31~EOF → notify.md, line 19~27 → align.md). 완전성은 grep 으로 검증.
2. **§번호 보존**: notify.md 가 알림 §1~§10 번호를 유지 → `agent.md` 의 "§5/§9 알림" 참조 무손상 (agent.md/constitution.md 미수정).
3. **tier-2 자동 install**: `notify.md` 는 governance glob(`install.sh`) 으로 자동 복사 — 하드코딩 목록 수정 불요.

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-two-tier-loading.sh    # ALL 10 PASSED (fragment 113w)
bash tests/test-governance-dedup.sh    # ALL 8 PASSED (sources↔설치본 sync)
```

**결과 요약**:
- ✅ `test-two-tier-loading`: 10/10 (Check 4 PASS)
- ✅ `test-governance-dedup`: 8/8
- ✅ 영향 회귀: install-manifest-sync / claude-import / install-layout / context-orchestration / director-protocol / role-model / sdd-config / queue-redesign / export-format / drift-stale-adr 전부 PASS

> 사전 존재 실패 2건(`test-sdd-drift` T1, `test-phase17-integration` 4c)은 본 PR 무관 — `git diff main...HEAD` 에 해당 코드/테스트 미포함 (walkthrough 참조).

### 수동 검증 시나리오
1. `wc -w` fragment → 113 (≤150)
2. relocation 완전성 grep → notify.md 전 구간 존재, fragment 누수 0
3. `diff -q` sources↔설치본 4쌍 → 전부 일치

## 📦 Files Changed

### 🆕 New Files
- `sources/governance/notify.md`: 선택지 제시 규약 + 알림 프로토콜 §1~§10 + 마크다운 컨벤션 (tier-2)
- `.harness-kit/agent/notify.md`: 설치본 동기화

### 🛠 Modified Files
- `sources/claude-fragments/CLAUDE.fragment.md`: 3095w → 113w (요약 + 포인터)
- `sources/governance/align.md`: 검증된 패턴/안티패턴 추가
- `sources/commands/hk-align.md`: notify.md import 추가
- `tests/test-two-tier-loading.sh`: 이전 검증 단언 3개 추가
- `.harness-kit/CLAUDE.fragment.md` · `.harness-kit/agent/align.md` · `.claude/commands/hk-align.md`: 설치본 동기화

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과 (two-tier 10/10, dedup 8/8)
- [x] `walkthrough.md` / `pr_description.md` ship commit
- [x] 코드 리뷰 게이트 (Skip — 사유 기록)
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Spec: `specs/spec-x-fragment-two-tier-restore/spec.md`
- Plan: `specs/spec-x-fragment-two-tier-restore/plan.md`
- Walkthrough: `specs/spec-x-fragment-two-tier-restore/walkthrough.md`
