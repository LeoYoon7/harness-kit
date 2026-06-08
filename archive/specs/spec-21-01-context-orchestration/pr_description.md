# feat(spec-21-01): establish context orchestration policy (§6.6 + ADR-010)

## 📋 Summary

### 배경 및 목적

phase-21(director-mode)의 **기반 spec**. fork 의 `agent.md §6.6` 은 모델 분배(WHO)만 규정하고 context 정책(무엇을 위임/주입/반환)은 비어 있었다. upstream 의 "메인 = context orchestrator" 전략(ADR-005)을 **fork 구조에 맞춰 재구현**해 §6.6 을 확장하고, director mode 토글과 무관하게 *항상 적용*되는 기반 정책을 확립한다.

### 주요 변경 사항
- [x] `agent.md §6.6` → `Model & Context Allocation Strategy` 로 확장: **context offloading 5축** (위임 대상 / scoped slice / distilled contract / 검증 보유 / fan-out)
- [x] always-on 명시 + director mode disambiguation (정책 on/off 가 아니라 위임 *적극성* 토글)
- [x] `ADR-010-context-orchestration` 작성 (fork 고유 결정 초점 + net-neutral convention)
- [x] net-neutral 다이어트로 단어 순증 **+48w** (±50w 목표 내, 기존 §6.6/§6.7 중복 트림)
- [x] `tests/test-context-orchestration.sh` (용어 grep + 미러 parity + ADR 존재)

### Phase 컨텍스트
- **Phase**: `phase-21` (director-mode)
- **본 SPEC 의 역할**: 후속 director mode(토글 §6.8/spec-21-03, model config/spec-21-04, 페르소나 패널/spec-21-05)의 *always-on 기반*. 이 정책 없이는 director mode 가 임의적 위임이 된다.

## 🎯 Key Review Points

1. **§6.6 5축의 fork 정합**: cherry-pick 이 아닌 재작성 — fork §6.7(workflow patterns)·ADR-007/008 과 충돌 없이 통합. 모델 표(Opus/Sonnet 하드코딩)는 불변(de-hardcode 는 spec-21-04).
2. **단어 예산 net-neutral**: 5축 추가(~95w)를 §6.6/§6.7 중복 트림으로 상쇄 → +48w. 완전 green(<6000w)은 본 spec 범위 아님(phase 성공기준 4 누적).
3. **검증 불변식 hook**: distilled contract 에 완료 상태(성공/부분/실패), 검증 실패 시 §7 Hard Stop 포인터 — 본격 불변식은 spec-21-03(§6.8).

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-context-orchestration.sh
bash tests/test-governance-dedup.sh
```

**결과 요약**:
- ✅ `test-context-orchestration.sh`: 6/6 PASS (용어 4 + 미러 parity + ADR-010)
- ✅ `test-governance-dedup.sh`: 무 NEW 회귀 (Check 3 단어 예산만 baseline red — +48w/±50w 내). Check 1(중복 0)/2(sync)/4/5/6 PASS
- ✅ Gemini cross-model 리뷰: **Approve** (Critical 0 / Major 0 / Minor 1 — ASCII 반영 완료)

### 수동 검증 시나리오
1. **§6.6 내용**: `git diff main...HEAD` → orchestrator–worker 5축 + always-on disambiguation 확인
2. **미러 parity**: `diff sources/governance/agent.md .harness-kit/agent/agent.md` → 차이 없음

## 📦 Files Changed

### 🆕 New Files
- `docs/decisions/ADR-010-context-orchestration.md`: context orchestration 결정 자산화
- `tests/test-context-orchestration.sh`: 정책 검증 (3 checks)
- `backlog/phase-21.md`: phase-21 정의
- `specs/spec-21-01-context-orchestration/*`: spec/plan/task/critique/walkthrough/pr/code-review-gemini

### 🛠 Modified Files
- `sources/governance/agent.md`: §6.6 확장 + net-neutral 다이어트
- `.harness-kit/agent/agent.md`: 미러 동기화
- `backlog/queue.md`: phase-21 active + Icebox 추가

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과 (6/6)
- [x] 거버넌스 회귀 무 NEW (단어 예산 +48w/±50w 내, before/after walkthrough 기록)
- [x] `walkthrough.md` / `pr_description.md` ship commit
- [x] 코드 리뷰 (Gemini Approve)
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Phase: `backlog/phase-21.md`
- Walkthrough: `specs/spec-21-01-context-orchestration/walkthrough.md`
- ADR: `docs/decisions/ADR-010-context-orchestration.md`
- 참조: upstream ADR-005 (context-orchestration, 번호 충돌로 참조만)
