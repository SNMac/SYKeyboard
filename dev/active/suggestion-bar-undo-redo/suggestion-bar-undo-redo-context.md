# Suggestion Bar Undo Redo Context

Last Updated: 2026-05-22

## Relevant Files

- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`: 리턴 버튼 입력, 반복 입력, 텍스트 프록시 래퍼, suggestion 후처리, undo/redo 상태 연결의 중심 파일이다.
- `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift`: 자동완성 후보 3개와 우측 undo/redo 버튼 표시 및 tap delegate를 담당한다.
- `Modules/SYKeyboardCore/Presentation/Utils/KeyboardUndoRedoManager.swift`: 세션 한정 undo/redo 기록과 debounce pending 그룹을 담당한다.
- `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/TextInteractionGestureController.swift`: 키/삭제 버튼 pan gesture를 담당한다. 리턴 버튼 undo/redo pan 분기는 제거했다.
- `Modules/SYKeyboardCore/Presentation/Utils/Enums/TextInteractableType.swift`: 리턴 버튼이 `.returnButton` 타입으로 분기되는 기준이다.
- `SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift`: undo/redo 기록 단위, redo 초기화, 치환 기록을 검증한다.
- `dev/codex-skill-playbook.md`: 키보드 extension UI와 버튼 이벤트 변경 시 확인할 프로젝트 로컬 규칙이다.
- `dev/coding-conventions.md`: UIKit 키보드 UI, 접근 제어, 주석, 테스트 스타일 기준이다.

## Facts Checked

- `git branch --show-current` 결과는 `feat/#31-undo-redo`이다.
- 리팩토링 전 `BaseKeyboardViewController.swift`는 `wc -l` 기준 1456줄이었다.
- undo/redo 세션 상태 분리 후 `BaseKeyboardViewController.swift`는 `wc -l` 기준 1388줄이고, `KeyboardUndoRedoManager.swift`는 482줄이다.
- suggestion 선택 흐름 분리 후 `BaseKeyboardViewController.swift`는 `wc -l` 기준 1403줄이다. 줄 수는 helper 분리로 늘었지만, `SuggestionBarDelegate` 본문은 selected text, n-gram, 현재 단어 확정, input buffer suggestion 경로 호출만 남았다.
- 현재 일반 리턴 입력은 `performTextInteraction(for:)`의 `.returnButton` 분기에서 `insertReturnText()`를 직접 호출한다.
- 현재 반복 리턴 입력은 `performRepeatTextInteraction(for:)`의 `.returnButton` 분기에서 `insertReturnText()` 호출 후 `button.playFeedback()`을 실행한다.
- 현재 `insertReturnText()`는 preview에서는 리턴하고, 실제 입력에서는 undo/redo 기록, `suggestionController.endSentence(inputBuffer:)`, `textDocumentProxy.insertText("\n")`, `resetInputBuffer()`, `suggestionController.clearReplacementHistory()`를 수행한다.
- 자동완성 바는 `isPredictiveTextEnabled`가 켜져 있고 현재 키보드가 tenKey가 아니며 host가 autocorrection을 금지하지 않을 때만 표시된다.
- undo/redo 버튼은 자동완성 바가 표시되고 `isUndoRedoEnabled`가 켜져 있을 때만 표시된다.
- undo/redo 버튼은 `UIButton`이 아니라 `SuggestionActionButtonView` 기반 `UIView`다. 자동완성 후보와 같은 직접 highlight 처리 방식을 유지해 `UIButton` 기본 탭 애니메이션을 피한다.
- undo/redo 액션 버튼 폭은 44pt이며, iOS 26 이상에서는 suggestion bar 높이에 맞춘 pill radius를 사용한다.
- undo/redo 액션 버튼의 `accessibilityLabel`, `accessibilityTraits`, `isAccessibilityElement` 코드는 현재 의도적으로 제거된 상태다. 사용자가 접근성 관련 코드를 일부러 뺐다고 명시했다.
- `isPredictiveTextEnabled`가 false이면 `isUndoRedoEnabled` 값과 관계없이 undo/redo 기록과 실행은 비활성화된다.
- undo/redo 기록은 키보드가 disappear 되면 비운다.
- `textWillChange`는 더 이상 무조건 undo/redo 기록을 비우지 않는다. `textInput` 식별자가 바뀌거나, 식별자를 얻을 수 없는 상황에서 before/after context 변화가 커서 이동으로 설명되지 않을 때만 기록을 비운다.
- undo/redo 기록은 편집 직후의 before/after context를 위치 anchor로 저장한다. 사용자가 커서를 이동한 뒤 undo/redo를 누르면 접근 가능한 context 범위 안에서 원래 편집 위치로 커서를 옮긴 뒤 적용한다.
- undo/redo 위치 복원이 실패하면 현재 커서에 잘못 적용하지 않고 history를 무효화한다.
- 한글 조합 중에는 debounce 타이머가 끝나도 pending mutation을 undo stack에 확정하지 않는다. 천지인/나랏글/두벌식 모두 `HangeulKeyboardCoreViewController.composingBuffer`를 공유하므로 같은 hook으로 처리한다.
- 조합 확정 지연 중 조합이 끝나면 `commitDeferredUndoRedoGroupIfNeeded()`로 미뤄둔 pending group을 확정한다.
- 스페이스 입력과 엔터 입력은 pending undo group을 즉시 확정한다.
- 단일 백스페이스 시작 시 기존 pending undo group을 확정한다.
- 한글 키보드는 단일/반복 백스페이스 시작 시 `commitUndoRedoGroupIgnoringCompositionDeferral()`로 조합 지연 여부와 관계없이 기존 pending undo group을 확정한다. 이는 `안녕핫 -> 백스페이스 -> 안녕하 -> undo`가 `안녕하` 전체 삭제가 아니라 방금 삭제를 되돌려 `안녕핫`을 복구하도록 하기 위한 처리다.
- `KeyboardUndoRedoManager`는 순수 입력에서 순수 삭제로, 또는 순수 삭제에서 순수 입력으로 전환될 때 기존 pending group을 확정하고 새 group을 시작한다.
- undo/redo 적용 후 `BaseKeyboardViewController.applyUndoRedoEdit(_:)`는 `undoRedoEditDidApply()` hook을 호출한다.
- `HangeulKeyboardCoreViewController.undoRedoEditDidApply()`는 `clearAllBuffers()`, `processor.reset한글조합()`, `lastInputText = nil`, space/shift 버튼 갱신을 수행한다. undo/redo 뒤 새 한글 입력이 이전 조합 상태와 이어 붙는 것을 막기 위한 처리다.
- 1차 리팩토링 커밋 직후 `git status --short --untracked-files=all` 출력은 비어 있었다.
- Xcode 프로젝트는 `Modules` 폴더를 파일 시스템 동기화 방식으로 참조하지만, 첫 undo/redo 세션 리팩토링은 새 파일 추가 대신 기존 `KeyboardUndoRedoManager.swift` 안에 별도 타입을 추가하는 방식으로 pbxproj 변경 위험을 피한다.
- `KeyboardUndoRedoSession`은 `KeyboardUndoRedoManager.swift` 안에 추가했다. debounce timer, deferred commit, undo/redo 적용 중 상태, text context change 감지를 담당한다.
- `BaseKeyboardViewController.applyUndoRedoEdit(_:)`의 실제 적용 순서는 유지했다. `restoreTextPositionIfPossible`, delete, insert, `undoRedoEditDidApply()`, `updateReturnButtonEnabled()`, `updateSuggestions()` 순서다.
- 1차 리팩토링 커밋은 `ad98772 refactor: #31 - undo redo 세션 상태 분리`이다.
- 2차 리팩토링에서 `SuggestionBarDelegate.suggestionBar(_:didSelectSuggestionAt:)`의 분기를 `handleSelectedTextSuggestion(at:)`, `handleNGramSuggestion(at:)`, `handleCurrentWordConfirmationIfNeeded(at:)`, `handleInputBufferSuggestion(at:)`로 분리했다.
- selected text 또는 n-gram mode에서 후보 선택이 실패할 때 해당 delegate 처리가 바로 끝나는 기존 early return 동작을 유지했다.
- 2차 리팩토링 커밋은 `1656d60 refactor: #31 - suggestion 선택 흐름 분리`이다.
- 3차 리팩토링에서 버튼 action binding을 정리했다. `allKeyboardButtonList`, `primaryAndNumericTextInteractableButtonList`, `makeTextInputAction()`을 추가하고, `setTextInteractableButtonAction()`을 기본/숫자, symbol, tenkey 경로로 분리했다.
- 3차 리팩토링은 control event와 gesture 추가 조건을 바꾸지 않았다. 삭제 버튼은 `touchDown`, 스페이스와 일반 입력 버튼은 `touchUpInside`, symbol keyboard의 자동 primary 전환 action, tenkey의 gesture 미추가 흐름이 유지된다.
- 4차 리팩토링에서 gesture delegate callback을 helper로 분리했다. primary pan 커서 이동, delete pan 삭제/복구, long press 반복 입력 타이머/number input 처리가 별도 private helper로 이동했다.
- 4차 리팩토링은 `primaryButtonPanning`의 `resetInputBuffer()` 호출 위치를 switch 이전으로 유지했다. 예상 밖 direction에서도 기존처럼 reset 후 assertion에 도달하도록 하기 위한 보존이다.
- 4차 리팩토링은 delete pan에서 `updateSuggestions()`, haptic, delete sound, debug log 호출 순서를 유지했다.
- 3차/4차 리팩토링 커밋은 `f2d569d refactor: #31 - 버튼과 제스처 처리 흐름 분리`이다.
- 5차 리팩토링에서 `replaceText` 내부의 문서 조작과 `inputBuffer` 갱신을 `replaceTextInDocument(deleteCount:insert:)`, `replaceInputBufferSuffix(deleteCount:insert:)`로 분리했다.
- `insertText`, `deleteText`, `replaceText`, `resetInputBuffer`는 일반 입력/삭제와 `inputBuffer` 동기화의 기본 경로다.
- 리턴 입력은 `suggestionController.endSentence(inputBuffer:)` 뒤 newline을 직접 삽입하고, undo 기록 확정 뒤 `resetInputBuffer()`를 호출하는 특수 경로다.
- selected text suggestion은 시스템 선택 영역 자동 교체를 유지하려고 `textDocumentProxy.insertText`를 직접 호출하고, undo deleted text를 selected text로 기록하는 특수 경로다.
- undo/redo 적용은 기존 history에 다시 기록되면 안 되므로 wrapper를 타지 않고 `undoRedoSession.performApplyingEdit` 안에서 직접 `textDocumentProxy`를 조작한다.
- 텍스트 프록시 wrapper의 별도 타입 추출은 보류했다. 별도 타입이 `inputBuffer`, `suggestionController`, undo/redo 기록, selected text 자동 교체, return 특수 처리, undo/redo 직접 적용 예외를 모두 알아야 해 책임이 더 커진다고 판단했다.
- `replaceTextInDocument(deleteCount:insert:)`와 `replaceInputBufferSuffix(deleteCount:insert:)`는 `Text Proxy Wrapper Helper Methods` 섹션으로 이동해 wrapper 근처에 모았다.
- 현재까지 후보였던 undo/redo 세션 상태, suggestion 선택 흐름, 버튼 action binding, gesture delegate, text proxy wrapper는 모두 한 차례 정리했다. 추가 타입 추출은 현 단계에서 보류한다.
- 2026-05-22 현재 5차 리팩토링 변경은 아직 커밋하지 않았다. `git status --short --untracked-files=all`의 미커밋 파일은 `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`와 `dev/active/suggestion-bar-undo-redo/` 문서 3종이다.

