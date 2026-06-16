# feat(spec-23-01): hk-wiki-ingest 커맨드 및 템플릿 wikilink 연동

## 📋 Summary

### 배경 및 목적

phase-19 가 `docs/wiki/` 지식 레이어 토대만 깔고 *갱신 워크플로*를 deferred 했다. 한 번 합성된 wiki 는 archive 가 쌓여도 stale 해지고, artifact 템플릿의 `[[wikilink]]` 역참조도 불균일했다. 본 spec 은 archive 후 wiki 를 갱신하는 표준 커맨드를 신설하고 템플릿 Related 연결을 정비한다 (phase-23 의 첫 spec).

### 주요 변경 사항
- [x] `/hk-wiki-ingest` 슬래시 커맨드 신설 — archived walkthrough → decisions/patterns 증류 → log/index 갱신 4단계 워크플로 (hallucination 방지: 원문 인용 강제)
- [x] 템플릿 `[[wikilink]]` Related 정비 — spec.md·walkthrough.md 신설, adr.md·rca.md 기존 섹션 보강
- [x] `sdd archive` 후처리 힌트 — `docs/wiki/` 존재 시에만 `/hk-wiki-ingest` 권장 (외부 install 노이즈 0)

### Phase 컨텍스트
- **Phase**: `phase-23` (wiki 운영 도구)
- **본 SPEC 의 역할**: wiki "만들고 → 갱신" 루프의 *갱신* 측. 후속 spec-23-02 가 *건강 점검* 추가.

## 🎯 Key Review Points

1. **archive 힌트 게이트**: `[ -d "$SDD_ROOT/docs/wiki" ]` 조건부 출력 — wiki 미사용 프로젝트 노이즈 방지 (TDD Check 10/11 로 양 케이스 검증).
2. **템플릿 스코프**: adr/rca 는 이미 Related 보유라 *보강*만(중복 신설 금지). spec/walkthrough 만 신설.

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-sdd-dir-archive.sh
bash tests/test-wiki-structure.sh
```

**결과 요약**:
- ✅ `test-sdd-dir-archive.sh`: 20/0 PASS (Check 10/11 신규)
- ✅ `test-wiki-structure.sh`: 32/32 PASS (회귀 없음)

### 수동 검증 시나리오
1. **커맨드 동형성**: `hk-wiki-ingest.md` 가 `hk-archive.md` 패턴 준수 → 4단계 명확
2. **템플릿 Related**: 4종 모두 `[[wikilink]]` 안내 보유

### 코드 리뷰
- Gemini cross-model: **Approve** (Critical 0 / Major 0 / Minor 1 — Related 위치, 무변경 처리). 상세: `specs/spec-23-01-wiki-ingest/code-review-gemini.md`

## 📦 Files Changed

### 🆕 New Files
- `sources/commands/hk-wiki-ingest.md`: wiki 갱신 슬래시 커맨드

### 🛠 Modified Files
- `sources/templates/{spec,walkthrough}.md`: `🔗 관련 문서 (Related)` 섹션 신설
- `sources/templates/{adr,rca}.md`: 기존 Related 에 `[[wikilink]]` 안내 보강
- `sources/bin/sdd`: `cmd_archive` 말미 wiki 힌트 (게이트)
- `tests/test-sdd-dir-archive.sh`: Check 10/11 추가

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과
- [x] 통합 테스트는 spec-23-02 로 분리 (본 spec Integration Test Required = no)
- [x] `walkthrough.md` ship commit 완료
- [x] `pr_description.md` ship commit 완료
- [x] 코드 리뷰 (Gemini Approve)
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Phase: `backlog/phase-23.md`
- Walkthrough: `specs/spec-23-01-wiki-ingest/walkthrough.md`
- 후속: spec-23-02 (sdd doctor wiki 점검 + test-wiki.sh)
