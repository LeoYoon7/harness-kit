# POC 프로토타입: 페르소나 리뷰 패널 (spec-22-01)

> 본 문서는 POC *정의*다. Task 4 가 이 정의대로 실행하고 결과를 `persona-panel-poc-run.md` 에 기록한다.
> 대상 커맨드 = `hk-spec-critique` (의견 발산형). production 커맨드는 변경하지 않는다.

## 1. 페르소나 (3)

비용·다양성 균형으로 3개. 각 페르소나는 **독립 sub-agent** 로 dispatch 된다.

| 페르소나 | 렌즈 | 중점 |
|---|---|---|
| **P1 설계자** | 아키텍처·단순성 | 과잉설계, 추상화, 구조 일관성, YAGNI |
| **P2 규제자** | 거버넌스·리스크 | 불변식 위반, 보안, 하위호환, 게이트 우회 |
| **P3 사용자 옹호자** | DX·도그푸딩 | 사용성, 모바일/원격 UX, 설치 대상 마찰 |

## 2. Dispatch (fan-out, 결과 계약만)

- 3개 페르소나를 **단일 메시지 병렬** sub-agent 로 팬아웃 (Agent tool, 동일 대상 spec 텍스트 주입).
- 각 sub-agent 는 **구조화된 결과 계약만** 반환 — transcript 금지 (ADR-010 정합):
  ```
  [{ "issue": "<한 줄>", "severity": "high|med|low", "rationale": "<한 줄>" }, ...]
  ```
- 메인(중재자)은 계약만 수신. 워커 transcript 는 sub-agent 안에서 소멸 → context 격리.

## 3. 종료 조건 (이견-한정 2차 + 하드 상한 ≤3)

1. **라운드 1**: 3 페르소나 병렬 → 결과 계약 수집.
2. **충돌 분석**: 같은 대상에 심각도/방향이 갈리는 이슈(=충돌) 식별. 충돌 없으면 즉시 종료(라운드 1로 끝).
3. **라운드 2 (이견-한정)**: 충돌 이슈만 각 페르소나에 재질의(상대 의견 계약 제시). 신규 distinct 이슈가 **0건**이면 종료.
4. **하드 상한**: 어떤 경우에도 **라운드 ≤ 3**. 의미적 중복(정규화 매칭)으로 "신규 가장 재실행" 차단.

## 4. 증류 (구조화 머지 — 이견 보존)

distilled contract = **이슈별 표**:

| 이슈 | 제기 페르소나 | 합의 | 심각도 | 근거 |
|---|---|---|---|---|

- 합의 = 단일/복수 페르소나 + 충돌 해소 여부. **이견은 평탄화하지 않고 "미합의(이견)"로 보존.**
- 표 위에 선택적 1문단 요약.

## 5. Baseline (self-consistency)

- 동일 대상 spec 에 **단일 Opus 3회** 동일 critique 프롬프트 실행 → 이슈 합집합(다수결 심각도).
- 페르소나 *없는* 앙상블 — 패널의 "페르소나 다양성" 기여를 분리하는 대조군.

## 6. 측정 (실행 시 기록)

| 지표 | 정의 |
|---|---|
| recall proxy | 진짜 이슈 발견 수 (ground truth = 대상 spec 의 실제 walkthrough/critique 가 잡았던 이슈) |
| precision proxy | 거짓 양성(무효·과잉) 이슈 수 |
| 고유 관점 | baseline 미발견 *유효* 신규 관점 수 |
| issue retention rate | distilled 잔존 distinct 이슈 / 페르소나 합집합 distinct 이슈 |
| 비용 | 출력 토큰 합 (패널 vs baseline) |
| 지연 | wall-clock (팬아웃 병렬 반영) |
| 라운드 수 | 종료까지 라운드 |
| 격리 | 메인 context 에 워커 transcript 유입 여부 (기대: 없음) |

## 7. 실행 표본

archived spec 1건 — **설계 선택지가 갈렸던** 것. Task 4 에서 1건 확정 (후보: `archive/specs/spec-x-notify-channel-formatter`, `archive/specs/spec-x-install-ignore-coverage`).
