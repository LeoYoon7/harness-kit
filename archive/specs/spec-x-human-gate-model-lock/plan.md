# Implementation Plan: spec-x-human-gate-model-lock

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-human-gate-model-lock` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] **잠금 범위 = `/hk-plan-accept` + `/hk-phase-ship` 2개만**. `/hk-ship`·`/hk-pr-*` 등 post-accept 위임 커맨드는 model-invocable 유지(정합).
> - [ ] **primary 레버 = `disable-model-invocation: true` frontmatter** (두 출처 합의). settings 권한 화이트리스트는 도구명/syntax 불확실로 **보류**(Icebox).

> [!WARNING]
> - [ ] **핵심 가정/위험**: `disable-model-invocation` 이 `.claude/commands/*.md`(스킬 아닌 커맨드)에 실제 적용된다는 가정(두 출처가 commands↔skills 호환 명시). *만약 커맨드엔 안 먹으면* frontmatter 가 무효 → **Hard Stop** 후 fallback(settings deny 또는 커맨드→스킬 전환) 재정렬.
> - [ ] production 코드 변경 없음(커맨드 frontmatter + docs + ADR). 단위 테스트 없음.

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **게이트 잠금** | `disable-model-invocation: true` on hk-plan-accept·hk-phase-ship | frontmatter 한 줄, 도구명/syntax 논쟁과 무관, 두 출처 합의 |
| **동기화** | sources/commands → .claude/commands 직접 반영 | ADR-003 단방향(원본→설치본). 커맨드는 .claude/commands/ 로 설치 |
| **settings 권한** | **보류** (Icebox) | SlashCommand vs Skill tool 이름·syntax·기본 posture 불확실 — 별도 검증 후 |
| **ADR** | 신규 ADR-008 (invariant) | "사람 게이트는 model-invocable 금지" 는 ADR-007(기능 채택)과 별개 불변식 |

### 📑 ADR 후보

- [x] ADR 가치 있는 결정 있음 → `ADR-008-human-gate-model-invocation` (type: invariant)
- [ ] 없음

## 📂 Proposed Changes

#### [MODIFY] `sources/commands/hk-plan-accept.md` · `sources/commands/hk-phase-ship.md`
- frontmatter 에 `disable-model-invocation: true` 추가 (기존 `description` 유지).

#### [MODIFY] `.claude/commands/hk-plan-accept.md` · `.claude/commands/hk-phase-ship.md`
- 도그푸딩 설치본 동기화 (동일 frontmatter).

#### [MODIFY] `sources/governance/native-feature-usage.md` · `.harness-kit/agent/native-feature-usage.md`
- §1.5 정정: SlashCommand/Skill tool 기준 + 검증된 category(`/workflows` 뷰어·`/team-onboarding` → 👤, `/batch` → 🤖) + `disable-model-invocation` 레버 + `/hk-*` invocable 사실.

#### [NEW] `docs/decisions/ADR-008-human-gate-model-invocation.md`
- type: invariant. "사람 승인 게이트 커맨드는 model-invocable 이면 안 된다" + `disable-model-invocation` 정책 + settings 레이어 보류 근거 + 검증 출처.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```text
해당 없음 — docs/config (constitution §9.1 justified).
```
```bash
# 거버넌스 문서(native-feature-usage 는 governance/) 편집 후 동기화 회귀 확인
bash tests/test-governance-dedup.sh   # Check 2 (sources ↔ .harness-kit) — native-feature-usage 포함 여부 무관, 기존 파일 회귀 없음 확인
```

### 수동 검증 시나리오
1. `grep -L disable-model-invocation` 로 hk-plan-accept·hk-phase-ship 에 frontmatter 적용 확인 (원본+설치본). — 기대: 4개 파일 모두 보유.
2. playbook §1.5 의 category 가 검증 결과와 일치. — 기대: 모순 없음.
3. (사용자 라이브, 선택) 모델이 `/hk-plan-accept` 를 자가 호출 시도 → 차단/미노출 확인. Done 조건 아님.

## 🔁 Rollback Plan

- frontmatter/docs 변경이라 commit revert 로 즉시 원복.
- 상태 영향 없음.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
