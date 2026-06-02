# Backlog Queue

> 본 문서는 *대시보드* 입니다. "지금 무엇을 하고 있고, 다음에 무엇을 해야 하는가"를 한눈에 보기 위함.
>
> **자동 갱신 마커**: `active`, `specx`, `done` — 마커 (`<!-- sdd:... -->`) 사이는 sdd 가 관리하므로 그대로 두세요.
> **사람 편집 섹션**: `🧊 Icebox`, `📋 대기 Phase` — 자유 메모.

## 📦 진행 중 Phase

<!-- sdd:active:start -->
(active phase 없음. `bin/sdd phase new <slug>` 로 시작)
<!-- sdd:active:end -->

## 📥 spec-x 대기

<!-- sdd:specx:start -->
없음
<!-- sdd:specx:end -->

## 🧊 Icebox

> 아이디어·보류 항목 보관소. 실행 불가. 관련 항목이 쌓이면 Phase로, 단발이면 spec-x로 승격.

- kit 새 버전 알림이 `sdd status` drift 섹션 한 줄에 그쳐 사용자 도달이 약함 — SessionStart 시 자동 노출 또는 알림 시각 강화 필요
- (phase-16 W9) ADR 승격 가이드 ROI metric — *측정 누적 (3 개월+) 선행 필요*. phase-17 종료 후 spec 의 ADR 승격 ratio 데이터 보고 결정
- `tests/test-uninstall-cmd-list.sh` Scenario 2 FAIL — uninstall 후 `hk-*.md` 커맨드가 하나도 제거되지 않고 15개 전부 잔존. Windows(Git Bash) 환경에서 `uninstall.sh` 의 파일 삭제 미동작 의심 (macOS 1차 타깃). spec-x-sdd-bugfix 재검증 (2026-06-01) 중 발견. 원인 범위 (환경 의존 vs uninstall 로직 회귀) 확인 필요
- 거버넌스 문서 단어 수 한계 초과 — `tests/test-governance-dedup.sh` 가 상한 6000w 인데 현재 6418w. 한계 재설정 또는 거버넌스 다이어트 검토
- **hk-wiki-ingest 슬래시 커맨드** — archive 후 Claude가 wiki를 갱신하는 표준 워크플로. `sources/commands/hk-wiki-ingest.md` + 템플릿에 `[[wikilinks]]` 관련 문서 섹션 추가. (phase-19 spec-19-02 deferred)
- **sdd doctor wiki 점검 3종** — wiki 고아 링크 감지, stale ADR/RCA 90일+ 경고, governance 단어 수 상한 경고. (phase-19 spec-19-03 deferred)
- 기존 루트 런처(`telegram.sh`/`discord.sh`)의 `.dockerignore` 미커버 — spec-x-skip-perms-launcher 는 신규 권한 우회 런처만 doctor 점검 추가. 동일 갭이 telegram/discord 에도 존재. doctor 점검 확장 또는 컨테이너 가이드 항목 추가 검토
- **root CLAUDE.md 슬림화** — 릴리스 전략 등 저빈도 내용을 `docs/release-strategy.md` 로 분리, root 는 포인터만. 항상-온 컨텍스트 토큰 절감 (Claude Code harness 기사 인사이트 #1)
- **분기별 governance prune protocol** — 거버넌스 ratchet 누적 방지. `/hk-governance-refresh` 또는 sdd 진단에 "rule age > 6mo" 경고. 모델 진화에 맞춰 stale rule 제거 메커니즘 부재 (기사 인사이트 #2)
- **하위 디렉토리 CLAUDE.md** — `sources/CLAUDE.md` (키트 원본 시점) / `specs/CLAUDE.md` (작업 로그 시점) 분리로 두 시점 혼동 방지 (기사 인사이트 #3)
- **LSP/MCP 활용 가이드** — agent.md §6.5 (Static Analysis First) 확장. 적용 대상 프로젝트가 LSP 지원 언어일 때 grep 대신 심볼 기반 정의/참조 추적 권장 (기사 인사이트 #4)
- **도그푸딩 sync 자동화** — sources 와 본 저장소 installed 자산 간 drift 가시화 메커니즘. 옵션: `sdd doctor` 에 sources vs installed diff 경고 / CI 의 `bash update.sh --check` (dry-run 모드 신설 후) / post-merge 자동 update. 본 사건(`spec-x-dogfood-sync`)의 근본 원인 — 별도 spec 으로 신중 설계
- ~~**ADR-NNN-dogfood-sync-policy 작성** (convention)~~ → ✓ **ADR-003** 작성 (2026-05-28, commit `3a4ad76`)
- **`check-secrets.sh` `.env.*.example` 패턴 제외 fix** — 현재 `(^|/)\.env(\..+)?$` 가 `.env.telegram.example` 같은 *템플릿* 까지 false positive 로 잡음. 본 사건에서 self-host 한정 회피(.gitignore 추가) 로 우회했으나 target 프로젝트에도 영향. 패턴을 `\.env(\.[a-z0-9_-]+)?$` 형태로 좁히거나 `.example`/`.sample` 접미사 화이트리스트 추가 필요
- **Telegram 응답 시 ack 중복 발송** — 사용자가 Telegram 으로 응답하면 (a) mcp_telegram_reply (예: "Plan Accepted. Strict Loop 시작...") + (b) `[ack]` notify 둘 다 발송됨. Plan Accept 단계뿐 아니라 Telegram 경유 모든 응답에서 발생 추정. fix: Telegram 경유 응답 시 한 채널만 사용 (mcp reply 에 §9 ack 포맷 통합 or §9 ack 만 발송하고 mcp reply 생략). 사용자 보고 (Telegram msg #3075, 2026-05-28)
- **§5 stop notification 과 AskUserQuestion 옵션 번호 불일치** — 에이전트가 AUQ 호출 시 권장안을 첫 번째에 배치 (라벨에 (권장)). 동시에 §5 stop notification 으로 동일 선택지를 Telegram 에 보낼 때는 사람이 작성한 순서 (예: 1.Gemini/2.Opus/3.Skip, 권장 3번). 두 채널의 번호가 sync 안 됨 → 사용자가 Telegram 의 "3번" (Skip) 으로 보고 Desktop 에서 3 누르면 Opus 가 선택되어 무반응/혼동. fix: (a) AUQ 호출 시 §5 stop 자동 생략 (hook (c) 가 cover) or (b) §5 stop 메시지를 AUQ 옵션 순서와 동일하게 자동 생성. spec-x-notify-ack-dedup 의 범위에 통합 후보. 사용자 보고 (Telegram msg #3084+#3086, 2026-05-28)
- **ADR-NNN-tool-output-in-tree-vs-out-of-tree** (type: tradeoff) — harness-kit 의 도구 출력물 (review/critique vs walkthrough/pr_description) 의 위치 정책 (in-spec-dir vs `.harness-kit/cache/`) 결정 자산화. spec-x-install-ignore-coverage 의 critique (대안 A) 가 떠올린 근본 분기점. 본 spec 머지 후 별도 spec-x-adr-tool-output 또는 ADR 단독 작성. 향후 신규 산출물 (`code-review-claude.md`, `code-review-codex.md`, JSON/HTML 형식 등) 추가 시 한 페이지 참조로 결정 가능
- **컨테이너 빌드 컨텍스트 비대칭** — `install.sh` 가 `.gitignore` 는 자동 관리하면서 `.dockerignore` 는 손대지 않음. Dockerfile 있는 프로젝트에 설치 시 `.harness-kit/`, `archive/`, `specs/`, `.env.*` 등이 빌드 컨텍스트에 포함되어 (a) WSL2 + Docker Desktop 환경에서 컨텍스트 전송 지연, (b) `COPY . .` 패턴 사용 시 `.env.telegram`/`.env.discord` 토큰이 이미지에 포함될 위험. fix 후보: `sdd doctor` 에 "Dockerfile 존재 + .dockerignore 에 `.harness-kit/` 미등재" 경고 + README 컨테이너 가이드 섹션. `install.sh` 자동 갱신은 사용자 정책 충돌 우려로 보류. 검토 메모: 토큰 유출은 대부분 프로젝트가 이미 `.env*` 차단으로 방어됨 — 진짜 비대칭 가치는 spec/archive 수백 파일로 인한 컨텍스트 비대화. Containerfile/compose.yml/Earthfile 등 다른 컨테이너 도구도 동일 함정. 권장 항목에서 `telegram.sh` 제외 (사용자 측 임의 스크립트 가능성)
- **Discord 마크다운 포맷팅 (notify.sh 채널별 분기)** — Discord 채택 근거가 Telegram 대비 마크다운 렌더링 우위 (bold, code block, separator). 그런데 `notify.sh` 가 채널 무관 동일 plain text 발송 → Discord 의 가독성 강점 사장, Telegram-호환 최저 공통분모로 평준화. 특히 `[선택지]` / `[상황 / 맥락]` 같은 구조화 정보 (표 포함) 가 plain text 로 가독성 떨어짐. fix 후보: `notify.sh` 또는 dispatch 단에 채널별 포맷터 분기 (Discord: bold 헤더 + code-block ASCII 표 + separator, Telegram: HTML/MarkdownV2 또는 plain). `§5 stop / §9 ack / Gate 메시지` 전반 영향. 사용자 보고 (Discord screenshot, 2026-05-29)
- **AUQ 잔존 호출 경로 추가 점검** — `spec-x-notify-bidirectional-policy` 후 "에이전트는 AskUserQuestion 사용 안 함" 정책이 있음에도, align 직후 단순 의도 확인 시 AUQ 호출 사례 발생 (2026-05-29). 정책 텍스트만으론 부족할 수 있어 보강 검토: (a) `agent.md §8.4` / CLAUDE.md fragment 의 "사용 안 함" 문구를 더 강하게 (예: "절대 금지 — 위반 시 RCA"), (b) AUQ 호출 시 사전 차단 hook 검토 가능성, (c) 메모리 보강 [[feedback-no-auq-ever]] 와 별개로 거버넌스 문서 자체 강화 필요 여부 평가
- **`update.sh` semver_lt 함수 leo suffix 버그** — `bash update.sh --yes` 실행 시 line 85 `((x < y))` 에서 unbound variable. 원인: version `0.15.0-leo.1` 의 dot split 셋째 요소 `0-leo` 가 arithmetic 비숫자 처리 실패. 영향: ADR-003 SSOT (도그푸딩 sync) 가 leo fork 환경에서 호출 불가. 본 사건 (spec-x-notify-channel-formatter 의 Task 11) 에서 노출되어 task pass 처리됨. fix 후보: (a) `local x=${a[i]:-0}` 의 fallback 을 numeric 검증 후 적용 (예: `x=${x%%[!0-9]*}`), (b) `0-leo` 같은 suffix 가 들어오면 0 으로 간주, (c) semver pre-release suffix (PEP 440 / SemVer 2 spec) 정식 처리. **별도 spec-x-update-semver-suffix-fix 후보**
- **Discord embed 기반 구조화 메시지 (`spec-x-notify-discord-embed`)** — `spec-x-notify-channel-formatter` 의 시각 검증 (2026-05-29) 에서 *모바일 좁은 화면* 의 code-block 표가 *긴 셀* (예: 31 chars `spec-x-notify-channel-formatter`) 일 때 자동 word wrap → 정렬 깨짐 실증. Critique 의 *대안 B (embed)* 가 결정적 — title/description/fields 분리로 모바일 가독성 우위. surface: `notify-discord.sh` 의 `content` 송신 → `embeds` JSON 으로 확장, embed 본문 4096자 / field name 256 / value 1024 / 총 6000자 제한 (Discord API), chunking 재설계. ADR-006 `discord-table-rendering-policy` (type: tradeoff) 본 spec 트리거 시 작성. *직전 spec 의 한계가 다음 spec 의 정확한 ROI* — 문제-실증 기반 spec 정신
- **stale ADR 오탐 근본책 (sdd drift 가 archive/ 미탐색)** — `sdd status` 의 stale ADR 검사가 `[ -e "$token" ]` 로 repo 루트만 확인 → ADR 이 참조하는 spec 이 archive 되면 경로가 깨져 false-positive 재발. 본 사건 (2026-06-01 ADR-003/004/005 경로 갱신) 의 근본 원인. fix 후보: (a) drift 검사 시 `archive/` 도 탐색 (`[ -e "$token" ] || [ -e "archive/$token" ]`), (b) ADR 템플릿이 spec 참조 시 처음부터 영구 식별자(PR 링크 / commit hash) 권장. 별도 spec-x 후보
- **CC 네이티브 기능 도입 — 2단계 정책 spec** (`native-feature-adoption-policy`) — `/goal`·`/effort ultracode`·`/fewer-permission-prompts`·`/code-review ultra`·`/ultraplan`·스킬 시스템의 게이트 보존 조건을 agent.md 가이드 1절 + ADR(type: convention)로 명문화. (조사: `spec-x-cc-native-adoption` report §7-2)
- **CC 네이티브 세션 기능 검증 spec** — `/background`·`/branch` 의 알림 타이밍·hook/§8.5/멀티모델 상태 승계 실측 (검증 테스트 1·4, Research 성격). (조사: report §7-3, 부록 A)
- **`/batch` Bitbucket 정합성** — target Bitbucket 에서 `/batch` 자동 PR off + worktree diff → `/hk-pr-bb` 경로. 검증 테스트 2·3·5 해소 전 보류. 도그푸딩(GitHub) 시점엔 정합하나 키트 배포 대상 중립성 우선. (조사: report §5 보류)
- **CC 네이티브 1단계 6종 즉시 채택** — `/deep-research`·`/workflows`·`/copy`·`/rewind`·`/team-onboarding`·`/btw` 는 거버넌스 직교라 spec 불필요 (`/powerup`·`/radio` 는 거버넌스 무관 — 개인 사용, 도입 논의 밖). 운영 관행 또는 CLAUDE.md 한 줄 메모로 승격 검토. (조사: report §5 1단계)

**[phase-17 으로 promote 된 항목 — 처리 진행 중]**:
- ~~접근성 개선~~ → phase-17 **spec-17-02** (accessibility-install-and-entry)
- ~~sdd marker 버그 (W5/W10)~~ → ✓ **spec-17-01** 머지로 종식 (RCA-001 prevention)
- ~~installed.json 캐시 (C3)~~ / ~~phase integration test (W2)~~ / ~~doctor 새 경로 (W6)~~ → phase-17 **spec-17-03** (internal-reliability-infra)
- ~~§6.4 표현 (W1)~~ / ~~stale ADR 회귀 마커 (W3)~~ / ~~ADR 가이드 (W4)~~ / ~~CHANGELOG 정책 (W7)~~ → phase-17 **spec-17-04** (governance-test-coherence)
- ~~sdd phase done title 버그~~ → ✓ **spec-17-01** 머지로 종식 (normalize)

## 📋 대기 Phase

> 다음에 진행할 phase 를 자유롭게 메모합니다 (사람이 직접 편집).
> 자동 갱신되지 않습니다 — Icebox 와 동일한 정책.

없음

## ✅ 완료

<!-- sdd:done:start -->
| Phase | 제목 | SPECs |
|-------|------|-------|
| [phase-01](phase-01.md) | 설치/운영 마찰 해소 | 2 (Merged) |
| [phase-02](phase-02.md) | 토큰 최적화 & 거버넌스 경량화 | 3 (Merged) |
| [phase-03](phase-03.md) | macOS 네이티브 설치 모드 | 1 (Merged) |
| [phase-04](phase-04.md) | 옵셔널 Sub-agent 리뷰 시스템 | 2 (Merged) |
| [phase-05](phase-05.md) | spec-kit 패턴 도입 & 크로스 에이전트 | 1 (Merged) |
| [phase-06](phase-06.md) | SDD UX 개선 및 커맨드 정리 | 2 (Merged) |
| [phase-07](phase-07.md) | SDD 프로세스 일관성 및 품질 강화 | 4 (Merged) |
- **phase-08** — 작업 관리 모델 재정립 — completed 2026-04-12
- **phase-09** — 설치 충돌 방어 — completed 2026-04-17
- **phase-10** — sdd 상태 진단 신뢰성 강화 — completed 2026-04-16
- **phase-11** — 식별자 체계 개선 및 디렉토리 아카이브 — completed 2026-04-17
- [x] spec-x-sdd-ux-fixes (완료)
- **phase-12** — 프로젝트 확장성 강화 — completed 2026-04-22
- **phase-13** — 개발자 경험(DX) 향상 — 자동화 & 온보딩 — completed 2026-04-25
- **phase-14** — 정합성 / 멱등성 버그 일괄 수정 — completed 2026-04-25
- [x] spec-x-phase-14-finalize (완료)
- [x] spec-x-update-preserve-state (완료)
- [x] spec-x-install-phase-ship-template (완료)
- [x] spec-x-sdd-phase-activate (완료)
- **phase-15** — upgrade-safety — 기존 사용자 update 경로 안전성 — completed 2026-04-30
- [x] spec-x-phase-15-finalize (완료)
- [x] spec-x-hk-align-drift-detect (완료)
- [x] spec-x-fix-archive-test-expectation (완료)
- [x] spec-x-install-fragment-fixes (완료)
- [x] spec-x-hook-bypass-fix (완료)
- [x] spec-x-output-ux (완료)
- [x] spec-x-confirm-ux (완료)
- [x] spec-x-precommit-chmod-fix (완료)
- [x] spec-x-kit-update-check (완료)
- [x] spec-x-doctor-hooks-path-fix (완료)
- [x] spec-x-archive-include-specx (완료)
- [x] spec-x-archive-clean-commit (완료)
- [x] spec-x-hook-allow-ff-when-no-spec (완료)
- [x] spec-x-phase-lifecycle-coherence (완료)
- [x] spec-x-governance-distribute-workflow-patterns (완료)
- [x] spec-x-hk-update-remote (완료)
- [x] spec-x-kit-update-hook (완료)
- [x] spec-x-readme-refresh (완료)
- [x] spec-x-phase-16-define (완료)
- **phase-16** — Reliability Layer 강화 — completed 2026-05-16
- [x] spec-x-phase-17-define (완료)
- **phase-17** — 운영 성숙도 (Operational Maturity) — completed 2026-05-17
- [x] spec-x-planning-economy (완료)
- [x] spec-x-sdd-state-guard (완료)
- [x] spec-x-ask-mode-toggle (완료)
- [x] spec-x-sdd-search (완료)
- [x] spec-x-claude-md-slim (완료)
- [x] spec-x-claude-md-nested (완료)
- [x] spec-x-kit-update-notify (완료)
- **phase-18** — Precheck Gate — 설정 기반 PR 사전 검증 자동화 — completed 2026-05-21
- [x] spec-x-check-secrets-dual-mode (완료)
- **phase-19** — 문서 지식 그래프 (Doc Knowledge Graph) — completed 2026-05-27
- [x] spec-x-notify-channels (완료)
- [x] spec-x-dogfood-sync (완료)
- [x] spec-x-check-secrets-env-example (완료)
- [x] spec-x-check-secrets-docs-context (완료)
- [x] spec-x-sdd-drift-fixes (완료)
- [x] spec-x-gemini-review (완료)
- [x] spec-x-md-lf-normalize (완료)
- [x] spec-x-notify-choice-context (완료)
- [x] spec-x-notify-auq-scope-fix (완료)
- [x] spec-x-notify-channel-coherence (완료)
- [x] spec-x-notify-bidirectional-policy (완료)
- [x] spec-x-install-ignore-coverage (완료)
- [x] spec-x-notify-drop-both (완료)
- [x] spec-x-notify-launcher-only (완료)
- [x] spec-x-notify-chunk-line-aware (완료)
- [x] spec-x-notify-channel-formatter (완료)
- [x] spec-x-update-semver-suffix-fix (완료)
- [x] spec-x-skip-perms-launcher (완료)
- [x] spec-x-review-gate-default (완료)
- [x] spec-x-cc-native-adoption (완료)
- [x] spec-x-native-feature-adoption-policy (완료)
<!-- sdd:done:end -->

---

## 📖 사용 방법

| 명령 | 동작 |
|---|---|
| `sdd phase new <slug>` | 새 Phase 생성 → 진행 중으로 등록 |
| `sdd phase new <slug> --base` | Phase base branch 모드로 생성 (opt-in) |
| `sdd spec new <slug>` | 진행 중 Phase에 다음 spec 등록 |
| `sdd plan accept` | spec Plan Accept → 실행 모드 진입 |
| `sdd ship` | spec 완료 처리 → Merged 갱신 + state 초기화 + NEXT 안내 |
| `sdd phase done <N>` | Phase 완료 → 완료 섹션으로 이동 |

자세한 사용법: `agent/constitution.md` §3 Work Type Model, `agent/agent.md`
