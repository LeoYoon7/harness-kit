# fix(spec-x-sdd-robustness-fixes): sdd 견고성 버그 2종 (ship spec-x scope + stale-adr fd race)

## 📋 Summary

### 배경 및 목적

`spec-x-review-b1-default`(#49) 작업 중 `sources/bin/sdd` 의 두 견고성 버그가 실증됐다. 본 PR 이 둘을 한 번에 수정한다.

### 주요 변경 사항
- [x] **Bug 1 — ship spec-x slug truncation**: `cmd_ship()` 이 커밋 scope 를 `awk -F- '{$1-$2-$3}'` 로 뽑아 `spec-x-{slug}` 를 `spec-x-{첫단어}` 로 잘랐다(예: `spec-x-review-b1-default` → `docs(spec-x-review):`). `sdd_ship_scope()` 헬퍼 + `spec-x-*` case 분기로 전체 id 보존.
- [x] **Bug 2 — stale-adr git-bash fd race**: `_drift_stale_adr()` 의 프로세스 치환(`done < <(...)`)이 git-bash 에서 간헐 미탐지(부하 시 fd race). here-string(`done <<< "$toks"`)으로 교체.
- [x] **소스 가드**: 말미 `main "$@"` → `[ "${BASH_SOURCE[0]}" = "$0" ] && main "$@"` — 직접 실행 불변 + 소싱 시 함수 단위 테스트 가능.
- [x] 도그푸딩 미러(`.harness-kit/bin/sdd`) 동기화(ADR-003).

### Phase 컨텍스트
- **Phase**: 없음 (spec-x, Solo)
- **역할**: 직전 spec(#49) 작업 중 실증된 sdd 버그의 즉시 수정 — "문제-실증 기반 후속" 패턴.

## 🎯 Key Review Points

1. **`sdd_ship_scope()` 분기**: `spec-x-*` 전체 보존 vs 일반 spec 첫 3필드.
2. **소스 가드**: 직접 실행 동작 불변(회귀 확인) + 소싱 시 main 미실행.
3. **here-string 빈 입력**: 빈 `toks` → 빈 줄 1회 → 기존 `[ -z "$token" ]` 가드가 처리(false positive 없음).

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-sdd-ship-scope.sh       # 5/5 PASS
bash tests/test-drift-stale-adr.sh      # 4/4 PASS (detection 회귀 없음)
bash -n sources/bin/sdd                 # 구문 OK
```

### 직접 실행 회귀 (소스 가드)
```bash
bash .harness-kit/bin/sdd help/version/status --brief --no-drift   # 모두 exit 0
```

### 코드 리뷰 (cross-model)
- **Gemini: Approve** — Critical 0 / Major 0 / Minor 0. 4 FR 충족 + bash 3.2 호환 + 빈 toks 처리 확인. (`code-review-gemini.md`)

### 도그푸딩 (Bug 1 라이브)
- 본 PR 의 ship 커밋 subject = `docs(spec-x-sdd-robustness-fixes): ...` — fix 적용된 미러로 `sdd ship` 이 돌아 truncate 없음 실증.

## 📦 Files Changed

### 🆕 New Files
- `tests/test-sdd-ship-scope.sh`: `sdd_ship_scope` 단위 테스트.
- `specs/spec-x-sdd-robustness-fixes/*`: spec/plan/task/walkthrough/pr_description/code-review-gemini.

### 🛠 Modified Files
- `sources/bin/sdd` / `.harness-kit/bin/sdd`: `sdd_ship_scope()` + 소스 가드 + here-string (미러 동기).
- `backlog/queue.md`: spec-x 등록.

**Total**: ~10 files (ship commit 포함)

## ✅ Definition of Done
- [x] 단위 테스트 PASS (ship-scope 5/5)
- [x] 회귀 테스트 PASS (stale-adr 4/4, 직접 실행)
- [x] cross-model 리뷰 Approve (0/0/0)
- [x] walkthrough/pr_description ship
- [ ] 사용자 검토 요청 (push 후)

## 🔗 관련 자료
- 발견 출처: `spec-x-review-b1-default`(#49) 작업
- Walkthrough: `specs/spec-x-sdd-robustness-fixes/walkthrough.md`
- 리뷰: `specs/spec-x-sdd-robustness-fixes/code-review-gemini.md`
