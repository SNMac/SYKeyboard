# Issue 84 Cursor Drag Indicator Plan

Last Updated: 2026-06-23

## Goal

- GitHub Issue #84의 텍스트 선택 기능 구현은 취소한다.
- 커서 드래그 중 표시되는 overlay는 유지한다.
- overlay 아이콘은 `character.cursor.ibeam`을 우선 사용하고, 아이콘에는 `UIVibrancyEffect`를 적용한다.

## Current State

- `UITextDocumentProxy.setMarkedText(_:selectedRange:)`는 기존 텍스트 범위를 선택하는 API가 아니라 marked text를 삽입/갱신하는 API에 가깝다.
- 실제 확인에서 `ㄱㄴㄷㄹㅁ` 같은 텍스트에서 선택을 시도하면 `ㄱㄴㄷㄹㄹㅁ`, `ㄱㄴㄷㄹㄹㅁㅁ`처럼 글자가 늘어나는 문제가 있었다.
- 따라서 selection mode, touch capture overlay, `setMarkedText` 기반 선택 적용, selection policy는 제거한다.
- 커서 드래그 자체는 기존처럼 `TextInteractionGestureController`와 `BaseKeyboardViewController.primaryButtonPanning(_:to:steps:)`가 담당한다.
- 커서 드래그 활성화 중에는 `CursorDragIndicatorView`만 `keyboardHStackView` 영역 위에 표시한다.
- indicator 배경은 iOS 26 이상 `UIGlassEffect(style: .regular)`, 그 미만 `UIBlurEffect(style: .systemMaterial)`를 유지한다.
- indicator 아이콘은 `character.cursor.ibeam`을 우선 사용하고, 구형 OS에서 심볼이 없으면 빈 이미지 방지를 위해 `text.cursor`로 fallback한다.
- indicator corner radius는 `KeyboardLayoutFigure.otherOverlayCornerRadius`를 사용한다. 현재 값은 iOS 26 이상 `12.0`, 그 미만 `0.0`이다.

## Approach

1. selection 구현 제거
   - `CursorDragSelectionPolicy`, 관련 테스트, touch capture overlay 파일을 삭제한다.
   - `TextInteractionGestureControllerDelegate.primaryButtonSelectionPanning`과 `isSelectionTouchActive` provider를 제거한다.
   - `BaseKeyboardViewController`의 selection state, capture overlay, `setMarkedText` 호출 경로를 제거한다.
2. cursor indicator 유지
   - `CursorDragIndicatorView`는 계속 `keyboardHStackView` 영역을 덮는다.
   - 시각 효과는 기존 Glass/Material 분기를 유지한다.
   - 아이콘은 `character.cursor.ibeam`을 우선 사용한다.
   - 아이콘은 `UIVibrancyEffect`가 적용된 `UIVisualEffectView.contentView` 안에 배치한다.
   - 기타 overlay 전용 corner radius 상수를 사용해 선택 overlay 수치와 분리한다.
3. 검증
   - `TextInteractionGestureControllerTests`에서 cursor movement callback만 검증한다.
   - `CursorDragOverlayTests`에서 effect, symbol name, fallback image, vibrancy 적용을 검증한다.
   - 가능한 경우 전체 `SYKeyboard` test와 키보드 extension build를 재실행한다.

## Risks

- `character.cursor.ibeam`은 OS별 SF Symbols 제공 여부가 다를 수 있어 구형 OS에서는 fallback이 보일 수 있다.
- `UIVibrancyEffect`는 blur 기반 API라 iOS 26 `UIGlassEffect` 자체를 직접 입력으로 받지는 않는다. 현재 구현은 Glass/Material 배경 위에 별도 vibrancy view를 얹는다.
- 실제 iOS 26+에서 Liquid Glass와 vibrancy 조합의 시각 결과는 수동 확인이 필요하다.

## Verification

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' \
  -only-testing:SYKeyboardTests/TextInteractionGestureControllerTests \
  -only-testing:SYKeyboardTests/CursorDragOverlayTests
```

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

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

## Done Criteria

- selection mode와 `setMarkedText` 기반 선택 적용 코드가 제거된다.
- cursor drag 중 indicator overlay는 계속 표시된다.
- indicator 아이콘은 `character.cursor.ibeam`을 우선 사용한다.
- indicator 아이콘에 `UIVibrancyEffect`가 적용된다.
- targeted gesture/overlay 테스트가 통과한다.
