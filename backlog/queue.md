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
- ~~거버넌스 문서 단어 수 한계 초과~~ → ✓ **phase-21 governance diet (#44)** + **ADR-012-governance-word-budget** — 상한 6000w→6500w 재설정 + agent.md 축소, 현재 6393w (test-governance-dedup 8/8 PASS, 2026-06-09 확인).
- **hk-wiki-ingest 슬래시 커맨드** — archive 후 Claude가 wiki를 갱신하는 표준 워크플로. `sources/commands/hk-wiki-ingest.md` + 템플릿에 `[[wikilinks]]` 관련 문서 섹션 추가. (phase-19 spec-19-02 deferred)
- **sdd doctor wiki 점검 3종** — wiki 고아 링크 감지, stale ADR/RCA 90일+ 경고, governance 단어 수 상한 경고. (phase-19 spec-19-03 deferred)
- 기존 루트 런처(`telegram.sh`/`discord.sh`)의 `.dockerignore` 미커버 — spec-x-skip-perms-launcher 는 신규 권한 우회 런처만 doctor 점검 추가. 동일 갭이 telegram/discord 에도 존재. doctor 점검 확장 또는 컨테이너 가이드 항목 추가 검토
- ~~**root CLAUDE.md 슬림화**~~ → ✓ **spec-x-claude-md-slim (#135, `046a091`)** — 릴리스 전략을 `docs/release-strategy.md` 로 분리, root 는 포인터.
- **분기별 governance prune protocol** — 거버넌스 ratchet 누적 방지. `/hk-governance-refresh` 또는 sdd 진단에 "rule age > 6mo" 경고. 모델 진화에 맞춰 stale rule 제거 메커니즘 부재 (기사 인사이트 #2)
- ~~**하위 디렉토리 CLAUDE.md**~~ → ✓ **spec-x-claude-md-nested (#136, `8bc7b41`)** — `sources/CLAUDE.md` + `specs/CLAUDE.md` 도입.
- **LSP/MCP 활용 가이드** — agent.md §6.5 (Static Analysis First) 확장. 적용 대상 프로젝트가 LSP 지원 언어일 때 grep 대신 심볼 기반 정의/참조 추적 권장 (기사 인사이트 #4)
- **도그푸딩 sync 자동화** (부분 해결) — drift 가시화는 ✓ `sdd status` 의 `_drift_dogfood_sync()` (sources vs installed diff 경고) 로 구현됨. 잔여: `update.sh --check` dry-run 모드 / post-merge 자동 update 는 미착수.
- ~~**ADR-NNN-dogfood-sync-policy 작성** (convention)~~ → ✓ **ADR-003** 작성 (2026-05-28, commit `3a4ad76`)
- ~~**`check-secrets.sh` `.env.*.example` 패턴 제외 fix**~~ → ✓ **spec-x-check-secrets-env-example** — `.env` 매칭 후 `grep -vE '\.(example|sample)$'` 로 템플릿 제외.
- **ADR-NNN-tool-output-in-tree-vs-out-of-tree** (type: tradeoff) — harness-kit 의 도구 출력물 (review/critique vs walkthrough/pr_description) 의 위치 정책 (in-spec-dir vs `.harness-kit/cache/`) 결정 자산화. spec-x-install-ignore-coverage 의 critique (대안 A) 가 떠올린 근본 분기점. 본 spec 머지 후 별도 spec-x-adr-tool-output 또는 ADR 단독 작성. 향후 신규 산출물 (`code-review-claude.md`, `code-review-codex.md`, JSON/HTML 형식 등) 추가 시 한 페이지 참조로 결정 가능
- **컨테이너 빌드 컨텍스트 비대칭** — `install.sh` 가 `.gitignore` 는 자동 관리하면서 `.dockerignore` 는 손대지 않음. Dockerfile 있는 프로젝트에 설치 시 `.harness-kit/`, `archive/`, `specs/`, `.env.*` 등이 빌드 컨텍스트에 포함되어 (a) WSL2 + Docker Desktop 환경에서 컨텍스트 전송 지연, (b) `COPY . .` 패턴 사용 시 `.env.telegram`/`.env.discord` 토큰이 이미지에 포함될 위험. fix 후보: `sdd doctor` 에 "Dockerfile 존재 + .dockerignore 에 `.harness-kit/` 미등재" 경고 + README 컨테이너 가이드 섹션. `install.sh` 자동 갱신은 사용자 정책 충돌 우려로 보류. 검토 메모: 토큰 유출은 대부분 프로젝트가 이미 `.env*` 차단으로 방어됨 — 진짜 비대칭 가치는 spec/archive 수백 파일로 인한 컨텍스트 비대화. Containerfile/compose.yml/Earthfile 등 다른 컨테이너 도구도 동일 함정. 권장 항목에서 `telegram.sh` 제외 (사용자 측 임의 스크립트 가능성)
- **AUQ 잔존 호출 경로 추가 점검** — `spec-x-notify-bidirectional-policy` 후 "에이전트는 AskUserQuestion 사용 안 함" 정책이 있음에도, align 직후 단순 의도 확인 시 AUQ 호출 사례 발생 (2026-05-29). 정책 텍스트만으론 부족할 수 있어 보강 검토: (a) `agent.md §8.4` / CLAUDE.md fragment 의 "사용 안 함" 문구를 더 강하게 (예: "절대 금지 — 위반 시 RCA"), (b) AUQ 호출 시 사전 차단 hook 검토 가능성, (c) 메모리 보강 [[feedback-no-auq-ever]] 와 별개로 거버넌스 문서 자체 강화 필요 여부 평가
- **Discord embed 기반 구조화 메시지 (`spec-x-notify-discord-embed`)** — `spec-x-notify-channel-formatter` 의 시각 검증 (2026-05-29) 에서 *모바일 좁은 화면* 의 code-block 표가 *긴 셀* (예: 31 chars `spec-x-notify-channel-formatter`) 일 때 자동 word wrap → 정렬 깨짐 실증. Critique 의 *대안 B (embed)* 가 결정적 — title/description/fields 분리로 모바일 가독성 우위. surface: `notify-discord.sh` 의 `content` 송신 → `embeds` JSON 으로 확장, embed 본문 4096자 / field name 256 / value 1024 / 총 6000자 제한 (Discord API), chunking 재설계. ADR-006 `discord-table-rendering-policy` (type: tradeoff) 본 spec 트리거 시 작성. *직전 spec 의 한계가 다음 spec 의 정확한 ROI* — 문제-실증 기반 spec 정신
- ~~**stale ADR 오탐 근본책 (sdd drift 가 archive/ 미탐색)**~~ → ✓ **spec-x-stale-adr-archive-path** 로 해결 (2026-06-09): `_drift_stale_adr()` 에 `[ -e "$SDD_ROOT/archive/$token" ] && continue` fallback (fix a) + 회귀 테스트 Step 5/6 + dogfood sync. Gemini cross-model Approve(0/0/0). 잔여 follow-up:
  - **(b) ADR 가 spec 참조 시 영구 식별자(PR#/commit SHA) 권장** (convention) — fix(a)의 보완재. 미착수 (Icebox).
  - **비기본 `specsDir`/`backlogDir` 대응 — `$SDD_SPECS` 기반 동적 archive 경로** — 현재 fix 는 기본 경로 1단계 prefix 전제. 외부 확산 시점 재평가 (critique/gemini 공통 관찰).
- ~~**CC 네이티브 세션 기능 검증 spec**~~ → ✓ `spec-x-native-session-feature-verify` 로 검증 (2026-06-02): `/background`·`/branch` 문서+정적 분석 → 조건부 Go(2단계) 승격, ADR-007 Amendment 반영. 잔여 라이브 test 1(계층 1 자동 알림)은 사용자 체크리스트로 분리(Done 조건 아님)
- **`/batch` Bitbucket 정합성** — target Bitbucket 에서 `/batch` 자동 PR off + worktree diff → `/hk-pr-bb` 경로. 검증 테스트 2·3·5 해소 전 보류. 도그푸딩(GitHub) 시점엔 정합하나 키트 배포 대상 중립성 우선. (조사: report §5 보류)
- ~~**CC 네이티브 1단계 6종 즉시 채택**~~ → ✓ `native-feature-usage.md` 에 6종(`/deep-research`·`/workflows`·`/copy`·`/rewind`·`/team-onboarding`·`/btw`) "1단계" 표로 채택 반영.
- **`/goal` 검증정책 Q1-b 적극안** — `spec-x-goal-verify-gate`(PR #30, 보수안 Q1-a) 머지 완료. 잔여 = 완전 무중단: 계획 *내* 가역 마이크로 A/B 의 **logged-default 레인**(멈춤 대신 default 선택+로그+ship 일괄 보고) + **agent.md §7 hard-stop 완화**. 중앙 규약(§7) 변경이라 보수안 운영 데이터 축적 후 별도 spec 승격 (hook 단계론). (2026-06-04)

- ~~**gemini-review.sh 엣지케이스 2종** (spec-21-01 발견)~~ → ✓ **spec-x-gemini-review-edgecases** 로 해결 (2026-06-09): (a) base 브랜치 부재 시 main fallback + (b) 지시문 argv→stdin 이동(ASCII 영어 `-p`). guard 테스트 T6/T7 추가 (16/16 PASS).
- ~~**gemini-review.sh plan-mode 위반 (심각, spec-21-04 발견)**~~ → ✓ **spec-x-gemini-review-sandbox** 로 해결 (2026-06-05 머지): `--approval-mode plan` read-only 불신 + 방어 래퍼(부수효과 감지/거부 + clean-pre 자동 원복 + 형식 검증). guard 테스트 12종. (완료 표기 누락분 — spec-x-gemini-review-edgecases 에서 정리.)
- ~~**spec-21-06 persona-review-panel**~~ → ✓ **phase-22 research (PR #45) 로 결론 (2026-06-08)**: Conditional No-Go — POC(n=1)에서 페르소나 패널이 self-consistency baseline(Opus×3)을 지배 못함(상보적, 비용 동급). 단순 패널 미구현. 후속 = 아래 하이브리드 항목.
- ~~**persona-panel 하이브리드 재설계 research**~~ → ✓ **spec-x-persona-hybrid-research (#48, 2026-06-09)**: Conditional No-Go (블랭킷 페르소나 패널). 발견 — generalist 정독=깊이 lever(항상 유효), 페르소나=폭 lever(폭 지배 리뷰 한정). Gemini cross-model blind 채점, n=2 (S1 폭 PASS / S2 깊이 FAIL, B1 cheaperEqual). 후속 = 아래 B1 항목.
- ~~**`hk-*-review` 기본을 B1 패턴으로 업그레이드** (persona-hybrid research 권고 A)~~ → ✓ **spec-x-review-b1-default** (2026-06-09): `/hk-code-review` 를 B1(Opus×3 self-consistency + generalist 정독 → 증류)로 교체 + 증류 조작적 정의(critique blocking 갭) + 페르소나 opt-in 문서화 + **ADR-013**(review-value-baseline)·**ADR-014**(review-eval-independence) invariant. 잔여 follow-up 아래.
  - **B2 — self-consistency N 분리 측정** (N=1 vs N=3 ROI). #48 은 generalist 깊이 회복만 직접 측정, N=3 비용 3배 증분은 미측정(약근거). 외부 문헌(arXiv 2511.00751)상 frontier self-consistency 증분 작음 — N 적정값 실측 필요.
  - **적응형 N / 폭·깊이 자동 라우팅** (#48 권고 B + spec-x-review-b1 critique 대안 A) — diff 크기·성격 판별로 N 또는 패널/B1 선택. 미검증·경계값 임의성으로 보류. B2 측정 후 재평가.
  - **hk-phase-review B1 적용 검토** — 코드 리뷰(diff) 외 phase 회고(다파일 감사)에 self-consistency 가 값하는지 별도 측정. 본 spec OOS.
- ~~**sdd ship spec-x 커밋 subject slug truncation 버그** — `docs(spec-x-review):` 로 `-b1-default` 누락~~ → ✓ **spec-x-sdd-robustness-fixes (#50, `f495749`)** 로 해결 (2026-06-09): `sdd_ship_scope()` 신설 — `spec-x-*` 케이스 전체 id 유지 + `tests/test-sdd-ship-scope.sh` 회귀 5/5 PASS. (strike 누락분을 spec-x-stale-adr-archive-path 에서 정리.)
- **test-drift-stale-adr.sh Step 2 Windows 플래키** — fixture(untracked ADR-999) 탐지가 간헐 실패(b6c2rakls PASS / bze38u4y7 FAIL, 동일 코드). Windows fs 쓰기→즉시 sdd status 읽기 race 또는 워킹트리 dirty 민감 의심. macOS 1차 타깃이라 best-effort — 재실행 시 green. 안정화(예: fixture write 후 sync/대기) 검토.
- ~~**`.gitignore` review 산출물 패턴이 `archive/` 미커버 (kit 버그, 2026-06-08 발견)**~~ → ✓ **spec-x-gitignore-archive-coverage (#46, `c5f28f8`)** — `.gitignore` 에 `archive/specs/**/code-review*.md` 추가(ignore 대칭). 잔여(소): 옛 archived spec 의 tracked `code-review*.md` 혼재 정리 정책 미결 — 필요 시 별도.

**[phase-17 으로 promote 된 항목 — 처리 진행 중]**:
- ~~접근성 개선~~ → phase-17 **spec-17-02** (accessibility-install-and-entry)
- ~~sdd marker 버그 (W5/W10)~~ → ✓ **spec-17-01** 머지로 종식 (RCA-001 prevention)
- ~~installed.json 캐시 (C3)~~ / ~~phase integration test (W2)~~ / ~~doctor 새 경로 (W6)~~ → phase-17 **spec-17-03** (internal-reliability-infra)
- ~~§6.4 표현 (W1)~~ / ~~stale ADR 회귀 마커 (W3)~~ / ~~ADR 가이드 (W4)~~ / ~~CHANGELOG 정책 (W7)~~ → phase-17 **spec-17-04** (governance-test-coherence)
- ~~sdd phase done title 버그~~ → ✓ **spec-17-01** 머지로 종식 (normalize)

## 📋 대기 Phase

> 다음에 진행할 phase 를 자유롭게 메모합니다 (사람이 직접 편집).
> 자동 갱신되지 않습니다 — Icebox 와 동일한 정책.

- **phase-21 후보 — director mode (컨텍스트 오케스트레이션)** — phase-20 성공기준 2 에서 **의식적 이관** (2026-06-04, 규모상 별도 phase 승격). upstream ADR-005/006 재구현 3부작: ① context orchestration(메인=orchestrator + worker offloading) ② `/hk-director` 모드 + ceremony 위임 ③ 페르소나 리뷰 패널. multi-spec 예상, ADR 010+(009=phase-FF), 검증 불변식(워커 transcript 전문 재흡수 금지) 포함. 참조: upstream `agent.md §6.1/6.6/6.8`, `hk-director.md`, `tests/test-director-*.sh`. **governance word-count(Check 3) 해소를 위한 agent.md 축소도 본 phase 에서 병행.**

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
- [x] spec-x-native-session-feature-verify (완료)
- [x] spec-x-native-feature-usage (완료)
- [x] spec-x-human-gate-model-lock (완료)
- [x] spec-x-goal-verify-gate (완료)
- **phase-20** — upstream-parity — completed 2026-06-04
- [x] spec-x-icebox-prune (완료)
- [x] spec-x-gemini-review-sandbox (완료)
- **phase-21** — director-mode — completed 2026-06-08
- **phase-22** — persona-review-panel — completed 2026-06-08
- [x] spec-x-gitignore-archive-coverage (완료)
- [x] spec-x-gemini-review-edgecases (완료)
- [x] spec-x-persona-hybrid-research (완료)
- [x] spec-x-review-b1-default (완료)
- [x] spec-x-sdd-robustness-fixes (완료)
- [x] spec-x-stale-adr-archive-path (완료)
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
