# Issue 84 Cursor Drag Indicator Tasks

Last Updated: 2026-06-23

## Checklist

- [x] `setMarkedText(_:selectedRange:)`가 기존 텍스트 선택 API로 적합하지 않음을 확인한다.
- [x] selection 기능 구현을 취소하고 indicator overlay만 유지하기로 결정한다.
- [x] `CursorDragSelectionPolicy`를 제거한다.
- [x] `CursorDragSelectionPolicyTests`를 제거한다.
- [x] `CursorDragSelectionTouchCaptureView`를 제거한다.
- [x] `TextInteractionGestureController`에서 selection touch provider를 제거한다.
- [x] `TextInteractionGestureControllerDelegate.primaryButtonSelectionPanning`을 제거한다.
- [x] `BaseKeyboardViewController`에서 selection state와 `setMarkedText` 호출 경로를 제거한다.
- [x] `BaseKeyboardViewController`에서 cursor drag indicator overlay만 표시하도록 정리한다.
- [x] indicator symbol을 `character.cursor.ibeam` 우선 사용으로 변경한다.
- [x] 구형 OS에서 symbol image가 nil이 되지 않도록 fallback을 둔다.
- [x] indicator icon에 `UIVibrancyEffect`를 적용한다.
- [x] indicator corner radius를 `KeyboardLayoutFigure.otherOverlayCornerRadius`로 분리해 반영한다.
- [x] `CursorDragOverlayTests`를 indicator effect/symbol/vibrancy 검증으로 갱신한다.
- [x] `TextInteractionGestureControllerTests`를 cursor movement callback 중심으로 갱신한다.
- [x] targeted `TextInteractionGestureControllerTests`, `CursorDragOverlayTests`를 실행한다.
- [x] selection/markedText 잔여 참조가 없는지 `rg`로 확인한다.
- [x] 전체 `SYKeyboard` test를 실행한다. 샌드박스 실패 후 권한 있는 실행으로 통과했다.
- [x] `HangeulKeyboard`, `EnglishKeyboard` extension build를 실행한다. `HangeulKeyboard` 샌드박스 실패 후 권한 있는 실행으로 둘 다 통과했다.
- [ ] 실제 iOS 26+ 환경에서 Liquid Glass + vibrancy indicator 시각 결과를 확인한다.