## Decisions

- 큰 리팩토링보다 작은 선행 리팩토링을 먼저 진행한다.
- 선행 리팩토링은 리턴 버튼 동작을 바꾸지 않고 전용 처리 메서드만 만든다.
- undo/redo 기능은 `KeyboardUndoRedoManager`와 `SuggestionBarView` 우측 버튼 delegate를 통해 추가한다.
- 연속 입력은 pending mutation으로 묶고, 0.8초 debounce 이후 `commitPendingGroup()`으로 확정한다.
- 스페이스/엔터/백스페이스 시작/입력↔삭제 전환은 사용자가 기대하는 편집 경계로 보고 undo group을 나눈다.
- 한글 백스페이스 시작은 조합 중이어도 undo 기록 경계로 본다. 단, 실제 한글 조합/삭제 동작은 유지하고 undo 기록만 이전 입력 group과 분리한다.
- debounce 확정 전에도 `canUndo`가 true가 되어 undo 버튼을 즉시 활성화한다.
- undo/redo 적용 뒤에는 `inputBuffer`를 초기화한다. 이는 외부 텍스트 삭제/복구가 자동완성 학습 버퍼에 섞이는 위험을 줄이기 위한 보수적 선택이다.
- 한글 undo/redo 적용 뒤에는 `composingBuffer`, `committedBuffer`, processor 상태도 초기화한다. 이는 undo/redo 후 새 한글 입력이 이전 조합 버퍼와 합쳐지는 실기기 버그를 막기 위한 결정이다.
- 커서 이동만으로는 undo/redo history를 무효화하지 않는다. 텍스트필드 focus 변경 또는 커서 이동으로 설명되지 않는 외부 context 변경에서만 history를 무효화한다.
- 리턴 버튼 pan undo/redo는 제거한다. 추후 클립보드 내역은 리턴 버튼 위쪽 드래그나 별도 UI로 다시 설계한다.
- 자동완성 바 안의 undo/redo 액션도 후보 텍스트와 동일하게 `SuggestionBarView`의 touch hit-test에서 처리한다.
- 접근성 label/traits는 현재 범위에서 제외한다. 리팩토링 중에도 사용자가 별도 요청하지 않으면 재추가하지 않는다.
- 기능 추가 후 실제 책임이 드러난 상태에서 `BaseKeyboardViewController`의 큰 리팩토링을 진행한다.
- 1차 리팩토링은 `KeyboardUndoRedoSession` 타입을 추가해 debounce timer, deferred commit, undo/redo 적용 중 상태, text context change 감지를 `BaseKeyboardViewController`에서 분리한다.
- 1차 리팩토링에서 실제 텍스트 적용, `undoRedoEditDidApply()`, `updateReturnButtonEnabled()`, `updateSuggestions()` 호출은 `BaseKeyboardViewController`에 남긴다.
- suggestion 선택 흐름, 버튼 action binding, gesture delegate 분리는 1차 리팩토링 검증 뒤 별도 단계로 진행한다.
- undo/redo 세션 리팩토링 뒤 다음 단계는 suggestion 선택 흐름 메서드 분리로 제한한다. 별도 coordinator 추출은 상태 접근 범위가 줄어든 뒤 다시 판단한다.
- suggestion 선택 흐름은 2차 리팩토링에서 별도 coordinator가 아니라 `BaseKeyboardViewController`의 private helper로만 분리한다. delegate에서 접근하던 `textDocumentProxy`, `inputBuffer`, `suggestionController`, undo/redo 기록 호출을 그대로 사용해 동작 변경 위험을 줄이기 위한 결정이다.
- 버튼 action binding 리팩토링은 새 타입 추출 없이 `BaseKeyboardViewController` 내부 helper 정리로 제한한다. 버튼 이벤트 타이밍과 gesture 조건이 실제 키보드 동작에 직접 영향을 주므로, control event 변경 없이 중복 목록 계산과 action 생성만 분리한다.
- gesture delegate 리팩토링은 callback 본문을 private helper로 나누는 수준으로 제한한다. `TextInteractionGestureController`와 `SwitchGestureController`의 delegate protocol, gesture recognizer wiring, 입력/삭제 실행 순서는 바꾸지 않는다.
- 텍스트 프록시 wrapper 리팩토링은 새 타입 추출보다 먼저 현재 예외 경로를 명시한다. selected text, return, undo/redo 경로는 기록과 버퍼 갱신 순서가 달라 일반 wrapper와 합치지 않는다.
- wrapper 별도 타입 추출은 하지 않는다. 현재 구조에서는 helper를 wrapper 섹션 주변에 두는 편이 기능 동일성을 보존하기 쉽다.

