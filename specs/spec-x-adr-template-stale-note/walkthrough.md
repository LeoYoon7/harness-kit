# Walkthrough: spec-x-adr-template-stale-note

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| fix 방식 | ① 평문 표기 / ② `../` prefix 예시 / ③ 휴리스틱에서 note 제외 | ① 평문 표기 | ② 는 note 가 "이 예시는 검사 대상"이라 설명하는데 `../` 는 *제외* 대상이라 자기모순. ③ 은 휴리스틱 변경 → Step 1~6 회귀 리스크. ① 이 최소·무모순 |
| 휴리스틱 변경 여부 | 변경 / 무변경 | 무변경 | 템플릿 content fix 로 충분. `_drift_stale_adr` 무손 → 기존 6 Step 보존 |
| 회귀 테스트 방식 | 하드코딩 note / 라이브 템플릿 추출 | 라이브 추출 (`grep '^>' sources/templates/adr.md`) | 미래에 트리거 예시 재도입 시 자동 실패 — 하드코딩보다 강한 가드 |
| `../` 제외 문서화 | 추가 / 생략 | 추가 | 휴리스틱 규칙 4 와 정합, 작성자 가이드 보강 (zero-risk 문서 개선) |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — 템플릿 문구 1곳 + 테스트 1 Step. routine fix.

## 💬 사용자 협의

- **주제**: 이슈 #55 처리 작업 모드
  - **사용자 의견**: 1번 (spec-x)
  - **합의**: PR 경로 + `Fixes #55` 자동 close
- **주제**: Windows 테스트 지연
  - **사용자 의견**: 소요 시간 질의 (Linux 대비)
  - **합의**: 느림은 Windows MSYS2 서브프로세스 spawn 비용 (sys 54s) — macOS/Linux 1차 타깃에선 ~1~2s/호출, 비이슈. 전체 suite 완주로 Red→Green 확인

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: `bash tests/test-drift-stale-adr.sh`
- **결과**: ✅ Passed (7/7, EXITCODE=0)
- **로그 요약**:
```text
TDD Red (fix 전, 커밋 648e243): Step 1~6 ✓ / Step 7 ✗
  stale ADR: 1 (missing-path) — docs/decisions/ADR-994-template-note-fixture.md
TDD Green (fix 후, 커밋 b070e2a): Step 1~7 ✓ "All tests passed."
  Step 7: template note fixture (live note embedded) → not in stale list
```

#### 정적 검증 (휴리스틱 규칙 직접 적용)
- **명령**: fixed note 의 backtick 토큰에 규칙 1~5 (슬래시/URL/확장자/`../`) 적용
- **결과**: 추출 가능한 트리거 토큰 **0개** — note 가 자가-트리거 불가 확인

#### 회귀 (템플릿 인접 suite)
- `test-install-manifest-sync` → ✅ Pass
- `test-wiki-structure` → ✅ Pass
- `test-two-tier-loading` → ❌ Check 4 FAIL (fragment 3095w > 150w) — **본 spec 무관·main 기존 실패** (내 diff 에 `CLAUDE.fragment.md` 없음, `git diff main...HEAD` 확인). Icebox 등록 (별도 spec-x 후보)

### 2. 수동 검증

1. **Action**: `grep '^>' sources/templates/adr.md` (fix 후)
   - **Result**: `src/foo.ts` 가 평문 (backtick 없음) 으로 표기됨 — `` `sdd status` `` (슬래시 없음) 외 backtick 경로 토큰 없음
2. **Action**: dogfood 사본 비교 `diff sources/templates/adr.md .harness-kit/agent/templates/adr.md`
   - **Result**: 동일 (sync 확인)

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | Skip |
| **결과 파일** | — |
| **요약** | — |
| **Skip 사유** | 변경이 ADR 템플릿 마크다운 1줄 + 테스트 1 Step 으로 production 로직 없음 (docs/test-only). 정적 검증(트리거 토큰 0) + drift-stale-adr 7/7 Green 으로 검증 완료 (agent.md §6.3-8 auditable skip) |

## 🔍 발견 사항

- 본 repo 의 `docs/decisions/ADR-*.md` 는 이미 안전했다 (ADR-013 류 실존 경로 예시 / ADR-002 류 무예시). 결함은 템플릿 한정 — kit 자체는 stale 오탐 없음.
- stale-ADR 휴리스틱이 system 루트 기준이라 monorepo sibling 레포 경로는 여전히 false-positive 가능 → Icebox 등록 (별도 검토).

## 🚧 이월 항목

- monorepo sibling 레포 경로 stale-ADR false-positive → `backlog/queue.md` Icebox (stale-adr-archive-path follow-up 계열)

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-12 |
| **최종 commit** | `b070e2a` (+ ship commit) |
| **연관 이슈** | #55 |
