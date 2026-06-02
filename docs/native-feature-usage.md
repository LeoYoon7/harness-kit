# Claude Code 네이티브 기능 사용 playbook (상황 → 기능 → 조건)

> 본 문서는 harness-kit 거버넌스 하에서 **어떤 상황에 어떤 Claude Code 네이티브 기능을, 어떤 조건으로 쓰는지**를 한눈에 보는 *사용 관점 reference* 입니다.
>
> **단일 출처 원칙**: 도입 판단과 조건의 **정본은 ADR-007** (`docs/decisions/ADR-007-native-feature-adoption-policy.md`) 과 그 Amendment 입니다. 본 문서는 사용 관점 *합성*이며, **모순이 있으면 ADR-007 이 우선**합니다. 8충돌축 근거는 조사 `spec-x-cc-native-adoption` (PR #25) `report.md`.
>
> **배포 범위**: 본 문서는 kit repo 전용(미배포)입니다. 배포되는 거버넌스 요지는 `agent.md §6.7`.

## 1. tier 정의

| tier | 의미 | 게이트 영향 |
|---|---|---|
| **1단계 — 무조건 사용 가능** | 거버넌스와 직교(코드/state 변경·게이트 우회 없음) | 없음 |
| **2단계 — 조건부** | 자율·권한·모델·웹핸드오프를 건드림. 게이트 보존 조건 하에서만 (ADR-007) | 있음 |
| **3단계 — 검증완료 조건부** | 세션 분리 기능. 문서+정적 분석 검증 후 조건부 채택 (ADR-007 Amendment, PR #27) | 있음 |
| **보류** | 조건 미충족으로 도입 보류 | — |
| **N-A — 거버넌스 무관** | 개인 사용. 도입 논의 밖 | — |

> **공통 원칙 (ADR-007)**: 자율·세션분리·웹핸드오프 기능이 텍스트 게이트(§8.5)·Plan Accept·양방향 알림(§10) **응답 기회를 박탈하지 않도록**, 각 게이트에서 멈추고 보고하는 조건을 보존한다. 규약(convention) 수준 — hook 강제 아님, 위반은 walkthrough/RCA 로 학습.

## 2. 상황별 사용 가이드 (★ 핵심)

> "지금 이 상황엔 뭘 쓰지?" → 아래에서 상황을 찾고, tier·조건을 확인한다.

| 상황 (when) | 권장 기능 | tier | 어떻게 (조건 요약) |
|---|---|:---:|---|
| 근거 수집 / 사전 조사 | `/deep-research` | 1 | 그대로 사용. 결과를 spec.md 에 첨부 → `/hk-spec-critique` 로 넘기는 흐름 권장 |
| 웹 핸드오프로 계획 수립 | `/ultraplan` | 2 | 복귀한 플랜을 **반드시 `/hk-plan-accept` 로 재게이팅** |
| 워크플로 관찰(watch/pause/resume) | `/workflows` | 1 | 그대로 사용 |
| 직전 응답을 PR/문서로 이관 | `/copy [N]` | 1 | 그대로 사용 (SSH 시 `w` 로 파일 저장) |
| 롤백 / 체크포인트 | `/rewind` | 1 | conversation 롤백 위주. **코드 롤백은 `git status` 확인 후** (git hook 관리와 어긋남 주의) |
| 온보딩 가이드 생성 | `/team-onboarding` | 1 | 가이드 생성 무관. *공유 링크*만 Pro/Max/Team/Ent 한정 |
| 흐름 안 깨는 짧은 질문 | `/btw` | 1 | 정보성 질문만. **새 작업 아이디어는 Idea Capture Gate(§5.5)로** |
| 긴 mechanical 자동 실행(테스트 수트·대량 수정) | `/background` (`/bg`) | 3 | **게이트가 예상되지 않는 구간 한정**. 게이트 발생 시 **계층 2 명시 `notify.sh` 필수**(계층 1 자동 hook 의존 금지). worktree 격리가 SDD 단일 체크아웃과 어긋남 인지 |
| 대안 탐색 분기 | `/branch` (`/fork`) | 3 | 기본은 peer fork(`CLAUDE_CODE_FORK_SUBAGENT` 미설정) — 게이트 보존. 세션 권한 재승인 인지. `=1` 은 백그라운드 subagent → `/background` 조건 적용 |
| 단일 spec/phase 자율 진행 | `/goal` | 2 | 단일 spec/phase 의 **acceptance criteria 한정** + 조건문에 "각 게이트에서 멈추고 보고" 명시. **phase 경계 불가침** |
| 구현 phase 심화 추론·오케스트레이션 | `/effort ultracode` | 2 | **확정된 구현 phase 내부 한정**. 전체 프로젝트 적용 금지. 토큰 소모 큼 |
| 권한 프롬프트 줄이기 | `/fewer-permission-prompts` | 2 | 생성된 allowlist **커밋 전 검토**. `.env*`·SSH 키 가드 우회 금지 |
| 중요 PR ship 직전 보강 리뷰 | `/code-review ultra` (`/ultrareview`) | 2 | 중요 PR ship 직전 **1회 보강**. 정식 리뷰는 `/hk-gemini-review` + `/hk-code-review`. 무료 3회/월 후 크레딧 |
| 수시 리뷰 / 자동 수정 | `/code-review` (기본형) | 2 | `--fix`·`--comment`·effort 조절이 고유 가치인 **보조** 도구. ship 게이트 정식 리뷰 대체 금지. `--comment` 는 GitHub PR 전제 |
| 반복 프로세스 자산화 | 스킬 시스템 (`/skills`) | 2 | `/hk-*` 와 **중복 안 되는** 개인 반복 작업 한정. 컨텍스트 비용 3순위(bash > slash > skill > MCP) 인지 |

## 3. tier 2·3 기능별 조건 (ADR-007 발췌)

> 정본은 ADR-007 / Amendment. 본 절은 빠른 참조용 요약.

**2단계 (조건부 Go)**

| 기능 | 게이트 보존 조건 | 막는 충돌 |
|---|---|---|
| `/goal` | 단일 spec/phase acceptance criteria + "각 게이트에서 멈추고 보고" 명시. phase 경계 불가침 | 자율 지속이 §8.5·Plan Accept 건너뜀 |
| `/effort ultracode` | 확정된 구현 phase 내부 한정. 전체 프로젝트 금지 | 자동 오케스트레이션이 phase별 모델 지정 override |
| `/fewer-permission-prompts` | allowlist 커밋 전 검토. `.env`·SSH 가드 우회 금지 | 무검토 allowlist 가 권한 자세 약화 |
| `/code-review ultra` | 중요 PR ship 직전 보강 1회(크레딧 제한). 정식 리뷰는 `/hk-gemini-review`+`/hk-code-review` | 크레딧 소진 + 정식 리뷰 대체 오인 |
| `/code-review` 기본형 | 수시 정리·자동수정(`--fix`) 보조. ship 정식 리뷰 대체 금지 | spec 대비 검증·테스트 커버리지 누락 |
| `/ultraplan` | 복귀 플랜을 `/hk-plan-accept` 로 재게이팅 | 계획이 훅·멀티모델·§8.5 밖에서 수립 |
| 스킬 시스템 | `/hk-*` 와 중복 안 되는 작업 한정. 컨텍스트 비용 인지 | 거버넌스 워크플로 중복·컨텍스트 비용 |

**3단계 (검증완료 조건부, PR #27)**

| 기능 | 게이트 보존 조건 | 막는 충돌 |
|---|---|---|
| `/branch` (peer fork) | 기본은 peer fork(`FORK_SUBAGENT` 미설정) — 컨텍스트·settings(hook)·모델·git 상태 승계로 게이트 보존. 세션 권한 재승인 인지 | fork 세션이 hook(F)·§8.5(A)·멀티모델(C) 미승계 우려 (→ 승계 확인) |
| `/background` | 게이트 없는 mechanical 구간 한정. 게이트 시 계층 2 명시 알림 필수. worktree 격리 ↔ SDD 단일 체크아웃 인지 | 백그라운드 계층 1 자동 알림 미확정 → 알림 누락(축 B, §9 비대칭 비용) |
| `CLAUDE_CODE_FORK_SUBAGENT=1` | `/fork` 가 백그라운드 subagent → `/background` 조건 적용 | 위 `/background` 와 동일 |

> `/background` 의 계층 1 자동 hook 발화 여부는 라이브 미확정 — 확인 시 조건 완화 가능 (`spec-x-native-session-feature-verify` report §6 체크리스트).

## 4. 경계 (각주)

- **보류 — `/batch`**: 다수 worktree 서브에이전트가 단위별 PR 자동 생성. target Bitbucket 자동 PR 정합성(자동 PR off + worktree diff → `/hk-pr-bb`) + 병렬·알림 한계(검증 테스트 2·3·5) 해소 전까지 보류. 도그푸딩(GitHub)에선 자동 PR 이 정합하나, 키트 배포 대상 중립성을 우선해 보수적으로 둔다.
- **N-A (거버넌스 무관) — `/powerup`·`/radio`**: 학습 레슨 / lo-fi BGM. SDD 거버넌스·개발 워크플로와 무관한 개인 사용 항목 — 막을 이유도 권장할 이유도 없다. (`/radio` 는 Bedrock·Vertex·Foundry 백엔드 미지원.)
- **사용 제한(축 H)**: 현 플랜에서 실질 가용성 제약은 `/code-review ultra` 크레딧(무료 3회/월)뿐. 나머지는 비용(토큰) 차원. 단 키트가 하위 플랜(무료/Pro)에 배포될 때는 클라우드/Workflow 기능 가용성 재확인 필요. 정확한 한도는 세션 `/help` 가 최종 기준.
