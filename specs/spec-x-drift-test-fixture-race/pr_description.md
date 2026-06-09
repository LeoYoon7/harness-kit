# fix(spec-x-drift-test-fixture-race): drift-stale-adr/phase16 테스트의 cross-test fixture 간섭 견고화

## 📋 Summary

### 배경 및 목적

`_drift_stale_adr()` 는 `docs/decisions/ADR-*.md` 를 **전역 glob** 하여 stale ADR **총 개수**를 출력한다. 그런데 `test-drift-stale-adr.sh`(Step 2)와 `test-phase16-integration.sh`(Scenario 2)가 둘 다 *전역 count* (`stale ADR: 1`)에 의존하는 단언을 쓴다. 두 테스트가 **동시 실행**되면(예: Claude Code 백그라운드 task 로 병렬 실행) 한 테스트의 ADR fixture 가 다른 테스트의 스캔에 잡혀 count 가 흔들리고 단언이 깨진다 — 간헐 실패의 정체.

### ⚠ 근본원인 정정 (honest correction)

최초 가설은 "fs-visibility race" 였으나 **오진**이었다. 당시 재현은 같은 fixture 파일을 쓰는 repro 스크립트 2개를 동시 실행한 *자가 collision* 아티팩트였다. 격리 micro-repro 는 solo·동시부하 모두 0 miss. 끝까지 파고든 결과 진짜 원인은 **cross-test fixture 간섭**이었다. 원래 플래키 보고의 `b6c2rakls`/`bze38u4y7` 는 CI 가 아니라 **이 하네스 백그라운드 task ID** — 즉 *동시 실행* 아티팩트이며 **serial 실행은 결정적**이다.

### 주요 변경 사항

- [x] `test-drift-stale-adr.sh` Step 1~6 단언을 *자기 fixture 파일명* 존재/부재 기준으로 교체 (전역 count/부재 제거)
- [x] `test-phase16-integration.sh` Scenario 2 도 동일 대칭 견고화 (`ADR-999-phase16-integration-fixture` 특정)
- [x] **제품 코드(`sdd`) 무변경** — 간섭은 테스트 단언 설계 문제, `_drift_stale_adr` 전역 스캔은 의도된 동작
- [x] queue: 플래키 항목 정정 strike + `sdd status` Windows 성능 저하 Icebox 기록

### Phase 컨텍스트

- **Phase**: 없음 (spec-x, SDD-x)
- **역할**: 테스트 격리 — 공유 글로벌 자원(전역 ADR 스캔)에 대한 단언을 *자기 자원 특정* 으로 만들어 병렬 실행 견고성 확보.

## 🎯 Key Review Points

1. **단언 견고화의 정확성**: 각 step 이 *자기 fixture basename* 만 grep — foreign ADR fixture 가 출력에 끼어도 영향 없음. stale 출력은 ADR rel-path 를 나열하므로 basename 매칭 성립.
2. **truncation 한계 (OOS)**: stale 목록은 최대 3개 + "…" 표시. 동시 stale fixture 가 4개 이상이면 자기 fixture 가 잘려 Step 2(포함 단언) false-fail 가능 — 현실적으로 ≤3(drift+phase16)이라 무시.
3. **Step 1 의미 좁힘**: 기존 "real ADR 도 clean" 역할은 사라지고 "자기 fixture 부재"만 확인 — 의도된 좁힘(real-ADR 건강은 본 테스트 범위 밖).

## 🧪 Verification

### deterministic 간섭 검증 (race 아님 — 1회 호출)
```bash
# foreign(phase16) + own fixture 동시 존재 → sdd status 1회
```
**결과**: `stale ADR: 2 (missing-path) — ADR-999-phase16-integration-fixture.md; ADR-999-stale-fixture.md`
- ✅ 구 단언 `grep "stale ADR: 1"` → **NO MATCH** (구 Step2 FAIL = 간섭 재현)
- ✅ 신 단언 `grep "ADR-999-stale-fixture"` → **MATCH** (신 Step2 PASS = 견고)
- ✅ phase16 fixture 도 목록에 나타남 → phase16 신 단언도 검증됨

### 회귀 sanity
```bash
bash tests/test-drift-stale-adr.sh   # solo 6/6 PASS
```

## 📦 Files Changed

### 🛠 Modified Files
- `tests/test-drift-stale-adr.sh` (+22/-23): Step 1~6 단언 fixture-특정화 + 헤더 주석
- `tests/test-phase16-integration.sh` (+7/-4): Scenario 2 동일 견고화
- `backlog/queue.md` (+2/-1): 플래키 항목 정정 strike + perf Icebox

### 🆕 New Files
- `specs/spec-x-drift-test-fixture-race/`: spec / plan / task / walkthrough / pr_description

**Total**: 테스트 2 + 문서

## ✅ Definition of Done

- [x] deterministic 간섭 검증 (구 실패 / 신 통과)
- [x] full drift 테스트 solo 6/6 PASS
- [x] `walkthrough.md` / `pr_description.md` ship
- [x] 코드 리뷰 게이트 (Gemini cross-model)
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Spec: `specs/spec-x-drift-test-fixture-race/spec.md`
- Walkthrough: `specs/spec-x-drift-test-fixture-race/walkthrough.md`
- 관련: `tests/test-phase16-integration.sh` (대칭 fixture — 같은 전역 스캔 공유)
