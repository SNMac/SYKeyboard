# Issue 65 Common Keyboard Interaction Runtime Tasks

Last Updated: 2026-06-14

## Investigation And Scope

- [x] GitHub issue #65 본문과 댓글을 확인한다.
- [x] Track 2 findings 원본과 관련 controller/button/input action 코드를 대조한다.
- [x] 세 finding이 현재 코드에서 성립하는지 평가한다.
- [x] 전환 제스처의 initial/continuation long press를 포함한 수정 범위를 확정한다.
- [x] 구현 시작 전 `git status --short`로 작업 범위를 다시 확인한다.

## Tests First

- [x] UIKit recognizer terminal 상태를 안정적으로 구동할 test double 또는 최소 internal helper 전략을 확정한다.
- [x] `ButtonStateControllerTests`에 일반 버튼 `.touchCancel` 후 눌림/suggestion bar 복구와 다음 버튼 입력 횟수 검증을 추가한다.
- [x] `ButtonStateControllerTests`에 Shift `.touchCancel` 후 `isShiftButtonPressed == false` 검증을 추가한다.
- [x] 활성 제스처 중 일반 버튼/Shift `.touchCancel`이 제스처와 눌림 상태를 유지하는 회귀 테스트를 추가한다.
- [x] 새 활성 제스처 `.touchCancel` 테스트가 첫 구현에서 실패하는지 확인한다.
- [x] `TextInteractionGestureControllerTests`에 짧은 pan의 `.ended`만 입력하고 `.cancelled`/`.failed`는 입력하지 않는 검증을 추가한다.
- [x] `TextInteractionGestureControllerTests`에 취소/실패 후 눌린 버튼, 사용자 상호작용, delete stop callback 정리 검증을 추가한다.
- [x] `SwitchGestureControllerTests`에 keyboard select pan의 정상 종료/취소/실패별 delegate 횟수와 overlay 정리 검증을 추가한다.
- [x] `SwitchGestureControllerTests`에 one-handed mode pan의 정상 종료/취소/실패별 delegate 횟수와 overlay 정리 검증을 추가한다.
- [x] `SwitchGestureControllerTests`에 initial 및 continuation long press 취소 시 mode 변경 없이 overlay/상호작용이 복구되는 검증을 추가한다.
- [x] 새 테스트가 현재 production 코드에서 의도대로 실패하는지 확인한다.

## Implementation

- [x] `TextInteractionGestureController`에서 `.ended`와 `.cancelled`/`.failed` 결과 확정 경로를 분리한다.
- [x] 텍스트 pan 취소/실패 시 stale pressed state와 gesture/UI 상태를 정리하고 필요한 stop callback을 유지한다.
- [x] `ButtonStateController`의 일반 버튼과 Shift 해제 이벤트에 `.touchCancel`을 추가한다.
- [x] 활성 제스처 중 UIKit이 발생시킨 `.touchCancel`은 해제하지 않도록 일반 취소와 분리한다.
- [x] `SwitchGestureController`의 두 pan handler에서 정상 종료만 `.touchUpInside`와 delegate 결과를 확정하도록 분리한다.
- [x] `SwitchGestureController`의 initial/continuation long press에서 취소/실패가 delegate 결과를 확정하지 않도록 분리한다.
- [x] 전환 제스처 취소 cleanup에서 overlay, 강조, 눌림, 상호작용, 내부 gesture 상태를 복구한다.

## Verification And Documentation

- [x] Track 2 집중 interaction 테스트를 실행한다.
- [x] 전체 `SYKeyboard` 테스트를 실행한다.
- [x] `HangeulKeyboard` scheme 빌드를 실행한다.
- [x] `EnglishKeyboard` scheme 빌드를 실행한다.
- [x] 조건부 `.touchCancel` 수정 후 집중 interaction 테스트를 다시 실행한다.
- [ ] 조건부 `.touchCancel` 수정 후 전체 테스트와 한글/영문 extension 빌드를 다시 실행한다.
- [x] 실기기에서 길게 누르기 반복 입력과 버튼 영역 밖 커서 드래그를 재확인한다.
- [ ] 실제 입력 앱에서 취소/정상 종료 흐름을 수동 확인한다.
- [x] `dev/active/code-review-scope/code-review-scope-findings.md`에 세 finding의 처리와 검증 결과를 반영한다.
- [x] `git diff --check`와 `git status --short`로 문서/코드 변경 범위를 확인한다.
