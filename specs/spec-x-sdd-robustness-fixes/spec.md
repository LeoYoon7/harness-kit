# spec-x-sdd-robustness-fixes: sdd 견고성 버그 2종 (ship spec-x scope + stale-adr 프로세스치환)

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-sdd-robustness-fixes` |
| **Phase** | 없음 (spec-x, Solo) |
| **Branch** | `spec-x-sdd-robustness-fixes` |
| **상태** | Planning |
| **타입** | Fix |
| **Integration Test Required** | no |
| **작성일** | 2026-06-09 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

`spec-x-review-b1-default`(#49) 작업 중 `sources/bin/sdd` 의 두 견고성 버그가 실증됐다(queue.md Icebox 기록).

### 문제점

1. **ship spec-x slug truncation** — `cmd_ship()`(`sources/bin/sdd:1808-1809`)이 커밋 scope 를 `awk -F- '{print $1"-"$2"-"$3}'` 로 추출한다. 일반 spec `spec-{phaseN}-{seq}-{slug}` 에선 첫 3필드=`spec-NN-NN` 로 정상이나, **spec-x `spec-x-{slug}` 에선 첫 3필드가 `spec-x-{slug첫단어}`** 가 되어 truncate 된다. 실증: `spec-x-review-b1-default` → 커밋 subject `docs(spec-x-review):` (수동 amend 로 정정). slug 에 하이픈/숫자가 있는 모든 spec-x 가 영향.

2. **stale-adr 탐지 git-bash 플래키** — `_drift_stale_adr()`(`sources/bin/sdd:402`)이 `done < <(grep ... | tr -d '`')` **프로세스 치환**으로 토큰을 읽는다. git-bash 에서 프로세스 치환은 fd race 가 알려진 취약점 — 부하(dirty 워킹트리)↑ 시 while 루프가 토큰을 못 읽어 `has_missing=0` → 미탐지(간헐). 실증: `test-drift-stale-adr.sh` Step 2 가 3회 중 1회 FAIL(dirty tree). `has_missing` 을 부모 스코프에 유지하려고 pipe 대신 프로세스 치환을 쓴 것이 원인.

### 해결 방안 (요약)

(1) `cmd_ship()` 의 scope 추출을 `sdd_ship_scope()` 헬퍼로 분리하고 `spec-x-*` 는 전체 id 를 scope 로 쓰도록 case 분기. (2) `_drift_stale_adr()` 의 프로세스 치환을 here-string(`<<<`)으로 교체해 fd race 제거. 둘 다 도그푸딩 미러(`.harness-kit/bin/sdd`) 동기화.

## 🎯 요구사항

### Functional Requirements

1. **ship scope 정확성** — `sdd_ship_scope()` 헬퍼: `spec-x-{slug}` → 전체 id, `spec-{N}-{seq}-{slug}` → 첫 3필드(`spec-{N}-{seq}`). `cmd_ship()` 이 이 헬퍼로 커밋 subject scope 를 구성.
2. **sdd 소스 가드** — sdd 말미 `main "$@"` 를 `[ "${BASH_SOURCE[0]}" = "$0" ] && main "$@"` 로 가드해 *직접 실행은 동일*, *소싱 시 main 미실행*(함수 단위 테스트 가능). 직접 실행 동작 불변이 필수.
3. **stale-adr fd race 제거** — `_drift_stale_adr()` 의 `done < <(...)` 를 here-string(`toks="$(...)"; done <<< "$toks"`)으로 교체. 탐지 결과(stale 카운트)는 기존과 동일.
4. **도그푸딩 미러 동기화** — `sources/bin/sdd` 변경을 `.harness-kit/bin/sdd` 에 동일 반영(ADR-003), 같은 commit.

### Non-Functional Requirements

1. **bash 3.2 호환** — case/here-string/`BASH_SOURCE` 모두 bash 3.2 OK. 프로세스 치환·declare -A 등 미사용.
2. **직접 실행 동작 불변** — 소스 가드 추가가 `bash .harness-kit/bin/sdd <cmd>` 실행을 바꾸면 안 됨(전 sdd 테스트 회귀 없음).
3. **자기 도그푸딩** — 본 spec ship 시 fix 된 미러로 `sdd ship` 이 돌아 커밋 subject 가 `docs(spec-x-sdd-robustness-fixes):` 로 온전히 나오는지 실증(Bug 1 라이브 검증).

## 🚫 Out of Scope

- **stale-adr 의 결정적 플래키 repro 테스트** — 레이스 기반 플래키를 결정적으로 재현하는 테스트는 안티패턴. 회귀(detection 정확성)만 기존 `test-drift-stale-adr.sh` 로 보장.
- **sdd 의 다른 함수 소싱 테스트 확대** — 소스 가드는 본 spec 의 Bug 1 테스트 활성화에 한정. 타 함수 테스트 추가는 미착수.
- **archive/ 미탐색 stale-adr 오탐**(별도 Icebox 항목) — 본 spec 무관, 제외.

## 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — 국소 버그 수정. 새 장기 불변식 없음(ADR-003 도그푸딩 sync 는 기존).

## ✅ Definition of Done

- [ ] `tests/test-sdd-ship-scope.sh` 작성 + PASS (`sdd_ship_scope` 단위: spec-x 전체 / 일반 spec 3필드)
- [ ] `tests/test-drift-stale-adr.sh` 회귀 PASS (here-string 교체 후 Step 1-4 green)
- [ ] sdd 직접 실행 회귀 — `sdd status` / `sdd help` 정상(소스 가드 후)
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] 브랜치 push + 사용자 알림
