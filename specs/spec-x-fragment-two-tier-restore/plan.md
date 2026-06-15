# Implementation Plan: spec-x-fragment-two-tier-restore

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-fragment-two-tier-restore` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] **이전 구조 결정** — fragment 의 상세를 어떻게 나눌 것인가:
>   - 알림 프로토콜(§1~§10) + 선택지 제시 규약 → 신규 `notify.md`
>   - 검증된 패턴/안티패턴 → `align.md` (의미상 work-sizing = 정렬 단계 가이드)
>   - (대안) 셋 모두 단일 `notify.md` 에 통합 — 파일 1개·sync 1개로 churn 최소, 단 파일명-내용 의미 불일치
> - [ ] **fragment 최종 형태** — 핵심 규칙 요약(101w) + tier-2 위치 포인터 1줄만 남김 (테스트 목표 150w 유지)

> [!WARNING]
> - [ ] **기능 트레이드오프** — 알림 상세가 tier-2 로 내려가 `/hk-align` 없이 시작한 세션은 상세 미보유 (완화책은 spec.md NFR 3 참조). 수용 가능 여부 확인.

## 🎯 핵심 전략 (Core Strategy)

### 아키텍처 컨텍스트

```text
[변경 전]
CLAUDE.md ──@import──> CLAUDE.fragment.md (3095w: 요약+패턴+선택지규약+알림프로토콜)   ← 상시 로딩, Check4 FAIL
hk-align.md ──@import──> agent/{constitution,agent,align}.md                          ← /hk-align 시 로딩

[변경 후]
CLAUDE.md ──@import──> CLAUDE.fragment.md (~116w: 핵심 규칙 요약 + tier-2 포인터)       ← 상시 로딩, Check4 PASS
hk-align.md ──@import──> agent/{constitution,agent,align, notify}.md                   ← /hk-align 시 로딩
                                          │            └ 패턴/안티패턴 추가
                                          └ notify.md (신규): 알림 프로토콜 §1~§10 + 선택지 제시 규약
```

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **신규 tier-2 문서** | `sources/governance/notify.md` 생성 | governance glob 자동 install (`install.sh:264-269`) — 하드코딩 목록 수정 불요 |
| **알림 프로토콜 + 선택지 규약** | fragment → `notify.md` 이전 (§1~§10 번호 보존) | 비대화 주범(~2800w). 두 규약은 결합(알림이 [권장]을 운반) |
| **패턴/안티패턴** | fragment → `align.md` 이전 | work-sizing 학습은 정렬 단계 가이드(align.md)가 의미상 적합 |
| **fragment** | 핵심 규칙 요약(101w) + 포인터 1줄만 | "핵심 규칙 요약" 문구 유지(Check5) + ≤150w(Check4) |
| **로더** | `hk-align.md` 에 `@.harness-kit/agent/notify.md` 추가 | tier-2 로더는 hk-align 단일 (조사 확인) |
| **cross-ref** | `agent.md`/`constitution.md` 미수정 | §5/§9 번호 보존으로 링크 유지 — surgical |
| **설치본 sync** | 변경 파일만 targeted cp | dogfood drift 방지 (dedup Check2 는 const/agent 만 검사하나 정합 위해 전부 sync) |

### 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 (spec.md 와 동일 — 기존 컨벤션 복원)

## 📂 Proposed Changes

### tier-2 신설

#### [NEW] `sources/governance/notify.md`
- 첫 줄: 한국어 헤더 코멘트 (역할 1줄).
- 내용: fragment 의 "선택지 제시 규약" + "의사결정 알림 프로토콜 §1~§10" + "알림 메시지 마크다운 컨벤션" + 관련 정책 섹션을 **그대로** 이전.
- §1~§10 알림 섹션 번호 보존. 인트로에 "agent.md §6.8 의 '§5/§9 알림' 은 본 문서의 §5/§9" 1줄 명시.

#### [MODIFY] `sources/commands/hk-align.md`
- §1 규약 로딩 목록에 `- @.harness-kit/agent/notify.md` 추가.

### tier-1 정리

#### [MODIFY] `sources/claude-fragments/CLAUDE.fragment.md`
- "핵심 규칙 요약" 섹션(현 lines 1-17)만 유지.
- 하단에 tier-2 위치 포인터 1줄 추가: 알림/선택지 상세 → `notify.md`, 패턴 → `align.md` (`/hk-align` 시 로딩).
- 나머지(패턴·선택지규약·알림프로토콜) 제거 → 목표 ≤150w.

#### [MODIFY] `sources/governance/align.md`
- 말미에 "## 검증된 패턴 & 안티패턴 (phase-08~18 distilled)" 섹션을 fragment 에서 이전.

### 도그푸딩 동기화

#### [MODIFY] 설치본 (targeted cp, 추적 대상만)
- `.harness-kit/CLAUDE.fragment.md` ← 신 fragment
- `.harness-kit/agent/notify.md` ← 신규 (new)
- `.harness-kit/agent/align.md` ← 패턴 추가본
- `.claude/commands/hk-align.md` ← import 추가본 (설치본 존재 시)

### 테스트

#### [MODIFY] `tests/test-two-tier-loading.sh`
- 신규 단언 추가 (TDD):
  - notify.md 존재 + 알림 프로토콜 핵심 문구 보유
  - `hk-align.md` 가 `@.harness-kit/agent/notify.md` import
  - fragment 가 알림 프로토콜 본문(예: "의사결정 알림 프로토콜" 헤딩)을 더 이상 보유하지 않음 (실제 이전 확인)

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
bash tests/test-two-tier-loading.sh
bash tests/test-governance-dedup.sh
```
기대: 양쪽 모두 `ALL ... CHECKS PASSED` (exit 0).

### 수동 검증 시나리오
1. `wc -w < sources/claude-fragments/CLAUDE.fragment.md` → ≤150 확인.
2. `grep -c "의사결정 알림 프로토콜" sources/governance/notify.md` ≥1, 동일 grep 이 fragment 에는 0.
3. `bash .harness-kit/bin/sdd status` → 동기화 상태 "깔끔" (drift 없음).

## 🔁 Rollback Plan

- 단일 브랜치의 문서 이동이므로 `git revert` 또는 브랜치 폐기로 즉시 원복.
- 데이터/상태 영향 없음 (문서·테스트만 변경).

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
