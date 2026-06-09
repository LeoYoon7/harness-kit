# POC 실행 로그: 하이브리드 리뷰 (spec-x-persona-hybrid-research)

> `persona-hybrid-poc.md` 정의대로 실행. 증분 — S1 먼저(사용자 결정 2026-06-09), S2 는 별도.
> 채점 = Gemini cross-model blind (Opus 자기채점 배제, 방법 라벨 익명화 A/B/C).

## 공통

- **워커**: 모두 Opus sub-agent, 결과 계약(JSON {issue,severity,rationale,source})만 반환 — transcript 미유입(ADR-010 격리 ✅ 실증, 메인은 계약만 수신).
- **입력 (공정)**: 각 워커는 대상 spec.md + 구현 diff(`git show <commit> -- <impl .sh>`)만. walkthrough/critique/pr_description(=ground truth) 차단.
- **방법**: A=H1(P1 설계자+P2 규제자+P3 사용자옹호자+G generalist), B=B0(generic Opus×3 self-consistency), C=B1(B0 ∪ G).
- **채점**: Gemini v0.45.2, `--approval-mode plan`, 익명화 패킷. 부수효과 없음(stdout만).
- **패킷 한계 메모**: 구현 diff 를 실행 스크립트(.sh)로 한정 → 일부 워커가 "CLAUDE.fragment/markdown_simplify diff 부재"를 지적했으나 이는 패킷 범위 artifact 이지 구현 결함 아님 → 채점에서 제외(Gemini 에도 OUT OF SCOPE 명시).

## S1 — `spec-x-notify-channel-formatter` (폭/설계 갈림 표본)

대상: Discord/Telegram 알림 마크다운 포맷터(표 변환). phase-22 의 동일 표본 — 당시 pure-panel 이 폭은 잡고 깊이(awk locale)를 놓쳤던 케이스.

### Ground truth (디렉터가 walkthrough/critique 에서 추출, 워커 비공개)
- **GT1 (폭, 지배적)**: Discord code-block 표가 모바일/긴 셀에서 word-wrap → 정렬 손실 (→ embed 후속 트리거).
- **GT2 (폭)**: CJK 한글+ASCII 혼합 표 정렬 깨짐 (length 기반 padding).
- **GT3 (깊이)**: `awk length()` 가 `LC_ALL=C` 에서 byte 카운트 → 한글 padding 붕괴 (GT2 의 근본 원인).
- **GT4 (깊이/risk)**: 표 휴리스틱이 비-표 파이프 content 과매칭 / separator regex 엣지 → 행 오처리.

### Gemini blind 채점 결과

| Method | valid | false-pos | depth valid | breadth valid | GT recall |
|---|---|---|---|---|---|
| **A = H1** (패널+generalist) | **15** | 0 | 7 | **5** | **GT1·GT2·GT3·GT4 = 4/4** |
| B = B0 (self-consistency Opus×3) | 9 | 0 | 6 | 2 | GT2·GT4 = 2/4 |
| C = B1 (B0 + generalist) | 13 | 0 | **10** | 2 | GT2·GT3·GT4 = 3/4 |

Gemini verdict: depthRecovery — A·C 가 GT3(byte vs char) 포착; B·C 가 fence-nesting 고유 버그. **breadthWinner = A**. personaNetValue = **YES**(A 가 GT1 모바일 UI + cross-channel UX 포착, generic 은 놓침). cheaperEqual = **NO**(C 는 깊이 우수하나 *지배적 GT1 을 놓침*).

### 사전등록 기준(report §3.4) 대비 — S1

| 기준 | 임계 | H1 결과 | 판정 |
|---|---|---|---|
| 깊이 회복 | ≥2/3 (phase-22 패널 0/3 깊이) | GT3 + GT4 + separator/빈셀 (depth valid 7) | ✅ PASS |
| 폭 retention | ≥0.8 | GT1+GT2 포착, breadth valid 5 (pure-panel 이상) | ✅ PASS |
| 페르소나 순기여 (H1 vs B1) | >0 | A valid 15 > C 13, **A 가 GT1 포착·C 는 놓침** | ✅ PASS |
| ROI (H1 vs B0) | ≥1.0 | value 15/9=1.67 ÷ 비용 4/3=1.33 ≈ **1.25** + GT 4/4 vs 2/4 | ✅ PASS |

**S1 = H1 4개 기준 모두 PASS.** phase-22(pure-panel No-Go)와 대비되는 결과 — *하이브리드*는 generalist 로 깊이(GT3)를 회복하면서 페르소나로 지배적 폭(GT1)을 잡아 baseline 2변형을 모두 지배. 특히 **B1(정독 강화)도 GT1 을 놓침 → 페르소나가 단순 정독으로 대체 불가한 폭 가치 제공**(대안 C "정독만으로 충분" 가설 S1 에서 반증).

