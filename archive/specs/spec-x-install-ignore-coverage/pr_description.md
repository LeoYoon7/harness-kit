# chore(spec-x-install-ignore-coverage): install/uninstall ignore line coverage + container build guide + ADR-005

> install.sh `.gitignore` 자동 갱신에 리뷰 도구 출력물 한 줄 추가 + uninstall.sh awk 대칭성 보강 + sdd doctor 의 ignore 위생 점검 (.gitignore + Dockerfile 조건부 .dockerignore) + README 컨테이너 빌드 가이드 + ADR-005 (kit-managed-ignore-line-symmetry invariant).

## 📋 Summary

### 배경 및 목적

`harness-kit` self-host 저장소에서 `/hk-gemini-review` 가 생성한 `code-review-gemini.md` 3건이 동시에 untracked drift 로 검출됨 — 직전 spec-x 가 일회성 `.gitignore` 수정으로 우회했으나, 같은 패턴이 모든 설치 프로젝트에서 재발 보장. 동시에 Icebox 에 누적된 컨테이너 빌드 컨텍스트 비대칭 (`.dockerignore` 누락) 도 같은 "install.sh ignore 위생" 카테고리라 bundle.

`/hk-spec-critique` 가 발견한 **critical 누락** (install.sh ↔ uninstall.sh awk 대칭성 결여 + 다중 라운드 update 안정성 미검증) 까지 함께 해결, ADR-005 invariant 로 향후 재발 방지.

### 주요 변경 사항

- [x] `install.sh` `.gitignore` 자동 갱신 블록에 `specs/**/code-review*.md` 추가 (멱등) + `# harness-kit` 헤더 self-host 시에도 강제 추가 (정책 전환)
- [x] `uninstall.sh` awk 패턴 enumeration 에 신규 라인 대응 등재 (install/uninstall 대칭성)
- [x] `sources/bin/sdd` `cmd_doctor()` 에 `ignore 위생` 섹션 신설 — `.gitignore` 미등재 경고 + Dockerfile 조건부 `.dockerignore` 미등재 경고 (관대 패턴 매칭으로 false positive WARN 회피)
- [x] `README.md` 컨테이너 빌드 컨텍스트 가이드 섹션 추가 (`.dockerignore` 권장 항목 + 다른 컨테이너 도구 안내 + sdd doctor 자동 감지 안내)
- [x] `docs/decisions/ADR-005-kit-managed-ignore-line-symmetry-invariant.md` 신규 작성 (type: invariant)
- [x] `tests/test-gitignore-config.sh` Scenario I (다중 라운드 안정성) + Scenario J (uninstall 대칭성) + A-4 / H-2 / H-3 신설
- [x] `tests/test-doctor-ignore-coverage.sh` 신규 — `.gitignore` 점검 3 시나리오 + `.dockerignore` 매트릭스 6 시나리오

### Phase 컨텍스트

- **Phase**: 없음 (spec-x — Phase 비소속)
- **본 SPEC 의 역할**: 모든 sdd 설치 프로젝트에서 반복 발생하는 drift 패턴 (review 출력) 의 근본 차단 + 컨테이너 사용자의 빌드 컨텍스트 위생 인지 강화 + 향후 신규 ignore 라인 추가 시점에 본 spec 의 critical 함정 (uninstall awk 비대칭) 재발 방지 (ADR-005)

## 🎯 Key Review Points

1. **`.gitignore` 자동 / `.dockerignore` 경고만 정책 비대칭**: spec.md §해결방안 §(3) + walkthrough.md §결정기록 + ADR-005 §Alternatives 에 근거 명시. Husky PR #951 사례 (자동 갱신의 사용자 마찰) 인지 + Terraform / dockerignore-generate 패턴 (사용자 자유도 우선) 과 정합.

2. **uninstall.sh awk 대칭성 invariant (ADR-005)**: install.sh 가 `.gitignore` 헤더 블록에 추가하는 모든 라인은 uninstall.sh awk 의 알려진 패턴 enumeration 에 *반드시* 대응 등재. 누락 시 awk 의 `inblk==1 { inblk=0 }` 가 알려지지 않은 라인에서 블록 조기 종료 → 인접 라인 추출 실패 + stale 잔존. 본 spec critique 가 위반 사례 발견 직후 invariant 박음.

3. **self-host 헤더 정책 전환**: 이전 정책 (self-host 시 헤더 skip — cosmetic 노이즈 회피) → 신규 정책 (헤더 강제 추가 — 신규 라인의 고아 라인 위험 차단). 본 저장소 self-host 적용 후 *orphan 헤더* 가 발생하나 기능적 무해 (uninstall awk 가 빈 블록을 EOF 로 자연 종료). 신규 fresh install 에는 정상.

