# Walkthrough: spec-21-05

> 작업 기록 — 거버넌스 단어 예산 다이어트 + 상한 재보정.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 다이어트 전략 | compress / extract / delete | **relocate > compress > delete** | enforcement 무손실 우선. §6.7→가이드 stub, §8.4 압축, 최대 섹션 prose 축약 |
| §8.4 처리 | 제거 / 압축 | **압축(+fork override 인용구)** | 배포 대상엔 AUQ 가이드 유효. fork no-AUQ 는 fragment override (NFR1 의미무변경 정합) |
| **<6000 도달 불가** (§7) | §11 추출 / 과압축 / 상한 상향 / **하이브리드** | **하이브리드(옵션 4)** | 안전 압축만으론 <6000 불가(잔여=법). 추출 friction·과압축 명료성손실 둘 다 회피 + 상한 현실 보정 |
| 상한 | 6000 유지 / 6500 / 8000 | **6500 (ADR-012 tradeoff)** | phase-21 정당한 추가 반영. upstream 8000 대비 19%↓, 하드캡 유지. spec-21-03 결정 갱신 |
| 번호 | (sdd 부여) | diet=**21-05**, persona=21-06 | sdd 생성순서 ID. narrative 번호는 DRAFT (phase.md 정정 노트) |

### ADR 승격 가이드
- [x] ADR 승격 대상 있음 → 작성됨: `docs/decisions/ADR-012-governance-word-budget.md` (type: tradeoff)
- [ ] 없음

## 💬 사용자 협의

- **주제**: 21-06→21-05 번호 충돌 — **합의**: sdd 부여 수용(diet=21-05).
- **주제**: Plan Accept — **합의**: Plan Accept (1).
- **주제**: **다이어트 한계(§7)** — **사용자 의견**: 4번(하이브리드) — **합의**: 안전압축 최대 + 상한 6000→6500 + ADR-012.
- **주제**: Ship 코드 리뷰 — **합의**: Opus → Approve.

## 🧪 검증 결과

### 1. 자동화 테스트
- **명령**: `bash tests/test-governance-dedup.sh`
- **결과**: ✅ **ALL 8 CHECKS PASSED** (phase 내내 red 였던 Check 3 최초 GREEN)
- **단어 예산 (before/after)**:
```text
before (phase-21 누적): agent 4696 + const 2798 = 7494w (상한 6000 → +1494 red)
after  (본 spec):       agent 4097 + const 2296 = 6393w
  · 안전 압축: ~1101w 제거 (agent -599, const -502) — relocate/compress/delete
  · 상한 재보정: 6000 → 6500 (ADR-012) — 정당한 director 추가 반영
  → 6393w ≤ 6500 GREEN. upstream 8000 대비 19%↓.
```

### 2. 회귀 (용어/enforcement 보존)
- director-protocol 13/13 · context-orchestration 6/6 · role-model-config 9/9 · director-mode 10/10 — 무 회귀(§6.6/§6.8 용어 보존).
- governance-dedup Check 1(중복0)/2(미러)/4/5/6 유지.
- enforcement spot-check: const `MUST NOT` 8→8 · `CRITICAL VIOLATION` 3→3 · agent `PROHIBITED`/`STRICTLY PROHIBITED` 보존. `MUST` 감소분은 전량 문장 병합(규칙 삭제 아님 — Opus 라인 대조 확인).

### 3. 수동 검증
1. `wc -w` before/after → 합계 6393w ≤ 6500.
2. `diff -q` 미러(const+agent) → 차이 없음.
3. 핵심 규칙 grep(One Task=One Commit / No Work on main / Premature Execution) 잔존 확인.

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Opus same-model — Gemini 제외: phase base fix 미반영 + governance prose) |
| **결과 파일** | `specs/spec-21-05-governance-diet/code-review.md` |
| **요약** | **Approve** / Critical 0 / Major 0 / Minor 1 |
| **Minor 처리** | §8.4 cross-ref 의 `constitution` 한정자 누락 → **즉시 복원**(`style` 커밋). §8.5 bullet 흡수는 범위 불변(조치 불요) |

> Opus 가 삭제 라인 전수 대조로 **규칙 손실 0** 확인 + ADR-012 근거 견고 판정.

## 🔍 발견 사항

- **안전 압축의 천장**: phase-21 의 정당한 거버넌스 추가 후, ~1100w 안전 압축으로도 <6000 불가 — 잔여가 대부분 *법(rule)*. <6000 강행은 §11.3(매 spec 사용) 추출 friction 또는 법 과압축 둘 중 하나를 강요 → 상한 재보정(ADR-012)이 합리적 균형.
- **§6.7/§8.4 stub 패턴 재사용**: 상세를 이미 존재하는 가이드(native-feature-usage.md)로 위임 = 정보 손실 0 의 가장 깨끗한 절감.

## 🚧 이월 항목

- **분기별 governance prune protocol** (Icebox 기존) — 거버넌스 ratchet 누적 방지 메커니즘. ADR-012 가 상한을 올렸으니 더 유의미.
- **persona-review-panel** → spec-21-06 (phase-21 잔여 마지막).

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent(Opus orchestrator) + Opus reviewer + Leo |
| **작성 기간** | 2026-06-08 |
| **최종 commit** | `cf1fe35` (ship commit 직전) |
