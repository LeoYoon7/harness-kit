# spec-x-gemini-review: Gemini CLI 기반 코드 리뷰 커맨드 추가 및 ship pre-flight 리뷰 게이트

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-gemini-review` |
| **Phase** | (없음 — Solo Spec) |
| **Branch** | `spec-x-gemini-review` |
| **상태** | Planning |
| **타입** | Feature (small-scope) |
| **Integration Test Required** | no |
| **작성일** | 2026-05-28 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

본 키트의 코드 리뷰 자산은 다음과 같습니다.

- `/hk-code-review` — Opus sub-agent (Agent tool, `model: "opus"`) 가 현재 spec 브랜치의 변경을 리뷰. 결과는 `specs/<spec-dir>/code-review.md` 에 저장.
- `/hk-spec-critique` — Plan Accept 전, Opus sub-agent 가 spec.md 를 비평. `.harness-kit/agent/agent.md` §4.4 에서 자동 제안됨.
- `/hk-phase-review` — Phase 회고용 Opus sub-agent.

### 문제점

1. **같은 모델 self-evaluation 의 편향**. Opus 가 작성/실행한 코드를 다시 Opus 가 리뷰하면 자기 추론 패턴에 동의하는 편향이 발생합니다. LLM-as-judge 연구에서 cross-model judge 가 self-judge 보다 발견율이 높다는 결과가 일관됩니다.
2. **`/hk-code-review` 의 발견성 부족**. `agent.md` / `hk-ship.md` / `hk-plan-accept.md` 어디에서도 자동 제안되지 않습니다. 사용자가 슬래시 커맨드 존재 자체를 인지해야만 호출 가능 — 실제 운영에서 한 번도 발화된 사례 없음.
3. **Ship 직전 마지막 검증 부재**. spec critique 는 구현 *전* 시점이고, 구현 *후 push/PR 직전* 의 검증 기회가 워크플로우에 없습니다.

### 해결 방안 (요약)

(1) Gemini CLI 를 호출하는 신규 `/hk-gemini-review` 커맨드를 추가하고, (2) `/hk-ship` pre-flight 에 "리뷰 진행할까요? 1) Gemini 2) Opus 3) Skip" 선택지를 삽입하여 cross-model 리뷰를 옵션으로 노출합니다. 기존 `/hk-code-review` (Opus) 는 변경 없이 그대로 유지합니다.

## 🎯 요구사항

### Functional Requirements

1. **신규 bash 스크립트** `sources/bin/gemini-review.sh`
   - 현재 활성 spec 디렉토리를 `sdd status --json` 으로 식별.
   - PR base branch (phase base 또는 main) 를 동일 명령으로 식별.
   - `spec.md` 본문 + `git diff <base>...HEAD` 를 묶어 프롬프트로 구성.
   - `gemini -p "<prompt>" --approval-mode plan` 헤드리스 호출 (read-only).
   - 출력을 `specs/<spec-dir>/code-review-gemini.md` 에 저장.
   - 실패 케이스: gemini CLI 미설치 / spec 비활성 / 변경 없음 → 명확한 에러 메시지 + 비-0 exit.
2. **신규 슬래시 커맨드** `sources/commands/hk-gemini-review.md`
   - 위 bash 호출 + 결과 헤더 요약을 사용자에게 보고.
3. **`/hk-ship` 수정** — pre-flight 의 사전 검증(§1) 직후, 품질 게이트(§2) 직전에 리뷰 선택지 블록 삽입.
   - 선택지: `1) Gemini (cross-model, 권장)` / `2) Opus (기존)` / `3) Skip`
   - `[권장]` 라벨 포함 (`.harness-kit/CLAUDE.fragment.md` 선택지 제시 규약 준수).
   - 사용자 선택 후 해당 리뷰 실행. Skip 이면 바로 §2 로 진행.
   - Critical 이슈가 있으면 사용자에게 보고 후 ship 진행 여부 재확인.
4. **`/hk-code-review` 결과 파일 이름 유지**. `code-review.md` (Opus). Gemini 는 `code-review-gemini.md` 로 분리 → cross-validation 시 두 결과 동시 보존 가능.
5. **agent.md §6.3 갱신**. Walkthrough & Description Protocol 에 "Ship 전 코드 리뷰 게이트" 한 줄 추가 (Gemini / Opus 선택 가능, 권장: Gemini).
6. **도그푸딩 sync**. `sources/` 에서 작성한 변경을 `.harness-kit/bin/`, `.claude/commands/`, `.harness-kit/agent/` 에도 복사하여 본 PR 안에서 즉시 작동 가능하도록 함 (본 프로젝트는 도그푸딩 중).

### Non-Functional Requirements

1. **bash 3.2+ 호환**. `declare -A`, `mapfile` 등 bash 4+ 기능 금지 (`CLAUDE.md` 작업 원칙 §3).
2. **gemini CLI 미설치 시 graceful**. bin 스크립트는 명확한 에러 메시지 (`gemini CLI 가 설치되지 않았습니다`) 와 함께 종료. Ship 흐름 자체는 차단하지 않음 (Skip 으로 fallback 가능).
3. **read-only 보장**. `gemini --approval-mode plan` 으로 호출하여 워크스페이스 수정 차단.
4. **출력 파일은 한국어**. Gemini 프롬프트에 "한국어로 작성하세요" 명시.
5. **install/update 영향 없음**. `install.sh` 가 `sources/bin/*` 와 `sources/commands/*` 를 글롭으로 복사하므로 새 파일 추가에 install.sh 수정 불필요 (확인: `install.sh:343` `do_cp_r "$KIT_DIR/sources/bin/." "$TARGET/.harness-kit/bin/"`).

## 🚫 Out of Scope

- 기존 `/hk-code-review` 동작 변경 (모델 교체, 출력 위치 변경 등).
- `/hk-spec-critique` / `/hk-phase-review` 의 Gemini 화 (후속 별도 spec 으로 검토 가능).
- Gemini 와 Opus 결과 자동 병합 / cross-validation 리포트.
- `.env.gemini` 추가 (gemini CLI 가 자체 인증 관리하므로 불필요).
- `/hk-pr-gh` / `/hk-pr-bb` 에 리뷰 게이트 추가 (hk-ship 만 손댐).
- 리뷰 결과를 PR 본문에 자동 첨부.

## 📑 ADR 후보 (Architecture Decision Records)

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — 기존 `/hk-code-review` 패턴을 미러링하는 추가 옵션이고, "cross-model 리뷰가 self-review 보다 효율적" 은 외부 연구로 정립된 사실이라 ADR 화 가치 낮음.

## ✅ Definition of Done

- [ ] `sources/bin/gemini-review.sh` 신규 작성 및 도그푸딩 동기화 (`.harness-kit/bin/gemini-review.sh`)
- [ ] `sources/commands/hk-gemini-review.md` 신규 작성 및 도그푸딩 동기화 (`.claude/commands/hk-gemini-review.md`)
- [ ] `sources/commands/hk-ship.md` 수정 및 도그푸딩 동기화 (`.claude/commands/hk-ship.md`)
- [ ] `sources/governance/agent.md` §6.3 갱신 및 도그푸딩 동기화 (`.harness-kit/agent/agent.md`)
- [ ] `gemini-review.sh` 수동 smoke test PASS (현재 spec 자체에 적용해 정상 동작 확인)
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-gemini-review` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
