---
description: 현재 SPEC 브랜치의 코드 변경을 B1 패턴(self-consistency Opus×N + generalist 정독)으로 리뷰
---

현재 브랜치의 코드 변경사항을 **독립적인 관점**에서 리뷰합니다.

기본 패턴은 **B1** 입니다 — 독립 Opus 리뷰어 **N=3 self-consistency**(같은 프롬프트를 3회 독립 실행해 비결정성 보정) + **generalist 정독 1패스**(렌즈 제약 없는 전반 정독, 깊이 lever) → 디렉터가 결과 계약만 받아 **증류**. 근거: `specs/spec-x-persona-hybrid-research/report.md`(#48) — 단일 리뷰어 대비 깊이 갭(구체 구현/locale/엣지 버그)을 회복.

## 1. 대상 확인

현재 활성 spec 과 diff 범위를 확인합니다:

```bash
bash .harness-kit/bin/sdd status --json
```

출력에서 `spec` 필드로 spec 디렉토리를 특정합니다. spec 이 없으면 사용자에게 알리고 멈춥니다.

리뷰 base 결정 — 같은 출력에서 **한 번에** 해석합니다 (해석 체인: phase `baseBranch` → `defaultBranch` → `main`):

```bash
REVIEW_BASE=$(bash .harness-kit/bin/sdd status --json | jq -r '.baseBranch // .defaultBranch // "main"')
```

`REVIEW_BASE` ref 가 로컬에 없으면 (base-branch 모드 첫 spec 등) `defaultBranch` → `main` 순으로 fallback 합니다 (`gemini-review.sh` 와 동일 체인).

diff 범위 확인:

```bash
git diff ${REVIEW_BASE}...HEAD --stat
```

변경 파일이 없으면 "리뷰할 코드 변경이 없습니다" 를 알리고 멈춥니다.

## 2. B1 리뷰 수행 (self-consistency + generalist 정독)

독립 서브에이전트 **4개**를 한 메시지에서 **병렬 dispatch** 합니다 (Agent tool, `subagent_type: general-purpose`, `model: "opus"`):

- **리뷰어 R1 · R2 · R3** — 동일한 아래 "3-렌즈 리뷰 프롬프트"(self-consistency).
- **generalist G** — 아래 "generalist 정독 프롬프트"(렌즈 제약 없는 전반 정독).

> **비용 주의**: 기본 4 dispatch(단일 리뷰 대비 4배). 깊이 회복 주역은 generalist 이며 N=3 self-consistency 는 약근거 기본값(#48 분리 미측정). 작은 diff 에서는 N 을 줄여도 됩니다(문서 옵션 — 적응형 자동화는 미구현). 측정·독립성 원칙은 ADR-013 / ADR-014 참조.

각 서브에이전트는 **결과 계약(배열)만** 반환합니다 — 전체 transcript 반환 금지(ADR-010 orchestration, 디렉터 context 격리):

```json
[
  { "issue": "<한 줄 요약>", "severity": "Critical|Major|Minor",
    "rationale": "<근거 + 파일:라인>", "source": "spec대비|품질|테스트|정독" }
]
```

R1~R3 의 `source` 는 `spec대비`/`품질`/`테스트` 중 해당값, generalist 의 `source` 는 `정독`.

### 3-렌즈 리뷰 프롬프트 (R1 · R2 · R3 동일)

> 당신은 독립적인 시니어 개발자 코드 리뷰어입니다.
>
> **입력 자료**:
> 1. spec 문서: `specs/<spec-dir>/spec.md` 를 읽어서 요구사항을 파악하세요.
> 2. 코드 변경: `git diff <REVIEW_BASE>...HEAD` 를 실행해서 전체 변경사항을 확인하세요 (REVIEW_BASE 는 디스패치 시 디렉터가 치환).
> 3. 변경된 파일들의 전체 내용이 필요하면 해당 파일을 직접 읽으세요.
>
> 다음 3가지 관점에서 리뷰하고, 발견된 문제마다 심각도(Critical/Major/Minor)를 매기세요:
>
> ### 1. Spec 대비 구현 검증 (source: `spec대비`)
> - spec.md 의 Functional Requirements 가 모두 구현되었는가?
> - Definition of Done 항목이 충족되었는가?
> - spec 에 없는 기능이 추가되지 않았는가? (scope creep)
>
> ### 2. 코드 품질 (source: `품질`)
> - **KISS**: 불필요하게 복잡한 로직이 있는가? 더 단순한 방법이 있는가?
> - **DRY**: 중복 코드가 있는가? 기존 유틸리티를 재사용할 수 있는가?
> - **Feature Envy**: 다른 모듈의 데이터를 과도하게 참조하는가?
> - **Dead Code**: 사용되지 않는 코드, 주석 처리된 코드가 남아있는가?
> - **네이밍**: 변수/함수/파일 이름이 의도를 명확히 전달하는가?
> - **에러 처리**: 적절한 에러 처리가 되어있는가? (시스템 경계에서)
>
> ### 3. 테스트 커버리지 (source: `테스트`)
> - 변경된 코드에 대한 테스트가 존재하는가?
> - 핵심 경로(happy path)가 테스트되는가?
> - 엣지 케이스(빈 입력, 경계값, 에러 상황)가 테스트되는가?
> - 테스트가 구현 세부사항이 아닌 동작을 검증하는가?
>
> **반환 형식**: 위 "결과 계약(배열)" JSON 만 반환하세요(한국어 본문, `issue`/`rationale` 에 `파일:라인` 포함). 산문 리포트·transcript 금지. 발견이 없으면 빈 배열 `[]`.

### generalist 정독 프롬프트 (G)

> 당신은 독립 시니어 리뷰어입니다. **렌즈에 얽매이지 말고** 변경 전체를 처음부터 끝까지 **정독**하세요.
>
> **입력 자료**: `specs/<spec-dir>/spec.md`(요구사항) + `git diff <REVIEW_BASE>...HEAD`(전체 변경, REVIEW_BASE 는 디렉터가 치환) + 필요한 파일 직접 읽기.
>
> 단일 리뷰어/렌즈가 놓치기 쉬운 **깊이** 에 집중하세요:
> - 구체 구현 버그(off-by-one, 경계, null/빈 입력, 상태 전이)
> - 플랫폼/locale 의존(awk/sort/date locale, byte vs char count, CP949/UTF-8 인코딩·절단)
> - 셸 이식성(bash 3.2 한계), 코드펜스/마커 desync, 파싱 경계
> - 테스트가 *실제로* 동작을 잡는지(형식만 통과하는 가짜 검증)
>
> **반환 형식**: 위 "결과 계약(배열)" JSON 만 반환하세요(`source` 는 모두 `정독`). 산문·transcript 금지. 발견이 없으면 `[]`.

## 3. 증류 (디렉터) — 조작적 정의

메인(디렉터)이 4 서브에이전트의 결과 계약을 받아 **이슈별 머지표**로 통합합니다. 재현성을 위해 아래 규칙을 따릅니다(규칙이 없으면 매 실행마다 표가 달라져 self-consistency 신호가 무의미해짐):

- **dedup**: 동일 이슈 판정 = `파일:라인` 근접을 우선, 모호하면 의미 일치를 디렉터가 판단 → 단일 이슈로 병합.
- **합의 수**: dedup 후 *그 이슈를 제기한 워커 수 ÷ 반환 워커 수 k*. 예: `2/4`. self-consistency 의 신호값.
- **심각도 충돌**: 워커마다 심각도가 다르면 **최고 심각도 채택** + 이견을 비고에 보존.
- **이견 보존(평탄화 금지)**: 1워커만 제기한 이슈도 표에서 제거 금지. generalist 고유 발견·심각도 이견을 모두 남깁니다.
- **부분 실패 fallback**: 4 중 일부가 실패/빈 반환이면 반환된 **k개로 증류 진행**. 합의 분모 = k, 미반환 워커 수를 결과에 명시(ship 게이트는 부분 결과로도 동작해야 함).

머지표 형식:

```
| 이슈 | 제기 워커·source | 합의(N/k) | 심각도 | 근거(파일:라인) |
```

## 4. 결과 저장

증류 결과(머지표 + 아래 요약)를 `specs/<spec-dir>/code-review.md` 에 저장합니다.

## 5. 사용자에게 보고

```
✅ Code Review (B1) 완료: <spec-id>
- 결과: specs/<spec-dir>/code-review.md
- 전체 평가: (Approve / Request Changes / Comment)
- Critical: N / Major: N / Minor: N
- 합의 분포: 4/4 N건, 3/4 M건, 2/4 K건, 1/4 L건
- 미반환 워커: <0~4>
```

Critical 이슈가 있으면 ship 전에 해결을 권고합니다.

## opt-in: 페르소나 패널 (폭 지배 리뷰 한정)

기본은 위 B1 입니다. 변경이 **폭(설계/UX/거버넌스) 지배** — 구체 버그보다 방향·설계·정책 분기가 큰 PR — 인 경우에 한해 **페르소나 패널을 opt-in** 으로 추가 고려할 수 있습니다.

방법(수동 dispatch — 자동 라우팅은 **미구현**): generalist 1 정독 + 페르소나 3 을 병렬 dispatch 하고, §2 와 동일한 결과 계약 반환 + §3 와 동일 증류.

- ① **설계자** — 아키텍처·단순성 렌즈
- ② **규제자** — 거버넌스·불변식·리스크 렌즈
- ③ **사용자 옹호자** — DX·도그푸딩·모바일 UX 렌즈

근거: `specs/spec-x-persona-hybrid-research/report.md`(#48) — 페르소나 패널은 **폭 지배 리뷰에서만 순기여**(깊이 지배 리뷰에선 비용만 추가, ROI 음). 따라서 블랭킷 채택은 안 하고 폭 지배 한정 opt-in 으로만 둡니다.
