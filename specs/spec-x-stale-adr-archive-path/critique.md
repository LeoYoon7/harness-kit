<!-- spec-x-stale-adr-archive-path 의 독립 critique 결과 -->
# Spec Critique: spec-x-stale-adr-archive-path

> 검토 범위: spec.md / plan.md / `_drift_stale_adr()` (line 375~430) / `cmd_archive()` 이동 로직 / `specs/CLAUDE.md` archive-skip 관례 / queue.md Icebox(line 43). fix 가 실제 문제를 해결하는지 코드 레벨로 검증함.

## 1. 유사 기법 조사

### 발견된 패턴/도구
- **lychee / markdown-link-check / md-dead-link-check (CI 링크 체커)**: repo 내 마크다운의 파일 링크·앵커 broken 여부를 검사하고 PR 머지를 차단하는 도구군. — 현재 spec과의 비교: 본 fix 와 *동일 문제(이동된 참조의 broken 탐지)* 를 풀지만, 이들은 "broken 이면 무조건 FAIL" 정책이다. 본 fix 는 반대로 *이동분을 broken 에서 면제* 한다. 즉 일반 도구는 "이동도 broken 으로 간주 → 고쳐라" 인데, 본 프로젝트는 archive 이동이 *루틴* 이라 그 정책이 비대칭 비용을 낳아 면제 쪽을 택한 것. 정책 선택 자체가 본 프로젝트 고유 맥락의 산물임이 확인됨.
- **Redirect map (301/302) — 콘텐츠 이전 시 구주소→신주소 매핑**: 웹에서 파일/URL 이동 시 표준 해법. 단일 prefix 치환이 아니라 *명시적 매핑 테이블* 로 관리. — 현재 spec과의 비교: 본 fix 의 `archive/$token` 은 "암묵적 redirect rule(`X` → `archive/X`)" 한 줄에 해당. 매핑이 단순 prefix 규칙으로 충분한 경우에만 성립하므로, archive 레이아웃이 prefix-보존이라는 *불변식* 에 의존한다(아래 §2 누락 참조).
- **Wayback Machine fallback (broken-link-checker 의 archived 위치 조회)**: 일부 링크 체커는 원본이 404 일 때 *아카이브된 사본* 을 조회해 "사라진 게 아니라 보존됨" 으로 처리. — 현재 spec과의 비교: 본 fix 와 *개념적으로 정확히 동일*. "live 위치에 없으면 archive 위치를 fallback 조회 → 존재로 간주". 본 접근법이 업계 패턴과 정합함을 보여주는 가장 강한 근거.
- **Content-addressed reference / GitHub permalink (commit hash 핀)**: 이동·rename 에 영향받지 않는 *불변 식별자* 로 참조를 고정(예: `y` 키 permalink, blob SHA). — 현재 spec과의 비교: 이것이 바로 queue 제안 (b)(ADR 가 spec 참조 시 PR 링크/commit hash 권장)의 정체. (b) 는 *문제를 원천 제거* 하나 convention 변경 + 기존 ADR 소급 비용이 큼. (a) 는 *증상 완화* 이나 즉효·저비용. 업계에서도 둘은 보완재(체커 + permalink 병행).

### 시사점
본 fix 의 archive-fallback 은 "Wayback fallback" 패턴의 로컬 축소판으로, 방향성은 업계 표준과 정합한다. 다만 업계 redirect 패턴이 *명시적 매핑* 을 쓰는 데 반해 본 fix 는 *암묵적 prefix rule* 에 의존하므로, 그 prefix 규칙이 깨지는 케이스(설정 가능한 `specsDir`, 중첩 archive)에서 silent 하게 어긋날 수 있다는 점이 핵심 리스크다. 또한 (a)/(b) 가 보완재라는 업계 관찰은 (b) 를 영구 폐기하지 말고 Icebox 에 남기는 현재 OOS 판단을 지지한다.

## 2. 요구사항 비판

