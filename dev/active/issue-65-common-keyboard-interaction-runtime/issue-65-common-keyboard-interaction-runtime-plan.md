# Issue 65 Common Keyboard Interaction Runtime Plan

Last Updated: 2026-06-14

## Goal

- 취소되거나 실패한 키보드 터치/제스처가 입력, 키보드 전환, 한 손 모드 변경을 확정하지 않도록 한다.
- 정상 종료된 탭과 제스처의 기존 입력 흐름, 버튼 이벤트 순서, overlay 정리 동작은 유지한다.
- GitHub issue #65의 Track 2 findings 세 건을 회귀 테스트와 함께 처리한다.

## Current State

- `TextInteractionGestureController.panGestureHandler(_:)`는 `.ended`만 짧은 pan 입력을 확정하고, 취소/실패 시 해당 gesture button의 눌림 상태만 정리한다.
- `ButtonStateController.setExclusiveActionToButtons(_:)`는 일반 터치의 `.touchCancel`에서 버튼 상태를 해제하되, 활성 제스처가 UIKit에 의해 발생시킨 `.touchCancel`은 무시한다.
- `SwitchGestureController`의 팬 및 long press 종료 경로는 `.ended`만 입력 action과 delegate 변경을 확정하고, 취소/실패 시 overlay와 상호작용 상태만 정리한다.
- 관련 controller의 취소/실패/정상 종료 상태 전이를 검증하는 interaction 테스트가 추가됐다.
- 첫 구현은 모든 `.touchCancel`에서 현재 버튼 상태를 해제해 실기기에서 길게 누르기 반복 입력과 커서 드래그 recognizer까지 취소하는 회귀가 발생했다. 활성 제스처 중 취소를 보존하는 회귀 테스트와 조건부 해제 로직을 추가했다.

## Approach

### 1. 취소 상태의 공통 원칙 확정

- `.ended`만 사용자가 확정한 동작으로 취급한다.
- `.cancelled`와 `.failed`는 입력 action과 delegate 변경을 수행하지 않는다.
- 취소/실패에서도 눌림 상태, gesture 상태, overlay, 강조 표시, 사용자 상호작용 잠금, 반복 입력/드래그 종료 상태는 정리한다.
- `.ended`의 기존 버튼 입력과 키보드/한 손 모드 전환 결과는 유지한다.

### 2. 텍스트 팬 제스처 종료 경로 분리

- `TextInteractionGestureController.panGestureHandler(_:)`에서 `.ended`와 `.cancelled`/`.failed`를 분리한다.
- 짧은 팬의 `.touchUpInside` 전송은 `.ended`에서만 수행한다.
- 취소/실패 시 `currentPressedButton`을 해제해 다음 버튼 터치가 이전 버튼을 입력하지 않도록 한다.
- 커서 이동 또는 삭제 드래그가 시작된 경우에는 종료 상태와 무관하게 필요한 stop callback과 UI 상호작용 복구를 수행한다.

### 3. 버튼 `touchCancel` 해제 처리 추가

- `ButtonStateController.setExclusiveActionToButtons(_:)`의 일반 버튼과 Shift 버튼에 `.touchCancel` 전용 action을 등록한다.
- 일반 버튼 취소 시 해당 버튼이 현재 눌린 버튼일 때만 `currentPressedButton`을 비운다.
- Shift 취소 시 `isShiftButtonPressed`를 `false`로 복구한다.
- 단, `isGesturing == true`인 버튼의 `.touchCancel`은 recognizer가 터치 소유권을 얻으면서 발생한 이벤트이므로 상태를 유지하고, 실제 terminal gesture handler가 정리하도록 한다.
- suggestion bar의 `isUserInteractionEnabled`가 취소 후 다시 활성화되는지 확인한다.

### 4. 전환 제스처의 결과 확정과 정리 분리

- `SwitchGestureController`의 다음 종료 경로에서 `.ended`만 결과를 확정하도록 분리한다.
  - `keyboardSelectPanGestureHandler(_:)`
  - `oneHandedModeSelectPanGestureHandler(_:)`
  - `oneHandedModeLongPressGestureHandler(_:)`
  - `keyboardHStackViewPressGestureHandler(_:)`
- 취소/실패 시 `.touchUpInside`, `changeKeyboard`, `changeOneHandedMode`를 호출하지 않는다.
- 취소/실패 전용 정리 경로에서 표시 중인 overlay를 숨기고, switch button 강조와 `isGesturing`, `isOverlayActive`, `isDragOutside`, `isKeepGesturing`, 눌린 버튼, 사용자 상호작용 상태를 일관되게 복구한다.
- 정상 `.ended`의 overlay 선택 및 one-handed mode 유지 제스처 전환은 기존 동작을 보존한다.

