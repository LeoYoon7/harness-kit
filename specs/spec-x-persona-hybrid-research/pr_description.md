docs(spec-x-persona-hybrid-research): 하이브리드 리뷰 research — Conditional No-Go

## 📋 Summary

### 배경 및 목적

phase-22 가 단순 페르소나 패널을 Conditional No-Go(패널은 framing 폭은 잡으나 구체 버그 깊이를 놓침, baseline 과 상보적, n=1) 한 후속. **하이브리드(페르소나 패널 + generalist 정독)** 가 깊이를 회복하며 폭을 유지하고 추가 비용을 정당화하는지 ≥2 표본·cross-model blind 채점으로 검증.

### 주요 결과 (Research)

- [x] **두 lever 분리 발견**: generalist 정독 = *깊이 lever*(두 표본 모두 phase-22 깊이갭 회복, 싸고 항상 유효) / 페르소나 패널 = *폭 lever*(폭 지배 리뷰에서만 순기여).
- [x] **S1(폭 표본)**: H1 4/4 GT, B1 은 지배적 폭 이슈(GT1 모바일→embed) 놓침 → H1 PASS, 페르소나 순기여 양(+).
- [x] **S2(깊이 표본)**: B1(self-consistency+정독) valid 12 ≥ H1 10, GT 동급 5/5 → **cheaperEqual, H1 FAIL**(ROI 0.83).
- [x] **결론: Conditional No-Go** (블랭킷 페르소나 패널) + **B1 정독 패턴 = 값싼 win** 권고.

### Phase 컨텍스트
- **Phase**: 없음 (spec-x — 비소속, 연구 단발). Go 시 구현은 별도 phase.

## 🎯 Key Review Points

1. **측정 신뢰도 (critique 대안 B)**: 채점을 Gemini cross-model blind(라벨 익명화)로 분리 → self-preference 순환 평가 차단. Go/No-Go 정량 임계 *사전 등록*(report §3.4) → 사후 합리화 차단.
2. **2자 비교 + baseline 2변형**: H1 vs B0(Opus×3) vs B1(B0+정독). B1 이 페르소나 vs 정독 기여를 분리 — *핵심 판별자*.
3. **균형 표집**: S1 폭 + S2 깊이 — 표집 편향 완화가 조건부 결론을 가능케 함.
4. **n=2 한계 정직성**: "일반화" 미주장, 표본별 방향 일치만 보고.

## 🧪 Verification (Research §9.1 — POC 실증)

```bash
# POC 자산
scripts/research/persona-hybrid-poc.md       # 프로토콜
scripts/research/persona-hybrid-poc-run.md   # S1/S2 실행 로그 + 교차 종합
```

**결과 요약**:
- ✅ liveness: 14 Opus 워커 격리(계약만)·종료(라운드1)·증류
- ✅ S1: H1 PASS (4기준), 페르소나 폭 가치 실증
- ✅ S2: H1 FAIL, B1 cheaperEqual 지배 실증
- ✅ Gemini cross-model blind 채점 (독립성)

## 📦 Files Changed

### 🆕 New Files
- `specs/spec-x-persona-hybrid-research/{spec,report,plan,task,walkthrough,pr_description,critique}.md`
- `scripts/research/persona-hybrid-poc.md` / `persona-hybrid-poc-run.md`

### 🛠 Modified Files
- `backlog/queue.md`: Icebox 하이브리드 라인 → 본 spec-x promote 표기.

**Total**: research docs/scripts only (production 코드 0).

## ✅ Definition of Done (Research)

- [x] 트레이드오프(하이브리드 H1 + H2/H3 문서) / 측정 설계 + 사전등록
- [x] 평가 독립성(Gemini blind) / POC 표본 ≥2 / value·깊이·폭 실증
- [x] Go/No-Go 권고 (Conditional No-Go + B1 win)
- [x] walkthrough.md / pr_description.md ship
- [x] 코드 리뷰 게이트 — Skip(`docs-only`, walkthrough 기록)
- [x] 사용자 검토 요청 알림

## 🔗 관련 자료

- 선행: `specs/spec-22-01-persona-panel-research/report.md` (phase-22 측정틀)
- Report: `specs/spec-x-persona-hybrid-research/report.md` (§6 Go/No-Go)
- ADR 후보: `review-value-baseline`, `review-eval-independence` (invariant, 후속 트리거)
