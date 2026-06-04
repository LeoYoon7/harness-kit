# 디렉터 모드 운영 가이드 (Director Mode Playbook)

> 본 문서는 `directorMode` 가 켜졌을 때(→ `/hk-director`) Opus 디렉터가 따르는 **운영 상세**입니다.
>
> **요지의 정본**: 강제 규약은 `agent.md §6.8 Director Mode Protocol` stub, 결정 근거는 `ADR-011` 입니다. 본 가이드는 그 stub 의 *how-to* 자족 지침이며, install 시 설치 대상에도 배포됩니다(`sources/governance/` → `.harness-kit/agent/`). 모순 시 agent.md / ADR-011 우선.
>
> **기반과의 관계**: always-on orchestration 정책은 `agent.md §6.6` / `ADR-010` 입니다. 디렉터 모드는 그 위임 *적극성*을 높이는 토글이지 위임 on/off 가 아닙니다.

## 1. 적용 조건

- `directorMode = on` 일 때 본 가이드의 *적극적 위임*이 적용된다.
- `off` 일 때도 §6.6 always-on 정책(판단·검증은 보존, 토큰 무거운/오염성 노동만 선택 위임)은 항상 적용된다.
- 모드는 런타임 커널이 아니라 *지시 주입* 이다. hk-align 이 거버넌스를 강제하는 것과 같은 규약 강도이며, hook 강제가 아니다. 위반은 walkthrough / RCA 로 학습한다.

## 2. 6개 규칙 운영 절차

### (1) 의도 합의 핸드셰이크 (Intent handshake)

워커를 디스패치하기 전에 사용자 의도를 한 번 되물어 확정한다. 직접 요약을 제시하고 승인을 받는 형태도 가능하다. 확정 후에 팀 편성·위임을 시작한다. 의도가 흐려진 채 위임하면 잘못된 가정 위에 작업이 쌓인다(understanding debt).

### (2) scoped brief 위임 (Scoped brief dispatch)

워커에게 전체 대화 히스토리를 주지 않는다. 아래 §3 의 필수 항목만 담은 *좁은 슬라이스*를 넘긴다. 특히 **산출물(planning/artifact files) 커밋 범위**를 brief 에 반드시 포함한다 — 빠지면 디렉터가 사후 커밋해야 하는 갭이 생긴다.

### (3) distilled contract 반납 (Distilled contract return)

워커는 커밋 SHA·테스트 상태·주요 결정 목록만 반납한다. transcript 전문 반납은 VIOLATION 이다. 디렉터의 큰 context 창은 *의도의 단일 보관소* 이므로, 워커의 raw 산출물로 오염되면 안 된다.

### (4) 행동 검증 — 전문 재흡수 금지 (Verification by action)

디렉터의 검수는 *테스트 재실행 + 동작 스모크 + 증류 계약 대조* 로만 수행한다. 워커 transcript 전문을 재흡수해 검수하는 것은 명시적 금지(VIOLATION)다. 이는 ADR-010 ④축의 운영적 구체화다. 검증 실패 시 agent.md §7 Hard Stop 으로 진입한다.

### (5) 게이트 보유 (Gates stay with director)

Plan Accept·Ship 게이트와 §5/§9 알림 게이트는 **디렉터+사용자가 보유**하며 워커에 내리지 않는다. 게이트를 워커에 위임하면 사용자 응답 기회가 박탈된다(human-gate, ADR-008 / 양방향 알림 정합). 자세한 원칙은 §6.

### (6) over-dispatch 금지 (No over-dispatch)

agent.md §6.7 의 sub-agent dispatch threshold 를 준수한다. 단발(단일 `git commit`, 단일 `cp` 등)은 인라인 처리한다. 디렉터 모드는 위임 *기본값을 높이는 것* 이지 모든 것을 위임하라는 게 아니다.

## 3. 워커 scoped brief 필수 항목

| 항목 | 내용 | 예 |
|---|---|---|
| 대상 파일 | 워커가 만지는 파일의 범위 | `src/foo.ts`, `tests/foo.spec.ts` |
| 기대 동작 | 무엇이 동작해야 완료인가 | "X 입력 시 Y 반환, 경계값 Z 처리" |
| 테스트 명령 | 검증에 쓸 정확한 명령 | `npm test -- foo` |
| 커밋 형식 | commit subject 규약 | `feat(spec-NN-NN): ...` |
| 산출물 커밋 범위 | 코드 외 커밋해야 할 산출물 | task.md 체크박스, walkthrough 섹션 |

## 4. 검증 체크리스트 (전문 재흡수 없이)

- [ ] 워커가 반납한 커밋 SHA 로 `git show --stat` 만 확인했는가 (전문 재흡수 아님).
- [ ] 테스트를 *디렉터가 직접* 재실행해 PASS 를 확인했는가.
- [ ] 동작 스모크(핵심 시나리오 1~2개)를 직접 돌렸는가.
- [ ] 증류 계약(결정 목록)이 의도와 어긋나지 않는가.
- [ ] 실패 시 §7 Hard Stop 으로 멈추고 사용자에게 보고했는가.

## 5. dispatch 경계 (over / under)

| 작업 | 처리 | 이유 |
|---|---|---|
| 단일 `git commit` / 단일 파일 복사 | 인라인 (디렉터 직접) | 디스패치 오버헤드 > 절감 |
| 다파일 구현 / 광역 탐색 / 로그 분류 | 위임 | 토큰 무거운/오염성 노동 |
| 아키텍처 결정 / scope 판단 / 게이트 | 인라인 (디렉터 보유) | 판단·의도 보존 노동 |
| docs-only(전부 markdown) task | 인라인 | spin-up 오버헤드 > 절감 (§6.7) |

## 6. 게이트 보유 원칙

- **보유 대상**: Plan Accept, Ship(push + PR), §5 Ad-hoc 선택지 알림, §9 응답 ack 알림, Phase Go/No-Go.
- **이유**: 이 게이트들은 사람 승인 지점(human-gate, ADR-008)이거나 사용자 응답 기회(양방향 알림 §10)다. 워커에 위임하면 사용자가 의사결정·응답 기회를 잃는다.
- **워커의 몫**: 게이트 *사이* 의 실행 노동(테스트 작성·구현·커밋)만. 게이트 자체의 판단·발화는 디렉터+사용자.