4. **`.dockerignore` 관대 매칭 패턴**: `(^|/)\.harness-kit/?$` — `.harness-kit/`, `.harness-kit` (슬래시 없이), `**/.harness-kit/` 모두 인정. 정확 매치 강제 시 사용자 자유도 침해 + false positive WARN.

## 🧪 Verification

### 자동 테스트

```bash
bash tests/test-gitignore-config.sh         # 21/21 PASS (신규 6 시나리오 포함)
bash tests/test-doctor-ignore-coverage.sh   # 9/9 PASS (신규 9 시나리오)
bash tests/test-hk-doctor.sh                # PASS (회귀)
bash tests/test-install-layout.sh           # PASS (회귀)
bash tests/test-update.sh                   # PASS (회귀)
bash tests/test-update-stateful.sh          # 16/17 PASS (S4 pre-existing FAIL — 본 spec 무관)
```

**결과 요약**:
- ✅ test-gitignore-config: A-4 / H-2 / H-3 / I-1/2/3 / J-1/2/3 신설 + 기존 12 시나리오 회귀 없음
- ✅ test-doctor-ignore-coverage: a-section / a-1 / a-2 / b-1 ~ b-4c 9 시나리오 모두 통과
- ✅ 회귀 3종 PASS (test-hk-doctor, test-install-layout, test-update)
- ⚠ test-update-stateful: 16/17 PASS — S4 "Icebox 메모 손실" **pre-existing FAIL** (본 spec 무관, main 에서도 동일 발생 확인). update.sh 의 queue.md Icebox 보존 별도 버그 → 별도 spec-x 후보

### 수동 검증 시나리오

1. **self-host update**: `bash update.sh --yes .` → `.gitignore` 멱등 + `.harness-kit/bin/sdd` 동기화 → 동작
2. **self-host doctor**: `bash .harness-kit/bin/sdd doctor` → `ignore 위생` 섹션 출력 + `.gitignore PASS` + `.dockerignore` Dockerfile 부재로 silent skip → 동작
3. **multi-round update**: tests/test-gitignore-config.sh Scenario I 가 자동 검증 — update × 3회 후 라인 멱등 + 헤더 멱등 + 인접 라인 무손상

## 📦 Files Changed

### 🆕 New Files
- `docs/decisions/ADR-005-kit-managed-ignore-line-symmetry-invariant.md`: invariant ADR (type: invariant, status: accepted)
- `tests/test-doctor-ignore-coverage.sh`: sdd doctor 의 `ignore 위생` 섹션 회귀 (9 시나리오)
- `specs/spec-x-install-ignore-coverage/`: spec / plan / task / critique / walkthrough / pr_description

### 🛠 Modified Files
- `install.sh` (+9, -3): `.gitignore` `_gi_ensure` 호출 시퀀스 + 헤더 강제 정책
- `uninstall.sh` (+1): awk 패턴에 `specs/**/code-review*.md` 매칭 추가 (ADR-005)
- `sources/bin/sdd` (+18): `cmd_doctor()` 에 `ignore 위생` 섹션 (`.gitignore` 점검 + Dockerfile 조건부 `.dockerignore` 점검)
- `README.md` (+23): 컨테이너 빌드 컨텍스트 가이드 섹션
- `tests/test-gitignore-config.sh` (+113, -4): A-4 / H-2 (expectation 반전) / H-3 / Scenario I / Scenario J
- `backlog/queue.md` (+2): Icebox 에 컨테이너 빌드 컨텍스트 항목 + ADR-tool-output-in-tree-vs-out-of-tree 후보 등재
- `.gitignore` (+2): self-host update.sh 적용 결과 (`# harness-kit` 헤더 append)
- `.harness-kit/bin/sdd` (+18): sources sync (ADR-003)
- `.harness-kit/installed.json` (timestamp): update.sh 갱신

**Total**: 8 modified + 3 new (spec dir + ADR + new test) = 11 file groups

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과 (test-gitignore-config + test-doctor-ignore-coverage)
- [x] 회귀 테스트 통과 (test-hk-doctor + test-install-layout + test-update + test-update-stateful)
- [x] `walkthrough.md` ship commit 완료
- [x] `pr_description.md` ship commit 완료
- [x] lint: shellcheck 미설치 환경 (warning 만, blocking 아님)
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Spec: `specs/spec-x-install-ignore-coverage/spec.md`
- Plan: `specs/spec-x-install-ignore-coverage/plan.md`
- Critique: `specs/spec-x-install-ignore-coverage/critique.md`
- Walkthrough: `specs/spec-x-install-ignore-coverage/walkthrough.md`
- ADR-005: `docs/decisions/ADR-005-kit-managed-ignore-line-symmetry-invariant.md`
- 직전 관련 commit: `2662536` (self-host 한정 `.gitignore` 일회성 우회 — 본 spec 이 모든 사용자에 전파)
