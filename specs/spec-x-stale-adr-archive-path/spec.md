# spec-x-stale-adr-archive-path: stale ADR 검사의 archive 경로 미탐색 false-positive 근본 해결

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-stale-adr-archive-path` |
| **Phase** | `phase-x` |
| **Branch** | `spec-x-stale-adr-archive-path` |
| **상태** | Planning |
| **타입** | Fix |
| **Integration Test Required** | no |
| **작성일** | 2026-06-09 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

`sdd status` 의 drift 진단에 포함된 `_drift_stale_adr()` (`sources/bin/sdd`) 는 `docs/decisions/ADR-*.md` (live ADR) 본문의 backtick 토큰 중 파일 경로로 보이는 것을 추출해 **존재 여부를 검사**한다. 존재하지 않으면 "stale ADR" 로 카운트한다.

존재 검사는 한 줄이다.

```bash
[ -e "$SDD_ROOT/$token" ] && continue   # line 401 — repo 루트만 확인
```

### 문제점

ADR 이 참조하는 spec (`specs/spec-x-foo/spec.md` 등) 이 `sdd archive` 로 `archive/specs/spec-x-foo/spec.md` 로 **이동**되면, root 경로(`specs/...`)는 더 이상 존재하지 않는다. 그러나 그 참조 대상은 *삭제된 것이 아니라 이동*했을 뿐이므로 ADR 은 여전히 유효하다. 현재 코드는 root 만 보므로 이 경우를 **stale ADR 오탐(false-positive)** 으로 보고한다.

- **실증 사건**: 2026-06-01, ADR-003/004/005 가 참조하던 spec 들이 archive 되면서 stale 로 오탐 → ADR 본문 경로를 수동으로 `archive/...` 로 갱신해야 했다. archive 는 *루틴 정리 작업*인데 매번 ADR 편집을 강요하는 것은 비대칭 비용이다.
- **재발성**: archive 는 주기적으로 일어나므로, 경로 기반 참조를 가진 ADR 이 늘수록 이 오탐은 반복된다. queue.md 의 미해결 근본책 항목.
- **참고**: #50(spec-x-sdd-robustness-fixes)은 같은 함수의 *fd race*(프로세스 치환 → here-string)만 고쳤고, archive 경로 미탐색은 그대로 남았다.

### 해결 방안 (요약)

`_drift_stale_adr()` 의 존재 검사에 **archive fallback** 한 줄을 추가한다. root 에 없으면 `archive/` 아래(이동된 위치)도 확인하고, 거기 있으면 *존재하는 것으로 간주*하여 stale 카운트에서 제외한다. `sdd archive` 는 최상위 1단계 prefix(`specs/`·`backlog/`)를 `archive/` 하위 동명 디렉토리로 보존하며 옮기므로(`specs/X` → `archive/specs/X`), 검사 경로는 `$SDD_ROOT/archive/$token` 이다.

### 적용 전제 및 trade-off (critique 반영)

- **전제 — 기본 경로(`specs/`·`backlog/`)**: 본 fix 의 `archive/$token` prefix 매칭은 `cmd_archive` 가 `specs/`·`backlog/` 를 `archive/` 하위 동명 디렉토리로 보존한다는 데 의존한다. `harness.config.json` 의 `specsDir`/`backlogDir` 로 경로를 override 한 경우(예: `specsDir: "work/specs"`)에는 토큰 prefix 와 archive 위치가 갈려 매칭이 보장되지 않는다. 본 프로젝트는 기본값을 쓰므로 도그푸딩에 무해하며, 비기본 경로 대응은 OOS.
- **trade-off — archived target 참조 ADR 의 영구 면제**: archive 는 immutable 보존소이므로, archived target 을 가리키는 ADR 은 그 참조가 archive 에 존재하는 한 stale 검사에서 *영구 면제*된다. 이는 "이동 ≠ 삭제" 라는 의도된 동작이다(진짜 삭제 시 root·archive 모두 부재 → 정상 탐지). immutable 전제 하에 수용 가능한 비대칭이다.

## 🎯 요구사항

### Functional Requirements

1. live ADR 이 참조하는 경로 토큰이 root(`$SDD_ROOT/$token`)에는 없지만 archive(`$SDD_ROOT/archive/$token`)에 존재하면, stale ADR 로 카운트하지 **않는다**.
2. root·archive 모두에 없는 경로(진짜 삭제/오타)는 **여전히** stale 로 정상 탐지한다 (기존 동작 회귀 없음).
3. `sources/bin/sdd` 와 도그푸딩 설치본 `.harness-kit/bin/sdd` 를 동일하게 반영한다 (dogfood sync, ADR-003).

### Non-Functional Requirements

1. bash 3.2+ 호환 (`#!/usr/bin/env bash` + `set -euo pipefail`, bash4 전용 기능 금지).
2. 기존 4개 step 테스트(`tests/test-drift-stale-adr.sh`)는 그대로 PASS — 회귀 없음.
3. 변경은 1줄 추가 수준의 surgical edit. 기존 필터 로직(슬래시/URL/확장자/`../` 제외)은 손대지 않는다.

