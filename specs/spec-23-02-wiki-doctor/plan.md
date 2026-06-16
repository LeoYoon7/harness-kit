# Implementation Plan: spec-23-02

## 📋 Branch Strategy

- 신규 브랜치: `spec-23-02-wiki-doctor` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> 본 Plan 을 Accept 하기 전에 사용자가 명시적으로 확인해야 할 항목들.

> [!IMPORTANT]
> - [ ] **stale 정의 = frontmatter `updated:`/`date:` (mtime 아님)**: clone 시 mtime 이 리셋돼 false-negative 나므로 frontmatter 날짜 사용. 이게 핵심 설계 결정.
> - [ ] **날짜 이식성 분기**: cutoff(today-90d) 계산을 GNU `date -d`/BSD `date -v` 분기 (macOS 1차 타깃). `YYYY-MM-DD` 문자열 비교로 비교 자체는 단순.
> - [ ] **모두 경고(`_doc_warn`)**: 차단 아님 (hook 단계론). 오탐(외부 URL/`org/repo`)은 `[[...]]` 내부 링크만 대상으로 회피.

> [!WARNING]
> - [ ] doctor 변경은 `sources/bin/sdd` (키트 원본). 설치 프로젝트는 `update.sh` 전까지 미반영.

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **고아 링크 (a)** | `docs/wiki/*.md` 의 `[[...]]` 추출 → prefix 별 glob 해석 → 부재 경고 | 지식 그래프 간선 검증. archive fallback(A1 교훈) |
| **stale 90d (b)** | frontmatter `updated:`→`date:` vs cutoff(today-90d) 문자열 비교 | mtime 은 clone 불안정. 이식성 분기 |
| **단어수 (c)** | `.harness-kit/agent/{constitution,agent}.md` `wc -w` 합 vs 6500 | ADR-012 + test-governance-dedup Check 3 동일 방식 |
| **테스트** | `tests/test-wiki.sh` 신설 (fixture 기반 3종 + 템플릿 Related 회귀) | phase-23 통합 테스트 |

### 📑 ADR 후보
- [ ] 있음
- [x] 없음 — phase-19/ADR-012 가 컨벤션·상한 기정립.

## 📂 Proposed Changes

### sdd doctor

#### [MODIFY] `sources/bin/sdd` (`cmd_doctor` — 신규 "wiki/문서 건강" 섹션)
- 각 점검은 대상 디렉토리 부재 시 silent skip. 모두 `_doc_warn`.
- (a) 고아 `[[wikilink]]`: `docs/wiki/*.md` 스캔 → `[[...]]` 추출 → prefix 분기 해석(`wiki/`·`ADR-`·`RCA-`·`spec-`, spec 은 archive fallback) → 미존재 카운트.
- (b) stale 90d: `docs/decisions/ADR-*.md`·`docs/rca/RCA-*.md` frontmatter 날짜 추출 → cutoff 비교 → 초과 카운트. cutoff 헬퍼:
```text
_cutoff_90d() {  # today-90d 를 YYYY-MM-DD 로 (GNU/BSD 분기)
  date -d '90 days ago' +%Y-%m-%d 2>/dev/null || date -v-90d +%Y-%m-%d
}
```
- (c) 단어수: `wc -w` 합 > 6500 경고 (현재값/상한 표시).

### 테스트

#### [NEW] `tests/test-wiki.sh`
- fixture: `docs/wiki/`(고아 링크 유/무), `docs/decisions/`(오래된/최근 frontmatter date), governance(6500 초과/이하).
- 3종 점검 각각 경고 발화 여부 + silent skip(대상 부재) 검증.
- 템플릿 Related 섹션 회귀: `sources/templates/{spec,walkthrough}.md` 에 `관련 문서` 존재 (phase 시나리오 2).

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
bash tests/test-wiki.sh
```

### 통합 테스트 (Integration Test Required = yes)
```bash
bash tests/test-wiki.sh   # phase-23 시나리오 1(고아+stale), 2(템플릿 Related) 커버
```

### 수동 검증 시나리오
1. dogfood 레포에서 `sdd doctor` 실행 → wiki/문서 건강 섹션 출력, 현재 단어수 vs 6500 표시 — 기대: 실제 상태 경고/통과.
2. 고아 링크 없는 정상 상태 → 경고 0.

## 🔁 Rollback Plan

- doctor 추가 섹션이라 격리. 문제 시 해당 커밋 revert (기존 점검 무영향).
- 모두 `_doc_warn` 라 false positive 도 차단 아닌 노이즈에 그침.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
