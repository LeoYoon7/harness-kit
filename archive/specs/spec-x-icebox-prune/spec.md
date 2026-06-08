# spec-x-icebox-prune: Icebox 해소 항목 5개 정리

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-icebox-prune` |
| **Phase** | 없음 (spec-x) |
| **Branch** | `spec-x-icebox-prune` |
| **상태** | Planning |
| **타입** | Chore (docs) |
| **Integration Test Required** | no |
| **작성일** | 2026-06-04 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황
`backlog/queue.md` 의 🧊 Icebox 섹션은 아이디어·보류 항목 보관소다. 그런데 일부 항목은 이미 완료된 spec 으로 해소되었는데도 Icebox 에 그대로 남아 있다. `완료` 섹션에 동일 slug 의 spec 이 존재해 대응 관계가 명확히 확인된다.

### 문제점
죽은(해소된) 항목이 Icebox 에 섞여 있으면 다음 문제가 생긴다.
- Icebox 검토 시 어떤 항목이 실제 미해결인지 신뢰도가 떨어진다.
- promote 후보 판단이 흐려진다 (해소된 항목을 다시 spec 화할 위험).
- 대시보드인 queue.md 가 비대해져 가독성이 떨어진다.

### 해결 방안 (요약)
`완료` 섹션의 spec 으로 해소됨이 확인된 Icebox 항목 5줄을 제거한다. 코드 변경 없는 순수 doc 정리이며, 각 제거 항목은 대응 완료 spec slug 로 근거가 추적된다.

## 🎯 요구사항

### Functional Requirements
1. 아래 5개 Icebox 항목을 `backlog/queue.md` 에서 제거한다.

   | 제거 대상 Icebox 항목 (요지) | 해소한 완료 spec |
   |---|---|
   | Telegram 응답 시 ack 중복 발송 | `spec-x-notify-drop-both` |
   | §5 stop ↔ AskUserQuestion 옵션 번호 불일치 | `spec-x-notify-auq-scope-fix` (+ AUQ 미사용 정책) |
   | Discord 마크다운 포맷팅 (notify.sh 채널별 분기) | `spec-x-notify-channel-formatter` |
   | `update.sh` semver_lt leo suffix 버그 | `spec-x-update-semver-suffix-fix` |
   | CC 네이티브 기능 도입 2단계 정책 spec | `spec-x-native-feature-adoption-policy` |

2. 제거는 해당 5줄만 대상으로 한다. 그 외 Icebox 항목 / 대기 Phase / 자동 마커 영역은 일절 건드리지 않는다.

### Non-Functional Requirements
1. `queue.md` 의 sdd 자동 갱신 마커 (`<!-- sdd:active -->`, `<!-- sdd:specx -->`, `<!-- sdd:done -->`) 영역은 보존한다.
2. 정리 후 `sdd status` 가 정상 동작해야 한다 (파일 파싱 무손상).

## 🚫 Out of Scope

- 아직 미해결인 다른 Icebox 항목 (uninstall FAIL, check-secrets 오탐, stale ADR 오탐, 거버넌스 단어수, 컨테이너/wiki/알림 테마 등) 은 건드리지 않는다 — 별도 promote 결정 사안.
- `대기 Phase` 섹션 (phase-21 director mode 후보) 은 손대지 않는다.
- 실제 코드/스크립트 동작 변경 없음.

## 📑 ADR 후보 (Architecture Decision Records)

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — 단순 대시보드 정리, 장기 자산 결정 없음.

## ✅ Definition of Done

- [ ] 5개 항목이 `backlog/queue.md` 에서 제거됨 (grep 으로 부재 확인)
- [ ] 미해결 항목 및 자동 마커 영역 무변경 (git diff 검토)
- [ ] `sdd status` 정상 동작 확인
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-icebox-prune` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
