# Selected Text Return Key Context

Last Updated: 2026-06-20

## Relevant Files

- `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardPresentationStatePolicy.swift`: return 버튼 활성화 정책이 before/after 문맥만 확인한다.
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`: `updateReturnButtonEnabled()`에서 정책에 `textDocumentProxy` 문맥을 전달한다.
- `SYKeyboardTests/Utils/KeyboardPresentationStatePolicyTests.swift`: return 자동 활성화 정책 테스트가 있다.
- `dev/active/code-review-scope/code-review-scope-findings.md`: 전체 코드리뷰 findings 추적 문서이며 처리 결과를 갱신해야 한다.

## Facts Checked

- GitHub Issue #85는 열린 bug 이슈이며 댓글은 없다.
- 이슈 #85의 실제 open finding은 `[P2] return 자동 활성화 판단이 선택된 텍스트를 텍스트 존재 여부에 포함하지 않음` 하나다.
- `KeyboardPresentationStatePolicy.isReturnButtonEnabled(...)` 현재 시그니처는 `enablesReturnKeyAutomatically`, `documentContextBeforeInput`, `documentContextAfterInput`만 받는다.
- `BaseKeyboardViewController.updateReturnButtonEnabled()`는 현재 `textDocumentProxy.documentContextBeforeInput`과 `documentContextAfterInput`만 전달한다.
- `SYKeyboardTests/Utils/KeyboardPresentationStatePolicyTests.swift`는 before 또는 after에 텍스트가 있을 때 활성화되는 케이스를 검증하지만 `selectedText`만 있는 케이스는 없다.
- SDK 헤더 `UIInputViewController.h`에서 `UITextDocumentProxy`는 `documentContextBeforeInput`, `documentContextAfterInput`, `selectedText`를 제공한다.
- SDK 헤더 `UITextInputTraits.h`에서 `enablesReturnKeyAutomatically`는 text widget contents의 zero-length/non-zero-length 상태에 따라 return key를 자동 비활성/활성화한다고 설명한다.
- `BaseKeyboardViewController`의 삭제, 반복 삭제, 자동완성 선택 경로는 이미 `textDocumentProxy.selectedText`를 별도로 전달한다.
- `currentTextContextSnapshot()`은 before/after만 담고 undo/redo cursor anchor에 사용된다.
- 구현 후 `KeyboardPresentationStatePolicy.isReturnButtonEnabled(...)`는 `selectedText`를 명시 입력으로 받는다.
- 구현 후 `BaseKeyboardViewController.updateReturnButtonEnabled()`는 `textDocumentProxy.selectedText`를 전달한다.

## Evaluation

- 타당함: selected text가 존재하면 text widget contents는 비어 있지 않은 상태로 해석하는 것이 `enablesReturnKeyAutomatically` 계약과 맞다.
- 타당함: custom keyboard에서 전체 선택 상태일 때 before/after 문맥이 비어 있을 수 있으므로, before/after만 보는 현재 정책은 false negative를 낼 수 있다.
- 타당함: 수정 범위는 return 버튼 표시 정책과 해당 테스트로 한정할 수 있으며, 입력 조합/삭제/커서 이동 정책을 바꿀 필요는 없다.

## Decisions

- `selectedText`를 return 활성화 정책의 명시 입력으로 추가한다.
- `selectedText`가 `nil`이거나 빈 문자열이면 기존 before/after 판단과 동일하게 동작하게 한다.
- `selectedText`가 공백 문자열만 포함하더라도 비어 있지 않으면 text contents가 있는 것으로 보고 활성화한다. 기존 before/after도 `isEmpty == false`만 확인하므로 같은 기준을 따른다.
- Track 9 handoff에서 제외한 snapshot, cursor drag, period shortcut, delete/repeat delete/suggestion selection 경로는 수정하지 않는다.

## Open Questions

- 실제 host 앱에서 전체 선택 상태일 때 before/after가 항상 빈 문자열 또는 nil로 노출되는지는 입력 필드 종류별로 다를 수 있다. 정책상 selected text를 포함하면 해당 차이에 더 안전하다.
- 수동 확인용 host 화면이 별도로 준비되어 있는지는 아직 확인하지 않았다. 자동 테스트로 정책은 검증할 수 있다.

## Verification Notes

- 실행한 명령:

```sh
git status --short
gh api repos/SNMac/SYKeyboard/issues/85
gh api repos/SNMac/SYKeyboard/issues/85/comments
sed -n '1,220p' Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardPresentationStatePolicy.swift
sed -n '940,1040p' Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
sed -n '1,220p' SYKeyboardTests/Utils/KeyboardPresentationStatePolicyTests.swift
rg -n "isReturnButtonEnabled|selectedText|updateReturnButtonEnabled|KeyboardTextContextSnapshot|currentTextContextSnapshot|CursorDragAccelerationPolicy|KeyboardPeriodShortcutPolicy|shouldRepeatDelete" Modules Keyboards SYKeyboard SYKeyboardTests
sed -n '16,30p' /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/UIKit.framework/Headers/UIInputViewController.h
sed -n '250,260p' /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/UIKit.framework/Headers/UITextInputTraits.h
```

- `gh issue view 85 --repo SNMac/SYKeyboard --comments`는 GitHub classic Projects GraphQL 필드 오류로 실패했다. 이슈 본문과 댓글은 `gh api`로 확인했다.
- TDD RED: `KeyboardPresentationStatePolicyTests`에 `selectedText` 파라미터와 selected text 전용 케이스를 먼저 추가한 뒤 focused 테스트를 실행했고, 기존 production API가 인자를 받지 못해 `extra argument 'selectedText' in call`로 실패했다.
- 구현 후 focused 테스트:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests
```

- 결과: `TEST SUCCEEDED`
- 구현 후 전체 테스트:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 결과: `TEST SUCCEEDED`
- 두 테스트 실행 모두 연결된 잠금 기기 관련 `DTDKRemoteDeviceConnection` 경고를 출력했지만, 시뮬레이터 테스트는 exit code 0으로 완료됐다.
