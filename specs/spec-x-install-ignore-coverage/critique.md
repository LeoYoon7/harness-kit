# Spec Critique: spec-x-install-ignore-coverage

> 본 비평은 독립 시니어 아키텍트 시점에서 작성. spec.md / plan.md / install.sh / uninstall.sh / update.sh / sources/bin/sdd (cmd_doctor) / tests/test-gitignore-config.sh 를 모두 읽고, 웹 조사로 유사 도구 패턴을 비교한 결과.

---

## 1. 유사 기법 조사

### 발견된 패턴/도구

- **Husky (PR #951 "Don't create .gitignore")**: Husky 는 prepare 스크립트 실행 시 `.husky/_/.gitignore` 를 자동 생성해 내부 스크립트를 ignore. 사용자 (DoctorDerek) 가 "왜 도구가 사용자 git 위생에 침입해서 매 branch 마다 npm run prepare 재실행을 강요하는가" 로 강한 반발. PR 은 wontfix 처리됐고, 후속 issue #1048 로 논의 지속. **현재 spec 과의 비교**: harness-kit 도 동일한 침입을 하지만 *프로젝트 루트 `.gitignore` 한 줄 추가* 형태로 침입 강도가 더 큼 (Husky 는 자기 디렉토리 내 격리). 사용자 반발 가능성을 spec 이 명시적으로 다루지 않음.

- **Terraform (`.terraform/` 자동 생성 + 사용자가 직접 `.gitignore` 추가)**: provider 바이너리/모듈 캐시 경로 (`.terraform/`) 와 state 파일은 ignore 필수지만 Terraform CLI 가 사용자 `.gitignore` 를 *직접 건드리지 않음*. 대신 docs/blog 로 권장 `.gitignore` 템플릿 가이드. **현재 spec 과의 비교**: 본 spec 의 `.dockerignore` 처리 (경고만 + README 가이드) 는 Terraform 패턴과 일치하지만, `.gitignore` 처리 (자동 갱신) 는 정반대. 정책 비대칭의 산업 표준 측 근거 약함.

- **Next.js / Vite (`.next/`, `.vite/` 캐시 디렉토리)**: 신규 프로젝트 부트스트랩 시 `create-next-app` 이 *한 번* `.gitignore` 생성 후 그 이후로는 손대지 않음. 즉 "최초 1회 install" 과 "지속 갱신" 이 분리됨. **현재 spec 과의 비교**: harness-kit 의 install/update 가 매번 `.gitignore` 갱신하는 모델은 Next.js 보다 침입적. 다만 멱등 헬퍼 (`_gi_ensure`) 가 있어 부작용은 제한적.

- **dockerignore-generate / configs.sh `.dockerignore` 생성기**: `.dockerignore` 자동 생성은 *별도 CLI/웹 도구* 로 분리. 빌드 시스템이 직접 침입하지 않음. **현재 spec 과의 비교**: 본 spec 의 "경고만, 자동 갱신 안 함" 정책과 일치. *근거 강함.*

- **devcontainer (`.devcontainer/.gitignore` 패턴)**: nodejs/devcontainer, rails/devcontainer 등은 자기 디렉토리 내 ignore 로 *격리* 하고 사용자 루트 `.gitignore` 를 건드리지 않음. **현재 spec 과의 비교**: harness-kit 도 `.harness-kit/.gitignore` 로 격리하는 대안이 가능하지만 본 spec 은 채택 안 함 (이유 미설명).

### 시사점

조사 결과 산업 패턴은 *대체로 두 갈래* 다.

1. **격리형** (devcontainer, Husky 의 `.husky/_/.gitignore`): 도구가 자기 디렉토리 안에서만 `.gitignore` 관리. 사용자 루트 git 위생을 건드리지 않음. 단점은 도구 출력이 사용자 디렉토리에 떨어지면 (예: harness-kit 의 `specs/**/code-review*.md`) 격리 모델로 해결 불가.

2. **루트 침입형** (Husky 의 일부, harness-kit): 사용자 루트 `.gitignore` 를 직접 modify. Husky 의 경우 PR #951 사례처럼 사용자 마찰 (특히 branch 전환 시) 이 보고됨. harness-kit 는 동일 위험에 더 노출 — `_gi_ensure` 의 멱등성이 *re-install 시 중복 회피* 는 보장하지만 *git mv / branch checkout 후 사라진 라인 복구* 는 보장 안 함.

본 spec 의 직접 동기 ("self-host 에 untracked drift 3건 발생") 는 진짜 문제이고 한 줄 추가가 가장 작은 해결책인 것도 맞다. 다만 *원인 자체* 가 `code-review.md` 산출물이 `specs/` 하위 (= 사용자 작업 디렉토리) 에 떨어지기 때문임을 spec 이 인정하면서도, 격리형 대안 (출력 경로를 `.harness-kit/cache/reviews/` 로 이동) 을 *UX 손실* 한 줄로 일축한 것은 근거 빈약. PR 첨부 동선 손실의 구체적 시나리오 (실제로 PR 에 reviews 를 첨부하는지, 첨부한다면 cache 경로에서 못 가져오는지) 가 검증 안 됨. 본 결정은 spec.md §Out of Scope 마지막 항목인데, 이게 사실은 본 spec 전체의 *근본 분기점* — 격리형으로 가면 본 spec 의 대부분 (install.sh `.gitignore` 갱신, doctor 경고 (a), test 시나리오) 이 불필요해진다.

`.dockerignore` 처리 (경고만) 는 산업 패턴과 정합 — Terraform / dockerignore-generate 모두 자동 갱신 안 함. 본 spec 의 정책 비대칭은 *후반부 (`.dockerignore`) 는 정합, 전반부 (`.gitignore`) 는 비정합* 이 더 정확한 평가.

---

## 2. 요구사항 비판

### 누락

- **uninstall.sh 대칭성 누락 (Critical)**: `install.sh` 가 `specs/**/code-review*.md` 라인을 추가하면, `uninstall.sh` 도 그 라인을 제거해야 한다. 현재 `uninstall.sh:159-167` 의 awk 블록은 5개 패턴만 명시 매칭:
  ```awk
  inblk==1 && /^!?\.harness-kit\/$/   { next }
  inblk==1 && /^\.harness-backup-\*\/$/ { next }
  inblk==1 && /^\.claude\/state\/$/   { next }
  inblk==1 && /^\.env\.telegram$/     { next }
  inblk==1 && /^\.env\.discord$/      { next }
  ```
  신규 라인 미처리 → uninstall 후 `.gitignore` 에 stale 라인 잔존. 더 미묘한 부작용: uninstall 의 `inblk==1` 블록 매처는 "헤더 직후 *연속된* 알려진 패턴" 을 끊는 로직 (`inblk==1 { inblk=0 }`) — 알려지지 않은 신규 라인을 만나면 거기서 블록을 *조기 종료* 한다. 즉 `specs/**/code-review*.md` 가 헤더 직후 나오는 케이스에서 그 뒤의 `.env.discord` 등이 *추출 안 됨*. spec.md / plan.md 어디에도 uninstall.sh 패치 task 없음.

- **update.sh 검증 시나리오 누락**: update.sh 는 uninstall → install 순서로 동작. 위 uninstall 의 awk 가 신규 라인을 모르면, update 시 (a) uninstall 이 헤더 + 기존 라인 제거 + 신규 라인 *남김* + (b) install 이 헤더 + 5개 + 신규 라인 *재추가* (멱등) → 결과적으로 `.gitignore` 에 신규 라인 1개 + uninstall 의 조기종료 부작용으로 헤더 직후 일부 라인 분리 위험. plan.md §검증계획 §회귀테스트의 `test-update.sh` 항목은 있지만 신규 라인 특화 시나리오는 없음. DoD §8 "self-host 에 update.sh 적용 → drift 재발 안 함" 도 *update 직후 1회* 만 보지 *update → uninstall → install 다중 라운드* 의 `.gitignore` 형태 안정성은 안 본다.

- **`_gi_ensure` 정규식 escape 검증 누락**: plan.md 의 신규 호출은 `_gi_ensure '^specs/\*\*/code-review\*\.md$' 'specs/**/code-review*.md'`. 정규식 첫 인자에서 `**` 와 `*` 를 backslash escape 한 것은 맞지만 (`grep -E` 에서 `*` 가 메타문자이므로), `.` escape 가 두 번째 `*` 뒤만 있고 (`code-review\*\.md`) 첫 번째 `\*\.md` 가 *literal `*.md`* 매칭이 되는지 확인 필요. 실제로 동작은 한다 (grep -E 에서 `\*` 는 literal `*`, `\.` 는 literal `.` 매칭) 하지만 spec/plan 어디에도 *왜 이 패턴이 맞는지* 의 의도 주석/테스트 없음. 라인별 멱등이 깨지는 가장 흔한 원인이 정규식 escape 실수 (이번 `_gi_ensure` 패턴은 *문자 그대로 매칭만 하면 충분* — 차라리 `grep -qF` 가 더 안전).

- **doctor 점검 섹션 헤더 형식 일관성**: plan.md 의 doctor 신규 섹션 헤더 `.gitignore / .dockerignore 위생` 은 기존 섹션 헤더 (`필수 도구`, `선택 도구`, `설치 파일`, `Claude Code 설정`, `훅 파일`) 와 다른 명명 패턴 (구분자 `/` 포함, 영어+한국어 mix). 출력 정렬 시 한 줄로 길게 표시될 가능성. 기존 패턴 일관성 (`설치 파일` 같은 2-3 글자 한국어) 따르려면 `Ignore 위생` 또는 `ignore 설정` 등이 더 적절.

- **doctor (b) 경고의 권장 매칭 패턴 약함**: plan.md `cmd_doctor()` 신규 코드에서 `grep -qE '^\.harness-kit/' "$SDD_ROOT/.dockerignore"` — 즉 `.harness-kit/` *접두 정확 매치*. 그러나 사용자가 `.dockerignore` 에 `.harness-kit` (슬래시 없이) 또는 `**/.harness-kit/` 또는 와일드카드 패턴 (`.h*`) 으로 ignore 했을 수 있음. 정확 매치만 검사하면 false positive WARN 발생. README 가이드와 강제 결합돼 *우리 가이드대로 적었는지* 만 검사하는 형태인데, 이는 사용자 자유도를 깎음.

- **테스트 정수성 검증 누락**: `test-doctor-ignore-coverage.sh` 의 시나리오 4 (Dockerfile 있음 + `.dockerignore` 에 `.harness-kit/` 있음) 만 PASS 를 검증. 그런데 (a) 점검 — `.gitignore` 에 신규 라인 있는 경우의 PASS 도 같은 파일에서 검증한다 했는데, `.dockerignore` 시나리오 4 가 *같은 fixture 에서* `.gitignore` 도 갖춰져야 PASS 가 나옴. fixture 셋업이 두 점검을 독립적으로 다루는지 명시 없음.

- **spec self-host guard 정책의 가독성 누락**: spec.md FR2 는 "신규 항목은 항상 추가" 라고만 명시. 그러나 self-host 시 `.gitignore` 에 `# harness-kit` *헤더 자체가 없는* 상태에서 신규 라인만 추가되면, 라인이 *고아* 가 됨 (어느 도구가 추가했는지 불명). uninstall.sh 의 awk 가 헤더 시작점 (`^# harness-kit$`) 을 못 찾으면 신규 라인도 못 지움 — 결국 사용자 `.gitignore` 에 영원히 stale 잔존. 헤더 없이 라인만 추가하는 정책의 *long-term 위생* 미검토.

### 모순

- **spec §해결방안 vs plan §주요결정 표 내용 불일치**: spec.md §해결방안 §1 은 "기존 `_gi_ensure` 패턴 연장". plan.md §주요결정 표는 "self-host guard *밖* 에 위치 — 항상 실행". 두 진술이 충돌하지 않지만, "패턴 연장" 이 정확히 *어디까지 (헤더 추가 포함? self-host 분기 포함?)* 인지 모호. install.sh 의 기존 `_gi_ensure` 호출 중 일부는 self-host 분기 안 (`[ "$_hk_self_host" -eq 0 ] && _gi_ensure ...` line 520), 일부는 밖 (line 521-525). plan 은 "521-525 영역" 이라 명시했지만 spec 은 안 함 → 구현자 해석 갈림.

- **spec §정책 비대칭의 합당성 근거 vs Husky 사례**: spec.md §문제점 §(3) 은 ".gitignore 자동 갱신" 을 "install.sh 가 이미 5개 항목 관리 → 한 줄 추가로 모든 사용자에 전파" 로 정당화. 하지만 Husky PR #951 사례는 *바로 그 자동 갱신* 이 사용자 마찰을 일으킨 케이스. spec 은 "기존 패턴 연장" 만 근거로 들고, 패턴 자체의 적절성은 재검토 안 함 — 자기 정당화 (begging the question) 의 약한 사례.

### 과잉 설계 (YAGNI)

- **7 task / 4-시나리오 테스트 매트릭스 vs 실제 변경 규모**: 실제 코드 변경은 (1) install.sh 한 줄 + (2) cmd_doctor 신규 섹션 (~15줄) + (3) README 섹션. 약 30-50 라인 추가. 그런데 plan.md 는 신규 test 파일 1개 (4 시나리오 매트릭스), README 섹션, 회귀 테스트 4개 실행, 수동 검증 시나리오 3개 — 검증 코드/문서가 본 코드보다 *몇 배* 크다. spec.md §6 (회귀테스트) 의 신규 시나리오 2-3개가 적절선 — 전용 신규 파일 필요한가? `test-gitignore-config.sh` 에 시나리오 I/J 추가가 더 간단.

- **README 컨테이너 가이드 섹션의 spec 결합도 과잉**: plan.md README 변경 본문 (13줄) 은 본 spec 외에도 가치가 큰 *독립* 문서. 이를 본 spec 의 DoD 에 포함시키면 (a) README 작성 시간이 본 spec 의 critical path 가 되고, (b) 다른 컨테이너 도구 (Podman 등) 지원 시점에 *같은 섹션을 또 수정* 해야 함. 차라리 `.dockerignore` 부분만 본 spec, README 가이드는 별도 spec (또는 FF) 으로 분리.

- **`.dockerignore` 점검 자체의 ROI**: spec 의 `.dockerignore` 동기 — "WSL2 + Docker Desktop 환경 빌드 컨텍스트 비대화 + 토큰 유출 위험". 그런데 (a) WSL2 환경 사용자가 본 키트 사용자 중 비율 미상 (자기 자신 1명?), (b) `.env.telegram` 은 이미 `.gitignore` 5번째 라인으로 차단 — `.dockerignore` 없어도 `git add` 단계에서 막힘. 토큰이 이미지에 포함되려면 사용자가 `COPY .env.telegram` 명시해야 함 (의도적). 즉 본 점검은 *bundle 응집* (한 spec 에 두 ignore 다루기) 의 명분으로 끼워넣은 것에 가까움. 실제 ROI 약함.

- **spec-x 인데 ADR 후보 검토 섹션 2회 (spec/plan 양쪽)**: spec.md / plan.md 둘 다 §ADR 후보 섹션을 두고 "없음" 으로 마무리. spec-x 의 *경량성* 정신과 어긋남. spec 만 두면 충분 (또는 둘 다 생략).

### 모호함

- **"리뷰 도구 출력물" 의 *경계***: spec FR1 은 `specs/**/code-review*.md` 만 명시. 그러나 `/hk-code-review` 가 생성하는 산출물은 미래에 (a) JSON 형식 (`code-review.json`), (b) HTML 리포트 (`code-review.html`), (c) sub-디렉토리 (`code-review/raw/`) 등으로 확장될 수 있음. `*.md` 한정의 *고의성* 이 spec 에 없음 — 향후 확장 시 마다 install.sh 1줄씩 추가? 차라리 `specs/**/code-review*` 또는 `specs/**/.review-cache/` 같은 더 큰 우산이 필요한가? 결정 근거 부재.

- **"신규 항목은 항상 추가" 의 시점**: spec FR2 의 "항상 추가" 가 (a) install 시점에 self-host 분기와 무관하게 *추가만* 한다는 뜻인지, (b) self-host 시에는 헤더도 없으니 *고아 라인* 으로 추가한다는 뜻인지 모호. plan §주요결정 표는 "521-525 영역에 배치" — 즉 self-host 분기 *밖* . 그러면 self-host 케이스에서 헤더 없는 라인이 됨. spec 은 이 시나리오를 명시 안 함.

- **doctor 신규 점검 (a) 의 "갱신 안내" 메시지**: plan.md `_doc_warn` 메시지는 `"갱신: bash update.sh ."`. 그런데 일부 사용자는 update.sh 가 아니라 단순 수동 `echo 'specs/**/code-review*.md' >> .gitignore` 가 더 가볍다고 느낄 수 있음 (update 가 uninstall → install 라운드라 destructive). 권장이 *update.sh* 만 향하는 정확성 모호.

---

## 3. 대안 제안

### 대안 A: 출력 경로 격리형 — `.harness-kit/cache/reviews/`

- **아이디어**: `/hk-code-review`, `/hk-gemini-review` 출력 경로를 `specs/<spec-dir>/code-review*.md` 에서 `.harness-kit/cache/reviews/<spec-dir>/code-review*.md` 로 이동. `.harness-kit/` 는 이미 `.gitignore` 로 차단됨 (`HK_GITIGNORE=1` 기본) — 별도 처리 없이 drift 원천 차단.
- **장점**:
  - 본 spec 의 install.sh / doctor (a) / 신규 test 시나리오 *전부 불필요*. 본 spec 의 70% 가 사라짐.
  - uninstall 비대칭 / update 다중 라운드 위험 없음.
  - 사용자 루트 `.gitignore` 침입 0 — devcontainer 패턴과 정합.
  - 미래 출력 형식 (JSON / HTML / sub-dir) 도 자동 처리.
- **단점**:
  - PR 첨부 동선 손실 (spec 이 거부 이유로 든 항목). *그러나* 사용자가 PR 에 review 를 첨부하는 빈도와 cache 경로에서 첨부하는 비용을 정량 검증 안 함 — 거부의 실증 근거 부재. 슬래시 커맨드 안내 메시지에 "출력: `.harness-kit/cache/reviews/<spec-id>/code-review.md`" 한 줄 추가하면 동선 회복 가능.
  - `HK_GITIGNORE=0` (`!.harness-kit/`) 사용자에게는 안 통함 — 별도 안내 필요. 다만 그 사용자는 이미 `.harness-kit/` 자체를 commit 정책으로 두고 있으니 review 산출물도 같은 의도일 가능성 큼.
  - 기존 review 산출물 (PR/세션에서 이미 생성한 `code-review.md`) 의 이주 가이드 필요. 단 *과거* 산출물은 spec 정리 시 archive 로 가니 실제 영향은 작음.

### 대안 B: 점검 분리 — `.gitignore` 만 본 spec, `.dockerignore` 는 다음 spec

- **아이디어**: 본 spec 은 `.gitignore` 한 줄 추가 + doctor (a) + 신규 test 시나리오 2개만. `.dockerignore` 점검 / README 가이드는 별도 spec-x-dockerignore-coverage 로 분리.
- **장점**:
  - 본 spec PR 무게 절반. Critique/리뷰 부담 ↓.
  - `.dockerignore` 점검의 ROI 약함 (위 §과잉설계 (3)) 을 별도 spec 에서 충분히 critique 가능.
  - 두 spec 의 정책 비대칭 (`.gitignore` 자동 vs `.dockerignore` 경고만) 결정도 *분리된 분기* 에서 더 명확히.
- **단점**:
  - Phase 응집도 손실 ("같은 ignore 위생" 한 묶음). bundle-before-spec-x 패턴 (CLAUDE.fragment.md §검증된 패턴) 의 반대 방향.
  - spec ceremony 2회 발생 — 1-2 commit 작업에 ceremony 2번은 과잉.

### 대안 C: 자동 갱신 영역 확장 — `.dockerignore` 도 install.sh 가 갱신

- **아이디어**: spec 의 §Out of Scope 첫 번째 항목 ".dockerignore 자동 갱신" 거부 결정을 뒤집어, install.sh 가 (Dockerfile 존재 시) `.dockerignore` 도 자동으로 `.harness-kit/`, `.claude/`, `backlog/`, `specs/`, `archive/` 라인을 멱등 추가.
- **장점**:
  - 정책 일관성 — 두 ignore 파일을 같은 모델로 다룸.
  - 사용자가 doctor 경고를 보고 *수동* 수정해야 하는 마찰 제거.
  - `.gitignore` 도 이미 사용자 합의 없이 갱신하므로 (Husky 사례에도 불구) `.dockerignore` 만 다르게 다룰 명분 약함.
- **단점**:
  - **Dockerfile 구조 다양성** — `COPY . .` 사용자 / `COPY package*.json` 선택적 사용자 / 멀티스테이지 빌드 사용자마다 `.dockerignore` 의도가 다름. 자동 추가가 *오히려 빌드를 깨뜨릴* 케이스 있음 (예: spec 디렉토리 안의 `Dockerfile.spec-example` 같은 fixture). spec 의 거부 이유는 합당.
  - 산업 패턴 (Terraform, dockerignore-generate 등) 과 *역행*. 본 spec 의 §유사기법 §시사점 §`.dockerignore` 처리 = 산업 정합 평가가 무효화됨.

### 대안 D: 헤더 강제 + uninstall 알려진 패턴 확장 (보수형 보강)

- **아이디어**: 본 spec 의 install.sh 변경은 유지하되, (a) self-host 케이스에서도 *신규 라인 추가 시* `# harness-kit` 헤더가 없으면 같이 추가 (고아 라인 방지), (b) uninstall.sh awk 블록에 `inblk==1 && /^specs\/\*\*\/code-review\*\.md$/ { next }` 추가.
- **장점**:
  - 본 spec 의 직접 동기 (self-host drift 해결) 유지하면서 누락된 대칭성 확보.
  - 향후 신규 ignore 라인 추가 시에도 같은 *uninstall awk 확장* 패턴 강제 — convention 으로 자리잡음.
- **단점**:
  - install.sh self-host guard 로직 살짝 복잡해짐 (헤더 강제 추가 분기). 다만 라인 1줄 추가 수준.
  - uninstall.sh 의 알려진 패턴 enumeration 이 길어짐. 매 ignore 라인 추가마다 *3군데* (install / uninstall / test) 동시 수정 필요 — 잊기 쉬움.

---

## 권장안

**대안 D (보수형 보강) + 부분적으로 대안 A 의 long-term 방향성 ADR 화** — 즉 이번 PR 은 본 spec 의 기본 형태를 유지하되 누락 대칭성을 보강하고, "리뷰 산출물의 in-tree 위치 vs out-of-tree 격리" 라는 더 큰 결정은 ADR 후보로 분리.

근거 3가지.
1. 본 spec 의 직접 동기 (self-host 의 untracked drift) 는 *지금* 해결돼야 하며 (사용자 작업 마찰), 대안 A (경로 이주) 는 슬래시 커맨드 수정 + 기존 산출물 이주 가이드까지 포함하면 spec-x 가 아닌 정식 spec 으로 무게가 커진다.
2. spec.md / plan.md 가 *uninstall 대칭성* 과 *update 다중 라운드 안정성* 을 놓친 것은 critical 누락 — 본 critique 의 가장 큰 발견. 대안 D 가 이를 가장 작은 추가 노력으로 닫음.
3. 대안 A 의 *근본 해결* 가치는 무시 못 함 — `.gitignore` 라인을 매 신규 산출물마다 추가하는 모델은 *언젠가 깨진다* (Husky PR #951 의 교훈). 본 spec 머지 후 별도 spec-x 또는 정식 spec 으로 "리뷰 산출물 격리" 검토를 *큐에 박아둘* 가치.

부차 권장: README 컨테이너 가이드 섹션은 별도 spec 분리 (대안 B 의 부분 채택) — 본 spec 의 critical path 에서 빼면 PR 머지 속도 ↑.

---

## 4. ADR 후보 추출

- [x] **후보 발견**: `tool-output-in-tree-vs-out-of-tree` — type: `tradeoff` — 이유: harness-kit 의 거의 모든 도구 출력 (specs/<spec-dir>/walkthrough.md, code-review.md, critique.md, pr_description.md) 이 *사용자 작업 디렉토리* 에 떨어진다. 이 중 walkthrough/pr_description 은 commit 대상이지만 review/critique 는 ephemeral. 어떤 산출물을 어디에 두고 git 위생을 어떻게 관리할지가 본 spec 1회로 끝나지 않을 *반복되는 결정* — convention 또는 tradeoff 로 박아 향후 신규 산출물 (`code-review-claude.md`, `code-review-codex.md` 등) 추가 시 한 페이지 참조로 결정 가능. 6 개월+ 유지 확실.

- [x] **후보 발견 (낮은 우선순위)**: `kit-managed-ignore-line-symmetry-invariant` — type: `invariant` — 이유: install.sh 가 추가하는 모든 `.gitignore` 라인은 uninstall.sh awk 블록에도 *반드시* 명시 매칭으로 등재돼야 한다 (헤더 직후 연속성 보장). 본 spec 이 이 invariant 를 위반할 뻔한 사례 자체가 invariant 명시 가치 증명. 짧지만 cross-spec 영향 큼.

- [ ] **후보 없음**: 본 spec 자체의 정책 비대칭 (`.gitignore` 자동 / `.dockerignore` 경고만) 은 ADR 가치 없음 — 산업 패턴 (Terraform / dockerignore-generate) 의 기성 정합 + 본 spec 만의 결정이 아님. spec/walkthrough 에 1단락 기록 충분.
