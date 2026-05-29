# spec-x-install-ignore-coverage: 리뷰 도구 출력물 + 컨테이너 빌드 컨텍스트 ignore 누락 해소

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-install-ignore-coverage` |
| **Phase** | (없음 — spec-x) |
| **Branch** | `spec-x-install-ignore-coverage` |
| **상태** | Planning |
| **타입** | Chore |
| **Integration Test Required** | no |
| **작성일** | 2026-05-29 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

`install.sh` 의 `.gitignore` 자동 갱신 블록 (`install.sh:475-528`) 은 다음 항목만 관리한다.

```bash
_gi_ensure '^\.harness-kit/$'         '.harness-kit/'   # (옵션 토글)
_gi_ensure '^\.harness-backup-\*/$'   '.harness-backup-*/'
_gi_ensure '^\.claude/state/$'        '.claude/state/'
_gi_ensure '^\.env\.telegram$'        '.env.telegram'
_gi_ensure '^\.env\.discord$'         '.env.discord'
```

반면 다음 두 부류의 산출물은 어떤 ignore 파일도 관리하지 않는다.

1. **리뷰 도구 출력물** — `/hk-code-review` 가 `specs/<spec-dir>/code-review.md`, `/hk-gemini-review` 가 `specs/<spec-dir>/code-review-gemini.md` 를 매 review 마다 생성. git history 상 한 번도 commit 된 적 없는 ephemeral 산출물이나 `.gitignore` 미등재 → 매번 untracked drift 누적.
2. **컨테이너 빌드 컨텍스트** — Dockerfile 사용 프로젝트의 `.dockerignore` 가 `.harness-kit/`, `archive/`, `specs/` 등 harness-kit 산출물을 인지하지 않음. `COPY . .` 패턴 사용 시 (a) 빌드 컨텍스트 비대화 (특히 WSL2 + Docker Desktop 환경에서 수백 파일 전송 지연), (b) `.env.telegram`/`.env.discord` 토큰의 이미지 포함 위험.

### 문제점

**(1) 리뷰 출력물 drift 재발**:
본 저장소(self-host)에서 `code-review-gemini.md` 3건 동시에 untracked drift 로 검출 (`spec-x-gemini-review`, `spec-x-md-lf-normalize`, `spec-x-notify-choice-context`). 직전 spec-x 가 해결한 self-host 한정 `.gitignore` 추가 (commit `2662536`) 는 일회성 우회 — 다른 모든 설치 프로젝트에서 같은 패턴 재발 보장.

**(2) 컨테이너 빌드 비대칭**:
`install.sh` 가 `.gitignore` 는 자동 관리하면서 `.dockerignore` 는 손대지 않음. 토큰 유출은 대부분 프로젝트가 이미 `.env*` 차단으로 방어되나, spec/archive 수백 파일로 인한 컨텍스트 비대화는 방어책이 없음. 사용자가 인지하지 못한 채 매 빌드마다 비용 발생.

**(3) 정책 비대칭의 합당성**:
두 문제는 같은 "ignore 파일 위생" 카테고리이나 처리 정책이 달라야 한다.
- `.gitignore` → **자동 갱신**: install.sh 가 이미 5개 항목 관리. 한 줄 추가로 모든 사용자에 전파.
- `.dockerignore` → **경고만**: Dockerfile 구조와 사용자 빌드 정책이 다양해 자동 침입 위험. 인지 강화로 충분.

### 해결 방안 (요약)

1. `install.sh` `.gitignore` 블록에 `specs/**/code-review*.md` 한 줄 추가 — 기존 `_gi_ensure` 패턴 연장.
2. `sources/bin/sdd` 의 `cmd_doctor()` 에 점검 2종 추가 — (a) `.gitignore` 에 리뷰 출력 패턴 미등재 경고, (b) Dockerfile 존재 + `.dockerignore` 에 `.harness-kit/` 미등재 경고.
3. README 에 "컨테이너 빌드 가이드" 섹션 추가 — 권장 `.dockerignore` 항목 명시.
4. 회귀 테스트 — `test-gitignore-config.sh` 에 시나리오 추가 + 신규 `test-doctor-ignore-coverage.sh`.

## 🎯 요구사항

### Functional Requirements

1. **install.sh `.gitignore` 확장**: `--yes` 또는 `--gitignore` 모드로 install 시 `.gitignore` 에 `specs/**/code-review*.md` 항목이 추가되어야 한다 (멱등 — 재설치 시 중복 없음).
2. **install.sh self-host guard 호환 + 헤더 강제**: 기존 self-host guard (`.harness-kit/` 가 git-tracked 일 때 옵션 토글 항목 건너뛰기) 와 무관하게 신규 항목은 **항상 추가**. 단, self-host 케이스에서 `# harness-kit` 헤더가 부재 시 신규 항목 추가와 함께 헤더도 같이 추가 (고아 라인 방지). 헤더 없는 라인은 uninstall.sh awk 가 시작점을 찾지 못해 영원히 잔존하는 위험 차단.
3. **uninstall.sh awk 패턴 대칭성**: `install.sh` 가 `.gitignore` 에 추가하는 모든 라인은 `uninstall.sh` 의 awk 블록 (line 159-167) 에 *명시 매칭 라인으로 등재* 되어야 한다. 신규 라인 `specs/**/code-review*.md` 도 등재 필수 — 누락 시 awk 의 `inblk==1 { inblk=0 }` 로직이 알려지지 않은 라인에서 블록을 조기 종료해 *인접한 다른 라인* 까지 추출 실패하는 부작용 발생.
4. **update.sh 다중 라운드 안정성**: `tests/test-gitignore-config.sh` 또는 `tests/test-update.sh` 에 update → uninstall → install 다중 라운드 시나리오 추가. 신규 라인 추가 후 update 를 2회 이상 반복해도 `.gitignore` 의 헤더 + 6개 라인 형태가 안정적으로 유지됨을 검증.
5. **sdd doctor `.gitignore` 미등재 경고**: 점검 섹션 (`ignore 위생` 신규 섹션) 에서 `specs/**/code-review*.md` 가 `.gitignore` 에 없으면 `⚠ 경고` 출력. install/update 권장 안내 포함.
6. **sdd doctor `.dockerignore` 미등재 경고**: 프로젝트 루트에 `Dockerfile` 존재하고 `.dockerignore` 가 (a) 없거나 (b) `.harness-kit` 관련 항목이 없으면 `⚠ 경고` 출력. 매칭 패턴은 사용자 자유도 보장 — `.harness-kit/`, `.harness-kit` (슬래시 없이), `**/.harness-kit/` 등 일반적 패턴 모두 인정. 정확 매치 강제 시 false positive WARN 발생 회피.
7. **README 컨테이너 가이드**: `README.md` 에 "컨테이너 빌드 컨텍스트" 또는 동등 섹션 추가. 권장 `.dockerignore` 항목 (`.harness-kit/`, `.claude/`, `backlog/`, `specs/`, `archive/`) 명시 + "다른 컨테이너 도구 사용 시 동일 점검 필요" 한 줄 안내.
8. **회귀 테스트**: 기존 `tests/test-gitignore-config.sh` 의 Scenario A 에 신규 항목 검증 추가 + 신규 `tests/test-doctor-ignore-coverage.sh` 작성 (Dockerfile 유/무 × `.dockerignore` 유/무 매트릭스).

