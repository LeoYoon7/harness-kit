# Walkthrough: spec-x-fragment-two-tier-restore

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| Check 4 FAIL 해소 방향 | 1) 상세 이전(two-tier 복원) 2) 임계 현실화(150→3200) 3) 하이브리드 | 1) 상세 이전 | 프로젝트 #1 원칙(컨텍스트 비용 0)과 원 설계계약 부합. 핵심 규칙 요약만 남기면 101w 로 ≤150 충족 실측 |
| 이전 그룹핑 | 단일 notify.md 통합 vs 분리(notify.md + align.md) | 분리 | 각 내용이 의미상 맞는 위치 — 알림/선택지는 notify.md, work-sizing 패턴은 정렬 단계(align.md). 다음 세션 탐색성 ↑ |
| cross-ref(§5/§9) 처리 | agent.md 재서술 vs 번호 보존 | 번호 보존 | notify.md 가 §1~§10 번호를 그대로 유지 → agent.md 의 "§5/§9 알림" 링크 무손상. surgical change (agent.md 미수정) |
| 코드 리뷰 게이트 | Gemini / Opus / Skip | Skip | verbatim relocation + grep 테스트 3개. 기계 검증 완료 |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — 2단계 로딩(tier-1 요약 / tier-2 상세)은 *기존 컨벤션*이며 테스트가 강제 중. 본 spec 은 드리프트를 원 의도로 *복원*했을 뿐 새 결정 없음

## 💬 사용자 협의

- **주제**: Check 4 FAIL 해소 방향 (구조 결정)
  - **사용자 의견**: 1번 (상세 이전 — two-tier 복원) — Telegram/PC 양 채널로 일관 응답
  - **합의**: fragment 는 핵심 규칙 요약만, 상세는 tier-2 로 이전
- **주제**: 코드 리뷰 게이트
  - **사용자 의견**: 3번 (Skip, Telegram 응답)
  - **합의**: docs/refactor relocation 으로 Skip, 사유 기록

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: `bash tests/test-two-tier-loading.sh` / `bash tests/test-governance-dedup.sh`
- **결과**: ✅ two-tier 10/10, governance-dedup 8/8
- **로그 요약**:
```text
two-tier: fragment 113 words → Check 4 PASS, Check 6/7/8(이전 검증) PASS → ALL 10 PASSED
dedup: Check 2 sources↔설치본 동기화 PASS, Check 3 const+agent 6393w ≤6500 PASS → ALL 8 PASSED
```

#### 영향 범위 회귀
- **결과**: ✅ install-manifest-sync 6/6 · claude-import 6/6 · install-layout 15/15 · context-orchestration 6/6 · director-protocol 13/13 · role-model 9/9 · sdd-config 14/14 · queue-redesign 5/5 · export-format 5/5 · drift-stale-adr PASS

### 2. 수동 검증

1. **Action**: `wc -w < sources/claude-fragments/CLAUDE.fragment.md`
   - **Result**: 113 (≤150)
2. **Action**: relocation 완전성 grep (notify.md 에 §1~§10/선택지규약/마크다운컨벤션 존재, fragment 에 누수 0)
   - **Result**: notify.md 마크다운컨벤션·비활성화·§10 모두 존재, fragment 누수 0
3. **Action**: `diff -q` sources↔설치본 4쌍
   - **Result**: 전부 일치

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | Skip |
| **결과 파일** | — |
| **요약** | — |
| **Skip 사유** | verbatim 거버넌스 문서 relocation + 단순 grep 테스트 3개. test-two-tier 10/10 + relocation 완전성 grep 으로 기계 검증, 사용자 승인(3번) |

## 🔍 발견 사항

- **사전 존재 테스트 실패 2건 (이 spec 무관, `git diff main...HEAD` 로 인과 배제)**:
  - `test-sdd-drift.sh` T1 — "동기화 상태 섹션 누락" (Windows 환경 drift 섹션 감지 이슈). sdd·테스트 모두 미변경. 일관 재현(플래키 아님).
  - `test-phase17-integration.sh` Scenario 4c — `CLAUDE.md` 의 "Phase ship 시 CHANGELOG draft" 룰을 grep 하나, spec-x-claude-md-slim(#135)이 룰을 `docs/release-strategy.md` 로 이전해 stale (CLAUDE.md hit=0, release-strategy hit=1). 테스트가 새 위치를 반영하도록 갱신 필요 — Icebox 후보.
- 신규 tier-2 문서(`notify.md`)는 단어 수 상한(budget) 테스트 밖 — 본 spec 은 내용 이동만이라 범위 외. 필요 시 별도 검토.

## 🚧 이월 항목 (Optional)

- `test-phase17-integration.sh` Scenario 4c stale-grep 수정 (CHANGELOG 룰 이전 반영) — 사용자 판단 후 Icebox/spec-x
- `test-sdd-drift.sh` T1 Windows drift-섹션 감지 — 기존 "sdd status Windows 성능 저하" 계열과 함께 검토

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-16 |
| **최종 commit** | (ship commit 시 갱신) |