### 누락
- **`specsDir`/`backlogDir` 설정 override 와 archive 레이아웃의 어긋남**: `lib/common.sh:50~57` 이 `harness.config.json` 의 `specsDir`/`backlogDir` 로 경로를 override 한다. 예를 들어 `specsDir: "work/specs"` 이면 ADR 토큰은 `work/specs/spec-x-foo/spec.md` 인데, `cmd_archive` 는 `git mv "$SDD_SPECS/.." archive/specs/` 로 *basename 만* 옮겨 `archive/specs/spec-x-foo/` 에 둔다(line 2262/2268). 결과적으로 토큰 prefix(`work/specs/`)와 실제 archive 위치(`archive/specs/`)가 갈려 `archive/$token`(=`archive/work/specs/...`)이 *매치 실패* → 오탐 잔존. 본 프로젝트는 기본 `specs/` 라 도그푸딩엔 무해하나, spec.md "Out of Scope" 나 NF 에 "기본 `specsDir`/`backlogDir` 전제(설정 override 시 미보장)" 를 한 줄 명시해야 함. fix 의 적용 전제(prefix-보존 불변식)가 문서화되지 않음.
- **archive 가 `specs/`·`backlog/` 두 종류만 prefix-보존한다는 사실의 미검증 명시**: 코드 검증 결과 `cmd_archive` 가 옮기는 대상은 spec 디렉토리(→`archive/specs/`)와 backlog 파일(→`archive/backlog/`) 뿐이다. 토큰이 `specs/...` 또는 `backlog/...` 일 때만 `archive/$token` 이 성립하고, `docs/...` 참조는 archive 되지 않으므로 fallback 이 동작하지 않는다(정상 — docs 는 안 옮기니까). spec.md 는 "specs/X → archive/specs/X" 만 예로 들어 *backlog 참조도 동일하게 커버됨* 을 명시하지 않았다(실제로는 커버됨, 우연히 prefix 가 보존되므로). 테스트 Step 5 가 spec 참조만 검증하면 backlog 참조 케이스는 미검증 회귀 사각지대가 됨.
- **중첩/재-archive 케이스**: spec.md 검토 관점이 물은 "archive 안에서 또 옮겨진 경우". `cmd_archive` 는 `specs/`/`backlog/` 에서만 수집하므로 archive 내부를 다시 옮기지 않는다 → 중첩 archive 는 발생 불가. 따라서 *실제로는 누락이 아님*. 다만 spec.md 가 이를 "발생 불가" 라고 한 줄 못박으면 향후 독자의 의문을 차단함(현재는 침묵).
- **`-e` 의 symlink/디렉토리 의미 일관성**: 기존 root 검사가 `[ -e ]`(존재) 이고 fallback 도 `[ -e ]` 라 일관됨 — 누락 아님(확인용 기록).

### 모순
- **`specs/CLAUDE.md` archive-skip 관례와의 충돌 — spec.md 의 "별개 관심사" 논증은 타당함**: 관례(line 10)는 "*외부 참조 검색* 시 archive 를 건너뛰는 것이 기본 — archived 파일을 권위 source 로 *스캔* 하면 false-positive" 를 막는다. 본 fix 는 archived 파일을 스캔하지 않는다 — 루프는 여전히 `docs/decisions/ADR-*.md`(live) 만 순회(line 383)하고, archive 는 *단일 target 의 존재 여부 확인* 에만 쓴다. "스캔(읽어서 그 안 참조를 따라감)" 과 "존재 확인(`-e` 한 번)" 은 다른 연산이므로 진짜 충돌 아님. spec.md §"관례 충돌 해소" 의 구분이 정확하다. **단, 권고**: 그 관례가 *과거 본 함수의 오탐 원인 자체* 였을 가능성(관례가 "archive 건너뛰라" 였기에 원저자가 root 만 봤을 수 있음)을 한 줄 짚으면, 두 문서가 같은 곳을 가리키게 되어 미래 혼선이 준다.

### 과잉/과소 설계
- **fix (a) 가 "진짜 stale(archived ADR 참조)" 까지 가리는 위험 — 수용 가능하나 비대칭이 한 방향뿐임을 명시 필요**: plan.md WARNING 이 이미 "이동≠삭제, archive 존재를 stale 제외" 를 의도된 동작으로 선언한 점은 적절. 다만 *부작용의 정확한 범위* 가 과소 기술됨. archive 로 이동한 파일은 *그 뒤 archive 안에서 삭제되어도* fallback 이 못 잡는 게 아니라(삭제되면 `archive/$token` 도 부재 → 정상 탐지됨), 진짜 위험은 "archive 가 immutable 보존소라 거기 있는 한 *영원히* 존재로 간주" 라는 점. 즉 archived target 을 가리키는 ADR 은 *링크 무결성 관점에서 사실상 검사 면제* 된다. 이는 archive 가 immutable 이라는 전제 하에 수용 가능(보존소에서 사라질 일이 없음). 수용 가능하나, spec.md 에 "archived target 참조 ADR 은 stale 검사에서 영구 면제됨(immutable 전제)" 을 *명시적 trade-off* 로 적는 게 정직함.
- **(a) 만 하고 (b) 는 OOS — 적절함**: (b)(영구 식별자 권장)는 convention 변경 + 기존 ADR 소급이라 범위가 크고, (a) 가 즉효·1줄·가역. 둘은 보완재(§1 시사점)이므로 (b) 를 Icebox 로 남긴 분리는 옳다. 과잉설계 아님.

### 모호함
- **"archive 로 이동된 참조도 존재로 간주" 의 경계**: 주석(plan.md line 46)이 "specs/X → archive/specs/X 상대구조 보존" 이라 했으나, 실제 `cmd_archive` 는 *상대구조 보존이 아니라 basename 이동*(`git mv $d archive/specs/`)이다. `specs/` 기본값에선 결과가 같아 보이지만(`specs/X`→`archive/specs/X`), 정확한 표현은 "specs/ 와 backlog/ 라는 *최상위 1단계 prefix* 가 archive/ 하위 동명 디렉토리로 보존됨" 이다. 주석을 "상대구조 보존" 으로 쓰면 `specsDir` override 시 깨지는 가정을 가린다. 구현/주석 표현을 "specs|backlog 1단계 prefix 보존(기본 경로 전제)" 으로 정밀화 권장.

