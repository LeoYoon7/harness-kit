# Walkthrough: spec-x-gemini-review-sandbox

> 작업 기록 — gemini-review.sh 워크스페이스 변조 방어.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 방어 방식 | `--sandbox`/`--worktree` 강제 / 감지+거부 | **감지+거부** | `--approval-mode plan` read-only 보장 불가 실증. sandbox 는 portability(docker/sandbox-exec) 리스크 — 감지는 portable·testable |
| 자동 원복 | 항상 / clean-pre 가드 | **clean-pre 가드 한정** | `reset --hard`/`clean -fd` 가 사용자 미커밋 작업 파괴 위험 → 사전 clean 일 때만 |
| 원격(push/PR) | 자동 원복 시도 / 경고 | **경고만** | push/PR 자동 원복 위험·불가. 사용자 처리 |
| 출력 검증 | 비검증 / 형식 grep | **형식 grep** (`# Code Review`/`## 요약`) | 21-04 비-리뷰(구현 요약) 오저장 방지 |
| spec-x base | phase base / main | **main (사전 분기)** | spec-x 는 main 타깃. phase-21 baseBranch 누수 회피 위해 main 에서 사전 분기 + PR `--base main` 명시 |
| ship 리뷰 | Gemini / Opus | **Opus** | gemini 가 본 spec 의 *수정 대상* — 자기 리뷰는 순환·위험 |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — 도구 하드닝(fix). "외부 리뷰 도구는 read-only 신뢰 말고 부수효과 감지·거부" 원칙은 동일 패턴 누적 시 RCA 로 자산화.

## 💬 사용자 협의

- **주제**: 작업 선택 (post spec-21-04) — **합의**: 1번 (gemini-review.sh 안전 결함 먼저 수정, spec-x).
- **주제**: Plan Accept — **합의**: Plan Accept (1).
- **주제**: Ship 코드 리뷰 — **합의**: Opus (gemini 제외).
- **주제**: 리뷰 권고 처리 — **합의**: 1번 (Minor-4 T5 + Minor-3 주석, Minor-1/2 skip).

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: `bash tests/test-gemini-review-guard.sh`
- **결과**: ✅ Passed (PASS=12 FAIL=0)
- **로그 요약**:
```text
T1 rogue commit → 거부+HEAD 원복+리뷰파일 부재
T2 rogue 파일쓰기 → 거부 · T3 비-리뷰 → 거부 · T4 정상 → 성공
T5 dirty 사전 → 자동원복 생략 + 사용자 미커밋 보존 (Minor-4)
결과: PASS=12 FAIL=0
```

### 2. 수동 검증

1. **Action**: stub gemini(STUB_MODE=rogue_commit) — **Result**: 스크립트가 HEAD 이동 감지 → clean-pre 자동 원복 → exit 1, 리뷰 파일 미생성.
2. **Action**: stub gemini(valid) — **Result**: 부수효과 없음 + 리뷰 형식 → code-review-gemini.md 생성, exit 0.
3. **Action**: `diff -q sources/bin/gemini-review.sh .harness-kit/bin/gemini-review.sh` — **Result**: 차이 없음(parity).

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Opus same-model — gemini 는 수정 대상이라 제외) |
| **결과 파일** | `specs/spec-x-gemini-review-sandbox/code-review.md` |
| **요약** | **Approve** / Critical 0 / Major 0 / Minor 4 |
| **Minor 처리** | Minor-4(dirty 분기 테스트)·Minor-3(ignored-write 한계 주석) → **반영**. Minor-1(형식 grep 주석)·Minor-2(status 실패=clean 구별) → **선택, skip**(reviewer 범위밖/선택 표기) |

## 🔍 발견 사항

- **gemini `--approval-mode plan` 은 read-only 를 강제하지 못한다**(gemini CLI 결함/버전). `gemini --help` 상 plan="read-only mode" 명세이나 headless `-p` 에서 도구 실행이 일어남. 따라서 *호출 래퍼가 방어*해야 한다.
- **컨테인먼트 플래그 존재** (`-s/--sandbox`, `-w/--worktree`)하나 portability·push 미차단 한계로 정본 방어로 부적합 — 감지+거부 채택.
- **spec-x ↔ phase-base 마찰**: `specx new` 가 phase 의 `baseBranch` 를 비우지 않아 spec-x 로 누수. 본 작업은 main 사전 분기 + PR `--base main` 으로 우회. → Icebox 후보(sdd 개선).

## 🚧 이월 항목

- **spec-x 중 phase baseBranch 누수** → `backlog/queue.md` Icebox (sdd `specx new` 가 spec-x active 시 baseBranch 무시/null 처리 개선).
- **gemini-review.sh 엣지케이스 2종**(21-01 발견, Icebox 기존) — first-spec base fallback + 비-ASCII argv. 본 spec 범위 밖.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent(Opus orchestrator) + Opus reviewer + Leo |
| **작성 기간** | 2026-06-05 |
| **최종 commit** | `ccd332c` (ship commit 직전) |
