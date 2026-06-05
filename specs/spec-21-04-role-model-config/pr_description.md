# PR Description - spec-21-04: 역할 기반 모델 config (de-hardcode)

## 🎯 목적
거버넌스 문서(`agent.md`)에서 특정 모델 이름(Opus/Sonnet)에 대한 의존성을 제거하고, 이를 설정 기반의 역할(Role) 추상화로 전환하여 모델 세대 교체에 유연하게 대응할 수 있도록 합니다.

## 🔍 변경 내용
- **`installed.json` 모델 설정 도입**: `director`, `worker`, `scout` 3가지 역할에 대한 모델 매핑을 관리합니다.
- **`sdd config models` 명령 추가**: 역할별 모델 매핑을 조회하거나 변경할 수 있는 인터페이스를 제공합니다.
- **거버넌스 문서 (§6.6) 개편**: 모델 이름을 역할 참조(`models.director` 등)로 대체하고, 표 구성을 역할 중심으로 단순화했습니다.
- **TDD 검증**: 신규 기능 및 문서 정합성을 보장하는 유닛 테스트를 추가했습니다.

## 🧪 테스트 결과
- `tests/test-role-model-config.sh`: 7/7 PASS
- 기존 핵심 기능(director-mode, director-protocol) 무회귀 확인.

## 🔗 관련 문서
- Spec: `specs/spec-21-04-role-model-config/spec.md`
- Walkthrough: `specs/spec-21-04-role-model-config/walkthrough.md`
- 근거 ADR: ADR-011 (director-mode)
