# POC 프로토타입: 하이브리드 리뷰 (spec-x-persona-hybrid-research)

> 본 문서는 POC *정의*다. Task 4 가 이 정의대로 실행하고 결과를 `persona-hybrid-poc-run.md` 에 기록한다.
> phase-22 `persona-panel-poc.md` 를 확장 — H1(패널+generalist), baseline 2변형, **cross-model blind 채점**.
> 대상 맥락 = `hk-spec-critique`. production 커맨드는 변경하지 않는다.

## 1. H1 워커 (4 = 페르소나 3 + generalist 1)

각 워커는 **독립 sub-agent** 로 dispatch. 페르소나 3 은 phase-22 재사용.

| 워커 | 렌즈 | 중점 |
|---|---|---|
| **P1 설계자** | 아키텍처·단순성 | 과잉설계, 추상화, 구조 일관성, YAGNI |
| **P2 규제자** | 거버넌스·리스크 | 불변식 위반, 보안, 하위호환, 게이트 우회 |
| **P3 사용자 옹호자** | DX·도그푸딩 | 사용성, 모바일/원격 UX, 설치 대상 마찰 |
| **G generalist (신규)** | 렌즈 없음 — 전반 정독 | 구체 구현/플랫폼/locale 의존, 엣지케이스, 테스트 갭, off-by-one/경계 |

## 2. Dispatch (fan-out, 결과 계약만)

- 4 워커를 **단일 메시지 병렬** sub-agent 팬아웃 (동일 대상 spec+diff 텍스트 주입).
- 각 sub-agent 는 **구조화된 결과 계약만** 반환 — transcript 금지 (ADR-010):
  ```
  [{ "issue": "<한 줄>", "severity": "high|med|low", "rationale": "<한 줄>", "source": "P1|P2|P3|G" }, ...]
  ```
- 메인(디렉터)은 계약만 수신. 워커 transcript 는 sub-agent 안에서 소멸 → context 격리.

## 3. 종료 + 증류 (phase-22 재사용)

- 라운드 1 병렬 → 충돌 이슈만 2차(필요 시) → 신규 0 또는 ≤3 상한.
- 증류 = 이슈별 구조화 머지표(이슈/제기 워커/합의/심각도/근거). 이견 보존(평탄화 X).

## 4. Baseline 2변형

| 변형 | 정의 | 목적 |
|---|---|---|
| **B0** | 단일 Opus **3회** self-consistency (동일 critique 프롬프트) → 합집합/다수결 | phase-22 baseline 동일 — 앙상블 효과 |
| **B1** | Opus 3회 + **generalist 정독 1패스** 추가 | 페르소나 *없이* 정독만으로 깊이 회복되나 — 페르소나 순기여 분리(대안 C 흡수) |

> H1 vs B1 = 비용 동급(워커 4) → **value 직접 비교로 페르소나 순기여 판정**. H1 vs B0 = ROI(비용 1.33배) 판정.

## 5. Cross-model blind 채점 (평가 독립성 — critique 핵심)

순환 평가(동일 Opus 가 생성·채점) 차단:
1. H1 / B0 / B1 산출물에서 **방법 라벨 제거** + 이슈 목록만 익명화.
2. **Gemini**(`hk-gemini-review` 자산 / `gemini` CLI) 가 blind 로 채점:
   - 각 이슈 **유효성**(real / false-positive) 판정.
   - ground truth(대상 spec 의 실제 walkthrough/critique + 후속 Icebox) 대비 **recall**.
   - **깊이 이슈**(구체 구현/플랫폼/locale) vs **폭 이슈**(framing/UX/설계) 분류.
3. 디렉터는 Gemini 채점 결과만 집계 — Opus 자기채점 배제.

> ground truth 자체가 과거 Opus 산출이라는 한계는 run 로그·report §5 에 명시(완전 독립 아님 — 채점자만 분리).

## 6. 측정 지표 (실행 시 기록)

| 지표 | 정의 |
|---|---|
| recall proxy | ground truth 대비 발견 (Gemini blind) |
| precision proxy | false-positive 수 (Gemini blind) |
| 깊이 회복 | phase-22 패널이 0/3 놓친 구체 버그 부류 회복 비율 (임계 ≥2/3) |
| 폭 retention | 패널 고유 framing 이슈 보존율 (임계 ≥0.8) |
| 페르소나 순기여 | H1 유효이슈 − B1 유효이슈 ( >0 이어야 페르소나 가치) |
| issue retention rate | distilled 잔존 / 워커 합집합 distinct |
| 비용 | 출력 토큰 (H1 vs B0 vs B1) |
| ROI | value 증분 / 비용 증분 (H1 vs B0, 임계 ≥1.0) |
| 격리 | 메인 context 에 워커 transcript 유입 여부 (기대: 없음) |

## 7. 실행 표본 (≥2, 균형)

| # | 표본 | 성격 | 비고 |
|---|---|---|---|
| S1 | `archive/specs/spec-x-notify-channel-formatter` | **폭/설계 갈림** | phase-22 표본 — 패널 우위였던 케이스 |
| S2 | `archive/specs/spec-x-notify-chunk-line-aware` | **깊이/구체 구현** | 청킹 경계·off-by-one 중심 — 표집 편향 완화(깊이 대조) |

## 8. 사전 등록 판정 규칙 (report §3.4)

H1 이 (깊이회복≥2/3) AND (폭 retention≥0.8) AND (B1 대비 페르소나 순기여>0) AND (ROI≥1.0 vs B0) 를 **S1·S2 모두** 충족 → Go; 1건 → 표본 확대; 0건 → No-Go. B1≥H1 이면 → 페르소나 불요(No-Go).
