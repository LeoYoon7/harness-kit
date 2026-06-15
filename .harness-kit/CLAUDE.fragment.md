## 에이전트 운영 규약 (harness-kit)

이 프로젝트는 harness-kit 의 거버넌스를 따릅니다.
SDD 작업 시작 시 `/hk-align` 슬래시 커맨드를 호출하면 전체 거버넌스가 로드됩니다.

**핵심 규칙 요약**:
- Plan Accept 전에는 PLANNING 모드 (코드 편집 금지)
- One Task = One Commit
- Phase ID: `phase-{N}` (예: `phase-01`) — 디렉토리는 `backlog/phase-{N}/`
- Spec ID:  `spec-{phaseN}-{seq}` (예: `spec-01-01`) — 디렉토리는 `specs/spec-{phaseN}-{seq}-{slug}/`
- Branch: `spec-{phaseN}-{seq}-{slug}` (브랜치 = spec 디렉토리 이름, `feature/` prefix 없음)
- Commit subject: `<type>(spec-{phaseN}-{seq}): <설명>` (모두 소문자)
- 모든 산출물은 한국어
- main 브랜치 직접 작업 금지
- **선택지 제시 시 반드시 권장안 포함** (agent.md §8.5)

상세 규약은 `/hk-align` 시 tier-2 로 로딩됩니다 — 거버넌스는 `agent/constitution.md`·`agent/agent.md`, 선택지 제시·알림 프로토콜은 `agent/notify.md`, 검증된 패턴/안티패턴은 `agent/align.md` 참조.
