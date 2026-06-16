# phase-23: wiki 운영 도구 (wiki-tooling)

> 본 phase 의 모든 SPEC 을 한 파일에 요점/방향성으로 나열합니다.
> *구체적* 작업 내용은 `specs/spec-23-{seq}-{slug}/spec.md` 에서 다룹니다.
>
> 본 문서는 "이번 phase 에서 무엇을 어디까지 할 것인가" 를 한 번에 보기 위한 *업무 지도* 입니다.

## 📋 메타

| 항목 | 값 |
|---|---|
| **Phase ID** | `phase-23` |
| **상태** | In Progress |
| **시작일** | 2026-06-16 |
| **목표 종료일** | 2026-06-23 |
| **소유자** | Leo |
| **Base Branch** | 없음 (각 spec PR → main 직접) |

## 🎯 배경 및 목표

### 현재 상황

phase-19(문서 지식 그래프)는 wiki *토대*만 깔고 운영 도구를 deferred 한 채 완료됐다. 현재 `docs/wiki/` 에 5개 페이지(`index.md`·`log.md`·`decisions.md`·`patterns.md`·`purpose.md`)와 `[[wikilinks]]` 컨벤션이 spec-19-01 로 부트스트랩돼 있으나, 다음 두 운영 도구가 비어 있다.

- **갱신 워크플로 부재**: archive 후 wiki 를 최신화하는 표준 절차(`/hk-wiki-ingest`)가 없어, wiki layer 가 한 번 만들어진 뒤 stale 해질 위험. 템플릿(spec/walkthrough/adr/rca)에도 `[[wikilinks]]` "관련 문서" 섹션이 없어 raw↔wiki 역참조가 끊긴다.
- **건강 점검 부재**: `sdd doctor` 가 wiki 고아 링크·미참조 결정문서·governance 비대화를 감지하지 못해, drift 가 조용히 누적된다. phase-19 가 약속한 `test-wiki.sh` 도 부재.

### 목표 (Goal)

phase-19 의 wiki 토대 위에 **유지보수 도구 2종**을 완성해, wiki layer 가 실제로 "만들고 → 갱신하고 → 건강을 점검"하는 닫힌 루프를 갖추게 한다. phase-19 의 미완 wiki 도구(19-02·19-03)를 승계해 정리한다.

