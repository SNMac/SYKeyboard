# Selected Text Return Key Plan

Last Updated: 2026-06-20

## Goal

- GitHub Issue #85의 `[P2] return 자동 활성화 판단이 선택된 텍스트를 텍스트 존재 여부에 포함하지 않음` finding을 수정한다.

## Current State

- 판단: finding은 타당하며 수정 완료했다.
- `KeyboardPresentationStatePolicy.isReturnButtonEnabled(...)`는 `documentContextBeforeInput`, `selectedText`, `documentContextAfterInput`을 확인한다.
- `BaseKeyboardViewController.updateReturnButtonEnabled()`는 `textDocumentProxy.selectedText`를 함께 전달한다.
- `UITextInputTraits.enablesReturnKeyAutomatically` SDK 헤더는 text widget contents가 zero-length이면 return key를 비활성화하고 non-zero-length이면 활성화한다고 설명한다.
- `UITextDocumentProxy` SDK 헤더에는 custom keyboard가 접근할 수 있는 문맥으로 `documentContextBeforeInput`, `documentContextAfterInput`, `selectedText`가 별도 속성으로 존재한다.
- 전체 텍스트가 선택되어 before/after가 비어 있고 `selectedText`만 있는 경우에도 return 자동 활성화 정책이 활성화된다.
- 관련 파일:
  - `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardPresentationStatePolicy.swift`
  - `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - `SYKeyboardTests/Utils/KeyboardPresentationStatePolicyTests.swift`
  - `dev/active/code-review-scope/code-review-scope-findings.md`

## Approach

1. `KeyboardPresentationStatePolicy.isReturnButtonEnabled(...)`에 `selectedText: String?` 파라미터를 추가한다.
2. `enablesReturnKeyAutomatically == false`이면 기존처럼 항상 `true`를 반환한다.
3. 자동 활성화가 켜져 있으면 before/selected/after 중 하나라도 비어 있지 않을 때 `true`를 반환한다.
4. `BaseKeyboardViewController.updateReturnButtonEnabled()`에서 `textDocumentProxy.selectedText`를 전달한다.
5. 기존 정책 테스트 호출부를 새 시그니처로 갱신하고, before/after가 nil 또는 빈 문자열이고 selectedText만 있는 경우 활성화되는 테스트를 추가한다.
6. finding 처리 후 `dev/active/code-review-scope/code-review-scope-findings.md`의 Track 9 항목을 `Resolved`로 갱신하고 처리/검증 결과를 기록한다.

## Non-Goals

- `currentTextContextSnapshot()`과 `KeyboardTextContextSnapshot`에는 `selectedText`를 섞지 않는다. 이 경로는 undo/redo cursor anchor용이다.
- `CursorDragAccelerationPolicy.applicableSteps(...)`에는 `selectedText`를 섞지 않는다. 이 경로는 커서 이동 가능 거리 계산용이다.
- `KeyboardPeriodShortcutPolicy`와 `EnglishKeyboardCoreViewController.updateShiftButton()`은 caret 앞 문맥 기준 기능이므로 현재 구조를 유지한다.
- 삭제, 반복 삭제, 자동완성 선택 경로는 이미 `selectedText`를 별도로 고려하고 있으므로 이번 수정 범위에서 확장하지 않는다.
- `KeyboardTextInteractionPolicy.shouldRepeatDelete(...)`의 빈 문자열 정책은 Track 9의 selected text 누락 문제가 아니므로 별도 이슈로 남긴다.

## Risks

- `isReturnButtonEnabled(...)` 호출부가 테스트 외에 추가될 경우 새 파라미터 누락으로 빌드가 실패할 수 있다. `rg -n "isReturnButtonEnabled"`로 전체 호출부를 확인한다.
- `selectedText`가 iOS 11+ API이지만 프로젝트 최소 버전은 iOS 16+이므로 별도 availability 분기는 필요하지 않다.
- return 버튼 활성화 상태는 실제 host text field의 `enablesReturnKeyAutomatically`와 proxy 문맥 조합에 의존하므로, 가능하면 실제 입력 필드에서 전체 선택 상태를 수동 확인한다.

## Verification

- 실행한 검증 명령:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests
```

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 결과:
  - 구현 전 focused 테스트는 `extra argument 'selectedText' in call`로 실패해 RED를 확인했다.
  - 구현 후 focused 테스트는 `TEST SUCCEEDED`로 통과했다.
  - 전체 `SYKeyboard` 테스트도 `TEST SUCCEEDED`로 통과했다.
  - 테스트 실행 중 연결된 잠금 기기 관련 `DTDKRemoteDeviceConnection` 경고가 출력됐지만, 시뮬레이터 테스트는 exit code 0으로 완료됐다.

- 수동 확인이 가능하면:
  - `enablesReturnKeyAutomatically`가 켜진 텍스트 필드에서 텍스트 전체를 선택한다.
  - before/after 문맥이 비어 있을 수 있는 상태에서 custom keyboard return 버튼이 활성화되는지 확인한다.

## Done Criteria

- `selectedText`만 있는 문맥에서도 return 자동 활성화 정책이 활성화된다.
- 정책 테스트에 selected text 전용 케이스가 추가되고 통과한다.
- 전체 `SYKeyboard` 테스트가 통과했다.
- `dev/active/code-review-scope/code-review-scope-findings.md`에 처리 상태와 검증 결과가 반영된다.
