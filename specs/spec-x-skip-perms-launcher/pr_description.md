feat(spec-x-skip-perms-launcher): opt-in claude --dangerously-skip-permissions 런처

## 📋 Summary

### 배경 및 목적
`claude --dangerously-skip-permissions` 를 빠르게 띄우는 런처가 필요하다. 다만 이 키트는 거버넌스/신뢰성 레이어라, 권한 우회 런처를 `sources/root/` 에 그냥 넣으면 **모든 대상 프로젝트에 기본 설치 + repo 커밋**되어 키트 취지와 충돌하고 팀원이 무심코 실행할 위험이 있다. 따라서 **opt-in 플래그**로만 설치하고, 설치 시 `.gitignore` 등재로 커밋을 차단한다.

### 주요 변경 사항
- [x] `sources/optional/claude-dangerously-skip-permissions.sh` 신규 — `sources/root/` 무조건 glob 설치와 분리
- [x] `install.sh --with-skip-launcher` (기본 off) — 플래그 시에만 복사 + `chmod` + `.gitignore` 등재 + `harness.config.json` 의 `skipLauncher` 영속화
- [x] `update.sh` 가 `skipLauncher` 선택 보존 (기존 gitignore 보존 패턴 동일)
- [x] `uninstall.sh` 가 런처 파일 + `.gitignore` 라인 대칭 제거 (ADR-005 orphan 방지)
- [x] `sdd doctor` 가 런처 설치 + Dockerfile 존재 + `.dockerignore` 미등재 시 경고

### Phase 컨텍스트
- **Phase**: 없음 (spec-x, Phase 비소속)
- **역할**: install 메커니즘에 opt-in 산출물 설치 경로를 추가하는 독립 개선

## 🎯 Key Review Points

1. **opt-in 보장**: 런처를 `sources/optional/` 에 두어 `install.sh §12b` 의 `sources/root/*.sh` 무조건 glob 에서 분리. 플래그 없으면 절대 설치 안 됨 (기존 사용자 영향 0).
2. **대칭 등록 (ADR-005)**: `install.sh §16` 이 추가하는 `.gitignore` 런처 라인을 `uninstall.sh §7` awk 에 `next` 규칙으로 대칭 추가. 미추가 시 awk 가 미등록 라인에서 멈춰 orphan 발생.
3. **`.dockerignore` = doctor 경고 방식**: install 이 `.dockerignore` 를 직접 쓰지 않고 기존 `.harness-kit/` 점검과 동일하게 doctor 가 경고. 런처가 gitignore 대상이라 clean CI 체크아웃엔 부재 → 빌드 안전 기본 확보.
4. **set -e 안전**: `[ "$HK_SKIP_LAUNCHER" -eq 1 ] && _gi_ensure ...` 는 기존 self-host guard(install L522)·prefix(update L139)와 동일한 안전 관용구.

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-skip-launcher.sh
```

**결과 요약**:
- ✅ `test-skip-launcher` (신규): 15/15 — A 미설치 / B 설치 / C 멱등 / D update 보존 / E uninstall 대칭 / F doctor 경고
- ✅ `test-gitignore-config`: 21/21
- ✅ `test-gitignore-idempotent`: 22/22
- ✅ `test-install-layout`: 15/15
- ✅ `test-doctor-ignore-coverage`: 9/9
- ⚠ `test-update-stateful` S4(Icebox) / `test-uninstall-cmd-list` hk-* 잔재 — **main 동일 사전존재 FAIL** (worktree 격리 확인), 본 변경 무관

### 수동 검증 시나리오
1. `install.sh --with-skip-launcher` → 런처 생성 + gitignore 등재 + config skipLauncher=true
2. `install.sh` (플래그 없음) → 런처 미생성
3. `update.sh` → 런처·선택 보존 / `uninstall.sh` → 런처·라인 제거

## 📦 Files Changed

### 🆕 New Files
- `sources/optional/claude-dangerously-skip-permissions.sh`: opt-in 런처 원본
- `tests/test-skip-launcher.sh`: A~F 시나리오 검증
- `specs/spec-x-skip-perms-launcher/{spec,plan,task,walkthrough,pr_description}.md`: SDD 산출물

### 🛠 Modified Files
- `install.sh` (+33): 플래그 + §12c 조건부 복사 + §16 gitignore + §17 config + §4 출력
- `uninstall.sh` (+8): 백업/제거 목록 + gitignore awk 대칭
- `update.sh` (+6): skipLauncher 보존
- `sources/bin/sdd` (+9): doctor (c) 런처 dockerignore 점검
- `README.md` (+11): 설치 옵션 + 보안 주의 + 컨테이너 가이드 + 커맨드 표
- `backlog/queue.md` (+1): sdd specx 추적

**Total**: 11 files changed

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과 (skip-launcher 15/15 + 회귀)
- [x] Integration Test Required = no
- [x] `walkthrough.md` ship commit 완료
- [x] `pr_description.md` ship commit 완료
- [x] 정적 점검: `bash -n` 통과 (shellcheck 미설치 — 환경 한계)
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Spec: `specs/spec-x-skip-perms-launcher/spec.md`
- Walkthrough: `specs/spec-x-skip-perms-launcher/walkthrough.md`
- 관련 ADR: `docs/decisions/ADR-005`(대칭 등록 — 재사용)