## 3. 대안 제안

### 대안 A: 현재 spec 유지 — `archive/$token` prefix fallback 1줄 (+전제 명시)
- **아이디어**: spec.md/plan.md 그대로. 단 §2 누락의 "기본 `specsDir`/`backlogDir` 전제" 한 줄과 backlog 참조 테스트 케이스를 보강.
- **장점**: 1줄·가역·bash 3.2 OK·기존 필터 무수정. 도그푸딩(기본 경로)에서 100% 정확. 업계 Wayback-fallback 패턴과 정합. 성능 영향 0(파일 1회 stat 추가).
- **단점**: `specsDir` override·prefix 규칙 외 케이스에서 silent 오탐 잔존. 토큰이 `specs/`·`backlog/` 외(예: 가상의 `docs/` 이동)면 무력 — 단 그런 이동은 현재 없음.

### 대안 B: basename find 매칭 — `find archive/ -path '*/$(basename token 상위)'`
- **아이디어**: prefix 치환 대신 archive 트리 전체에서 토큰의 *말단 경로(예: `spec-x-foo/spec.md`)* 를 `find archive/ -path "*/spec-x-foo/spec.md"` 로 탐색.
- **장점**: `specsDir` override·prefix 변형·중첩에 견고. archive 레이아웃 변화에 둔감.
- **단점**: (1) 성능 — ADR 토큰마다 `find` 전체 트리 스캔(N개 ADR × M개 토큰). drift 는 매 `sdd status` 호출되므로 누적 비용. (2) *오탐 반대 방향 위험* — basename 만 매칭하면 동명 파일(다른 spec 의 `spec.md`)이 우연히 매치돼 *진짜 stale 을 놓침*. (3) 1줄→루프+find 로 surgical 성 상실, bash 3.2 견고성 검증 부담↑. → 본 프로젝트(기본 경로 고정 도그푸딩, "No Over-engineering" 원칙)에 과함.

### 대안 C: (b) 선택 — ADR 참조를 PR 링크/commit hash 로 (content-addressed)
- **아이디어**: ADR 템플릿이 spec 참조 시 경로 대신 PR#/commit SHA 권장. 경로 토큰 자체를 줄여 stale 검사 표면을 축소.
- **장점**: 이동·rename·archive 전부에 면역(근본책). 업계 permalink 패턴과 정합.
- **단점**: convention 변경 + 기존 ADR 소급 비용. 즉효성 없음. 경로 가독성 손실(SHA 는 사람이 못 읽음). 본 사건의 *즉시 통증* 을 못 줄임. → 단독으론 부적합, (a) 의 *보완재* 로 Icebox 유지가 옳음.

## 권장안
**현재 spec(대안 A) 유지 + 2가지 경미 보강 권장.** 근거: fix 방향이 업계 Wayback-fallback 패턴과 정합하고, 코드 검증 결과 기본 경로(`specs/`·`backlog/`)에서 `archive/$token` 매칭이 정확히 성립함을 확인했다(`cmd_archive` 가 두 prefix 를 archive/ 하위 동명 디렉토리로 보존). 1줄·가역·bash 3.2 호환으로 "No Over-engineering" 원칙에 부합. 대안 B(find)는 성능·동명 오탐 역위험·surgical 성 상실로 과하고, 대안 C(b)는 보완재로 Icebox 가 맞다. **보강 2건**: (1) spec.md 에 "기본 `specsDir`/`backlogDir` 전제 — 설정 override 시 미보장" 1줄(전제 정직화). (2) 테스트에 *backlog 참조 archive* 케이스를 Step 5 에 추가하거나 Step 6 로 분리(spec 참조만으론 prefix 일반성 미검증). 둘 다 1줄 수준이라 surgical 성 유지.

## 4. ADR 후보 추출
- [x] **후보 없음**: plan.md 의 "ADR 없음 — 작은 robustness fix" 판단에 동의한다. "archive 를 stale 검사에서 존재로 간주한다" 는 invariant 후보로 보이나, 실제로는 *기존 불변식("archive 는 immutable 보존소" — `specs/CLAUDE.md` line 10 + `cmd_archive` prefix-보존 동작)의 적용* 이지 새 장기 결정이 아니다. 새 어휘(decision/invariant/convention/tradeoff)에 해당하는 결정은 없음 — spec.md §"관례 충돌 해소" 의 인라인 기록으로 충분. 다만 **만약** §2/§권장안의 "archived target 참조 ADR 은 stale 검사 영구 면제(immutable 전제)" 와 "stale 검사는 specs|backlog prefix-보존에 의존" 을 *불변식으로 격상* 하고 싶다면 그때 `stale-check-archive-as-present`(type: **invariant**) 후보가 성립하나, 현 1줄 fix 규모엔 과함 — Icebox 의 (b) 후속 spec 트리거 시 함께 재평가 권장.
