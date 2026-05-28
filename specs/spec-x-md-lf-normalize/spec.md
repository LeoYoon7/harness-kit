# spec-x-md-lf-normalize: `*.md` LF 라인 엔딩 통일 (.gitattributes + 일괄 normalize)

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-md-lf-normalize` |
| **Phase** | (없음 — Solo Spec) |
| **Branch** | `spec-x-md-lf-normalize` |
| **상태** | Planning |
| **타입** | chore (repo hygiene) |
| **Integration Test Required** | no |
| **작성일** | 2026-05-28 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

본 repo 는 Windows 환경에서 운영되며, `git config core.autocrlf` 가 local/global 모두 `false`. 결과적으로 Windows 에서 작성된 마크다운 파일은 CRLF 로 저장되고, 신규 Write 툴 산출물은 LF 로 저장되어 mixed 상태입니다.

실측 (`find . -name "*.md" -not -path "./.git/*"`):

| 영역 | LF | CRLF | 비고 |
|---|---:|---:|---|
| repo 전체 *.md | 48 | 638 | CRLF 다수파 |
| `sources/*.md` | 5 | 26 | 일부 신규 파일만 LF |
| `.harness-kit/*.md` | (소수) | 12 | 동일 |
| `.claude/commands/*.md` | 1 | 다수 | 본 PR 직전 추가된 hk-gemini-review.md 만 LF |

기존 `.gitattributes` 는 `*.sh text eol=lf` 만 강제. 마크다운 규칙 없음.

### 문제점

1. **`sdd status` 의 dogfood drift false alarm**. 직전 PR (`spec-x-gemini-review`) 에서 `.claude/commands/hk-ship.md` 를 sources LF + installed CRLF 비대칭으로 sync 한 결과, `_drift_dogfood_sync` 가 매번 "1 파일 sources/와 비동기" 를 보고합니다 (`.harness-kit/bin/sdd:431-459` — `diff -q` 바이트 단위 비교).
2. **향후 sync 시점마다 반복 결정**. 새 `.md` 파일을 추가할 때마다 라인 엔딩을 어느 쪽으로 맞출지 결정해야 하고, walkthrough 에 trade-off 를 기록해야 합니다 (실제 spec-x-gemini-review 가 그렇게 처리됨).
3. **cross-platform 일관성 부재**. 본 키트는 macOS 1차 / Linux best-effort 를 명시 (CLAUDE.md). CRLF 가 다수파인 현 상태는 키트의 cross-platform 지향에 역행.

### 해결 방안 (요약)

`.gitattributes` 에 `*.md text eol=lf` 1줄 추가 + `git add --renormalize .` 로 repo 전체 일괄 LF 정규화. 사용자 명시 결정 — archive/ 포함 전체 normalize (선택지 1번, 2026-05-28). 사용자에게 별도로 `git config --global core.autocrlf input` 1회 설정을 권고하여 향후 신규 commit 도 자동 정상화.

## 🎯 요구사항

### Functional Requirements

1. **`.gitattributes` 갱신**
   - 기존 `*.sh text eol=lf` 라인 유지.
   - 신규 `*.md text eol=lf` 추가.
2. **일괄 LF 정규화**
   - `git add --renormalize .` 실행. git 의 정규화 메커니즘이 `.gitattributes` 의 `eol=lf` 규칙에 따라 모든 `*.md` 를 LF 로 변환.
   - 변환 후 working tree 의 파일도 LF 가 되어야 함.
3. **검증**
   - 변환 후 `find . -name "*.md" -not -path "./.git/*" | xargs file | grep -c CRLF` 결과 `0` 이어야 함.
   - `bash .harness-kit/bin/sdd status` 출력의 "도그푸딩 sync" 경고 사라져야 함.
4. **사용자 안내** (walkthrough / pr_description 내)
   - `git config --global core.autocrlf input` 1회 설정 권고 — 본 spec 의 직접 작업은 아니지만 후속 권고로 명시.

### Non-Functional Requirements

1. **내용 무변경 보장**. `*.md` 의 텍스트 내용은 byte-for-byte 동일해야 함. 라인 엔딩만 변경.
2. **archive/ immutability 호환**. archive/ 의 spec 산출물은 "내용" 기준으로 immutable. 라인 엔딩 정규화는 표시 형식 변경이라 immutability 정신에 위배되지 않음 (walkthrough 에 명시).
3. **타 파일 영향 없음**. `*.sh`, `*.json`, 기타 확장자는 본 spec 범위 외 — `.gitattributes` 에 별도 규칙 추가하지 않음 (현재 drift 미보고 영역).
4. **bash 의존성 없음**. `git add --renormalize .` 는 git 자체 기능, OS 무관.

## 🚫 Out of Scope

- `*.sh`, `*.json`, `*.yml` 등 다른 확장자의 라인 엔딩 규칙 (현재 drift 미발생 영역, 향후 별도 spec 가능).
- `git config --global core.autocrlf input` 의 실제 실행 (사용자 환경 변경이라 사용자가 직접 수행 — 본 spec 은 권고만).
- `.gitignore` 항목 추가 / 변경.
- `.codegraph/` 등 untracked 부산물 처리.
- 키트가 install 되는 *대상 프로젝트* 의 `.gitattributes` 자동 추가 (install.sh 변경 안 함).

## 📑 ADR 후보 (Architecture Decision Records)

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — `.gitattributes` 에 `*.md text eol=lf` 추가는 정해진 git 메커니즘 적용이고, "LF 우선" 은 본 키트 1차 타깃 (macOS) 과 일치. ADR 가치 낮음.

## ✅ Definition of Done

- [ ] `.gitattributes` 에 `*.md text eol=lf` 추가
- [ ] `git add --renormalize .` 실행으로 repo 전체 `*.md` LF 정규화
- [ ] 검증: 잔여 CRLF *.md 파일 0개
- [ ] 검증: `sdd status` 의 dogfood drift 경고 사라짐
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit (`autocrlf input` 후속 권고 포함)
- [ ] `spec-x-md-lf-normalize` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
