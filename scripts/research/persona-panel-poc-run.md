# POC 실행 로그: 페르소나 패널 vs baseline (spec-22-01 Task 4)

> 정의: `persona-panel-poc.md`. 본 문서는 1회 실행 증빙이다 (n=1).
> 대상 표본: `archive/specs/spec-x-notify-channel-formatter/spec.md` (설계·거버넌스·모바일 UX 가 갈리는 spec, ground truth = 해당 critique/walkthrough + 후속 `spec-x-notify-discord-embed` Icebox 트리거).
> 실행: 2026-06-08. 모델 = Opus(패널 3 + baseline 3 전부 동일 — 공정 비교).

## 1. 실행 구성

- **패널**: P1 설계자 / P2 규제자 / P3 사용자 옹호자 — 병렬 sub-agent 팬아웃, 각자 결과 계약(JSON `issue/severity/rationale`)만 반환.
- **baseline**: 단일 Opus 동일 critique 프롬프트 3회(self-consistency) — 페르소나 없음.

## 2. liveness 결과

| 항목 | 결과 |
|---|---|
| **격리** | ✅ 6 워커 전원 JSON 결과 계약만 반환 — 메인 context 에 transcript 전문 미유입 (ADR-010 불변식 준수 실증) |
| **종료/라운드** | ✅ **라운드 1 에서 수렴** — 페르소나 이슈가 *상충(같은 대상 심각도 반대)* 이 아니라 *상보(다른 렌즈)* 라 이견-한정 2차 불필요. 하드 상한(≤3) 미접근 |
| **무한 루프** | ✅ 없음 (신규 이슈 발산 없이 1라운드 종료) |
| **증류** | ✅ 구조화 머지표 생성 가능, 이견 보존 |

## 3. 산출 이슈 (distinct, 중복 제거 후)

- **패널 합집합**: ~15 distinct (P1 6 / P2 6 / P3 6, 일부 상보적 중복 — §9 ack·CJK 정렬은 2 페르소나 동시 제기 = 합의 신호)
- **baseline 합집합**: ~16 distinct (3회 중 통합테스트·awk locale·fence 충돌은 3/3 또는 2/3 재현 = 높은 self-consistency)

## 4. value 비교 (패널 vs baseline)

### 4.1 패널만 잡음 (baseline 미발견)
- 6개 FR **응집도 낮은 번들** (P1) — spec 구조 차원
- critique 본문 인라인 **과밀화** (P1)
- 채널별 **멘탈 모델 부담** (P3)
- **모바일 좁은 화면 표 줄바꿈** 시나리오 부재 (P3) ← **ground truth 핵심** (실제 후속 `spec-x-notify-discord-embed` 를 촉발한 이슈)
- YAGNI 미래 spec 선명명 (P1), dead code link sed (P1)

### 4.2 baseline 만 잡음 (패널 미발견) — ⚠ 주목
- **awk `length()` 의 locale(LANG/LC_ALL) 의존 — ASCII 표조차 정렬 비결정** (B1·B2·B3 **3/3, high**) ← *구체적 기술 지뢰*. 페르소나 3 전원 놓침
- code-block 안 표 **이중 변환** 위험 (B2·B3)
- `---` 구분선 vs `| --- |` separator **패턴 충돌** (B1)
- agent.md 조건부 처리로 **plan 결정성 저하** (B2·B3)

### 4.3 양쪽 다 잡음 (교집합)
- 통합 테스트 비결정성/실발송 의존 (패널 P2·P3 + baseline 3/3 — 가장 강한 합의)
- §9 [ack] grep 의 markdown_simplify 의존 (P2·P3 + B2)
- CJK/ASCII 혼합 표 정렬 깨짐, F6 도그푸딩 동기화 게이트, backtick/메타문자 한계

### 4.4 정량 요약

| 지표 | 패널 | baseline (Opus×3) |
|---|---|---|
| distinct 이슈 | ~15 | ~16 |
| 고유 발견(상대 미발견) | ~6 (설계·UX framing) | ~4 (구체 기술 버그) |
| ground truth 핵심(모바일→embed) | ✅ 잡음 (P3) | △ 약함 |
| 구체 기술 지뢰(awk locale) | ❌ 전원 놓침 | ✅ 3/3 |
| issue retention rate | ~0.87 (구조화 머지, 이견 보존) | n/a |
| 비용(서브에이전트 토큰 합) | ~141k | ~161k (비슷) |
| 지연 | 병렬 ~30s | 병렬 ~35s |
| 라운드 | 1 | 1 (투표) |

## 5. 해석

- 패널의 **페르소나 다양성**은 *framing 폭*(구조·응집도·멘탈모델·모바일 UX)에서 우위였고, 이 spec 의 **실제 가장 중요한 이슈(모바일 표 → embed)** 를 P3 가 정확히 포착했다.
- 그러나 baseline(동일 프롬프트 3회 정독)은 **구체적 구현 지뢰(awk locale 의존)** 를 3/3 안정적으로 잡았고 **패널은 전원 놓쳤다** — 렌즈 제약이 깊은 코드/스크립트 디테일 탐색을 희생시킨 것으로 보인다.
- **비용은 사실상 동급** (둘 다 Opus×3 규모).
- 결론적으로 이 표본에서 **패널이 self-consistency baseline 을 *지배(dominate)하지 못했다*** — 둘은 *상보적*이다. 패널=폭/framing, baseline=깊이/구체 버그.

> ⚠ **n=1 한계**: 단일 표본·단일 도메인(notify formatter). 일반화 금지. 본 결과는 Go/No-Go 의 *방향* 근거이며, 표본 확대 시 달라질 수 있다.
