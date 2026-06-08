# phase-22: persona-review-panel

> 본 phase 의 모든 SPEC 을 한 파일에 요점/방향성으로 나열합니다.
> *구체적* 작업 내용은 `specs/spec-22-{seq}-{slug}/spec.md` 에서 다룹니다.
>
> 본 문서는 "이번 phase 에서 무엇을 어디까지 할 것인가" 를 한 번에 보기 위한 *업무 지도* 입니다.

## 📋 메타

| 항목 | 값 |
|---|---|
| **Phase ID** | `phase-22` |
| **상태** | Planning |
| **시작일** | 2026-06-08 |
| **목표 종료일** | (미정 — research 결과에 따라) |
| **소유자** | Leo |
| **Base Branch** | 없음 (non-base — research 결과가 no-go/재설계 가능성이라 base 브랜치에 미리 묶지 않음) |

## 🎯 배경 및 목표

### 현재 상황

phase-21(director-mode)에서 persona-review-panel 은 정량 성공기준 5개 외 후순위로 **Icebox defer** 되었다 (2026-06-08, phase-ship go/no-go). defer 사유는 "페르소나 패널 종료조건·증류 난점(무한 루프·context 오염)" 으로, 단순 구현이 아니라 **미검증 설계 문제**다.

upstream(Changsik00/harness-kit)을 조사한 결과, **upstream 에도 persona-panel 구현 명세(spec-20-06)는 존재하지 않는다.** `tests/test-director-mode.sh` 의 T13(3개 review 커맨드에 "페르소나 패널" 텍스트 문구 존재) / T14(sources ↔ .claude 미러 parity)만 있고, 실제 패널 오케스트레이션은 upstream 도 Icebox 로 유보했다. 중재(mediation) 패턴 역시 upstream 은 research-only 로만 다뤘다.

즉 이 기능은 "복사 포팅" 대상이 아니라, fork 가 **처음으로 설계를 확정해야 하는 연구 과제**다. 그래서 본 phase 는 *research-first* — 구현부터 들어가면 defer 사유(아래 5난점)가 그대로 리스크로 남는다.

### 목표 (Goal)

review 커맨드(`hk-code-review`/`hk-spec-critique`/`hk-phase-review`)에 **페르소나 패널** 오케스트레이션(단일 Opus → 페르소나 부여 워커 패널 + 종합/중재)을 도입할지·어떻게 할지를, **5개 미해결 난점을 먼저 연구로 해소**한 뒤 (Go 시) 구현한다. research 가 No-Go 면 그 근거를 자산화하고 Icebox 를 정리하며 phase 를 종료한다 (연구 자체가 가치).

### 미해결 5난점 (연구가 답해야 할 것)

1. **종료 조건**: 페르소나 패널·중재가 언제 "충분히 협의됨" 으로 수렴·종료하는가.
2. **증류 (distillation)**: 페르소나별 의견·논거를 어떻게 한 장의 distilled contract 로 압축하는가 (정보 손실 vs 일관성).
3. **무한 루프 방지**: 중재가 새 이슈 제기 → 워커 재실행 → 재중재 순환을 어떻게 차단하는가 (라운드 상한 등).
4. **검증 불변식 양립**: ADR-010 "워커 transcript 전문 재흡수 금지" 와 "중재자는 워커 의견을 이해해야 함" 의 균형.
5. **context 오염**: 패널 전문이 메인 세션 context 를 오염시키지 않게 하는 격리 방식.

### 성공 기준 (Success Criteria) — 정량 우선

1. **(연구) 난점 해소 설계**: 위 5난점 각각에 대해 설계 답안 + **최소 2안 트레이드오프 비교**(§9.1) 가 `report.md` 에 문서화.
2. **(연구) POC 수렴 증빙**: review 커맨드 1개(예: `hk-spec-critique`)에 페르소나 패널 프로토타입을 적용해 **실제 실행**, 종료조건이 유한 라운드에 수렴하고 증류 산출물이 생성됨을 증빙(로그/산출물 첨부).
3. **(연구) Go/No-Go 권고**: §9.1 에 따른 명시적 Go/No-Go 결론 + 근거 문서화.
4. **(조건부 구현 — research Go 시)**: 3개 review 커맨드에 페르소나 패널 절 추가 + `sources ↔ .claude` 미러 parity + 테스트(T13/T14 포팅 + 종료조건 가드 테스트) PASS.