## Open Questions

- 추후 클립보드 내역 UI를 리턴 버튼 위쪽 드래그로 열지, 자동완성 바 영역의 별도 컨트롤로 둘지는 아직 확정되지 않았다.
- 실제 텍스트 입력 앱에서 undo/redo 버튼 크기와 자동완성 후보 폭이 손에 맞는지 수동 확인이 필요하다.
- 실제 한글 키보드에서 `안녕핫 -> 백스페이스 -> 안녕하 -> undo -> 안녕핫`과 undo/redo 후 새 한글 입력이 이전 조합과 섞이지 않는지 수동 확인이 필요하다.
- suggestion 선택 흐름의 별도 coordinator 추출은 보류한다. private helper 분리 뒤에도 `inputBuffer`와 `textDocumentProxy` 직접 접근이 남아 있어, coordinator 추출은 텍스트 프록시 wrapper 정리 이후 다시 판단한다.
- 현재 `BaseKeyboardViewController` 리팩토링은 추가 타입 추출 없이 마무리한다. 다음 작업은 현재 미커밋 5차 리팩토링을 커밋하기 전 diff와 검증 범위를 확인하는 것이다.

## Verification Notes

- 선행 리팩토링 후 아래 명령을 실행했다.

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboardCore \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- wrapper helper 섹션 이동 후 작업 범위 파일 기준 `git diff --check`가 통과했다.
- wrapper helper 섹션 이동 후 `SYKeyboardCore` 빌드가 통과했다.

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboardCore \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 첫 실행은 샌드박스에서 Xcode/SwiftPM 캐시와 CoreSimulator 로그 접근 권한 문제로 실패했다.
- 동일 명령을 권한 있는 환경에서 재실행했고 `** BUILD SUCCEEDED **`를 확인했다.
- `KeyboardUndoRedoManagerTests`를 먼저 실패시켰고, `KeyboardUndoRedoManager` 구현 후 같은 테스트가 통과했다.
- 기능 연결 후 아래 명령이 통과했다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardUndoRedoManagerTests
```

- 자동완성 바 버튼 설계로 변경한 뒤 같은 targeted 테스트가 통과했다.
- 자동완성 바 버튼 설계로 변경한 뒤 전체 `SYKeyboard` 테스트도 통과했다.

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

- undo/redo 버튼을 `UIButton`에서 `UIView` 기반 액션 뷰로 바꾼 뒤 `HangeulKeyboard`, `EnglishKeyboard` 빌드가 다시 통과했다.
- 한글 조합 중 undo stack 확정 지연과 cursor 이동 후 위치 anchor 복원 로직을 추가한 뒤 targeted `KeyboardUndoRedoManagerTests`, `HangeulKeyboard`, `EnglishKeyboard` 빌드가 다시 통과했다.
- space/return 즉시 group 확정과 debounce 0.8초 변경 뒤 targeted `KeyboardUndoRedoManagerTests`, `KeyboardTextContextNavigatorTests`, `HangeulKeyboard`, `EnglishKeyboard` 빌드가 통과했다.
- 입력↔삭제 전환 테스트를 먼저 실패시킨 뒤 `KeyboardUndoRedoManager`에 방향 전환 group boundary를 추가했다. 이후 아래 명령이 통과했다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardUndoRedoManagerTests \
  -only-testing:SYKeyboardTests/KeyboardTextContextNavigatorTests
```