### liveness
- 격리 ✅ (워커 계약만, 메인 transcript 미유입) · 종료 ✅ (라운드 1 수렴, 상충 적음) · 증류 — 구조화 가능(이견 보존).

## S2 — `spec-x-notify-chunk-line-aware` (깊이/구체 구현 표본)

대상: notify chunk 분할(라인 경계 + 코드펜스 균형). 구체 알고리즘 — locale/경계/펜스가 핵심.

### Ground truth (디렉터 추출, 워커 비공개) — 대부분 *깊이*, 지배적 폭 GT 없음
- **GT-A(깊이)**: `awk length()`/CHUNK_SIZE locale 의존(char vs byte) → CJK 본문 채널 한도 초과 가능(원 리뷰는 "마진 안전"으로 기각).
- **GT-B(깊이)**: long-line fallback `substr` UTF-8 codepoint 중간 절단 → mojibake.
- **GT-C(깊이/회귀)**: 모든 청크에 trailing newline 추가 → 단일 청크 byte 비동일(NFR3/4 회귀, 원 리뷰 미발견).
- **GT-D(깊이)**: long-line fallback 펜스 desync / END dangling 펜스 → invalid 마크다운(fix 목적 자체 훼손, 원 리뷰 미발견).
- **GT-E(risk)**: mktemp 예측가능 /tmp 경로 + 본문 디스크 기록.

### Gemini blind 채점 결과

| Method | valid | false-pos | depth valid | breadth valid | GT recall(5) |
|---|---|---|---|---|---|
| A = H1 (패널+generalist) | 10 | 1 | 7 | 3 | GT-A·B·C·D·E = 5/5 |
| B = B0 (self-consistency) | 9 | 1 | 7 | 2 | GT-A·C·D·E = 4/5 |
| **C = B1 (B0+generalist)** | **12** | 1 | **10** | 2 | GT-A·B·C·D·E = **5/5** |

Gemini verdict: depthRecovery — A·C 둘 다 모든 깊이 GT 회복, **C 가 long-line fallback 논리버그 식별에서 기술적 우위**. breadthWinner = A(단 폭 GT 부재). personaNetValue = "yes, A 가 A8(temp 파일 process-substitution) 설계 이슈 추가" (단 *버그 아닌 설계 제안*). **cheaperEqual = YES — C 가 total valid 더 높고 GT recall 동급.**

### 사전등록 기준(report §3.4) 대비 — S2

| 기준 | 임계 | H1 결과 | 판정 |
|---|---|---|---|
| 깊이 회복 | ≥2/3 | 5/5 GT 회복 | ✅ (단 C 가 더 우수) |
| 폭 retention | ≥0.8 | 폭 GT 부재 — breadth 3, marginal | △ N/A(폭 표본 아님) |
| 페르소나 순기여 (H1 vs B1) | >0 | **A valid 10 < C 12, GT 동급** → 순기여 ≤0(A8 설계 제안만) | ❌ FAIL |
| ROI (H1 vs B0) | ≥1.0 | value 10/9=1.11 ÷ 비용 1.33 ≈ **0.83** | ❌ FAIL |
| **B1≥H1 → 페르소나 불요** | (No-Go 트리거) | **C(B1) 12 ≥ A(H1) 10, GT 동급** | ❌ **트리거됨** |

**S2 = H1 FAIL.** 깊이 표본에선 정독(generalist)이 깊이를 다 잡고, 페르소나는 *비용만 추가*(설계 제안 외 순기여 없음). B1(정독 강화)이 더 싸면서 H1 이상.

## 교차 표본 종합 (S1 vs S2)

| | S1 (폭 표본) | S2 (깊이 표본) |
|---|---|---|
| H1 GT recall | 4/4 ✅ | 5/5 ✅ |
| B1(C) GT recall | 3/4 (**GT1 폭 놓침**) | 5/5 (동급) |
| 페르소나 순기여 | **양(+) — 폭 GT1 결정적** | **≈0 — 설계 제안뿐** |
| ROI(H1 vs B0) | 1.25 ✅ | 0.83 ❌ |
| 사전등록 판정 | PASS | FAIL |

**명확한 조건부 메커니즘 (n=2, 일반화 아님 — 방향 일치 보고)**:
- **generalist 정독 패스 = 깊이 lever** — 두 표본 모두에서 phase-22 패널이 놓친 구체 버그를 회복. *값싸고 항상 유효*.
- **페르소나 패널 = 폭 lever** — *폭(설계/UX/거버넌스)이 지배적인 리뷰에서만* 순기여. 깊이 지배 리뷰에선 비용만 추가.
- **B1(self-consistency + 정독)** 이 깊이 표본에서 H1 을 cheaperEqual 로 지배 → *블랭킷 페르소나 패널 채택은 비용 정당화 실패*.