> 기준 4 는 spec-22-01(research) 의 Go 결론을 **전제**로 한다. No-Go 면 기준 1~3 충족 + Icebox 재정리로 phase Done.

## 🧩 작업 단위 (SPECs)

> 본 표는 phase 의 *작업 지도* 입니다. SPEC 은 *요점 + 방향성 + 참조* 까지만 적습니다.
> 자세한 spec/plan/task 는 `specs/spec-22-{seq}-{slug}/` 에서 작성합니다.
> sdd 가 `<!-- sdd:specs:start --> ~ <!-- sdd:specs:end -->` 사이를 자동 갱신하므로 마커는 그대로 두세요.
>
> ⚠ **본 분해는 DRAFT** (constitution §11.3). spec-22-02 는 spec-22-01(research) 의 Go 결론을 전제로 한 *조건부* spec 이며, research 결과에 따라 범위·분해가 바뀌거나 drop 될 수 있다.

<!-- sdd:specs:start -->
| ID | 슬러그 | 우선순위 | 상태 | 디렉토리 |
|---|---|:---:|---|---|
| `spec-22-01` | persona-panel-research | P? | Active | `specs/spec-22-01-persona-panel-research/` |
<!-- sdd:specs:end -->

> 상태 허용값: `Backlog` / `In Progress` / `Merged`
> sdd가 ship 시 자동으로 `Merged`로 갱신합니다. `In Progress`는 active spec에 자동 마킹됩니다.

### spec-22-01 — persona-panel-research (Research Spec, 먼저)

- **요점**: 페르소나 패널의 5난점(종료조건/증류/무한루프/검증불변식/context오염)을 설계로 해소하고, review 커맨드 1개에 POC 를 적용해 수렴을 실증한 뒤 Go/No-Go 를 권고. 산출물은 `report.md`(§9.2, spec.md 대체) + POC.
- **방향성**: §9 Research Spec Protocol. ① 5난점별 ≥2안 트레이드오프 분석 → ② 1개 커맨드(`hk-spec-critique` 권장 — 가장 의견 발산형) POC → ③ 실제 실행 로그로 종료·증류 검증 → ④ Go/No-Go. fork 의 ADR-010(context-orchestration)·ADR-011(director-mode)·ADR-008(human-gate) 불변식과 정합 필수 — 디렉터 게이트는 패널에 위임 불가.
- **참조**:
  - upstream `tests/test-director-mode.sh` T13/T14 (텍스트+미러 — 약한 기준이므로 fork 는 설계로 강화)
  - fork `docs/decisions/ADR-010-context-orchestration.md`, `ADR-011-director-mode.md`, `ADR-008-human-gate-model.md`
  - `archive/backlog/phase-21.md` spec-21-06 절 (defer 근거)
- **연관 모듈**: `specs/spec-22-01-persona-panel-research/report.md`, `scripts/research/` (POC)

### spec-22-02 — persona-panel-impl (조건부 — research Go 시)

- **요점**: research 가 확정한 설계로 3개 review 커맨드에 페르소나 패널 절 추가 + 미러 parity + 테스트.
- **방향성**: spec-22-01 의 `report.md` 설계를 그대로 구현. T13/T14 포팅 + 종료조건/라운드상한 가드 테스트 추가. **research No-Go 면 본 spec 은 생성하지 않고 drop.**
- **참조**: spec-22-01 `report.md`, upstream `tests/test-director-mode.sh` T13/T14
- **연관 모듈**: `sources/commands/hk-code-review.md`, `sources/commands/hk-spec-critique.md`, `sources/commands/hk-phase-review.md`, `.claude/commands/`(미러), `tests/test-persona-panel.sh`

## 📌 결정 기록 (Review)

