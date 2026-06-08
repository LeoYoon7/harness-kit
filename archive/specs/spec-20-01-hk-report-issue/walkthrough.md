# Walkthrough: spec-20-01

> 본 문서는 *작업 기록* 입니다. 결정·협의·검증·발견을 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 포팅 방식 | 복사 / 재작성 | **upstream 원본 복사** (`git show upstream/main:...`) | 커맨드가 분기 거버넌스 비의존 + 충실 포팅으로 향후 sync 용이 |
| git-bash 한글 argv | 적응 / 비처리 | **비처리** | 키트 1차 타깃 macOS(argv raw) + 기존 fork 커맨드 공통 quirk → 별도 처리 대상 |
| installedCommands 순서 | 끝 추가 / 알파벳 | hk-pr-gh 뒤 삽입 | 기존 배열의 느슨한 알파벳 순서 유지 |

### ADR 승격 가이드
- [ ] ADR 승격 대상 있음
- [x] 없음 — 단순 포팅, 신규 결정 없음

## 💬 사용자 협의

- **주제**: upstream 신규 기능 fork 적용 전략 (phase-20 alignment)
  - **사용자 의견**: upstream 기능을 로컬에 적용하고 싶다.
  - **합의**: 전체 merge 비권장(분기 과대) → **기능별 혼합 전략**. quick wins 먼저(`/hk-report-issue`) → director mode 는 후반 재구현. 본 spec 이 그 첫 quick win.

## 🧪 검증 결과

### 1. 자동화 테스트
- **명령**: `bash tests/test-report-issue-cmd.sh`
- **결과**: ✅ ALL PASS (exit 0). TDD Red(5 FAIL) → Green 전환 확인.
- **로그 요약**:
```text
✓ sources/installed 커맨드 존재 + 동일
✓ 핵심 섹션(판정 게이트 / gh issue create / 시크릿 / [Y/n])
✓ installedCommands 등록 + README 언급
```

### 2. 수동 검증
1. **Action**: `git show upstream/main:sources/commands/hk-report-issue.md | diff - sources/...` — **Result**: DIFF_EMPTY (upstream 와 byte 동일, 충실 포팅 확인)
2. **Action**: 설치 후 Claude Code 스킬 목록 확인 — **Result**: `hk-report-issue` 가 즉시 스킬로 인식됨 (설치 위치 정상 검증)

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | Skip |
| **Skip 사유** | `small-port` — upstream 원본 verbatim 복사(이미 upstream 에서 리뷰됨) + 2줄 등록 + 구조 테스트 PASS. 신규 로직 없음 |

## 🔍 발견 사항

- **CC PreToolUse hook vs git pre-commit hook 대비**: 본 spec 커밋 중 git 의 `staged-lint` pre-commit hook 이 정상 발화(shellcheck 미설치 경고)한 반면, CC PreToolUse hook 은 여전히 no-op([[hooks-noop-stdin-vs-env]]). 두 hook 계층이 별개임을 재확인.
- `/hk-report-issue` 자체가 위 hook no-op 결함을 upstream 에 환류하는 경로 — phase-20 의 첫 산출물이 곧 후속 작업의 도구.

## 🚧 이월 항목

- 없음 (소규모 fix·director mode 는 phase-20 후속 spec)

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-04 |
| **최종 commit** | ship commit (push 직전) |
