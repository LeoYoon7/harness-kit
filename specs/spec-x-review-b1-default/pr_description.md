# refactor(spec-x-review-b1-default): hk-code-review 기본을 B1 패턴으로 업그레이드

## 📋 Summary

### 배경 및 목적

`/hk-code-review` 는 **단일 Opus 서브에이전트**가 3 렌즈로 리뷰하는 ship 게이트 기본 채널이었다. 직전 연구 `spec-x-persona-hybrid-research`(#48)가 cross-model blind 채점으로 측정한 결과, **generalist 정독 1패스가 단일 리뷰어의 깊이 갭(awk locale/byte-count, fence desync, UTF-8 절단 등 구체 버그)을 두 표본 모두에서 회복**함을 실증했다(권고 A). 본 spec 은 그 결론을 코드에 반영한다.

### 주요 변경 사항
- [x] `/hk-code-review` 기본을 **B1 패턴**으로 업그레이드 — 독립 Opus 리뷰어 N=3(self-consistency) + generalist 정독 1패스 → 디렉터 증류.
- [x] 증류 **조작적 정의** 명문화(dedup / 합의 N/k / 심각도충돌 / 이견보존) + **부분 실패 fallback** — critique 가 지적한 재현성 blocking 갭 해소.
- [x] **페르소나 패널 opt-in** 문서화(폭 지배 리뷰 한정, 미구현·수동 dispatch) — #48 의 라우팅 결론 반영.
- [x] **ADR-013/014**(invariant) 작성 — 리뷰 value 측정 전제 + 측정 독립성(cross-model) 형식화.
- [x] 독립 Opus critique 실행 → 외부 문헌 대조 후 A~F 반영, N=3 약근거 정직화.

### Phase 컨텍스트
- **Phase**: 없음 (spec-x, Solo)
- **본 SPEC 의 역할**: #48 연구 결론(권고 A)을 실 리뷰 워크플로에 반영 — "직전 spec 의 한계가 다음 spec 의 ROI" 패턴.

## 🎯 Key Review Points

1. **B1 dispatch + 결과 계약(ADR-010)**: 4 서브에이전트가 결과 계약 배열만 반환(transcript 금지), 디렉터 context 격리.
2. **증류 재현성**: dedup·합의·심각도충돌·이견보존·fallback 의 조작적 정의가 .md 지시문으로 *재현 가능*하게 적혔는지.
3. **N=3 비용 vs 근거**: 기본 4 dispatch(1→4 비용). generalist=강근거 / N=3=약근거를 정직히 표기(NFR4)했는지.
4. **ADR baseline 상대정의**: ADR-013 의 baseline 을 "직전 채택 구성"(상대적)으로 정의해 순환 회피.

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-review-b1.sh
bash tests/test-governance-dedup.sh
bash tests/test-drift-stale-adr.sh
```

**결과 요약**:
- ✅ `test-review-b1.sh`: 18/18 PASS (C1~C8 — B1 용어·페르소나 opt-in·ADR-010·미러 parity·ADR type·증류 조작적 정의·fallback). TDD: 16 FAIL(Red) → 18 PASS(Green).
- ✅ `test-governance-dedup.sh`: 8/8 PASS (거버넌스 본문 무변경, 6393w ≤ 6500w).
- ✅ `test-drift-stale-adr.sh`: clean state (새 ADR backtick 경로 유효).

### 수동 검증 시나리오
1. **미러 parity**: `diff -q sources/commands/hk-code-review.md .claude/commands/hk-code-review.md` → 차이 0 (ADR-003).
2. **skill 라이브 반영**: hk-code-review 설명이 "B1 패턴" 으로 갱신.

## 📦 Files Changed

### 🆕 New Files
- `tests/test-review-b1.sh`: B1 구조 검증 테스트(C1~C8).
- `docs/decisions/ADR-013-review-value-baseline.md`: 리뷰 value 측정 전제(invariant).
- `docs/decisions/ADR-014-review-eval-independence.md`: 측정 독립성(invariant).
- `specs/spec-x-review-b1-default/*`: spec/plan/task/critique/walkthrough/pr_description.

### 🛠 Modified Files
- `sources/commands/hk-code-review.md` (+107/-72 가량): 단일 리뷰 → B1 dispatch + 증류 + 페르소나 opt-in.
- `.claude/commands/hk-code-review.md`: 도그푸딩 미러(byte-identical).

**Total**: 9 files changed (725 insertions, 72 deletions)

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과 (test-review-b1 18/18)
- [x] 회귀 테스트 통과 (governance-dedup 8/8, stale-adr clean)
- [x] `walkthrough.md` ship commit 완료
- [x] `pr_description.md` ship commit 완료
- [x] lint (staged-lint: shellcheck 미설치 skip — non-blocking)
- [ ] 사용자 검토 요청 알림 (push 후)

## 🔗 관련 자료

- 선행 연구: `specs/spec-x-persona-hybrid-research/report.md` (#48)
- Walkthrough: `specs/spec-x-review-b1-default/walkthrough.md`
- Critique: `specs/spec-x-review-b1-default/critique.md`
- ADR: `docs/decisions/ADR-013-review-value-baseline.md`, `docs/decisions/ADR-014-review-eval-independence.md`
