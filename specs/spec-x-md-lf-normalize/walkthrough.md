# Walkthrough: spec-x-md-lf-normalize

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| Normalize 범위 | A) repo 전체 (archive/ 포함) / B) kit 영역만 / C) sources 채움 영역만 | A | 사용자 명시 결정 (AskUserQuestion, 2026-05-28). archive/ immutability 는 "내용" 기준이라 라인 엔딩 정규화 무관 |
| Working tree refresh 방식 | A) `git checkout-index --force --all` / B) `git rm --cached` + `reset --hard` / C) 수동 `tr -d '\r'` 루프 | C | A 미시도 + B 권한 차단됨. C 가 가장 안전 (git 상태 무영향, 파일 byte 만 변경) |
| Out-of-scope 부수 효과 | A) 무시 / B) unstage / C) 받아들이고 walkthrough 에 기록 | C | `git add --renormalize` 가 `sources/bin/bb-pr` (확장자 없는 bash) 와 `version.json` 도 normalize 함. 키트의 LF 원칙과 일치 — 유익한 fix |
| `autocrlf` global config | A) agent 가 실행 / B) 사용자 권고만 | B | global git config 변경은 사용자 환경 변화. agent 가 임의 실행 부적절 |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — `.gitattributes` 의 `*.md text eol=lf` 는 표준 git 메커니즘. ADR 가치 낮음

## 💬 사용자 협의

- **주제**: 직전 PR (spec-x-gemini-review) 의 dogfood drift 경고 원인 파악
  - **사용자 의견**: "Windows 기반이라 종종 발생할텐데 모든 프로젝트에 .gitattributes 를 생성해야 된단말?"
  - **합의**: 본 키트 (cross-platform OSS) 에만 `.gitattributes` 추가. 사용자 본인 환경은 `git config --global core.autocrlf input` 1회 설정 권고
- **주제**: Normalize 범위 (3지선다)
  - **사용자 선택**: A — repo 전체 (archive/ 포함)
  - **합의**: 638 *.md 일괄 LF 통일

## 🧪 검증 결과

### 1. 자동화 테스트 (해당 없음)

bash + 마크다운 변경이라 단위 테스트 미적용. 검증은 수동 카운트 + sdd status 로 수행.

### 2. 수동 검증

1. **Action**: 사전 카운트 — `find . -name "*.md" -not -path "./.git/*" | xargs file | grep -c CRLF`
   - **Result**: `638` (CRLF 다수파)
2. **Action**: `.gitattributes` 에 `*.md text eol=lf` 추가
   - **Result**: commit `5318967`
3. **Action**: `git add --renormalize .` 실행
   - **Result**: 29 *.md + 1 `sources/bin/bb-pr` + 1 `version.json` = 30 파일 staged. 내용 byte-identical (2666 insertions = 2666 deletions, 라인 엔딩만). task.md 1개는 session 진행 중 편집이라 unstage. 나머지 29개 commit `87c3979`.
4. **Action**: Working tree disk refresh — `git checkout HEAD -- "*.md"` 시도
   - **Result**: smudge filter 가 stat-cache 때문에 미적용. Working tree 의 CRLF 잔재 그대로.
5. **Action**: `git rm --cached -r .` + `git reset --hard` 시도
   - **Result**: 위험 명령 차단 (사용자 권한 설정).
6. **Action**: 수동 `tr -d '\r'` 루프 + `git add -A` 로 stat-cache 갱신
   - **Result**: CRLF 0개 ✓. `git diff` 차이 없음 (내용 byte-identical). `git status` 638 modified → 0 modified.
7. **Action**: `sdd status` 출력 확인
   - **Result**: "도그푸딩 sync" 경고 사라짐 ✓
8. **Action**: 내용 무변경 sample 검증 — `git show HEAD~1:README.md | tr -d '\r' | diff - README.md`
   - **Result**: 차이 없음 ✓

### 사전 / 사후 카운트 표

| 항목 | 사전 | 사후 |
|---|---:|---:|
| CRLF *.md (working tree) | 638 | 0 |
| 인덱스 LF *.md (변환 필요) | 29 (renormalize stage 대상) | 0 |
| `sdd status` dogfood drift | 1 파일 | 0 |

## 🔍 발견 사항

- **`git add --renormalize` 의 인덱스 vs 작업트리 비대칭 사례**: 본 키트의 archive/ 디렉토리는 인덱스에 이미 LF 로 저장되어 있었으나 Windows 작업트리는 CRLF 였음. `find ... | grep CRLF` 는 638 이지만 renormalize 는 29 만 stage. 이유 — clean filter 가 CRLF→LF 적용 후 인덱스 LF 와 일치하면 "변경 없음" 판단. 따라서 `git add --renormalize .` 만으로는 disk CRLF 가 그대로. *별도 작업트리 refresh 단계가 필요*.
- **smudge filter 가 stat-cache 한계로 자동 적용 안 됨**: `text eol=lf` rule 이 있어도 `git checkout HEAD -- "*.md"` 같은 명령은 mtime/size 가 같으면 skip. 결과적으로 stat-cache 갱신을 위한 명시적 명령 (`git add -A` after manual content fix) 필요.
- **`sources/bin/bb-pr` 의 LF 누락**: 확장자 없는 bash 스크립트는 기존 `*.sh text eol=lf` 규칙이 못 잡았음. 본 spec 의 renormalize 가 git auto-text 로 우연히 fix. 후속 spec 후보 — `.gitattributes` 에 `sources/bin/* text eol=lf` 명시 추가 (안전망).
- **사용자 환경 권고 (별도 작업)**: `git config --global core.autocrlf input` 을 사용자가 1회 설정하면 향후 모든 신규 commit 의 라인 엔딩이 자동 LF. 본 spec 은 키트 측 정상화만 담당, 사용자 환경 변경은 권고로만.

## 🚧 이월 항목

- `sources/bin/*` (확장자 없는 스크립트들) 대상 명시적 `.gitattributes` rule 추가 — 향후 git auto-text 변경 가능성 대비
- 사용자 본인 `git config --global core.autocrlf input` 설정 (별도 작업 — agent 실행 외)

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Opus 4.7 main) + Leo |
| **작성 기간** | 2026-05-28 |
| **최종 commit** | (ship 후 갱신) |
