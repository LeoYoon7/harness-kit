# fix(spec-x-adr-template-stale-note): plain-text path example in adr template note

Fixes #55

## 📋 Summary

### 배경 및 목적

ADR 템플릿(`sources/templates/adr.md`) note 의 예시 경로 `` `src/foo.ts` `` (inline backtick) 가 stale-ADR 검사 휴리스틱(`_drift_stale_adr`)의 검사 대상 패턴(backtick + 슬래시 + 확장자)을 충족하면서 실존하지 않아, 이 note 를 복사한 모든 다운스트림 ADR 이 영구 stale(false-positive)로 보고되던 문제(이슈 #55)를 해결합니다.

### 주요 변경 사항
- [x] 템플릿 note 예시를 **backtick 없는 평문**으로 변경 → 휴리스틱 추출 대상에서 제외 (휴리스틱은 backtick 토큰만 추출)
- [x] note 에 `../` 상대경로 제외 규칙 명시 (휴리스틱 규칙 4 와 정합, 작성자 가이드 보강)
- [x] 휴리스틱(`_drift_stale_adr`) **무변경** — 템플릿 content fix 로 충분
- [x] dogfood 사본(`.harness-kit/agent/templates/adr.md`) 동기
- [x] 회귀 테스트 Step 7 추가 — 라이브 템플릿 note 를 fixture ADR 에 삽입해 stale 미보고 단언 (미래 트리거 예시 재도입 차단)

### Phase 컨텍스트
- **Phase**: 없음 (spec-x — Solo Spec)
- **역할**: ADR 템플릿의 stale-ADR 자가-트리거 결함 제거

## 🎯 Key Review Points

1. **fix 방식 (이슈 후보 ① 평문 표기)**: 후보 ② (`../` prefix) 는 "이 예시는 검사 대상"이라는 note 설명과 자기모순(`../` 는 제외 대상), 후보 ③ (휴리스틱 변경) 은 회귀 리스크 → ① 채택. `_drift_stale_adr` 무손.
2. **회귀 테스트 (`tests/test-drift-stale-adr.sh` Step 7)**: 하드코딩이 아니라 `grep '^>' sources/templates/adr.md` 로 라이브 note 를 추출해 fixture ADR 에 삽입 → 템플릿이 미래에 다시 트리거 예시를 도입하면 실패.

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-drift-stale-adr.sh   # 7/7 PASS (EXITCODE=0)
```

**결과 요약**:
- ✅ TDD Red (fix 전, `648e243`): Step 1~6 ✓ / Step 7 ✗ — `stale ADR: 1 — ADR-994-template-note-fixture.md`
- ✅ TDD Green (fix 후, `b070e2a`): Step 1~7 ✓ "All tests passed."
- ✅ 정적 검증: fixed note 에 휴리스틱 트리거 토큰 0개
- ✅ 회귀: `test-install-manifest-sync`, `test-wiki-structure` Pass
- ⚠ `test-two-tier-loading` Check 4 FAIL (fragment 3095w > 150w) — **본 PR 무관·main 기존 실패** (diff 에 `CLAUDE.fragment.md` 없음). Icebox 등록

### 수동 검증 시나리오
1. `grep '^>' sources/templates/adr.md` (fix 후) → `src/foo.ts` 평문 표기, backtick 경로 토큰 없음
2. `diff sources/templates/adr.md .harness-kit/agent/templates/adr.md` → 동일 (dogfood sync)

## 📦 Files Changed

### 🛠 Modified Files
- `sources/templates/adr.md` (+2, -2): note 예시 평문화 + `../` 제외 규칙
- `.harness-kit/agent/templates/adr.md` (+2, -2): dogfood sync
- `tests/test-drift-stale-adr.sh` (+33): Step 7 (라이브 note 자가-트리거 회귀)
- `backlog/queue.md` (+2): Icebox 2건 (monorepo sibling stale-ADR / two-tier fragment 초과)

### 🆕 New Files
- `specs/spec-x-adr-template-stale-note/` — spec/plan/task/walkthrough/pr_description

**Total**: 9 files changed

## ✅ Definition of Done

- [x] `tests/test-drift-stale-adr.sh` 전체 PASS (Step 7 포함)
- [x] `walkthrough.md` / `pr_description.md` ship commit
- [x] 코드 리뷰 게이트 (walkthrough 기록)
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Issue: #55
- Walkthrough: `specs/spec-x-adr-template-stale-note/walkthrough.md`
- 연관 Icebox: monorepo sibling 레포 stale-ADR false-positive / two-tier fragment 단어수 초과
