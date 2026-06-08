# Walkthrough: spec-x-review-gate-default

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 코드 리뷰 게이트가 유명무실 | 1.스코프 트리거 / 2.감사형 기본값 / 3.결합 | **2 (감사형 기본값)** | 누락 원인이 forcing function 부재. 스코프 트리거(1)는 "trivial 선언" 으로 빠져나갈 여지가 남음. 기록 동반 Skip 이 누락을 직접 차단 |
| 게이트 강제 강도 | optional 유지 / 완전 강제 / 감사형 | **감사형 (기록 동반 Skip 허용)** | `agent.md §6.3` optional gate 의도와 양립. 완전 강제는 docs-only 에 과도 |
| 변경 범위 | sources 원본만 / 설치본 동기 수정 | **sources 원본만** | ADR-003 도그푸드 동기화 정책. 설치본은 update.sh 책임 |

### ADR 승격 가이드

- [x] ADR 승격 대상 있음 → 작성됨: `docs/decisions/ADR-006-code-review-gate-default-run.md`
- [ ] 없음

## 💬 사용자 협의

- **주제**: "ship 단계 code review 에 제한이 없다 / optional 기준이 뭐냐"
  - **사용자 의견**: optional 로 뒀다면 그 기준이 무엇인가. 실제 운영 시 거의 제안하지 않아 유명무실하다.
  - **합의**: 기준이 없다는 진단에 동의. 4개 방향(스코프 트리거 / 감사형 기본값 / 결합 / 기타) 중 **2번(감사형 기본값)** 채택.
- **주제**: working tree 의 수동 복사 런처(`claude-dangerously-skip-permissions.sh`) 처리
  - **사용자 의견**: 수동 복사본이니 삭제하면 원래 상태로 복귀.
  - **합의**: 삭제로 정리(원본은 `sources/optional/` 에 보존, 언제든 재복사 가능). 본 spec 시작 전 선행 처리 완료.
- **주제**: ship 코드 리뷰 게이트(§1.5) 본 ship 적용
  - **사용자 의견**: docs-only 변경.
  - **합의**: **Skip (사유 `docs-only`)** — 새 정책 도그푸딩.

## 🧪 검증 결과

### 1. 자동화 테스트

docs/거버넌스/템플릿 + ADR 변경으로 실행 가능한 동작이 없어 **단위/통합 테스트 N/A** (constitution §9.1 docs-only 정당화). 정적 grep 검증으로 대체.

### 2. 수동 검증

1. **Action**: `grep -nE "default-run|auditable skip" sources/governance/agent.md`
   - **Result**: line 218 매치 — §6.3-8 정책 개정 확인 (FR1)
2. **Action**: `grep -cE "사유" sources/commands/hk-ship.md`
   - **Result**: 5건 매치 — §1.5 Skip 사유 기록 절차 확인 (FR2)
3. **Action**: `grep -nE "코드 리뷰" sources/templates/walkthrough.md`
   - **Result**: line 63 "## 🔍 코드 리뷰" 매치 — 템플릿 칸 신설 확인 (FR3)
4. **Action**: `grep -nE "^type:\s*decision" docs/decisions/ADR-006-code-review-gate-default-run.md`
   - **Result**: line 3 매치 — ADR-006 frontmatter 확인 (FR4)

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | **Skip** |
| **결과 파일** | (없음) |
| **요약** | (없음) |
| **Skip 사유** | `docs-only` — 거버넌스/커맨드/템플릿 마크다운 + ADR 변경으로 diff 기반 코드 리뷰 대상 코드가 없음. 본 spec 이 신설한 docs-only 예외에 정확히 해당 (도그푸딩) |

## 🔍 발견 사항

- **gitbash 비-ASCII argv 손상 라이브 재현**: Ship 정적 검증 시 `grep -nE "## 🔍 코드 리뷰"` (이모지 포함) 가 무매치였으나, 한글만의 `grep "코드 리뷰"` 는 정상 매치. 메모리에 기록된 git-bash CP949 argv 손상 패턴(RCA-002 계열)이 이모지에서 재현됨. 검증 패턴에 이모지를 넣지 않는 것이 안전.
- **메타 도그푸딩**: "리뷰 게이트를 강화하는 spec" 자체가 리뷰 대상 코드가 없어 새 정책의 docs-only Skip 경로를 즉시 검증하게 됨.

## 🚧 이월 항목 (Optional)

- **Critical 하드 게이트** (리뷰에서 Critical 발견 시 "무시하고 ship" 옵션 제거) → 본 spec Out of Scope. 필요 시 별도 spec/Icebox 후보.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Opus) + Leo |
| **작성 기간** | 2026-06-02 |
| **최종 commit** | (ship commit 시점) |
