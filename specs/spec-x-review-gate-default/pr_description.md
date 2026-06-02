# docs(spec-x-review-gate-default): 코드 리뷰 게이트를 기본 실행 + 감사형 skip 으로 전환

## 📋 Summary

### 배경 및 목적

ship 직전 코드 리뷰 게이트(`agent.md §6.3-8`, `hk-ship.md §1.5`)가 `(optional)` 로만 정의돼 있어 *언제 리뷰해야 하는가* 의 기준이 없었다. "사용자가 Skip 할 수 있다" 는 의미일 뿐이라 (1) 트리거 부재, (2) 마찰 비대칭(리뷰=1스텝 / Skip=즉시 push), (3) 무감사(Skip 기록 0) 로 인해 실제 운영에서 리뷰 제안 자체가 거의 발화되지 않아 게이트가 **유명무실**해졌다.

본 PR 은 게이트의 **기본값을 "리뷰 실행" 으로 뒤집고, Skip 을 한 줄 사유 기록을 동반하는 감사형(auditable) 행위로 전환**한다. 리뷰를 Skip 불가로 강제하지는 않되, 누락을 *침묵이 아닌 기록되는 의도적 결정* 으로 만들어 forcing function 을 부여한다.

### 주요 변경 사항
- [x] `agent.md §6.3-8`: "(optional)" → "(default-run, auditable skip)". 기본=실행, Skip 은 walkthrough 사유 기록 필수
- [x] `hk-ship.md §1.5`: 게이트 프레이밍 재구성 + Skip(3) 분기에 사유 기록 절차 추가 (docs-only 한 단어 허용)
- [x] `walkthrough.md` 템플릿: "🔍 코드 리뷰" 칸 신설 (수행/Skip audit surface)
- [x] `ADR-006`: 정책 결정 + 기각 대안 3종(순수 optional / 완전 강제 / 스코프 트리거) 기록

### 컨텍스트
- **타입**: spec-x (독립 스펙, Phase 비소속)
- **역할**: 리뷰 게이트의 실효성 회복 — 누락을 기록되는 결정으로 전환

## 🎯 Key Review Points

1. **설계 의도 양립**: 리뷰를 Skip 불가로 만들지 않음. `agent.md §6.3` optional gate 의도와 충돌하지 않도록 "기록 동반 Skip" 까지만 강제 (NFR1).
2. **과도한 마찰 방지**: docs/markdown-only 변경은 사유 `docs-only` 한 단어로 충분 (NFR2).
3. **변경 범위**: `sources/` 원본만. 실행 repo 의 live 거버넌스(`.harness-kit/`)는 `update.sh` 가 동기화 (ADR-003).

## 🧪 Verification

docs/거버넌스/템플릿 + ADR 변경으로 실행 가능한 동작이 없어 **단위/통합 테스트 N/A** (constitution §9.1 docs-only 정당화). 정적 grep 검증으로 대체.

```bash
grep -nE "default-run|auditable skip" sources/governance/agent.md            # FR1 → line 218 매치
grep -cE "사유" sources/commands/hk-ship.md                                   # FR2 → 5건
grep -nE "코드 리뷰" sources/templates/walkthrough.md                         # FR3 → line 63 매치
grep -nE "^type:\s*decision" docs/decisions/ADR-006-code-review-gate-default-run.md  # FR4 → line 3 매치
```

**결과 요약**: FR1~4 모두 통과.

### 코드 리뷰 게이트(본 PR 자체)
- **Skip** (사유: `docs-only`) — 리뷰 대상 코드 없음. 본 PR 이 신설한 docs-only 예외에 해당 (도그푸딩). 상세는 walkthrough 🔍 코드 리뷰 칸.

## 📦 Files Changed

### 🆕 New Files
- `docs/decisions/ADR-006-code-review-gate-default-run.md`: 정책 결정 기록 (type: decision)

### 🛠 Modified Files
- `sources/governance/agent.md` (+2, -1): §6.3-8 게이트 정책 개정
- `sources/commands/hk-ship.md` (+~10, -~7): §1.5 절차 재구성 + Skip 사유 기록
- `sources/templates/walkthrough.md` (+12): "🔍 코드 리뷰" 칸 신설
- `backlog/queue.md` (+1): spec-x 등록

**Total**: 8 files changed (spec 산출물 4 포함)

## ✅ Definition of Done

- [x] FR 1~4 모두 반영
- [x] docs-only → 단위 테스트 N/A, 정적 grep 검증 통과
- [x] `walkthrough.md` / `pr_description.md` 작성 및 ship commit
- [x] `spec-x-review-gate-default` 브랜치 push
- [x] 사용자 검토 요청 알림

## 🔗 관련 자료

- Walkthrough: `specs/spec-x-review-gate-default/walkthrough.md`
- ADR: `docs/decisions/ADR-006-code-review-gate-default-run.md`
- 관련 ADR: `docs/decisions/ADR-003-dogfood-sync-policy.md` (sources 원본만 변경 근거)