> **스코프 제외 (이미 처리/분리됨)**:
> - 19-03 의 "root CLAUDE.md 슬림화" → 이미 spec-x-claude-md-slim(#135)으로 완료.
> - "분기별 governance prune protocol" → 별도 Icebox 항목으로 분리 (본 phase 는 *경고*까지만, prune *프로토콜*은 OOS).

### 성공 기준 (Success Criteria) — 정량 우선

1. `sources/commands/hk-wiki-ingest.md` 신규 슬래시 커맨드 존재 + 4단계 워크플로(archived walkthrough 읽기 → decisions/patterns 갱신 → log 기록 → index 갱신) 명시.
2. `sources/templates/` 의 spec.md / walkthrough.md / adr.md / rca.md 에 `[[wikilinks]]` "관련 문서 (Related)" 섹션 반영.
3. `sdd archive` 실행 시 후처리 힌트(`→ /hk-wiki-ingest 로 wiki 갱신 권장`) 출력.
4. `sdd doctor` 가 ① wiki 고아 `[[wikilink]]` ② 90일+ 미참조 ADR/RCA ③ governance 단어 수 상한 초과 를 각각 경고.
5. `tests/test-wiki.sh` 신규 — 위 doctor 점검 3종 + 템플릿 Related 섹션 존재를 회귀 검증, 전 시나리오 PASS.

## 🧩 작업 단위 (SPECs)

> 본 표는 phase 의 *작업 지도* 입니다. SPEC 은 *요점 + 방향성 + 참조* 까지만 적습니다.
> 자세한 spec/plan/task 는 `specs/spec-23-{seq}-{slug}/` 에서 작성합니다.
> sdd 가 `<!-- sdd:specs:start --> ~ <!-- sdd:specs:end -->` 사이를 자동 갱신하므로 마커는 그대로 두세요.

<!-- sdd:specs:start -->
| ID | 슬러그 | 우선순위 | 상태 | 디렉토리 |
|---|---|:---:|---|---|
| `spec-23-01` | wiki-ingest | P? | Merged | `specs/spec-23-01-wiki-ingest/` |
<!-- sdd:specs:end -->

> 상태 허용값: `Backlog` / `In Progress` / `Merged`
> sdd가 ship 시 자동으로 `Merged`로 갱신합니다. `In Progress`는 active spec에 자동 마킹됩니다.

### spec-23-01 — hk-wiki-ingest 슬래시 커맨드 & 템플릿 연동

- **요점**: archive 후 Claude 가 wiki 를 갱신하는 표준 워크플로(`/hk-wiki-ingest`) + 모든 artifact 템플릿에 `[[wikilinks]]` "관련 문서" 섹션 추가.
- **방향성**:
  - `sources/commands/hk-wiki-ingest.md` 신규: ① 최근 archived spec 의 walkthrough.md 읽기 → ② `docs/wiki/decisions.md`·`patterns.md` 갱신(원문 인용 원칙, hallucinate 방지) → ③ `docs/wiki/log.md` 인제스트 이벤트 기록 → ④ `docs/wiki/index.md` 카탈로그 갱신.
  - `sources/templates/{spec,walkthrough,adr,rca}.md` 에 "관련 문서 (Related)" 섹션 추가(`[[spec-id]]`·`[[ADR-NNN]]`·`[[wiki/page]]`).
  - `sources/bin/sdd` archive 후처리에 힌트 출력 한 줄 추가.
- **참조**: archived `phase-19.md` spec-19-02, 기존 `sources/commands/` 슬래시 커맨드 패턴, `docs/wiki/purpose.md`(스키마).
- **연관 모듈**: `sources/commands/hk-wiki-ingest.md`(신규), `sources/templates/{spec,walkthrough,adr,rca}.md`, `sources/bin/sdd`(archive 후처리).

### spec-23-02 — sdd doctor wiki/문서 건강 점검 & test-wiki.sh

- **요점**: `sdd doctor` 에 문서 건강 점검 3종 추가 + 회귀 테스트 `test-wiki.sh` 신설.
- **방향성**:
  - doctor 신규 점검: ① `docs/wiki/` 의 `[[wikilink]]` 고아 링크(참조 대상 파일 부재) 감지 ② `docs/decisions/`·`docs/rca/` 중 90일+ 미참조 경고 ③ governance(`constitution.md`·`agent.md`) 단어 수 상한 초과 경고(상한값은 ADR-012 기준 재확인).
  - 기존 `_drift_stale_adr`(backtick 경로 missing) 와 **구분** — 본 점검은 `[[wikilink]]` 고아 + *시간 기반* stale(90일+) 로 성격이 다름.
  - `tests/test-wiki.sh`: fixture 기반으로 3종 점검 + 템플릿 Related 섹션을 회귀 검증.
- **참조**: archived `phase-19.md` spec-19-03, `docs/decisions/ADR-012-governance-word-budget.md`, 기존 `sources/bin/sdd` `ignore 위생` 점검 패턴.
- **연관 모듈**: `sources/bin/sdd`(doctor 서브커맨드), `tests/test-wiki.sh`(신규).

## 📌 결정 기록 (Review)

> Phase PR review 중 발생한 결정·합의·발견을 누적합니다. Spec walkthrough 의 결정 기록과 동일 패턴이며 Phase 레벨 living decision log 역할 (→ agent.md §6.3.2).

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| phase-19 미완 승계 방식 | 19 revive vs 신규 phase | 신규 phase-23 | phase-19 는 이미 archive/완료. 신규 phase 가 깔끔 |
| governance prune 포함 여부 | 경고만 vs prune 프로토콜까지 | 경고만 (본 phase) | prune 프로토콜은 중앙 규약 변경이라 별도 Icebox 분리. 본 phase 는 doctor 경고까지 |

## 🧪 통합 테스트 시나리오 (간결)

> 본 phase 의 Done 조건 중 하나. 구현 위치: `tests/test-wiki.sh`.

### 시나리오 1: sdd doctor → wiki 고아 링크 + stale 문서 감지

- **Given**: `docs/wiki/` 에 존재하지 않는 대상을 가리키는 `[[wikilink]]` 1개 이상, 그리고 90일+ 미참조 ADR/RCA fixture.
- **When**: `sdd doctor` 실행.
- **Then**: `⚠ 고아 wiki 링크 N개` + `⚠ stale 결정문서 N개(90일+)` 경고 출력.
- **연관 SPEC**: spec-23-02.

### 시나리오 2: 템플릿 Related 섹션 + archive 힌트

- **Given**: spec-23-01 머지 후 상태.
- **When**: `sources/templates/{spec,walkthrough,adr,rca}.md` 검사 + `sdd archive` 실행.
- **Then**: 4개 템플릿 모두 "관련 문서 (Related)" 섹션 보유 + archive 출력에 `/hk-wiki-ingest 권장` 힌트.
- **연관 SPEC**: spec-23-01.

### 시나리오 3 (수동/반자동): /hk-wiki-ingest → wiki 갱신

- **Given**: `sdd archive` 후 신규 archived spec 존재.
- **When**: `/hk-wiki-ingest` 실행.
- **Then**: `docs/wiki/log.md` 에 타임스탬프 + 인제스트 대상 기록, `index.md` 카탈로그 갱신.
- **비고**: LLM 워크플로라 완전 자동 단언 대신 *구조 검증*(log/index 갱신 여부) 위주. 내용 정확성은 사람 검증.
- **연관 SPEC**: spec-23-01.

### 통합 테스트 실행
```bash
bash tests/test-wiki.sh
bash tests/test-doctor.sh
```

## 🔗 의존성

- **선행 phase**: phase-19 (wiki 토대 `docs/wiki/` 부트스트랩 — 이미 Merged)
- **외부 시스템**: 없음
- **연관 ADR**:
  - `docs/decisions/ADR-001-knowledge-types.md`
  - `docs/decisions/ADR-012-governance-word-budget.md`

## 📝 위험 요소 및 완화

| 위험 | 영향 | 완화책 |
|---|---|---|
| `/hk-wiki-ingest` 가 wiki 내용을 hallucinate | 잘못된 결정 참조 누적 | walkthrough.md 원문 인용 원칙 + "출처: spec-XX walkthrough §결정" 명시 강제 |
| 고아 링크 점검이 정상 외부참조(GitHub repo 등)를 오탐 | doctor 노이즈 (A1 의 stale-ADR 오탐과 동류) | `[[...]]` 내부 링크만 대상, 외부 URL/`org/repo` 형태 제외 |
| 90일 기준이 자주 갱신되는 ADR 을 stale 로 오판 | 불필요 경고 | "미참조" = mtime 또는 wiki/spec 역참조 부재 기준으로 한정, 단순 파일 나이 아님 |

## 🏁 Phase Done 조건

- [ ] 모든 SPEC(23-01, 23-02) 이 main 으로 merge
- [ ] 통합 테스트(`test-wiki.sh`) 전 시나리오 PASS
- [ ] 성공 기준 1~5 정량 측정 결과 기록 (본 문서 하단 "검증 결과")
- [ ] 사용자 최종 승인 (`/hk-phase-ship` go/no-go)

## 📊 검증 결과 (phase 완료 시 작성)

<!-- 통합 테스트 로그, 성공 기준 측정값, 회귀 점검 결과 등을 여기 첨부 -->
