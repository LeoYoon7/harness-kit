# chore(spec-x-md-lf-normalize): `*.md` LF 라인 엔딩 통일 (.gitattributes + 일괄 normalize)

## 📋 Summary

### 배경 및 목적

직전 PR (`spec-x-gemini-review`, #6) 에서 `.claude/commands/hk-ship.md` 의 sync drift 가 발생했고, 원인 조사 결과 본 키트의 `*.md` 파일들이 OS 별로 CRLF/LF mixed 상태였음을 확인. 실측 638/686 (CRLF/total).

본 PR 은 `.gitattributes` 에 `*.md text eol=lf` 1줄을 추가하고 `git add --renormalize .` 로 일괄 LF 정규화 + 수동 작업트리 disk refresh 로 OS 무관 일관성 보장.

### 주요 변경 사항

- [x] `.gitattributes` 에 `*.md text eol=lf` 추가 (기존 `*.sh text eol=lf` 유지)
- [x] `git add --renormalize .` 로 인덱스 LF 정규화 — 29 *.md + 부수적으로 `sources/bin/bb-pr` (확장자 없는 bash) + `version.json` 까지 30 파일 (모두 byte-identical, 라인 엔딩만 변경)
- [x] 수동 `tr -d '\r'` 루프로 작업트리 disk 의 CRLF 잔재 정리 — git smudge filter 가 stat-cache 한계로 자동 적용 안 되어 명시적 변환 필요
- [x] 검증: working tree CRLF *.md = 0, `sdd status` dogfood drift 경고 사라짐

### Phase 컨텍스트

- **Phase**: 없음 (spec-x — Solo Spec)
- **본 SPEC 의 역할**: 키트 cross-platform 일관성 확보 + 향후 sync drift 발생 source 차단

## 🎯 Key Review Points

1. **`.gitattributes` 1줄 추가** — 가장 중요한 변경. 향후 모든 클론에 LF 강제. PR 리뷰의 핵심 1줄.
2. **거대한 diff 의 본질** — 638+ 파일 변경 표시되나 모두 라인 엔딩만 변경, 내용 byte-identical. `git diff -w` 또는 `git diff --ignore-cr-at-eol` 로 보면 차이 없음. 리뷰 시 `git log --oneline` 와 commit subject 만 확인하면 충분.
3. **archive/ immutability 호환** — archive/specs/* 는 "내용 immutable" 정책. 본 PR 의 변경은 라인 엔딩만이라 내용 무변경 — immutability 정신 위배 아님.
4. **부수 효과 (의도적 수용)** — `sources/bin/bb-pr` (확장자 없는 bash 스크립트) 와 `version.json` 도 LF 통일됨. 키트의 bash LF 강제 원칙과 일치하므로 유익.
5. **사용자 환경 별도 권고** — `git config --global core.autocrlf input` 을 사용자가 1회 설정. 본 PR 미포함 — 사용자 직접 작업. 설정 후에는 새 commit 에 자동 LF 적용.

## 🧪 Verification

### 수동 검증 시나리오

1. **사전 / 사후 CRLF 카운트**
   ```bash
   find . -name "*.md" -not -path "./.git/*" | xargs file | grep -c CRLF
   ```
   - 사전: `638`
   - 사후: `0` ✓

2. **dogfood drift 해소 확인**
   ```bash
   bash .harness-kit/bin/sdd status
   ```
   - 사후: "도그푸딩 sync" 경고 사라짐 ✓

3. **내용 무변경 sample**
   ```bash
   git show HEAD~2:README.md | tr -d '\r' | diff - README.md
   ```
   - 결과: 차이 없음 ✓

4. **rendering 검증** — markdown viewer / GitHub UI 에서 일반 표시 정상 (CRLF→LF 가 표시에 영향 없음).

## 📦 Files Changed

### 🛠 Modified Files

#### 핵심 파일 (논리적 변경 있음)
- `.gitattributes` (+3): 마크다운 LF 규칙 + 주석 추가

#### 라인 엔딩만 변경 (내용 byte-identical, 600+ 파일)
- `archive/specs/**/*.md` (대부분)
- `specs/**/*.md`
- `sources/**/*.md`, `sources/bin/bb-pr`
- `.harness-kit/**/*.md`
- `.claude/commands/*.md`
- `backlog/*.md`
- `docs/**/*.md`
- `README.md`, `CHANGELOG.md`, `CLAUDE.md`
- `version.json`

### 🆕 New Files

- `specs/spec-x-md-lf-normalize/{spec,plan,task,walkthrough,pr_description}.md`

## ✅ Definition of Done

- [x] `.gitattributes` 에 `*.md text eol=lf` 추가
- [x] `git add --renormalize .` 로 인덱스 LF 정규화
- [x] 잔여 CRLF *.md 파일 0 (working tree disk)
- [x] `sdd status` dogfood drift 경고 사라짐
- [x] 내용 무변경 검증 (README.md sample) PASS
- [x] `walkthrough.md` + `pr_description.md` ship commit
- [x] (예정) push + PR 생성 + 사용자 알림

## 🔗 관련 자료

- Spec: `specs/spec-x-md-lf-normalize/spec.md`
- Plan: `specs/spec-x-md-lf-normalize/plan.md`
- Walkthrough: `specs/spec-x-md-lf-normalize/walkthrough.md`
- 직전 PR (drift 발견 계기): #6 `spec-x-gemini-review`
- 관련 ADR: (없음)
- 후속 권고 (사용자 직접): `git config --global core.autocrlf input`
