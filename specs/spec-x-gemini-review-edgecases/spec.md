# spec-x-gemini-review-edgecases: gemini-review.sh 엣지케이스 2종 수정

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-gemini-review-edgecases` |
| **Phase** | `phase-x` (spec-x — 비소속) |
| **Branch** | `spec-x-gemini-review-edgecases` |
| **상태** | Planning |
| **타입** | Fix |
| **Integration Test Required** | no |
| **작성일** | 2026-06-09 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

`sources/bin/gemini-review.sh` (+ `.harness-kit/bin/` 미러)는 ship 코드 리뷰 게이트의 cross-model 도구다 (`/hk-gemini-review`). 직전 `spec-x-gemini-review-sandbox` 가 read-only 위반(워크스페이스 변조) 방어 래퍼를 추가해 *안전성* 결함은 닫았다. 그러나 별개의 *동작* 결함 2종이 spec-21-01 에서 발견된 채 Icebox 에 미해결로 남아 있다.

### 문제점

**(a) base-branch phase 의 첫 spec — 빈 diff 로 리뷰 불가**
스크립트는 `BASE_BRANCH=$(... .baseBranch // "main")` 로 base 를 정하고 `git diff "${BASE_BRANCH}...HEAD"` 로 변경을 수집한다 (line 65, 71). base-branch 모드 phase 는 base 브랜치(`phase-{N}-{slug}`)를 *첫 spec 의 hk-ship 시점에 just-in-time 생성*한다 (constitution §3.1). 따라서 **첫 spec 작업 중에는 base 브랜치가 아직 없다** → `git diff phase-N-...HEAD` 가 ref 부재로 실패(stderr 억제됨) → `DIFF_STAT` 빈 값 → "리뷰할 변경이 없습니다" 로 *오진단* 하고 종료한다. spec-21-01 작업은 `main` 대상 수동 우회로 진행했다.

**(b) 비-ASCII argv 손상 — Windows git-bash CP949**
한국어 지시문 `INSTRUCTION` 이 `gemini -p "$INSTRUCTION"` 의 **argv** 로 전달된다 (line 94, 106). Windows git-bash 는 네이티브 프로그램 argv 를 코드페이지(CP949)로 재인코딩하므로 비-ASCII 가 손상된다 (입력 *본문* 은 이미 stdin 파일로 우회됨 — 지시문만 미해결). 손상된 지시문은 리뷰 품질을 떨어뜨리거나 형식 이탈을 유발할 수 있다.

**(c) housekeeping — stale Icebox 라인**
조사 중 발견: Icebox 의 `gemini-review.sh plan-mode 위반 (심각)` 라인은 이미 `spec-x-gemini-review-sandbox`(2026-06-05 머지)로 *해결*됐으나 완료 표기 없이 남아 있다. 본 작업과 같은 영역이므로 함께 정리한다.

### 해결 방안 (요약)

(a) base 브랜치가 실재하지 않으면 `main` 으로 fallback 한다. (b) 한국어 지시문을 argv 가 아닌 **stdin 입력 본문 최상단**으로 옮기고 `-p` 에는 짧은 ASCII 영어 프롬프트만 전달한다. (c) queue.md Icebox 의 해결/완료 라인을 정리한다.

## 📊 개념도

```text
BASE 결정: baseBranch(state.json) // "main"
   │
   ├─ (a) base 브랜치 실재? ──no──▶ ⚠ main 으로 fallback (≠main 일 때)
   │                          yes─▶ 그대로 사용
   │
입력 본문(stdin file) = [한국어 지시문] + Spec + Diff      ← (b) 지시문을 argv→stdin 이동
   │
gemini -p "<ASCII 영어 포인터>" --approval-mode plan < INPUT  ← argv 는 순수 ASCII
   │
(sandbox 가드: 부수효과 감지/거부 + 형식 검증)  ▶ code-review-gemini.md
```

## 🎯 요구사항

### Functional Requirements

1. **base fallback**: `BASE_BRANCH` 가 git commit-ish 로 실재하지 않으면 (그리고 `main` 이 아니면) `main` 으로 fallback 하고 ⚠ 안내를 stderr 로 출력한다. base 가 실재하면 기존 동작 무변경.
2. **argv ASCII 안전**: `gemini` 호출의 argv 에는 비-ASCII 문자가 포함되지 않는다. 한국어 리뷰 지시문은 stdin 입력 본문 최상단으로 전달한다. `-p` 는 ASCII 영어 프롬프트(stdin 상단 지시문을 따르라는 포인터).
3. **이중 미러**: `sources/bin/gemini-review.sh` ↔ `.harness-kit/bin/gemini-review.sh` 바이트 동일.
4. **Icebox 정리**: queue.md 의 (i) 해결된 `plan-mode 위반` 라인, (ii) 본 spec 이 닫는 `엣지케이스 2종` 라인을 완료/해결 표기.

### Non-Functional Requirements

1. **정상 경로 무회귀**: base 실재 + ASCII 환경에서 기존과 동일하게 `code-review-gemini.md` 생성. 직전 sandbox 가드(부수효과 감지/거부, 형식 검증)는 그대로 유지.
2. **bash 3.2 호환**: `declare -A`/`mapfile`/`**`/`${,,}` 미사용.
3. **리뷰 의미 보존**: 지시문 위치 변경 후에도 리뷰 출력 형식(`# Code Review`/`## 요약` 등)이 유지되도록 영어 `-p` 가 stdin 지시문을 명시적으로 가리킨다.

## 🚫 Out of Scope

- **gemini CLI 자체 수정** — upstream 결함은 통제 밖. 호출 래퍼만 방어.
- **sandbox 가드 재설계** — `spec-x-gemini-review-sandbox` 에서 완료. 본 spec 은 그 위에 동작 결함만 보강.
- **`--sandbox`/`--worktree` 컨테인먼트** — sandbox spec 에서 의도적 미채택 결정(portability). 변경 없음.
- **`/hk-code-review`(Opus) 경로** — 외부 CLI 무관. 변경 없음.

## 📑 ADR 후보 (Architecture Decision Records)

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — 도구 하드닝(fix). "외부 CLI 호출 시 비-ASCII 는 argv 아닌 stdin/파일로 전달" 원칙은 메모리 `gitbash-nonascii-argv-codepage` 에 이미 자산화됨. 동일 패턴 누적 시 invariant 노트/RCA 로 승격 가능하나 본 spec 범위 밖.

## ✅ Definition of Done

- [ ] 모든 단위 테스트 PASS (`tests/test-gemini-review-guard.sh` — 기존 12 + 신규 2)
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-gemini-review-edgecases` 브랜치 push 완료 (PR base=main)
- [ ] 사용자 검토 요청 알림 완료
