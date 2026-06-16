# feat(spec-23-02): sdd doctor wiki/문서 건강 점검 3종 + test-wiki.sh

## 📋 Summary

### 배경 및 목적

phase-19 가 `docs/wiki/` 토대를, spec-23-01 이 갱신 워크플로·템플릿 `[[wikilink]]` 를 깔았으나 `sdd doctor` 는 wiki/문서 레이어 건강을 점검하지 못했다. 본 spec 은 건강 점검 3종을 추가하고 phase-23 통합 테스트 `test-wiki.sh` 를 신설한다 (phase-23 의 마지막 spec).

### 주요 변경 사항
- [x] **(c) governance 단어수**: `.harness-kit/agent/{constitution,agent}.md` `wc -w` 합 > 6500(ADR-012) 경고
- [x] **(a) 고아 `[[wikilink]]`**: `docs/wiki/` 스캔 → prefix glob 해석(spec archive fallback). 오탐 방지(purpose.md 제외 + concrete-format)
- [x] **(b) 90일+ stale ADR/RCA**: frontmatter `updated:`/`date:` vs cutoff(GNU/BSD `date` 이식성). mtime 아닌 clone-stable 날짜
- [x] **`tests/test-wiki.sh`** 신설 — 3종 + 템플릿 Related 회귀 (14 케이스)

### Phase 컨텍스트
- **Phase**: `phase-23` (wiki 운영 도구) — 본 spec 으로 2/2 완료 → phase done 준비
- **역할**: wiki "만들고 → 갱신 → **건강 점검**" 루프의 점검 측

## 🎯 Key Review Points

1. **날짜 이식성 (b)**: `date -d '90 days ago'`(GNU) `||` `date -v-90d`(BSD) + `YYYY-MM-DD` 문자열 비교. set -e 안전(`|| true`, if/then).
2. **고아 링크 오탐 방지 (a)**: purpose.md(컨벤션 문서) 제외 + concrete 포맷(ADR-숫자 등)만 검증 — placeholder(`ADR-NNN`) 무시. A1 교훈.
3. 모든 점검 `_doc_warn`(경고) + 대상 부재 silent skip (노이즈 0).

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-wiki.sh
bash tests/test-hk-doctor.sh
bash tests/test-doctor-ignore-coverage.sh
```

**결과 요약**:
- ✅ `test-wiki.sh`: 14/14 PASS
- ✅ `test-hk-doctor.sh`: 7/7 · `test-doctor-ignore-coverage.sh`: 10/10 (cmd_doctor 무회귀)

### 수동 검증 시나리오
1. 실제 레포 `sdd doctor` → wiki/문서 건강 3종 전부 PASS (단어수 6400w / 고아 0 / stale 0), 오탐 0.

### 코드 리뷰
- Gemini cross-model: **Approve (with Comments)** — Critical 0 / Major 1(수정됨 `45bfbb4`) / Minor 2(근거와 함께 무변경). 상세: `code-review-gemini.md` + `walkthrough.md`.

## 📦 Files Changed

### 🆕 New Files
- `tests/test-wiki.sh`: phase-23 통합 테스트

### 🛠 Modified Files
- `sources/bin/sdd`: `cmd_doctor` 에 "wiki/문서 건강" 섹션 3종 점검 추가

## ✅ Definition of Done

- [x] doctor 3종 + `test-wiki.sh` 단위/통합 테스트 PASS
- [x] doctor 회귀 무손상
- [x] 코드 리뷰 (Gemini, Major 수정)
- [x] `walkthrough.md` / `pr_description.md` ship
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Phase: `backlog/phase-23.md` (본 spec 으로 완료)
- Walkthrough: `specs/spec-23-02-wiki-doctor/walkthrough.md`
- 관련 ADR: `docs/decisions/ADR-012-governance-word-budget.md`
