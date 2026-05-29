# Implementation Plan: spec-x-md-lf-normalize

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-md-lf-normalize`
- 시작 지점: `main` (현재 main HEAD: 8482610, spec-x-gemini-review 머지 후)
- PR base: fork main (LeoYoon7/harness-kit)
- 첫 task 가 브랜치 생성을 수행

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] **범위 = repo 전체 (archive/ 포함, 638 *.md 파일)** — 사용자 명시 결정 (AskUserQuestion 응답, 2026-05-28)
> - [ ] **archive/ immutability 해석** — 라인 엔딩 정규화는 "내용" 변경 아님 → immutability 정신 위배 아님

> [!WARNING]
> - [ ] **거대한 PR diff** — 638 파일 변경 표시. 단, 내용 byte-identical, git 자동 처리. 리뷰 시 file content 가 아닌 .gitattributes / 검증 결과만 확인하면 됨.
> - [ ] **사용자 별도 작업 권고** — `git config --global core.autocrlf input` 1회 설정. 본 spec 은 권고만 명시 (walkthrough/pr_description), 실제 실행은 사용자 직접.

## 🎯 핵심 전략 (Core Strategy)

### 아키텍처 컨텍스트

```mermaid
flowchart TD
    A[현재: *.md 638 CRLF + 48 LF mixed] --> B[.gitattributes: + *.md text eol=lf]
    B --> C[git add --renormalize .]
    C --> D[git status 에 변경된 파일들 표시]
    D --> E[git commit]
    E --> F[검증: file *.md | grep -c CRLF == 0]
    E --> G[검증: sdd status 의 dogfood drift 사라짐]
```

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **`.gitattributes` 규칙** | `*.md text eol=lf` 1줄 추가 (`*.sh` 기존 유지) | 가장 narrow 한 규칙 — 현재 drift 발생 영역만 cover, 다른 확장자는 미보고 |
| **Normalize 방식** | `git add --renormalize .` | git 정식 메커니즘. OS 무관. 한 명령으로 완료 |
| **범위** | repo 전체 (archive/ 포함) | 사용자 결정. immutability 는 내용 기준이라 라인 엔딩 정규화는 무관 |
| **commit 구조** | 2 commit: (1) `.gitattributes` + (2) renormalize 결과 | renormalize 결과만 따로 보면 거대해서 검토 어려움 → `.gitattributes` 변경을 분리하면 normalize commit 의 의도가 명확 |
| **autocrlf 처리** | 사용자 직접 설정 권고만 — 본 spec 미실행 | global git config 변경은 사용자 환경 변화. agent 가 임의 실행 부적절 |

### 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음

## 📂 Proposed Changes

### [수정] `.gitattributes`

#### [MODIFY] `.gitattributes`

기존:
```text
# Shell 스크립트는 LF 로 저장 — macOS/Linux 에서 bash\r shebang 오류 방지 (autocrlf 설정 무관 강제)
*.sh text eol=lf
```

수정 후:
```text
# Shell 스크립트는 LF 로 저장 — macOS/Linux 에서 bash\r shebang 오류 방지 (autocrlf 설정 무관 강제)
*.sh text eol=lf

# 마크다운도 LF 로 통일 — Windows / macOS / Linux 간 일관성 보장, sdd status dogfood drift 방지
*.md text eol=lf
```

### [renormalize] 638 `*.md` 파일

#### [BULK NORMALIZE] `git add --renormalize .`

git 이 `.gitattributes` 의 새 규칙에 따라 CRLF *.md 를 LF 로 변환하고 index 에 stage. 변환된 파일 수는 walkthrough.md 에 file-stat 으로 기록.

명령:
```bash
git add --renormalize .
git status --short | wc -l  # 변경된 파일 수 확인 (예상: ~638)
```

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (해당 없음)

### 검증 시나리오

1. **사전 상태**:
   ```bash
   find . -name "*.md" -not -path "./.git/*" | xargs file | grep -c CRLF
   # 예상: 638
   ```
2. **`.gitattributes` 갱신 + renormalize 후**:
   ```bash
   find . -name "*.md" -not -path "./.git/*" | xargs file | grep -c CRLF
   # 기대: 0
   ```
3. **dogfood drift 해소 확인**:
   ```bash
   bash .harness-kit/bin/sdd status
   # 기대: "도그푸딩 sync" 경고 사라짐
   ```
4. **내용 무변경 확인 (sample 1개)**:
   ```bash
   git show HEAD~1:README.md | tr -d '\r' | diff - README.md
   # 기대: 차이 없음 (CRLF→LF 외 변경 없음)
   ```

### Lint / Format

- `shellcheck` 미적용 (md only).
- `markdownlint` 미적용 (본 repo 도입 안 됨).

## 🔁 Rollback Plan

- 본 PR revert 로 .gitattributes 1줄 + renormalize 결과 일괄 되돌리기 가능. git 이 자동 reverse normalize 처리.
- 로컬 working tree 의 LF 가 별도 commit 으로 들어가 있어도 .gitattributes 만 revert 하면 git 이 다음 add 시 원래대로 (autocrlf 설정에 따름).

## 📦 Deliverables 체크

- [x] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
