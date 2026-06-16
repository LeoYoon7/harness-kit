# Walkthrough: spec-23-01

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| ingest 의 log/index 갱신 vs purpose.md 운영규칙 #2("수동 유지") | A: synthesis만 갱신 / B: log append + index refresh | B | log.md 는 정의상 *인제스트 이벤트 이력* → ingest 가 append 하는 게 자연스러움. rule #2 의 "수동"은 *구조 큐레이션* 의미로 해석, 이벤트 append/인벤토리 refresh 와 양립 (spec-19-02 워크플로와 일치) |
| 템플릿 Related 위치 (Gemini Minor) | 통일 vs 현행 유지 | 현행 유지 | Gemini 권고 규칙("메타 있으면 직전, 없으면 최하단")이 *이미* 현재 배치 — spec.md(trailing 메타 없음)=최하단, walkthrough.md(메타 footer)=직전. 절대 위치만 달라 보일 뿐 동일 규칙 |
| archive 힌트 노출 조건 | 항상 / `docs/wiki/` 존재 시만 | 존재 시만 | wiki 미사용(외부 install) 프로젝트 노이즈 0 (NFR) |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — phase-19 가 wiki 컨벤션/스키마를 이미 정립. 본 spec 은 운영 도구로 신규 아키텍처 결정 없음.

## 💬 사용자 협의

- **주제**: C1(wiki 도구) 착수 방식
  - **사용자 의견**: 권장안대로 신규 Phase(SDD-P) 진행
  - **합의**: phase-19 미완 도구를 phase-23 으로 승계, non-base 모드, spec-23-01(ingest)부터
- **주제**: spec 스코프 (실측 기반 정정)
  - **합의**: adr.md·rca.md 는 이미 `🔗 Related` 보유 → 신설 아닌 보강. archive 힌트는 `docs/wiki/` 게이트. 통합 테스트는 spec-23-02 로 분리

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: `bash tests/test-sdd-dir-archive.sh`
- **결과**: ✅ Passed (20/0) — Check 10(docs/wiki 존재→힌트), Check 11(부재→노이즈 0) 신규
- **회귀**: `bash tests/test-wiki-structure.sh` → ✅ 32/32 PASS (템플릿 frontmatter 무회귀)

### 2. 수동 검증

1. **Action**: `hk-wiki-ingest.md` 가 `hk-archive.md` 와 동형(frontmatter + 단계 지시 + 결과 보고)인지 육안
   - **Result**: 4단계 워크플로 + hallucination 방지(원문 인용) 명시 확인
2. **Action**: `grep -l '관련 문서' sources/templates/{spec,walkthrough}.md` + adr/rca 의 `[[wikilink]]` 안내
   - **Result**: 4종 모두 Related/`[[` 확인

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Gemini cross-model) |
| **결과 파일** | `specs/spec-23-01-wiki-ingest/code-review-gemini.md` |
| **요약** | **Approve** — Critical 0 / Major 0 / Minor 1 |
| **Minor 처리** | Related 섹션 위치 통일 권고 → 무변경 (권고 규칙을 현행이 이미 충족, 위 결정 기록 참조) |

## 🔍 발견 사항

- adr.md·rca.md 템플릿이 이미 `🔗 Related` 섹션 보유 → 스코프 2종(spec/walkthrough)으로 축소.
- `docs/wiki/purpose.md` 운영규칙 #2(log/index 수동)와 ingest 워크플로(spec-19-02)의 미세 긴장 — 본 spec 에서 "ingest=이벤트 append/인벤토리 refresh, 사람=구조 큐레이션" 으로 reconcile. 규칙 문구 자체 개정은 미수행(스코프 외).

## 🚧 이월 항목

- `sdd doctor` wiki 점검 3종 + `tests/test-wiki.sh` → **spec-23-02** (phase-23 계획 내, 별도 신규 항목 아님).

## 🔗 관련 문서 (Related)
- 후속 spec: [[spec-23-02]]
- wiki 스키마: [[wiki/purpose]]
- Phase: `backlog/phase-23.md`

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-16 |
| **최종 commit** | `988b7db` (+ ship commit) |
