# Code Review (Gemini): spec-x-md-lf-normalize

## 요약

- 전체 평가: **Approve**
- Critical 이슈 수: 0
- Major 이슈 수: 0
- Minor 이슈 수: 1

## 상세 리뷰

### 1. Spec 대비 구현 검증
- **요구사항 충족**: `.gitattributes` 에 `*.md text eol=lf` 규칙을 추가하고, `git add --renormalize .` 를 통해 저장소 전체의 마크다운 파일 라인 엔딩을 LF로 정규화하겠다는 계획이 충실히 이행되었습니다.
- **Scope Creep 검증**: `*.md` 외에도 `version.json` 과 `sources/bin/bb-pr` (확장자 없는 bash) 파일이 함께 정규화되었으나, 이는 git의 auto-text 감지 기능에 의한 부수 효과이며 프로젝트의 LF 통일 기조와 일치하므로 유익한 범위 확장으로 판단됩니다.
- **아카이브 호환성**: `archive/` 디렉토리 내의 과거 spec 산출물들도 정규화 대상에 포함되었습니다. "내용 불변" 원칙을 해치지 않으면서 표시 형식만 일관성을 맞춘 것이므로 적절한 결정입니다.

### 2. 코드 품질
- **KISS (Keep It Simple, Stupid)**: 복잡한 변환 스크립트 대신 git 자체 기능인 `renormalize` 를 활용하여 명확하고 단순하게 해결했습니다.
- **일관성**: 기존 `*.sh` 에만 적용되던 LF 강제 규칙을 `*.md` 로 확대하여, Windows/macOS/Linux 혼합 환경에서의 `sdd status` drift 오탐지를 근본적으로 차단했습니다.
- **문서화**: `walkthrough.md` 에 `git add --renormalize` 가 작업 트리(disk)의 파일까지 자동으로 처리하지 못할 때의 대응 (수동 `tr` 변환) 이 상세히 기록되어 있어 지식 자산으로서 가치가 높습니다.

### 3. 테스트 커버리지
- **동작 검증**: `find` 명령을 통한 CRLF 카운트(`0`)와 `sdd status` 의 drift 보고 여부를 통해 수동 검증이 완료되었습니다.
- **엣지 케이스**: `sources/bin/bb-pr` 처럼 확장자가 없으나 텍스트인 파일들이 정규화 과정에서 누락되지 않고 처리된 것을 확인했습니다.
- **오타 (Minor)**: `specs/spec-x-md-lf-normalize/task.md:46` 라인에 "도그푓딩" 이라는 오타가 발견되었습니다. 구현 내용에는 영향이 없으나 문서 정합성을 위해 수정을 권장합니다.

## 권고사항

- **[Minor]** `specs/spec-x-md-lf-normalize/task.md:46`: `"도그푓딩 sync"` 를 `"도그푸딩 sync"` 로 수정하세요.
- **[권고]** PR 본문 및 사용자 안내에 명시된 대로, 향후 신규 commit에서의 자동 정규화를 위해 사용자가 `git config --global core.autocrlf input` 을 1회 설정하도록 강력히 권고하는 내용을 ship 리포트에 포함하세요.
- **[향후 과제]** `sources/bin/*` 와 같이 확장자가 없으나 bash 인 파일들에 대해 `.gitattributes` 에 명시적인 `text eol=lf` 규칙을 추가하는 것을 다음 hygiene 작업으로 고려해 볼 수 있습니다. (walkthrough 의 발견 사항에 이미 기록되어 있음)
