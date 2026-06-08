docs(spec-22-01): persona review panel research (Conditional No-Go)

## 📋 Summary

### 배경 및 목적
review 커맨드의 단일 Opus 리뷰를 **페르소나 패널**(다관점 워커 + 종합/중재)로 바꿀지 결정하기 위한 **Research Spec** (§9). phase-21 에서 "종료조건·증류 난점" 으로 defer 된 항목을 research-first 로 재개. 핵심은 5난점 해소 + **value(단일 Opus 대비 우위) 반증가능 측정**.

### 주요 변경 사항
- [x] 5난점(종료조건/증류/무한루프/검증불변식/context오염) 설계 분석 (각 ≥2안) → `report.md §2`
- [x] 측정틀 설계 (value/issue retention/비용 + self-consistency baseline) → `report.md §3`
- [x] POC 실행 (패널 3 + baseline Opus×3, n=1) → `scripts/research/` + `report.md §5`
- [x] **Conditional No-Go 권고** → `report.md §6`

### Phase 컨텍스트
- **Phase**: `phase-22` (persona-review-panel, research-first, non-base)
- **본 SPEC 의 역할**: 패널 도입 여부를 *짓기 전에* 실증으로 판정. 결과는 단순 패널 보류 + 하이브리드 방향 + 재사용 측정틀.

## 🎯 Key Review Points

1. **결론 = Conditional No-Go**: liveness(수렴/격리)는 ✅ 이나 value 가 self-consistency baseline 을 지배 못함(상보적, 비용 동급). 단순 페르소나 패널 ROI 불명확.
2. **핵심 증거**: 패널은 framing 폭(모바일→embed 핵심 이슈)에서 우위, baseline 은 구체 버그(awk locale, 3/3)에서 우위. 패널이 그 버그를 전원 놓침.
3. **context 격리 실증**: 6 워커 전원 결과 계약(JSON)만 반환 → ADR-010 불변식(워커 transcript 재흡수 금지) 준수.
4. **n=1 한계**: 단일 표본. 일반화 금지 — 권고는 *방향* 근거.

## 🧪 Verification

### 자동 테스트
Research/docs-only — production 코드 미변경, 표준 단위 테스트 해당 없음 (§9.1 POC 실증으로 대체).

### 수동 검증 시나리오 (POC, n=1)
1. **패널+baseline 팬아웃** (`archive/specs/spec-x-notify-channel-formatter`) → 6 워커 결과 계약만 반환, 라운드 1 수렴, 격리 확인.
2. **value 비교** → 패널 ≯ baseline (상보적, 비용 동급) → Conditional No-Go.

## 📦 Files Changed

### 🆕 New Files
- `backlog/phase-22.md`: phase 작업 지도 (research-first)
- `specs/spec-22-01-persona-panel-research/{spec,plan,task,critique,report,walkthrough}.md`
- `scripts/research/persona-panel-poc.md`, `persona-panel-poc-run.md`: POC 정의 + 실행 로그

### 🛠 Modified Files
- `backlog/queue.md` (+1, -1): phase-22 active 마커

**Total**: 9 files (docs/research only)

## ✅ Definition of Done

- [x] 5난점 ≥2안 트레이드오프 분석
- [x] 측정 설계 + POC + baseline 비교 실증
- [x] Go/No-Go 권고 (Conditional No-Go)
- [x] `walkthrough.md` / `pr_description.md` ship commit
- [x] 코드 리뷰: Skip (`docs-only`)
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Phase: `backlog/phase-22.md`
- Report: `specs/spec-22-01-persona-panel-research/report.md`
- 관련 ADR: 정합 점검 ADR-008/010/011 (신규 ADR 미작성 — No-Go)