### Non-Functional Requirements

1. **bash 3.2+ 호환**: install.sh / sdd doctor 신규 코드는 macOS 기본 bash (3.2.57) 에서 동작.
2. **멱등성**: 재설치/재실행 시 `.gitignore` 항목 중복 없음 (기존 `_gi_ensure` 헬퍼 사용).
3. **단일 명령 원칙 준수**: 신규 테스트 스크립트는 agent.md §6.4 의 bash 단일 명령 원칙 준수 (compound `&&`/`||` 회피, 한 줄로 묶지 않음).
4. **doctor 경고 비차단**: 두 경고 모두 `WARN` 등급 — `FAIL` 아님. 기존 `_doc_warn` 헬퍼 재사용.
5. **README 가이드 한국어**: 사용자 대면 문서이므로 한국어 작성 (constitution §5.4).

## 🚫 Out of Scope

- **`.dockerignore` 자동 갱신**: install.sh 가 `.dockerignore` 를 직접 수정하지 않는다. Dockerfile 구조와 빌드 정책이 사용자별로 달라 자동 침입 위험 — 경고만 출력.
- **`Containerfile` / `compose.yml` / `Earthfile` 점검**: Podman, Compose, Earthly 등 다른 컨테이너 도구 대응은 본 spec 에서 다루지 않는다 (첫 릴리스는 `Dockerfile` 한정). README 에 "다른 컨테이너 도구 사용 시 동일 점검 필요" 한 줄 안내만 포함.
- **다른 도구 산출물 ignore**: `.codegraph/` 등 사용자가 도입한 외부 도구의 출력물 일반화는 본 spec 범위 외. harness-kit 산출물 (`specs/**/code-review*.md`) 만 다룸.
- **기존 사용자 자동 전파**: install.sh 변경은 신규/재설치/update 시점에만 적용된다. 기존 설치 프로젝트가 자동으로 갱신되지는 않음 — `bash update.sh .` 실행이 사용자 책임. doctor 경고가 이를 안내함.
- **`/hk-code-review` / `/hk-gemini-review` 출력 경로 변경**: 출력 위치 변경 (예: `.harness-kit/cache/reviews/`) 은 사용자 UX 손실 (PR 첨부 동선 등) 이 커서 거부. 본 spec 은 ignore 정책으로 해결. 단 본 결정의 정합성은 critique (대안 A) 가 별도 ADR 후보 (`tool-output-in-tree-vs-out-of-tree`, type: tradeoff) 로 분리 권장 — 본 spec 외부 작업 (Icebox 등재 완료).
- **미래 출력 형식 (JSON / HTML / sub-directory)**: 현재 글롭 패턴 `specs/**/code-review*.md` 는 `*.md` 한정. 향후 `/hk-code-review` 가 (a) JSON 형식 (`code-review.json`), (b) HTML 리포트 (`code-review.html`), (c) sub-디렉토리 (`code-review/raw/`) 등으로 확장 시 *별도 spec* 으로 ignore 정책 갱신. 현 시점 `*.md` 한정은 명시적 결정 — 우산 패턴 (`specs/**/code-review*`) 은 사용자 의도와 무관한 파일 (예: `code-review-notes.md` 같은 수동 메모) 까지 잡을 위험이 있어 보수적 선택.

