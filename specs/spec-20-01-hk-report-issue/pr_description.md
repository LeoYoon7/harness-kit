# feat(spec-20-01): `/hk-report-issue` 커맨드 포팅 (upstream parity)

## 📋 Summary

### 배경 및 목적
fork 는 upstream(#98912f0)이 추가한 **`/hk-report-issue`** — 키트 자체 버그를 kit GitHub repo 에 이슈로 환류하는 커맨드 — 를 보유하지 않았다. 다운스트림/도그푸딩 사용자가 키트 결함(예: 본 세션의 hook no-op)을 발견해도 구조화된 환류 경로가 없었다. 이를 fork 로 충실 포팅한다.

### 주요 변경 사항
- [x] `sources/commands/hk-report-issue.md` + `.claude/commands/hk-report-issue.md` 설치 (upstream verbatim, byte-identical)
- [x] `README.md` 커맨드 목록 + `installed.json` installedCommands 등록
- [x] 구조 검증 단위 테스트 추가 (`tests/test-report-issue-cmd.sh`)

### Phase 컨텍스트
- **Phase**: `phase-20` (upstream-parity) — **첫 spec, quick win**
- **역할**: 낮은 위험의 포팅으로 흐름 검증. 후속 director mode(재구현)의 발판.

## 🎯 Key Review Points

1. **충실 포팅**: 커맨드 본문은 upstream 원본 verbatim (`git show upstream/main:...` diff 0). 자의적 변형 없음 → 향후 sync 용이.
2. **분기 거버넌스 비의존**: 커맨드가 `kitOrigin`/gh/doctor/§5.7 만 참조 → fork 무수정 동작.
3. **git-bash argv 비처리** (의도): 키트 1차 타깃 macOS 기준 + 기존 fork 커맨드 공통 quirk.

## 🧪 Verification

```bash
bash tests/test-report-issue-cmd.sh   # ✅ ALL PASS (TDD Red→Green)
```
- ✅ sources↔installed byte-identical + upstream diff 0
- ✅ 핵심 섹션(판정 게이트 / gh issue create / 시크릿 / [Y/n]) + 등록 확인
- ✅ 설치 후 Claude Code 가 `hk-report-issue` 스킬 인식

## 📦 Files Changed

### 🆕 New Files
- `sources/commands/hk-report-issue.md`, `.claude/commands/hk-report-issue.md`: 포팅된 커맨드
- `tests/test-report-issue-cmd.sh`: 구조 검증 테스트

### 🛠 Modified Files
- `README.md` (+1): 커맨드 목록
- `.harness-kit/installed.json` (+1): installedCommands

## ✅ Definition of Done

- [x] 구조 검증 단위 테스트 PASS
- [x] sources↔installed byte-identical + upstream diff 0
- [x] README / installed.json 등록
- [x] walkthrough.md / pr_description.md ship
- [x] 코드 리뷰 게이트 (`small-port` skip, walkthrough 기록)

## 🔗 관련 자료

- Phase: `backlog/phase-20.md`
- upstream 출처: `98912f0`, `sources/commands/hk-report-issue.md`
- Walkthrough: `specs/spec-20-01-hk-report-issue/walkthrough.md`
