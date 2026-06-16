# spec-23-02: sdd doctor wiki/문서 건강 점검 & test-wiki.sh

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-23-02` |
| **Phase** | `phase-23` |
| **Branch** | `spec-23-02-wiki-doctor` |
| **상태** | Planning |
| **타입** | Feature |
| **Integration Test Required** | yes (`tests/test-wiki.sh` — phase-23 통합 테스트) |
| **작성일** | 2026-06-16 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

phase-19 가 `docs/wiki/` 토대를, spec-23-01 이 `/hk-wiki-ingest` 갱신 워크플로 + 템플릿 `[[wikilink]]` 연결을 깔았다. 그러나 `sdd doctor` 는 wiki/문서 레이어의 건강을 전혀 점검하지 못한다 (`ignore 위생` 등 다른 점검만 존재). phase-19 가 약속한 `tests/test-wiki.sh` 도 부재.

### 문제점

- **고아 `[[wikilink]]` 무감지**: 참조 대상이 사라진 `[[link]]` 가 조용히 누적 → 지식 그래프 간선 끊김.
- **stale 결정문서 무감지**: 오래된 ADR/RCA 가 wiki 로 증류되지 않은 채 방치 → "결정 즉시 참조" 목적 훼손.
- **거버넌스 비대화 무감지**: constitution+agent.md 단어수가 상한(ADR-012, 6500w)을 넘어도 `test-governance-dedup` 실행 전엔 모름. doctor 에 조기 경고 없음.

### 해결 방안 (요약)

`sdd doctor` 에 "wiki/문서 건강" 점검 3종(고아 링크 / 90일+ stale ADR·RCA / governance 단어수 상한)을 추가하고, 이를 회귀 검증하는 `tests/test-wiki.sh` 를 신설한다. 모두 *경고(warn)* 수준 — 차단하지 않는다(hook 단계론).

## 🎯 요구사항

### Functional Requirements

1. **고아 `[[wikilink]]` 점검**: `docs/wiki/*.md` 의 `[[...]]` 토큰을 추출·해석해 대상 부재 시 경고. 해석 규칙(`docs/wiki/purpose.md`):
   - `[[wiki/X]]` → `docs/wiki/X.md`
   - `[[ADR-NNN]]` → `docs/decisions/ADR-NNN-*.md` (glob)
   - `[[RCA-NNN]]` → `docs/rca/RCA-NNN-*.md` (glob)
   - `[[spec-NN-NN]]` → `specs/spec-NN-NN-*/` 또는 `archive/specs/spec-NN-NN-*/` (archive fallback — A1 stale-ADR 교훈)
2. **90일+ stale ADR/RCA 점검**: `docs/decisions/ADR-*.md`·`docs/rca/RCA-*.md` 의 frontmatter `updated:`(없으면 `date:`) 가 today-90일 이전이면 경고. clone-stable 위해 mtime 아닌 *frontmatter 날짜* 사용. cutoff 는 이식성 분기(GNU `date -d`/BSD `date -v`) + `YYYY-MM-DD` 문자열 비교.
3. **governance 단어수 상한 점검**: `.harness-kit/agent/constitution.md` + `agent.md` 의 `wc -w` 합계가 6500(ADR-012) 초과 시 경고. (측정 방식 = `test-governance-dedup.sh` Check 3 와 동일).
4. **`tests/test-wiki.sh` 신설**: 위 3종을 fixture 기반 회귀 검증 + 템플릿 Related 섹션 존재(spec-23-01 산출물) 검증 — phase-23 통합 테스트 시나리오 1~2 커버.

### Non-Functional Requirements

1. bash 3.2+ / macOS BSD `date` 호환 (이식성 분기 필수).
2. 대상 디렉토리(`docs/wiki`, `docs/decisions`, `docs/rca`) 부재 시 각 점검 silent skip — 외부 install 노이즈 0.
3. 모든 점검은 `_doc_warn`(경고) — `_doc_fail`(차단) 아님. 외부 URL/`org/repo` 형 토큰 오탐 제외(A1 교훈).
4. 산출물 한국어.

## 🚫 Out of Scope

- 발견된 고아 링크/stale 문서의 *자동 수정* — 본 점검은 경고만 (수정은 `/hk-wiki-ingest` 또는 수동).
- 분기별 governance prune 프로토콜 (별도 Icebox).
- `_drift_stale_adr`(backtick missing-path, 별개 메커니즘) 변경.

## 📑 ADR 후보 (Architecture Decision Records)

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — phase-19/ADR-012 가 컨벤션·상한을 이미 정립. 본 spec 은 점검 구현으로 신규 아키텍처 결정 없음. (stale 정의 "frontmatter date, not mtime" 는 walkthrough 결정 기록으로 충분)

## ✅ Definition of Done

- [ ] doctor 3종 점검 + `tests/test-wiki.sh` 단위 테스트 PASS
- [ ] phase-23 통합 테스트(`test-wiki.sh`) 시나리오 PASS
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-23-02-wiki-doctor` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