- 전체 `git diff --check`는 `SuggestionBarView.swift`의 trailing whitespace 때문에 한 번 실패했고, whitespace 정리 후 관련 파일 범위 `git diff --check`가 통과했다.
- 한글 백스페이스 undo 경계와 undo/redo 후 조합 버퍼 초기화를 추가한 뒤, 샌드박스에서는 SwiftPM/Xcode 캐시와 CoreSimulator 로그 권한 문제로 테스트가 실패했다. 동일 명령을 권한 있는 환경에서 재실행했고 `** TEST SUCCEEDED **`를 확인했다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardUndoRedoManagerTests
```

- 같은 변경 뒤 작업 범위 파일 기준 `git diff --check`가 통과했다.

```sh
git diff --check -- \
  Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift
```

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- undo/redo 세션 상태 분리 후 샌드박스에서 `swiftc -typecheck`와 `xcodebuild`가 Xcode/SwiftPM 캐시 권한 문제로 실패했다.
- 동일 변경을 권한 있는 환경에서 검증했고 `SYKeyboardCore` 빌드가 통과했다.

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboardCore \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- undo/redo 세션 상태 분리 후 targeted undo/redo 테스트가 통과했다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardUndoRedoManagerTests \
  -only-testing:SYKeyboardTests/KeyboardTextContextNavigatorTests
```

