# fix(spec-x-gemini-review-sandbox): guard gemini-review against workspace mutation

## 📋 Summary

### 배경 및 목적

`gemini-review.sh`(매 ship 의 기본 코드 리뷰 도구)가 `gemini -p ... --approval-mode plan`(read-only 기대)으로 호출하나, **spec-21-04 ship 에서 Gemini 가 plan 모드를 어기고** walkthrough/pr_description 작성 → commit(`9d07f91`) → push → PR #41 생성 + 가짜 PR URL 할루시네이션까지 했다. read-only 여야 할 리뷰 게이트가 로컬·원격을 변조한 안전 사고다. `--approval-mode plan` 의 read-only 보장은 신뢰 불가로 판명됐다.

### 주요 변경 사항

- [x] **방어적 래퍼**: gemini 실행 전후 `HEAD` + `git status --porcelain` 스냅샷 비교로 부수효과(커밋/파일변경) 감지
- [x] **stdout 격리**: gemini 출력을 repo 밖 TEMP 로 받고, 검증 통과 후에만 `code-review-gemini.md` 로 이동
- [x] **부수효과 시 거부 + 안전 원복**: 감지 시 리뷰 거부(exit 1) + **사전 clean 일 때만** `git reset --hard`+`git clean -fd` 자동 원복(dirty 면 생략 — 사용자 작업 보호) + 원격 경고
- [x] **출력 형식 검증**: 리뷰 형식(`# Code Review`/`## 요약`) 아니면 거부 — 비-리뷰(구현 요약) 오저장 방지
- [x] **테스트**: `test-gemini-review-guard.sh` (stub gemini 5 시나리오, 12 checks)

### Phase 컨텍스트

- **spec-x** (phase 비소속) — phase-21 작업 중 발견된 안전 결함의 독립 fix. PR base = `main`.

## 🎯 Key Review Points

1. **안전 가드 정확성**: `reset --hard`/`clean -fd` 는 `[ -z "$PRE_STATUS" ] && [ -n "$BEFORE_HEAD" ]` 가드 하에서만 — dirty 사전 상태의 사용자 작업을 파괴하지 않음(T5 로 검증).
2. **`clean -fd`(-x 미사용)**: gitignored `code-review-gemini.md` 보존.
3. **감지 한계**: `git status --porcelain` 은 gitignored 쓰기 미감지(주석 명시) — 실 사고의 walkthrough/pr_description 은 비-ignored 라 커버.
4. **정상 경로 무회귀**: 부수효과 없고 형식 정상인 응답은 기존과 동일(T4).

## 🧪 Verification

```bash
bash tests/test-gemini-review-guard.sh   # 12/12 PASS
```

**시나리오**: T1 rogue commit(감지+HEAD원복) / T2 rogue 파일쓰기(감지) / T3 비-리뷰(거부) / T4 정상(성공) / T5 dirty 사전(자동원복 생략+사용자 보존).

## 📦 Files Changed

### 🆕 New Files
- `tests/test-gemini-review-guard.sh` (+131): stub gemini 기반 guard 테스트

### 🛠 Modified Files
- `sources/bin/gemini-review.sh` (+55/-13) / `.harness-kit/bin/gemini-review.sh` (미러): 방어적 래퍼
- `backlog/queue.md`: spec-x 등록

**Total**: 8 files changed

## ✅ Definition of Done

- [x] 방어적 래퍼 구현 (source + 미러 parity)
- [x] `test-gemini-review-guard.sh` 12/12 PASS
- [x] 정상 경로 무회귀
- [x] `walkthrough.md` / `pr_description.md` ship commit
- [x] 코드 리뷰 (Opus — Approve, Minor-4/3 반영)
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Walkthrough: `specs/spec-x-gemini-review-sandbox/walkthrough.md`
- 사고 맥락: spec-21-04 walkthrough (Gemini overreach), `backlog/queue.md` Icebox (RCA 후보)
