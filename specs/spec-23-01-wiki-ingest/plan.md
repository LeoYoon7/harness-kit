# Implementation Plan: spec-23-01

## 📋 Branch Strategy

- 신규 브랜치: `spec-23-01-wiki-ingest` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> 본 Plan 을 Accept 하기 전에 사용자가 명시적으로 확인해야 할 항목들.

> [!IMPORTANT]
> - [ ] **템플릿 스코프 정정**: adr.md·rca.md 는 이미 `## 🔗 Related` 보유 → *신설 아닌 보강*. 신규 Related 섹션은 spec.md·walkthrough.md 2종만.
> - [ ] **archive 힌트 게이트**: `docs/wiki/` 존재 시에만 출력 (외부 install 대상 노이즈 방지).
> - [ ] **통합 테스트 분리**: phase 통합 테스트 `test-wiki.sh` 는 spec-23-02. 본 spec 은 archive 힌트 단위 테스트만.

> [!WARNING]
> - [ ] 템플릿 변경은 *키트 원본* (`sources/templates/`) 시점 — 이미 install 된 프로젝트는 `update.sh` 전까지 미반영 (CLAUDE.md 두 시점 원칙).

## 🎯 핵심 전략 (Core Strategy)

### 아키텍처 컨텍스트

`/hk-wiki-ingest` 는 코드가 아닌 *프롬프트 워크플로 문서* (다른 `hk-*` 커맨드와 동일 — `sources/commands/hk-archive.md` 패턴). 실제 wiki 갱신은 Claude 가 커맨드 지시를 따라 수행. sdd 변경은 archive 완료 후 이 커맨드를 권하는 힌트 한 줄뿐.

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **hk-wiki-ingest.md** | 순수 지시 문서 (frontmatter `description:` + 4단계) | 기존 슬래시 커맨드와 동형. 코드 무관, 컨텍스트 비용 0 |
| **템플릿 Related** | spec/walkthrough 신설 + adr/rca 보강 | 중복 섹션 방지 — 실측상 adr/rca 는 이미 보유 |
| **archive 힌트** | `cmd_archive` 말미 `[ -d docs/wiki ]` 게이트 echo | wiki 미사용 프로젝트 노이즈 0, ingest 워크플로 연결 |
| **테스트** | `test-sdd-dir-archive.sh` 확장 (힌트 유/무 단언) | 기존 archive fixture 재사용 (git-init/main 고정 등 검증된 인프라) |

### 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — phase-19 가 wiki 컨벤션을 이미 정립.

## 📂 Proposed Changes

### 슬래시 커맨드

#### [NEW] `sources/commands/hk-wiki-ingest.md`
- frontmatter `description:` + 4단계 워크플로 (archived walkthrough 읽기 → decisions/patterns 갱신 → log 기록 → index 갱신).
- hallucinate 방지: walkthrough 원문 인용 + "출처: spec-XX §결정" 명시 지시.
- `docs/wiki/purpose.md` 의 frontmatter 스키마(`type`/`sources`/`updated`/`linked`) 참조 지시.

### 템플릿

#### [NEW 섹션] `sources/templates/spec.md`, `sources/templates/walkthrough.md`
- 말미에 `## 🔗 관련 문서 (Related)` 추가 — `[[spec-id]]`·`[[ADR-NNN]]`·`[[wiki/page]]` 작성 가이드 주석 포함.

#### [MODIFY] `sources/templates/adr.md`, `sources/templates/rca.md`
- 기존 `## 🔗 Related` 섹션에 `[[wikilink]]` 컨벤션 안내 한 줄 보강 (섹션 신설 금지).

### sdd

#### [MODIFY] `sources/bin/sdd` (`cmd_archive`, ~L2340 `ok "...→ archive/"` 직후)
```text
[ -d "$SDD_ROOT/docs/wiki" ] && printf "  → %s\n" "/hk-wiki-ingest 로 wiki 갱신 권장"
```

### 테스트

#### [MODIFY] `tests/test-sdd-dir-archive.sh`
- fixture 에 `docs/wiki/` 존재 케이스 → archive 출력에 `/hk-wiki-ingest` 힌트 포함 단언.
- `docs/wiki/` 부재 케이스 → 힌트 미포함 단언.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
bash tests/test-sdd-dir-archive.sh
```

### 수동 검증 시나리오
1. `/hk-wiki-ingest` 커맨드 문서 가독성 — 4단계가 Claude 가 따라할 수 있게 명확한가.
2. `sources/templates/{spec,walkthrough}.md` 에 Related 섹션 존재 — `grep -l '관련 문서'`.
3. `sources/templates/{adr,rca}.md` Related 섹션에 `[[wikilink]]` 안내 존재.
4. 로컬에서 `docs/wiki/` 있는 상태로 `sdd archive --dry-run` 후 실제 archive 시 힌트 출력 육안 확인.

## 🔁 Rollback Plan

- 전부 추가/문서 변경이라 영향 격리. 문제 시 해당 커밋 `git revert`.
- sdd 힌트는 게이트(`[ -d docs/wiki ]`)라 회귀 위험 최소 — 최악의 경우 한 줄 제거.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