- 같은 변경 뒤 전체 `SYKeyboard` 테스트가 통과했다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 작업 범위 파일 기준 `git diff --check`가 통과했다.
- suggestion 선택 흐름 분리 후 작업 범위 파일 기준 `git diff --check`가 통과했다.

```sh
git diff --check -- \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
```

- suggestion 선택 흐름 분리 후 `SYKeyboardCore` 빌드가 통과했다.

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboardCore \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- suggestion 선택 흐름 분리 후 전체 `SYKeyboard` 테스트를 한 번 실행했을 때 Simulator app launch 단계에서 `No such process`로 실패했다. 같은 명령을 재실행했고 `** TEST SUCCEEDED **`를 확인했다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 2차 리팩토링 커밋 전 같은 전체 `SYKeyboard` 테스트를 재실행했고 `** TEST SUCCEEDED **`를 확인했다.
- 버튼 action binding 분리 후 `SYKeyboardCore` 빌드가 통과했다.

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboardCore \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 버튼 action binding 분리 직후 `git diff --check`는 새 helper 사이 빈 줄의 trailing whitespace 때문에 실패했다. whitespace 정리 후 같은 파일 범위 검사가 통과했다.

```sh
git diff --check -- \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
```

- gesture delegate callback 분리 후 작업 범위 파일 기준 `git diff --check`가 통과했다.
- gesture delegate callback 분리 후 `SYKeyboardCore` 빌드가 통과했다.

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboardCore \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 3차/4차 리팩토링 묶음과 문서 갱신 후 전체 `SYKeyboard` 테스트가 통과했다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 5차 리팩토링 후 작업 범위 파일 기준 `git diff --check`가 통과했다.
- 5차 리팩토링 후 `SYKeyboardCore` 빌드가 통과했다.

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboardCore \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```
