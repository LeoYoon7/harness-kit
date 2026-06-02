# Walkthrough: spec-x-skip-perms-launcher

> 권한 우회 런처(`claude --dangerously-skip-permissions`)를 키트의 opt-in 설치 산출물로 추가한 작업 기록.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 런처 배포 방식 | ①개인 dotfile / ②opt-in 키트 플래그 / ③기본 키트 산출물 | **②** | 거버넌스 키트가 권한 우회 도구를 *기본값*으로 모든 대상에 커밋·배포하는 footgun 회피. 사용자의 "install/update 가 설치" 요구는 충족 |
| 작업 모드 | spec-x / 새 Phase | **spec-x** | install 메커니즘 단일 영역·단일 PR·기존 테스트 인프라 재사용. 새 phase 응집도 없음 |
| 런처 원본 위치 | `sources/root/` / `sources/optional/` | **`sources/optional/`** | `sources/root/*.sh` 는 §12b glob 으로 무조건 설치됨 → 분리해야 opt-in 보장 |
| 커밋 차단 | .gitignore 등재 / 커밋 허용 | **.gitignore 등재** | 권한 우회 런처가 대상 repo 에 커밋되어 팀원이 무심코 실행하는 것 방지 (개인 로컬 전용) |
| `.dockerignore` 처리 | install 자동기록 / sdd doctor 경고 | **doctor 경고** | 기존 `.harness-kit/` 점검과 동일 패턴(install 은 .dockerignore 를 직접 쓰지 않음). 런처가 gitignore 대상이라 clean CI 체크아웃엔 부재 → 빌드 안전 기본 확보. 추가 uninstall 대칭 부담도 회피 |
| uninstall 대칭 | 파일만 제거 / 파일+gitignore 라인 제거 | **파일+라인 모두** | install 이 추가한 ignore 라인을 uninstall 이 안 지우면 orphan (ADR-005). awk 가 미등록 라인에서 멈춰 잔재 발생 |
| CHANGELOG | 지금 기록 / release 롤업 | **release 롤업** | release-strategy.md 상 `## [X.Y.Z]` 는 release 시 `git log tag..main` 으로 PR `(#N)` 에서 기록 (#18/#19/#20 → #21 패턴). `## [Unreleased]` draft 는 Phase ship 규칙이라 spec-x 비해당 |

### ADR 승격 가이드
- [ ] ADR 승격 대상 있음
- [x] 없음 — 기존 ADR-005(대칭 등록) + 기존 dockerignore 컨벤션 재사용. 신규 long-lived 결정 없음.

## 💬 사용자 협의

- **주제**: 런처를 이 repo 에 둘지 vs 키트 설치 산출물로 둘지
  - **사용자 의견**: "이 프로젝트에 필요한 게 아니라 install/update 실행 시 설치한다"
  - **합의**: `sources/optional/` 키트 산출물 + `--with-skip-launcher` opt-in
- **주제**: 배포 방식 (footgun 우려)
  - **사용자 의견**: 2번 (opt-in 키트 플래그)
  - **합의**: 기본 off + gitignore 비커밋 + doctor 경고
- **주제**: 작업 모드
  - **사용자 의견**: 1번 (spec-x)
  - **합의**: spec-x-skip-perms-launcher

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트 (신규)
- **명령**: `bash tests/test-skip-launcher.sh`
- **결과**: ✅ Passed (15/15)
- **로그 요약**:
```text
A(미설치) 3/3 · B(설치+gitignore+config+내용) 4/4 · C(재설치 멱등) 1/1
D(update 보존) 3/3 · E(uninstall 대칭) 2/2 · F(doctor 경고) 2/2
결과: 15 / 15 PASS  ✅ ALL PASS
```

#### 회귀 테스트
- **명령**: `bash tests/test-{gitignore-config,gitignore-idempotent,install-layout,doctor-ignore-coverage}.sh`
- **결과**: ✅ 모두 PASS (21/21, 22/22, 15/15, 9/9)
- **사전존재 FAIL (본 변경 무관)**:
  - `test-update-stateful.sh` S4 "Icebox 메모 손실" — PASS=16/FAIL=1
  - `test-uninstall-cmd-list.sh` "hk-* 잔재 15개" — PASS=8/FAIL=1
  - 두 건 모두 `git worktree` 로 `main` 격리 실행 시 동일하게 FAIL → 사전존재(이 Windows/git-bash 환경 특성, 키트 1차 타깃은 macOS). 본 spec 의 launcher 변경과 무관.

### 2. 수동 검증

1. **Action**: `bash install.sh --yes --with-skip-launcher <fixture>`
   - **Result**: 루트에 `claude-dangerously-skip-permissions.sh` 생성, `.gitignore` 등재, config `skipLauncher=true`
2. **Action**: `bash install.sh --yes <fixture>` (플래그 없음)
   - **Result**: 런처 미생성, config `skipLauncher=false` (기존 사용자 영향 0)
3. **Action**: `git update-index --chmod=+x` 후 `git ls-files -s`
   - **Result**: `100755` (실행 비트, macOS 타깃에서 실행 가능)

## 🔍 발견 사항

- **기존 루트 런처(`telegram.sh`/`discord.sh`)도 `.dockerignore` 미커버** — 동일 갭이나 본 spec 범위 밖. Icebox 기록.
- **Windows/git-bash 사전존재 테스트 실패 2건** — S4(Icebox), hk-* 잔재. 별도 조사 대상(키트 1차 타깃 macOS 라 우선순위 낮음).
- `grep -c ... || echo 0` 관용구 함정 — `grep -c` 는 0 매치 시 "0" 출력 + exit 1 → `|| echo 0` 이 중복 출력 → "0\n0" 정수비교 오류. `|| true` 가 정답.

## 🚧 이월 항목

- 기존 루트 런처(telegram/discord)의 `.dockerignore` 커버리지 → `backlog/queue.md` Icebox 에 추가

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-02 |
| **최종 commit** | (ship commit) |
| **브랜치** | `spec-x-skip-perms-launcher` (11 commits, 11 files) |
