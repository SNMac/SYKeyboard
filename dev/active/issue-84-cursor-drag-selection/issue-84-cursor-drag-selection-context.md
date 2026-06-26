# Issue 84 Cursor Drag Indicator Context

Last Updated: 2026-06-26

## Relevant Files

- `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/TextInteractionGestureController.swift`: primary/delete 버튼 pan gesture의 활성화, cursor step 계산, delegate 호출을 담당한다. selection 분기는 제거하고 cursor movement callback만 유지한다.
- `Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardFigure.swift`: 버튼, 선택 overlay, 기타 overlay의 공통 레이아웃 수치를 정의한다. cursor drag indicator는 `otherOverlayCornerRadius`를 사용한다.
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`: cursor 이동과 cursor drag indicator overlay 표시/정리를 담당한다. `setMarkedText(_:selectedRange:)` 기반 selection 적용은 제거한다.
- `Modules/SYKeyboardCore/Presentation/View/Components/Overlays/CursorDragIndicatorView.swift`: cursor drag 활성 상태를 보여주는 overlay다. iOS 26 이상 `UIGlassEffect(style: .regular)`, 그 미만 `UIBlurEffect(style: .systemMaterial)`를 사용한다. `character.cursor.ibeam` 아이콘은 Liquid Glass에서는 effect view에 직접 표시하고, Material fallback에서는 vibrancy view 안에 표시한다.
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/CursorDragAccelerationPolicy.swift`: cursor drag step 계산 정책이다.
- `SYKeyboardTests/Utils/TextInteractionGestureControllerTests.swift`: cursor drag 활성화, cursor movement callback, stop callback을 검증한다.
- `SYKeyboardTests/Utils/CursorDragOverlayTests.swift`: cursor indicator effect, symbol name/fallback, OS별 vibrancy 적용 여부를 검증한다.
- 2026-06-26 추가: 같은 `CursorDragIndicatorView`를 delete drag overlay에도 재사용한다. delete overlay는 `delete.backward` symbol을 주입한다.

## Facts Checked

- `UITextDocumentProxy.setMarkedText(_:selectedRange:)`는 기존 텍스트 선택 전용 API가 아니다.
- 실제 입력 확인에서 `setMarkedText` 기반 selection 시도는 기존 글자를 선택하지 않고 marked text를 추가해 글자가 늘어나는 문제를 만들었다.
- 사용자는 selection 기능 구현 취소를 결정했고, cursor drag indicator overlay는 유지하기로 했다.
- 공개 UIKit `UIImage.SymbolConfiguration`에는 SF Symbol locale/language를 직접 강제하는 옵션이 확인되지 않았다.
- `character.cursor.ibeam`을 우선 사용하고, OS에서 해당 symbol을 제공하지 않으면 `text.cursor` fallback을 사용한다.
- `UIVibrancyEffect`는 `UIBlurEffect` 기반 API다. Xcode 26.5 SDK header에서도 `UIBlurEffect`가 설정된 `UIVisualEffectView` 위/하위에 두는 용도라고 설명한다.
- Liquid Glass에서는 `UIVibrancyEffect`를 사용하지 않고, Material fallback에서만 vibrancy view를 사용한다.
- `KeyboardLayoutFigure.otherOverlayCornerRadius`는 iOS 26 이상에서 `12.0`, 그 미만에서 `0.0`을 반환한다.
- `delete.backward` SF Symbol 이미지는 현재 테스트 환경에서 nil이 아니다.

## Decisions

- Issue #84의 텍스트 선택 기능은 현 단계에서 구현하지 않는다.
- `CursorDragSelectionPolicy`, selection policy tests, `CursorDragSelectionTouchCaptureView`는 제거한다.
- `TextInteractionGestureController`는 `isSelectionTouchActive` provider와 `primaryButtonSelectionPanning` delegate를 갖지 않는다.
- `BaseKeyboardViewController`는 cursor drag 중 indicator overlay만 표시한다.
- indicator SF Symbol은 `character.cursor.ibeam`을 우선 사용한다.
- 구형 OS에서 `character.cursor.ibeam`이 없으면 overlay가 비지 않도록 `text.cursor` fallback을 둔다.
- cursor drag indicator corner radius는 선택 overlay용 `selectOverlayCornerRadius`가 아니라 기타 overlay용 `otherOverlayCornerRadius`를 사용한다.
- delete drag overlay는 cursor drag overlay와 같은 UI/effect/corner radius를 사용하고 symbol만 `delete.backward`로 다르게 둔다.
- delete drag overlay 표시는 `BaseKeyboardViewController.deleteButtonPanning(_:to:)`에서, 숨김은 `deleteButtonPanStopped(_:)`에서 수행한다.
- 기존 cursor drag overlay 기본 symbol은 `character.cursor.ibeam`으로 유지한다.

