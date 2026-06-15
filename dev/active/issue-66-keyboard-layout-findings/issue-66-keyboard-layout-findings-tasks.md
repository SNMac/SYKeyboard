# Issue 66 Keyboard Layout Findings Tasks

Last Updated: 2026-06-15

## Checklist

- [x] GitHub Issue #66 본문과 댓글을 확인한다.
- [x] Track 3 두 finding을 현재 코드와 호출 경로에 대조한다.
- [x] 각 finding의 타당성과 원 제안의 보완점을 기록한다.
- [x] 구현 범위, 위험, 자동/수동 검증 계획을 작성한다.
- [x] P2 폭 동작의 focused test 또는 순수 폭 계산 정책 테스트를 먼저 추가한다.
- [x] P2 설정값을 최소 폭으로 적용하는 최종 계약을 확정한다.
- [x] P2 preview 폭을 최소 폭 제약 상수에 직접 반영한다.
- [x] P2 가로 한 손 모드에서도 최소 폭을 적용한다.
- [x] PR #74 리뷰의 제약 활성화 및 반복 fitting 지적을 현재 레이아웃 구조와 대조한다.
- [x] 제약 활성화 변경을 한 손 모드 갱신 경로로 분리한다.
- [x] 불필요해진 Chevron 최소 폭 캐시와 clamp 정책 테스트를 제거한다.
- [x] Chevron hidden 상태와 폭 제약 갱신을 `KeyboardView`로 통합한다.
- [x] 한 손 모드 전환 중 필수 제약 충돌 원인을 확인한다.
- [x] `999` 우선순위 수정의 전체 UI 압축 회귀를 확인하고 폐기한다.
- [x] 실패한 고정 폭 및 Chevron 폭 0 축소 방식을 제거한다.
- [x] 실제 extension에서 `isHidden` 기반 전환의 제약 경고가 계속 발생하는지 확인한다.
- [x] 기준 커밋과 현재 제약을 비교해 `>=`와 `==` 계약 차이를 확인한다.
- [x] Chevron 표시를 기존 `isHidden` 방식으로 복원한다.
- [x] 최소 폭 제약을 항상 활성화한다.
- [x] P3 기본 리턴 이미지의 rendering mode와 상태별 tint 테스트를 먼저 추가한다.
- [x] P3 비활성/활성/강조 상태에서 라벨과 이미지 tint를 함께 갱신한다.
- [x] 전체 `SYKeyboard` 테스트를 실행한다.
- [x] `HangeulKeyboard`와 `EnglishKeyboard` scheme을 빌드한다.
- [ ] 한글/영문 preview 및 실제 extension에서 수동 검증한다.
- [x] `dev/active/code-review-scope/code-review-scope-findings.md`에 처리 상태와 검증 결과를 반영한다.
- [x] `git status --short`로 의도하지 않은 변경이 없는지 확인한다.
