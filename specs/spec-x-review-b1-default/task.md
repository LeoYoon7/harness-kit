# Task List: spec-x-review-b1-default

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 phase.md 표 미해당(queue.md done 은 ship 시 `sdd specx done`)
- [x] 사용자 Plan Accept

---

## Task 1: 구조 검증 테스트 작성 (TDD Red)

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-review-b1-default`
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. 테스트 작성 (TDD Red)
- [x] `tests/test-review-b1.sh` 작성 — grep 기반 구조 검증 (C1~C8, `test-director-protocol.sh` 패턴 차용)
  - C1: `hk-code-review.md` B1 용어 (self-consistency / generalist 정독 / 결과 계약 / 증류)
  - C2: 페르소나 opt-in 섹션 (폭 지배 / opt-in / 미구현)
  - C3: ADR-010 참조 (결과 계약 only 근거)
  - C4: 미러 parity (`sources/commands/hk-code-review.md` == `.claude/commands/hk-code-review.md`)
  - C5: `ADR-013-review-value-baseline.md` 존재 + `type: invariant`
  - C6: `ADR-014-review-eval-independence.md` 존재 + `type: invariant`
  - C7: 증류 조작적 정의 용어 (dedup / 합의 / 심각도) — 재현성 blocking enforcement
  - C8: fallback 용어 (부분 / 미반환 또는 fallback)
- [x] `bash tests/test-review-b1.sh` → **Fail 확인** (16 FAIL — C4·C7심각도만 PASS)
- [x] Commit: `test(spec-x-review-b1-default): add failing structural test for B1 review`

---

## Task 2: ADR 2종 작성 (불변식 형식화 → C5/C6 Green)

### 2-1. ADR 작성
- [x] `docs/decisions/ADR-013-review-value-baseline.md` — type: `invariant`, status: accepted. 다관점 리뷰 도입 = baseline(직전 채택 구성, 상대정의) 대비 value 측정을 Go 전제로. #48 사례.
- [x] `docs/decisions/ADR-014-review-eval-independence.md` — type: `invariant`, status: accepted. 리뷰 value 측정 채점자/GT 는 피측정 모델과 독립(cross-model/사람 blind) + 동일모델 self-consistency 비독립 포섭. #48 Gemini blind 사례.
- [x] `bash tests/test-review-b1.sh` → **C5/C6 PASS** (C1~C4·C7·C8 아직 Fail) + stale-ADR clean 확인
- [x] Commit: `docs(spec-x-review-b1-default): add ADR-013/014 for review value baseline + eval independence`

---

## Task 3: hk-code-review B1 업그레이드 + 미러 + 페르소나 opt-in (→ C1~C4 Green)

### 3-1. 커맨드 + 미러 동시 수정 (도그푸딩 sync — 같은 commit)
- [ ] `sources/commands/hk-code-review.md` — "독립 리뷰 수행" 을 B1 dispatch(Opus×3 self-consistency + generalist 정독)로 교체. 결과 계약(ADR-010, source enum) + **증류 조작적 정의**(dedup/합의(N/k)/심각도충돌/이견보존) + **부분실패 fallback** + 요약(합의 분포·미반환 워커) + 페르소나 opt-in 섹션 추가.
- [ ] `.claude/commands/hk-code-review.md` — 위와 **byte-identical** 동기화.
- [ ] `bash tests/test-review-b1.sh` → **전 항목 PASS** (C1~C6)
- [ ] `bash tests/test-governance-dedup.sh` → PASS (회귀 없음)
- [ ] Commit: `refactor(spec-x-review-b1-default): upgrade hk-code-review to B1 + persona opt-in doc`

---

## Task 4: Ship (필수)

- [ ] 전체 관련 테스트 실행 → PASS (`test-review-b1.sh`, `test-governance-dedup.sh`, `test-drift-stale-adr.sh` — ADR 추가 회귀 확인)
- [ ] 코드 리뷰 게이트 (§6.3): 본 spec 으로 업그레이드되는 `/hk-code-review` 적용 가능 — 단 docs/마크다운 변경이라 Skip + walkthrough 사유 기록 허용
- [ ] **walkthrough.md 작성** (증거 로그)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] **Ship Commit**: `docs(spec-x-review-b1-default): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-review-b1-default`
- [ ] **PR 생성**: `/hk-pr-gh` (PR base = fork main, 사용자 승인 후)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고
- [ ] (머지 후) `sdd specx done review-b1-default`

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 4 |
| **예상 commit 수** | 4 (test 1 + docs 1 + refactor 1 + ship 1) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-09 |