## 📑 ADR 후보 (Architecture Decision Records)

- [x] **ADR 가치 있는 결정 있음** → 후보 한 줄 요약: `kit-managed-ignore-line-symmetry-invariant` (type: invariant)
  - 내용: install.sh 가 `.gitignore` 헤더 블록에 추가하는 모든 라인은 uninstall.sh awk 블록의 알려진 패턴 enumeration 에 반드시 등재되어야 한다 (대칭성 invariant).
  - 근거: 본 spec critique 가 이 invariant 누락의 critical 위험을 발견 — uninstall awk 의 `inblk==1 { inblk=0 }` 로직이 알려지지 않은 라인에서 블록 조기 종료 → 인접 라인 추출 실패 + stale 잔존. 향후 신규 ignore 라인 추가 시 같은 함정 반복 방지.
  - 작성 위치: `docs/decisions/ADR-005-kit-managed-ignore-line-symmetry-invariant.md`
  - 작성 시점: 본 spec 내 별도 task (install.sh / uninstall.sh 변경 직후, ship 전)
- [x] **추가 ADR 후보 (Icebox 등재 완료)**: `tool-output-in-tree-vs-out-of-tree` (type: tradeoff) — 본 spec 외부 작업으로 분리 (queue.md Icebox).
- [ ] 없음

## ✅ Definition of Done

- [ ] `install.sh` `.gitignore` 블록에 `specs/**/code-review*.md` 항목 추가, 멱등성 + self-host 헤더 강제 확인
- [ ] `uninstall.sh` awk 블록에 `specs/**/code-review*.md` 매칭 라인 추가 (대칭성 invariant)
- [ ] `tests/test-gitignore-config.sh` 에 update → uninstall → install 다중 라운드 안정성 시나리오 추가 + PASS
- [ ] `sources/bin/sdd` `cmd_doctor()` 에 `ignore 위생` 섹션 신설 + `.gitignore` 미등재 경고 추가
- [ ] `sources/bin/sdd` `cmd_doctor()` 에 `.dockerignore` 미등재 경고 (Dockerfile 조건부, 사용자 자유도 보장 패턴) 추가
- [ ] `README.md` 에 컨테이너 빌드 가이드 섹션 추가
- [ ] `tests/test-gitignore-config.sh` Scenario A 에 신규 항목 검증 추가 + PASS
- [ ] `tests/test-doctor-ignore-coverage.sh` 신규 작성 + PASS
- [ ] `docs/decisions/ADR-005-kit-managed-ignore-line-symmetry-invariant.md` 신규 작성
- [ ] 전체 회귀 테스트 영향 없는 항목 PASS 유지
- [ ] 본 저장소(self-host) 에 `update.sh` 적용 → drift 재발 안 함 검증 (walkthrough 증거)
- [ ] `walkthrough.md` / `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-install-ignore-coverage` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
