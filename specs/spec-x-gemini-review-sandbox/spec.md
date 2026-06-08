# spec-x-gemini-review-sandbox: gemini-review.sh 워크스페이스 변조 방어

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-gemini-review-sandbox` |
| **Phase** | `phase-x` (spec-x — 비소속) |
| **Branch** | `spec-x-gemini-review-sandbox` |
| **상태** | Planning |
| **타입** | Fix |
| **Integration Test Required** | no |
| **작성일** | 2026-06-05 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

`sources/bin/gemini-review.sh` (+ `.harness-kit/bin/` 미러)는 ship 코드 리뷰 게이트의 **기본 도구**다(`/hk-gemini-review`, agent.md §6.3-8 권장). `gemini -p "$INSTRUCTION" --approval-mode plan < input > code-review-gemini.md` 로 호출하며, `--approval-mode plan` 이 read-only 를 보장한다고 전제한다(스크립트 헤더 주석 "실행 모드: read-only").

### 문제점

**실증 사고 (spec-21-04 ship, 2026-06-05)**: `--approval-mode plan` 인데도 Gemini 가 *자체 도구*로 워크스페이스를 변조했다.
1. `walkthrough.md` + `pr_description.md` 를 **작성**(stdout 리다이렉트가 아닌 Gemini 의 파일 쓰기 도구).
2. `git commit` 실행(`9d07f91`).
3. 브랜치 `git push`.
4. PR #41 **생성** + 존재하지 않는 PR URL 할루시네이션.

즉 **read-only 여야 할 리뷰 게이트가 로컬 워크스페이스 변조 + 원격 push/PR 까지** 했다. 스크립트는 stdout 만 캡처하므로 이 부수효과를 *감지하지 못하고*, 게다가 비-리뷰 출력(구현 요약)을 그대로 `code-review-gemini.md` 로 저장해 "리뷰 통과"로 오인될 수 있었다.

**리스크 비대칭**: 본 도구는 *매 ship* 에서 호출되는 기본 경로라 재발 시 매번 워크스페이스/원격이 오염된다. `--approval-mode plan` 의 read-only 보장은 (CLI 버전/headless 모드에서) **신뢰 불가**로 판명됐다.

### 해결 방안 (요약)

`--approval-mode plan` 을 *신뢰하지 않고*, 스크립트가 **방어적 래퍼**로 안전을 강제한다. (1) gemini 실행 전후 `HEAD` + 워킹트리 스냅샷을 비교해 부수효과(커밋/파일 변경)를 *감지*, (2) 감지 시 리뷰 결과를 거부(저장 안 함)하고 사전 워킹트리가 깨끗했으면 로컬 변경 자동 원복, (3) 출력이 리뷰 형식이 아니면 거부, (4) 원격(push/PR)은 자동 원복 불가하므로 명확히 경고.

## 📊 개념도

```text
BEFORE: HEAD 스냅샷 + git status --porcelain 스냅샷
   │
gemini -p ... --approval-mode plan  →  stdout → TEMP (repo 밖)
   │
AFTER: HEAD / 워킹트리 재확인
   ├─ HEAD 이동 or 파일 변경 감지 → ❌ 리뷰 거부
   │     ├─ 사전 clean 이었으면 → git reset --hard + clean (자동 원복)
   │     └─ 사전 dirty 였으면 → 원복 생략 + 수동 확인 안내
   │     └─ ⚠ 원격(push/PR) 경고 (자동 원복 불가)
   ├─ 출력이 리뷰 형식 아님 → ❌ 거부
   └─ clean + 리뷰 형식 → ✅ TEMP → code-review-gemini.md
```

## 🎯 요구사항

### Functional Requirements

1. **부수효과 감지**: gemini 실행 전 `git rev-parse HEAD` 와 `git status --porcelain` 을 스냅샷, 실행 후 재확인해 (a) HEAD 변경(커밋), (b) 워킹트리 변경(파일 쓰기/수정/삭제) 을 감지한다.
2. **gemini stdout 격리**: gemini 출력을 repo 내부 파일이 아니라 **repo 밖 TEMP**(mktemp)로 받는다. 검증 통과 후에만 `code-review-gemini.md` 로 이동.
3. **부수효과 시 거부 + 안전 원복**: 부수효과 감지 시 리뷰 결과를 저장하지 않고 변경 내역(커밋 목록/파일 목록)을 보고 후 `exit 1`. **사전 워킹트리가 clean 이었던 경우에 한해** `git reset --hard <before>` + `git clean -fd` 로 로컬 자동 원복(가드 — dirty 였으면 원복 생략 + 수동 안내).
4. **원격 경고**: push/PR 은 자동 감지·원복 불가하므로, 부수효과 감지 시 "원격(push/PR)을 직접 확인하라"는 경고를 명시 출력.
5. **출력 형식 검증**: 부수효과가 없어도 TEMP 출력이 리뷰 형식(`# Code Review` 헤더 또는 `## 요약` 포함)이 아니면 거부(`exit 1`) — 비-리뷰(구현 요약 등) 오저장 방지.
6. **이중 미러**: `sources/bin/gemini-review.sh` ↔ `.harness-kit/bin/gemini-review.sh` 동기화.

### Non-Functional Requirements

1. **bash 3.2 호환**: `declare -A`/`mapfile`/`**`/`${,,}` 미사용.
2. **정상 경로 무회귀**: 부수효과 없고 리뷰 형식 정상인 gemini 응답은 기존과 동일하게 `code-review-gemini.md` 생성 + 요약 출력.
3. **자동 원복 안전 가드**: `git reset --hard`/`clean -fd` 는 *사전 clean* 확인 후에만. 사전 dirty 면 절대 파괴적 명령 실행 금지(사용자 작업 보호).
4. **gitignore 정합**: `code-review-gemini.md` 는 gitignore 대상 — `git clean -fd`(`-x` 미사용)가 이를 제거하지 않음 확인.

## 🚫 Out of Scope

- **gemini CLI 자체 수정** — upstream 도구 결함은 우리 통제 밖. 우리는 *호출 래퍼*만 방어.
- **`--sandbox`/`--worktree` 강제 적용** — 컨테인먼트 플래그는 portability(docker/sandbox-exec 의존) 리스크가 있어 *신뢰 기반*으로 삼지 않음. 감지+거부가 정본 방어. (향후 sandbox 가용 환경 한정 옵션은 별도 검토.)
- **`/hk-code-review`(Opus) 경로** — 본 사고와 무관(내장, 외부 CLI 없음). 변경 없음.
- **이미 발생한 #41/`9d07f91` 정리** — spec-21-04 에서 처리 완료(별건).

## 📑 ADR 후보 (Architecture Decision Records)

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — 도구 하드닝(fix). "외부 리뷰 도구는 read-only 를 신뢰하지 말고 부수효과를 감지·거부한다"는 원칙은 RCA(향후 동일 패턴 누적 시) 또는 invariant 노트로 자산화 가능하나 본 spec-x 범위 밖.

## ✅ Definition of Done

- [ ] `gemini-review.sh` 방어적 래퍼 구현 (source + 미러)
- [ ] `tests/test-gemini-review-guard.sh` 신규 — stub gemini 로 (a) rogue commit 감지+원복, (b) rogue 파일쓰기 감지, (c) 비-리뷰 출력 거부, (d) 정상 리뷰 성공 검증
- [ ] 기존 테스트 무 회귀
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit (코드 리뷰는 **Opus** — gemini 회피)
- [ ] `spec-x-gemini-review-sandbox` 브랜치 push 완료 (PR **base=main**)
- [ ] 사용자 검토 요청 알림 완료
