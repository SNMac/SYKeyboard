# Issue 65 Common Keyboard Interaction Runtime Context

Last Updated: 2026-06-14

## Relevant Files

- `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/TextInteractionGestureController.swift`: 텍스트 버튼 pan/long press의 상태 전이와 입력 확정을 담당한다.
- `Modules/SYKeyboardCore/Presentation/Utils/ButtonStateController.swift`: 현재 눌린 버튼, Shift 눌림 상태, suggestion bar 상호작용을 관리한다.
- `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/SwitchGestureController.swift`: 키보드 선택과 한 손 모드 pan/long press 및 overlay 상태를 관리한다.
- `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/Bases/BaseKeyboardButton.swift`: 코드 기반 `sendActions(for:)` 호출 중 `isProgrammaticCall`을 활성화한다.
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`: `isProgrammaticCall`이면 현재 눌린 버튼 검증 없이 텍스트 입력을 수행한다.
- `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/Protocols/SwitchGestureHandling.swift`: 키보드 선택 및 한 손 모드 overlay 표시/숨김 계약을 정의한다.
- `SYKeyboardTests/Utils/KeyboardGesturePolicyTests.swift`: 현재 gesture 관련 테스트 패턴을 보여 주지만 취소 interaction은 검증하지 않는다.
- `dev/active/code-review-scope/code-review-scope-findings.md`: issue #65가 처리할 Track 2 findings 원본이다.

## Facts Checked

- GitHub issue #65의 본문과 Track 2 findings 문서에는 동일한 세 finding이 기록되어 있고 댓글은 없다.
- 작업 시작 시 `git status --short` 출력은 비어 있었다.
- `TextInteractionGestureController.panGestureHandler(_:)`는 `.ended`, `.cancelled`, `.failed`를 같은 분기에서 처리한다.
- 짧은 텍스트 팬의 terminal 분기는 cursor가 활성화되지 않았으면 `gestureButton?.sendActions(for: .touchUpInside)`를 호출한다.
- `BaseKeyboardButton.sendActions(for:)`는 호출 중 `isProgrammaticCall = true`로 설정한다.
- `BaseKeyboardViewController.makeTextInputAction()`은 `isProgrammaticCall == true`이면 `currentPressedButton` 일치 확인 없이 입력을 수행한다.
- `ButtonStateController.setExclusiveActionToButtons(_:)`는 해제 action을 `.touchUpInside`, `.touchUpOutside`에만 등록한다.
- 첫 수정에서 `.touchCancel`을 기존 release action에 함께 등록하면, recognizer가 시작될 때 UIKit이 전달하는 `.touchCancel`도 현재 버튼을 해제한다.
- `currentPressedButton`의 `didSet`은 이전 버튼의 모든 recognizer 상태를 `.cancelled`로 변경한다.
- 실기기에서 첫 수정 후 길게 누르기 반복 입력은 글자 하나와 햅틱 한 번 뒤 종료됐고, 커서 드래그는 손가락이 버튼 영역을 벗어나는 순간 종료됐다.
- 활성 제스처 중 `.touchCancel`을 무시하면 terminal gesture handler가 기존처럼 버튼, recognizer, 사용자 상호작용 상태를 정리한다.
- 다음 버튼의 `.touchDown`은 이전 `currentPressedButton`이 남아 있으면 이전 버튼에 `.touchUpInside`를 전송한다.
- 일반 버튼의 `currentPressedButton = nil`은 이전 버튼의 눌림 표시를 해제하고 suggestion bar 상호작용을 다시 활성화한다.
- `SwitchGestureController`의 키보드 선택 pan, 한 손 모드 pan, 한 손 모드 long press, keyboard stack continuation long press는 terminal 상태에서 취소/실패와 정상 종료를 같은 완료 경로로 처리한다.
- `endKeyboardSelect(...)`, `endOneHandedModeSelect(...)`, `onkeyboardHStackViewPressGestureEnded(...)`는 현재 위치에 따라 delegate 변경을 호출한다.
- 현재 `SYKeyboardTests`에는 `TextInteractionGestureController`, `ButtonStateController`, `SwitchGestureController`의 UIControl/recognizer 취소 상태 전이 테스트가 없다.
- `SYKeyboardTests`는 `@testable import SYKeyboardCore`와 Swift Testing을 사용하며, gesture 관련 pure policy 테스트 패턴은 이미 존재한다.

## Review Evaluation

- 세 finding은 현재 코드 경로에서 성립하므로 수정 대상이다.
- issue의 제안처럼 `.ended`만 결과를 확정해야 한다.
- 제안에 추가로, 취소/실패 시 결과 확정만 생략하면 안 되고 stale pressed state, overlay, 강조, 상호작용 잠금, drag/long-press stop 상태를 함께 정리해야 한다.
- `SwitchGestureController`는 issue에 명시된 팬 및 one-handed long press뿐 아니라 이어지는 `keyboardHStackViewPressGestureHandler(_:)`의 취소 상태도 같은 원칙으로 처리해야 한다. 그렇지 않으면 continuation recognizer 취소 시 한 손 모드 변경이 남는다.

## Decisions

- 정상 `.ended`와 `.cancelled`/`.failed`를 명시적으로 분리한다.
- 취소/실패에서는 사용자 결과를 확정하지 않지만 cleanup과 stop callback은 수행한다.
- 전환 제스처는 결과 확정 helper와 취소 cleanup helper의 책임을 분리한다.
- 테스트는 결과 호출 횟수와 cleanup 상태를 함께 검증한다. pure policy 테스트만 추가하고 실제 action/delegate 횟수 검증을 생략하지 않는다.
- production 공개 API는 늘리지 않는다. 테스트 가능성을 위한 분리가 필요하면 internal 범위의 최소 helper를 사용한다.
- 일반 터치 취소와 recognizer 소유권 전환에 따른 취소를 `BaseKeyboardButton.isGesturing`으로 구분한다.

## Open Questions

- 실제 입력 앱에서 시스템 또는 다른 recognizer가 제스처를 취소하는 흐름이 자동 테스트와 동일하게 overlay와 입력 상태를 복구하는지 수동 확인이 남아 있다.

## Verification Notes

- 일반 샌드박스의 `xcodebuild -list -project SYKeyboard.xcodeproj`는 CoreSimulator/Xcode/SwiftPM 캐시 권한 오류로 실패했다.
- TDD RED:
  - `ButtonStateControllerTests`의 일반 버튼/Shift `touchCancel` 테스트가 현재 코드에서 실패함을 확인했다.
  - `TextInteractionGestureControllerTests`의 취소된 짧은/delete pan 테스트가 현재 코드에서 실패함을 확인했다.
  - `SwitchGestureControllerTests`의 keyboard/one-handed pan과 initial/continuation long press 취소 테스트가 현재 코드에서 실패함을 확인했다.
  - 다른 현재 버튼 보존 테스트가 첫 cleanup 구현에서 실패함을 확인하고 cleanup 범위를 gesture button으로 좁혔다.
- 권한 있는 환경의 집중 interaction 테스트는 최종 코드에서 `TEST SUCCEEDED`였다.
- 권한 있는 환경의 전체 `SYKeyboard` 테스트는 최종 코드에서 `TEST SUCCEEDED`였다.
- 권한 있는 환경의 `HangeulKeyboard`, `EnglishKeyboard` scheme 빌드는 최종 코드에서 모두 `BUILD SUCCEEDED`였다.
- 첫 구현의 실제 입력 앱 확인에서 길게 누르기 반복 입력과 커서 드래그 회귀가 발견됐다.
- 회귀 TDD RED:
  - 활성 제스처 중 일반 버튼 `.touchCancel`이 `currentPressedButton`과 recognizer 상태를 유지해야 하는 테스트가 첫 구현에서 실패함을 확인했다.
  - 활성 제스처 중 Shift `.touchCancel`이 눌림 상태를 유지해야 하는 테스트가 첫 구현에서 실패함을 확인했다.
- 조건부 `.touchCancel` 수정 후 집중 테스트의 일반 샌드박스 실행은 CoreSimulator/SwiftPM 캐시 권한 오류로 중단됐다.
- 권한 있는 환경에서 조건부 `.touchCancel` 수정 후 집중 interaction 테스트를 재실행해 `TEST SUCCEEDED`를 확인했다.
- 사용자 실기기 확인에서 조건부 `.touchCancel` 수정 후 길게 누르기 반복 입력과 버튼 영역 밖 커서 드래그가 정상 동작함을 확인했다.
- 확인한 이슈: `https://github.com/SNMac/SYKeyboard/issues/65`
- 확인한 프로젝트 지침:
  - `dev/README.md`
  - `dev/codex-skill-playbook.md`의 `ios-keyboard-extension`, `docs-and-infrastructure`
  - `dev/coding-conventions.md`의 UIKit 키보드 UI 및 테스트 스타일

## Current Uncommitted State

- `Modules/SYKeyboardCore/Presentation/Utils/ButtonStateController.swift`
- `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/TextInteractionGestureController.swift`
- `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/SwitchGestureController.swift`
- `SYKeyboardTests/Utils/ButtonStateControllerTests.swift`
- `SYKeyboardTests/Utils/TextInteractionGestureControllerTests.swift`
- `SYKeyboardTests/Utils/SwitchGestureControllerTests.swift`
- `dev/active/code-review-scope/code-review-scope-findings.md`
- `dev/active/issue-65-common-keyboard-interaction-runtime/`

## Next Action

- 권한 있는 환경에서 interaction 테스트, 전체 테스트, 한글/영문 extension 빌드를 다시 실행한다.
- 나머지 취소/정상 종료 흐름을 실제 입력 앱에서 확인한다.