> Phase PR review 중 발생한 결정·합의·발견을 누적합니다. Spec walkthrough 의 결정 기록과 동일 패턴이며 Phase 레벨 living decision log 역할 (→ agent.md §6.3.2).

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 작업 모드 | spec-x / 새 phase | **새 phase-22 (SDD-P)** | persona panel 은 feature 라 spec-x 자격 미달(§3.3). phase-21 닫혀 spec-21-06 불가 |
| 접근 | 구현 직행 / research-first | **research-first** | defer 사유(5난점) 미해결. upstream 도 중재 research-only. 수렴성 검증 후 구현이 안전 |
| Base 모드 | base / non-base | **non-base** | research 결과가 no-go/재설계 가능 → base 브랜치 선결정 회피 (유연성) |
| upstream 통합 | 포팅 / 재설계 | **재설계** | upstream 에 구현 명세(spec-20-06) 부재. T13/T14 테스트만 존재 → fork 가 설계 확정 |

## 🧪 통합 테스트 시나리오 (간결)

> 본 phase 의 Done 조건 중 하나. 키트 자체 검증 스크립트는 `tests/` 에 위치.

### 시나리오 1: research 수렴 실증 (POC)
- **Given**: spec-22-01 의 페르소나 패널 POC 가 `hk-spec-critique` 에 적용됨
- **When**: 실제 spec 1개에 POC 리뷰 실행
- **Then**: 유한 라운드(상한 내)에 종료 + 증류 산출물 1건 생성 + 메인 context 에 워커 전문 미재흡수(ADR-010 불변식 준수)
- **연관 SPEC**: spec-22-01

### 시나리오 2: (조건부) 커맨드 패널 절 + 미러 parity
- **Given**: research Go 후 spec-22-02 구현 완료
- **When**: `tests/test-persona-panel.sh` 실행 (T13/T14 포팅 + 종료조건 가드)
- **Then**: 3개 커맨드 페르소나 패널 절 존재 + `sources ↔ .claude` 미러 동일 + 종료조건 가드 PASS
- **연관 SPEC**: spec-22-02

### 통합 테스트 실행
```bash
bash tests/test-persona-panel.sh   # spec-22-02 구현 시 신설 (research Go 전제)
```

## 🔗 의존성

- **선행 phase**: phase-21(director-mode) — orchestrator–worker(ADR-010)·director protocol(ADR-011) 기반 위에 패널을 얹음
- **외부 시스템**: 없음 (키트 내부 거버넌스/커맨드)
- **연관 ADR**:
  - 정합 점검: `ADR-010-context-orchestration`, `ADR-011-director-mode`, `ADR-008-human-gate-model`
  - 신규 후보: `ADR-NNN-persona-panel-orchestration` (research Go + 설계 확정 시 작성)

## 📝 위험 요소 및 완화

| 위험 | 영향 | 완화책 |
|---|---|---|
| 종료조건 미수렴 (무한 루프) | 패널이 끝나지 않음 | research 에서 라운드 상한 + 수렴 신호 설계 + POC 실증. 미해결 시 No-Go |
| 증류 정보 손실 | 패널 가치 < 단일 Opus | ≥2 증류안 비교 + POC 산출물 품질 평가 |
| context 오염 (워커 전문 유입) | ADR-010 불변식 위반 | 격리 설계(sub-agent 결과만 반환) + 시나리오 1 검증 |
| 디렉터 게이트 위임 | human-gate(ADR-008) 우회 | 패널은 *리뷰 의견* 만 생성, Plan Accept/Ship 게이트는 디렉터+사용자 보유 명문화 |
| research 끝에 No-Go | phase 산출 빈약 인상 | No-Go 도 유효 결과 — 근거 자산화 + Icebox 재정리가 Done. ROI 음수 구현 회피가 가치 |

## 🏁 Phase Done 조건

- [ ] spec-22-01(research) merge — report.md(5난점 설계 + POC + Go/No-Go) 완성
- [ ] (Go 시) spec-22-02(impl) merge — 3개 커맨드 패널 절 + 미러 + 테스트 PASS
- [ ] 통합 테스트 시나리오 PASS (No-Go 면 시나리오 1만)
- [ ] 성공 기준 정량 측정 결과 기록
- [ ] 사용자 최종 승인 (`/hk-phase-ship` go/no-go)

## 📊 검증 결과 (phase 완료 시 작성)

<!-- research report 요지, POC 로그, Go/No-Go 결론, (구현 시) 테스트 결과 -->