## 🚫 Out of Scope

- **queue 제안 (b) — ADR 템플릿이 spec 참조 시 영구 식별자(PR 링크/commit hash) 권장**: convention 변경이라 별도 검토 필요. 본 spec 은 즉효성 있는 fix (a) 만 수행하고, (b) 는 Icebox follow-up 으로 남긴다.
- archive 외의 다른 이동(예: spec 디렉토리 rename) 대응. 본 fix 는 archive 이동만 다룬다.
- **비기본 `specsDir`/`backlogDir`(config override) 대응**: `archive/$token` prefix 매칭이 보장되지 않음(위 "적용 전제" 참조). 기본 경로 전제만 지원.
- `_drift_stale_adr` 외 다른 drift 검사(원격 behind/ahead, 워킹트리, dogfood sync)의 archive 처리.

### ⚠ 관례 충돌 해소 (specs/CLAUDE.md)

`specs/CLAUDE.md` 는 "`archive/specs/*` 는 grep/정합성 검사 false positive 의 원천이므로 외부 참조 검색 시 archive 는 건너뛰는 것이 기본" 이라고 명시한다. 본 fix 는 archive 를 *검사*하므로 표면상 충돌처럼 보이나, 둘은 **별개 관심사**다.

- 관례가 막는 것: archived 파일을 *권위 있는 source 로 스캔*해 그 안의 참조를 따라가는 것 (이동분이 중복 매치를 만들어 노이즈가 됨).
- 본 fix 가 하는 것: *live ADR 이 가리키는 단일 target 의 존재 여부*를 확인할 때, 그 target 이 archive 로 이동했는지 fallback 확인 (이동 = 존재, 삭제 ≠ 존재). archived 파일을 스캔하지 않는다 — loop 는 여전히 `docs/decisions/ADR-*.md` (live) 만 순회한다.

## 🔍 Critique 결과 (반영 완료)

`/hk-spec-critique` (Opus, 코드 레벨 검증 포함) 실행. 권장안 = **현재 spec(대안 A) 유지 + 경미 보강**. 전체: `specs/spec-x-stale-adr-archive-path/critique.md`

- 반영: ① 기본 `specsDir`/`backlogDir` 전제 + archived target 영구 면제 trade-off 명시, ② `backlog/` 참조 archive 테스트(Step 6) 추가, ③ "상대구조 보존" → "1단계 prefix 보존" 표현 정밀화.
- 미반영(가치 낮음): archive-skip 관례가 과거 root-only 검사의 배경이었을 가능성 한 줄.
- 모순 판정: `specs/CLAUDE.md` archive-skip 관례와 진짜 충돌 아님 — fix 는 "스캔" 이 아닌 "존재 확인" (critique 가 spec 의 구분이 정확하다고 확인).
- ADR 후보: **없음** (기존 immutable 불변식의 적용일 뿐, 새 장기 결정 아님).

## ✅ Definition of Done

- [ ] 모든 단위 테스트 PASS (`tests/test-drift-stale-adr.sh` — 기존 4 step + 신규 Step 5/6 archived spec·backlog)
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-stale-adr-archive-path` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