### 5. Interaction 회귀 테스트 추가

- `ButtonStateController`는 실제 `UIControl.sendActions(for:)`를 사용해 일반 버튼과 Shift 버튼의 `.touchCancel` 상태 전이를 검증한다.
- `TextInteractionGestureController`는 `.ended`, `.cancelled`, `.failed`별 `.touchUpInside` 입력 횟수, 눌린 버튼 해제, 삭제 드래그 stop callback을 검증한다.
- `SwitchGestureController`는 overlay가 표시된 상태에서 각 팬/long press가 `.ended`일 때만 delegate를 호출하고, `.cancelled`/`.failed`에서는 delegate 호출 없이 overlay와 상호작용 상태만 정리되는지 검증한다.
- UIKit recognizer를 안정적으로 구동하기 어렵다면 넓은 추상화 대신 controller 내부의 terminal-state 결정/정리 helper를 최소 범위로 분리하고, handler 연결과 결과 횟수를 함께 검증한다.

### 6. Findings와 검증 결과 반영

- 세 finding을 각각 수정 및 검증한 뒤 `dev/active/code-review-scope/code-review-scope-findings.md`에 처리 내용과 실제 검증 결과를 기록한다.

## Risks

- `BaseKeyboardButton.sendActions(for:)`는 `isProgrammaticCall`을 켜 입력 검증을 우회하므로 취소 경로에서 호출이 한 번이라도 남으면 의도하지 않은 입력이 발생한다.
- 취소 시 `currentPressedButton`을 정리하지 않으면 다음 버튼의 `touchDown`이 이전 버튼 입력을 확정할 수 있다.
- 텍스트 삭제 드래그와 long press 반복 입력은 취소 시에도 stop callback이 필요하다. 결과 확정을 막으면서 타이머/드래그 상태 정리는 유지해야 한다.
- `SwitchGestureController`의 one-handed long press는 initial recognizer에서 keyboard stack recognizer로 이어질 수 있다. 두 recognizer의 취소 경로를 모두 처리하지 않으면 delegate 변경이 남는다.
- overlay를 숨기기만 하고 강조, 버튼 상호작용, `isKeepGesturing`을 복구하지 않으면 키보드가 비활성 상태로 남을 수 있다.
- UIKit interaction 테스트가 main actor와 recognizer 상태 전이에 민감할 수 있으므로 테스트 helper가 production 동작을 우회하지 않는지 확인해야 한다.
- recognizer의 `cancelsTouchesInView`로 발생한 `.touchCancel`을 일반 터치 취소처럼 처리하면 `currentPressedButton.didSet`이 활성 recognizer를 취소해 반복 입력과 커서 드래그가 즉시 종료된다.

## Verification

집중 테스트:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/ButtonStateControllerTests \
  -only-testing:SYKeyboardTests/TextInteractionGestureControllerTests \
  -only-testing:SYKeyboardTests/SwitchGestureControllerTests
```

전체 테스트:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

키보드 extension 빌드:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

수동 확인:

- 실제 텍스트 입력 앱에서 문자/스페이스 짧은 팬을 취소한 뒤 문자가 입력되지 않고 다음 키가 정상 입력되는지 확인한다.
- 삭제 드래그/길게 누르기를 취소한 뒤 반복 삭제가 멈추고 다음 입력이 정상 동작하는지 확인한다.
- 문자/삭제 버튼을 길게 눌렀을 때 반복 입력이 계속되고, 버튼 영역 밖으로 드래그해도 커서 이동이 계속되는지 확인한다.
- 키보드 선택 및 한 손 모드 overlay를 연 뒤 제스처를 취소했을 때 모드가 변경되지 않고 overlay와 버튼 상호작용이 정상 복구되는지 확인한다.
- 같은 흐름을 정상 종료했을 때 기존 입력과 전환 결과가 유지되는지 확인한다.

## Done Criteria

- 취소/실패한 텍스트 팬이 입력 action을 실행하지 않는다.
- 일반 터치의 `.touchCancel` 후 버튼/Shift/suggestion bar 상태가 정상 복구되고, 활성 제스처 중 `.touchCancel`은 반복 입력과 커서 드래그를 중단하지 않는다.
- 취소/실패한 키보드 선택 및 한 손 모드 팬/long press가 delegate 변경을 확정하지 않는다.
- 정상 `.ended` 동작과 stop/cleanup callback은 유지된다.
- 관련 interaction 테스트, 전체 테스트, 한글/영문 extension 빌드 결과가 기록된다.
- Track 2 findings 세 건이 처리 및 검증 결과와 함께 `Resolved` 또는 근거가 있는 다른 상태로 갱신된다.