## Open Questions

- 실제 iOS 26+ 기기에서 `UIGlassEffect` indicator와 아이콘 대비가 의도대로 보이는가?
- iOS 26+ 시스템 locale에서 `character.cursor.ibeam`이 한글/영문 키보드 사용 맥락에 맞게 표시되는가?
- 실제 iOS 26+ 또는 iOS 27 기기에서 delete drag overlay의 `delete.backward` 대비와 위치가 의도대로 보이는가?

## Verification Notes

- RED:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' -only-testing:SYKeyboardTests/TextInteractionGestureControllerTests -only-testing:SYKeyboardTests/CursorDragOverlayTests
```

  - 결과: `CursorDragIndicatorSymbolFactory`가 없어 실패했다.

- GREEN:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' -only-testing:SYKeyboardTests/TextInteractionGestureControllerTests -only-testing:SYKeyboardTests/CursorDragOverlayTests
```

  - 결과: 통과했다.
  - 실행 중 연결된 잠긴 실기기 때문에 `DTDKRemoteDeviceConnection ... The device is passcode protected` 경고가 반복되었지만 테스트 결과는 성공이었다.

- `KeyboardLayoutFigure.otherOverlayCornerRadius` 반영 후 overlay 테스트:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' -only-testing:SYKeyboardTests/CursorDragOverlayTests
```

  - 결과: 통과했다.
  - 실행 중 연결된 잠긴 실기기 때문에 `DTDKRemoteDeviceConnection ... The device is passcode protected` 경고가 반복되었지만 테스트 결과는 성공이었다.

- PR review 반영 후 overlay 테스트:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' -only-testing:SYKeyboardTests/CursorDragOverlayTests
```

  - 결과: 통과했다.
  - `vibrancyView` lazy 초기화를 Material fallback 분기로 제한하고, 테스트 기대값을 iOS 26 이상 Liquid Glass에서는 vibrancy 없음 / iOS 25 이하 Material에서는 vibrancy 있음으로 분기했다.
  - 실행 중 연결된 잠긴 실기기 때문에 `DTDKRemoteDeviceConnection ... The device is passcode protected` 경고가 반복되었지만 테스트 결과는 성공이었다.

- 전체 테스트:

```sh
xcodebuild -quiet test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'
```

  - 샌드박스 실행은 CoreSimulator, SwiftPM cache, clang ModuleCache 접근 제한으로 환경 실패했다.
  - 권한 있는 재실행은 통과했다.

- 키보드 extension 빌드:

```sh
xcodebuild -quiet build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'
xcodebuild -quiet build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'
```

  - `HangeulKeyboard` 샌드박스 실행은 CoreSimulator, SwiftPM cache, clang ModuleCache 접근 제한으로 환경 실패했다.
  - 권한 있는 `HangeulKeyboard`, `EnglishKeyboard` 빌드는 모두 통과했다.

- 잔여 참조 확인:

```sh
rg -n "SelectionTouch|selectionTouch|SelectionPanning|setMarkedText|cursorDragSelection|CursorDragSelection|isSelectionTouchActive|primarySelectionPanning" Modules/SYKeyboardCore SYKeyboardTests SYKeyboard.xcodeproj/project.pbxproj
```

  - 결과: 일치 항목 없음.

- delete drag overlay RED:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/CursorDragOverlayTests/testDeleteIndicatorSymbol_deleteBackward
```

  - 결과: `CursorDragIndicatorSymbolFactory`에 `deleteSymbolName`과 symbol 주입 가능한 `image(symbolName:)`가 없어 실패했다.

- delete drag overlay GREEN:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/CursorDragOverlayTests
```

  - 결과: 통과했다. 기존 `character.cursor.ibeam` symbol 테스트와 신규 `delete.backward` symbol 테스트가 모두 통과했다.

- delete drag overlay targeted 검증:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/TextInteractionGestureControllerTests -only-testing:SYKeyboardTests/CursorDragOverlayTests
```

  - 결과: 통과했다. `** TEST SUCCEEDED **`

- delete drag overlay 전체 검증:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

  - 결과: 통과했다. `** TEST SUCCEEDED **`

- 사용자 실기기 수동 확인:

```text
삭제 버튼 드래그 중 delete.backward overlay 표시 동작 확인
```

  - 결과: 정상 동작 확인.
