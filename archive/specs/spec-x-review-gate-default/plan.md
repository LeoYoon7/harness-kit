# Implementation Plan: spec-x-review-gate-default

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-review-gate-default` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> 본 Plan 을 Accept 하기 전에 사용자가 명시적으로 확인해야 할 항목들.

> [!IMPORTANT]
> - [ ] 게이트 **기본값을 "실행" 으로 뒤집고** Skip 에 한 줄 사유 기록 의무를 부과한다 — 매 ship 마찰이 소폭 증가하는 것을 수용하는가?
> - [ ] 리뷰를 완전 강제(Skip 불가)하지 않고 **감사형(기록 동반 Skip 허용)** 으로 둔다 — 방향 2 확정.

> [!WARNING]
> - [ ] 본 변경은 `sources/` 원본만 수정한다. 실행 중인 본 repo 의 live 거버넌스(`.harness-kit/`)는 `update.sh` 가 별도 동기화하므로, 본 PR 머지만으로는 즉시 적용되지 않는다 (ADR-003).

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **게이트 강제 방식** | 감사형 Skip (기본=실행, Skip 시 사유 기록) | 누락을 침묵이 아닌 *기록되는 의도적 행위* 로 전환. forcing function 을 차단이 아닌 책임으로 구현 |
| **3지선다 구조** | 유지 (Gemini/Opus/Skip) | 기존 hk-ship §1.5 와 호환. cross-model(Gemini) 권장 유지 |
| **변경 범위** | `sources/` 원본만 | 도그푸드 동기화 정책(ADR-003) — 설치본은 update 책임 |

### 📑 ADR 후보

- [x] ADR 가치 있는 결정 있음 → 후보 한 줄 요약: `code-review-gate-default-run` (type: **decision**)
- [ ] 없음

## 📂 Proposed Changes

### 거버넌스 규칙

#### [MODIFY] `sources/governance/agent.md` (§6.3 Walkthrough & Description Protocol, 8번 항목)

"Code Review Gate (optional)" 항목을 개정한다.

```text
변경 전: Code Review Gate (optional) — offers a review choice ... or Skip.
변경 후: Code Review Gate (default-run, auditable skip)
         - 기본/권장 = 리뷰 실행(Gemini cross-model 권장)
         - Skip 가능하나, walkthrough.md "코드 리뷰" 칸에 한 줄 사유 기록 필수
         - docs-only 변경은 사유 "docs-only" 한 단어 허용
```

### 커맨드 절차

#### [MODIFY] `sources/commands/hk-ship.md` (§1.5 코드 리뷰 게이트)

- 게이트 프레이밍을 "선택" → "기본 실행, Skip 은 사유 기록 동반" 으로 재구성.
- Skip(3) 분기에 "한 줄 사유를 받아 walkthrough.md 코드 리뷰 칸에 기록" 절차를 추가.
- 권장(Gemini) 및 Critical 처리(§1.5 하단)는 유지.

### 산출물 양식

#### [MODIFY] `sources/templates/walkthrough.md`

- "🔍 코드 리뷰" 칸 신설 (검증 결과 섹션 근처). 수행 시 모델(Gemini/Opus) + 결과 파일 링크, Skip 시 사유 한 줄을 기록.

### 결정 기록

#### [NEW] `docs/decisions/ADR-006-code-review-gate-default-run.md`

- type: `decision`. 결정(감사형 기본값) + 기각 대안(순수 optional / 완전 강제 / 스코프 트리거) + 근거(forcing function via accountability) + 결과(영향).

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)

본 spec 은 거버넌스/커맨드/템플릿 마크다운 + ADR 변경으로 **실행 가능한 동작이 없어 단위 테스트 N/A** (constitution §9.1 docs-only 정당화). 대신 아래 정적 검증으로 대체한다.

```bash
# 1. agent.md 게이트 항목이 "기본 실행/사유 기록" 으로 개정됐는가
grep -nE "auditable skip|사유 기록|default-run" sources/governance/agent.md
# 2. hk-ship §1.5 Skip 분기에 사유 기록 절차가 있는가
grep -nE "사유" sources/commands/hk-ship.md
# 3. walkthrough 템플릿에 코드 리뷰 칸이 생겼는가
grep -nE "코드 리뷰" sources/templates/walkthrough.md
# 4. ADR-006 존재 + frontmatter type
grep -nE "^type:\s*decision" docs/decisions/ADR-006-code-review-gate-default-run.md
```

### 수동 검증 시나리오

1. `hk-ship.md §1.5` 를 통독 → Skip 선택 시 사유를 받아 walkthrough 에 기록하는 흐름이 명확한가. 기대: 명확함.
2. `walkthrough.md` 템플릿의 코드 리뷰 칸이 "수행/Skip" 두 경우를 모두 커버하는가. 기대: 커버함.
3. `agent.md §6.3-8` 과 `hk-ship §1.5` 의 문구가 서로 모순되지 않는가. 기대: 일관됨.

## 🔁 Rollback Plan

- 문서/템플릿/ADR 변경만 있으므로 `git revert` 로 안전하게 되돌릴 수 있다. 코드·상태·데이터 영향 없음.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
