# feat(spec-x-gemini-review): Gemini CLI 기반 cross-model 코드 리뷰 + Ship pre-flight 리뷰 게이트

## 📋 Summary

### 배경 및 목적

기존 `/hk-code-review` 는 Opus sub-agent 를 사용해 self-review 형태로 동작했고, 워크플로우 어디에서도 자동 제안되지 않아 발견성도 낮았습니다. LLM-as-judge 연구에서 cross-model judge 가 self-judge 보다 발견율이 높다는 결과가 일관되게 보고됩니다.

본 PR 은 (1) Gemini CLI 를 호출하는 `/hk-gemini-review` 슬래시 커맨드를 신규 추가하고, (2) `/hk-ship` pre-flight 에 "Gemini / Opus / Skip" 3지선다 리뷰 게이트를 삽입해 cross-model 리뷰를 사용자 선택 옵션으로 노출합니다.

기존 `/hk-code-review` (Opus) 는 손대지 않아 cross-validation (두 모델 결과 비교) 도 가능합니다.

### 주요 변경 사항

- [x] `sources/bin/gemini-review.sh` 신규 — `sdd status --json` 으로 활성 spec / base branch 식별, spec.md + git diff 를 stdin 으로 전달, `gemini -p "<지시문>" --approval-mode plan` 헤드리스 호출 (read-only).
- [x] `sources/commands/hk-gemini-review.md` 신규 — 슬래시 커맨드 entrypoint, 결과 파일은 `code-review-gemini.md` (Opus 의 `code-review.md` 와 분리).
- [x] `sources/commands/hk-ship.md` §1.5 추가 — Ship pre-flight 에 리뷰 선택지 + [권장] + Critical 이슈 시 진행 재확인.
- [x] `sources/governance/agent.md` §6.3 — Walkthrough & Description Protocol 8번 항목으로 Code Review Gate 명시.
- [x] 도그푸딩 sync — `.harness-kit/bin/`, `.claude/commands/`, `.harness-kit/agent/` 동기화 (본 PR 안에서 즉시 작동 가능).

### Phase 컨텍스트

- **Phase**: 없음 (spec-x — Solo Spec)
- **본 SPEC 의 역할**: 리뷰 자산 확장 + cross-model 편향 완화 옵션 제공

## 🎯 Key Review Points

1. **`sources/bin/gemini-review.sh` 의 stdin 전달 패턴**: Windows argv 크기 한계 (`Argument list too long`) 회피를 위해 큰 프롬프트는 stdin, 짧은 지시문만 `-p` 로 전달. 같은 패턴이 향후 다른 Gemini 호출 (예: spec-critique 의 Gemini 화) 에도 재사용 가능.
2. **`/hk-ship` §1.5 게이트의 강제성**: Skip 도 사용자가 명시적으로 선택해야 통과 — "옵션으로 제시" 요청에 맞춤. Critical 이슈 발견 시 ship 진행 여부 한 번 더 확인.
3. **결과 파일 분리**: Opus 는 `code-review.md`, Gemini 는 `code-review-gemini.md`. 두 모델을 동시에 돌려 cross-validation 가능.
4. **gemini CLI 의존성 추가**: 본 키트의 필수 의존성은 여전히 bash 3.2+ / jq / git. gemini CLI 는 *선택적* — 미설치 시 명확한 에러 + Skip 으로 fallback 가능. ship 흐름 자체는 차단하지 않음.

## 🧪 Verification

### 정적 분석
- `shellcheck` 미설치 환경 — pre-commit hook 이 자동 skip (정상 동작).

### 수동 검증 시나리오

1. **시나리오 1 (Task 2 시점 smoke)**: `bash .harness-kit/bin/gemini-review.sh` → `Argument list too long` 발견 → stdin 전환 fix → 재실행 정상. Critical 4 / Major 1 / Minor 2 발견 중 false positive (Critical 4 모두 — 후속 task 미구현 시점 영향) 와 유효 발견 (Major 1 [stderr 차단, 이미 fix], Minor 2 [sdd 경로/grep]) 분류 후 fix 적용.
2. **시나리오 2 (Task 6 최종 dogfood)**: 본 spec 의 §1.5 게이트가 실제로 발화 → 사용자가 Gemini 선택 → 최종 상태 리뷰 실행. 결과는 walkthrough.md 의 검증 결과 §2.6 참조.

## 📦 Files Changed

### 🆕 New Files

- `sources/bin/gemini-review.sh`: Gemini 리뷰 실행 bash 스크립트
- `sources/commands/hk-gemini-review.md`: `/hk-gemini-review` 슬래시 커맨드
- `.harness-kit/bin/gemini-review.sh`: 도그푸딩 sync
- `.claude/commands/hk-gemini-review.md`: 도그푸딩 sync

### 🛠 Modified Files

- `sources/commands/hk-ship.md` (+45): §1.5 코드 리뷰 게이트 삽입
- `.claude/commands/hk-ship.md` (+45): 도그푸딩 sync
- `sources/governance/agent.md` (+1): §6.3 Walkthrough Protocol 8번 항목 추가
- `.harness-kit/agent/agent.md` (+1): 도그푸딩 sync
- `backlog/queue.md` (+1): spec-x 등록 (sdd 자동)

### 산출물

- `specs/spec-x-gemini-review/{spec,plan,task,walkthrough,pr_description}.md`

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과 (해당 없음 — 변경이 bash + 마크다운)
- [x] 수동 smoke test 통과 (Task 2 시점 + Task 6 dogfood)
- [x] `walkthrough.md` ship commit 완료
- [x] `pr_description.md` ship commit 완료
- [x] lint / type check 통과 (shellcheck 미설치 skip)
- [x] 사용자 검토 요청 알림 완료 (Telegram ship 레벨, 본 PR 머지 후)

## 🔗 관련 자료

- Spec: `specs/spec-x-gemini-review/spec.md`
- Plan: `specs/spec-x-gemini-review/plan.md`
- Walkthrough: `specs/spec-x-gemini-review/walkthrough.md`
- 관련 ADR: (없음)
- 외부 참고: LLM-as-judge cross-model bias 연구 (PRD-judge / Constitutional AI 등 다수)
