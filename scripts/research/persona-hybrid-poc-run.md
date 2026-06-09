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

_(사용자 S2 진행 결정 시 실행)_
