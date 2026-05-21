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

- `git branch --show-current` 결과는 `feat/#31-return-button-undo-redo`이다.
- `BaseKeyboardViewController.swift`는 `wc -l` 기준 1159줄이다.
- 현재 일반 리턴 입력은 `performTextInteraction(for:)`의 `.returnButton` 분기에서 `insertReturnText()`를 직접 호출한다.
- 현재 반복 리턴 입력은 `performRepeatTextInteraction(for:)`의 `.returnButton` 분기에서 `insertReturnText()` 호출 후 `button.playFeedback()`을 실행한다.
- 현재 `insertReturnText()`는 preview에서는 리턴하고, 실제 입력에서는 undo/redo 기록, `suggestionController.endSentence(inputBuffer:)`, `textDocumentProxy.insertText("\n")`, `resetInputBuffer()`, `suggestionController.clearReplacementHistory()`를 수행한다.
- 자동완성 바는 `isPredictiveTextEnabled`가 켜져 있고 현재 키보드가 tenKey가 아니며 host가 autocorrection을 금지하지 않을 때만 표시된다.
- undo/redo 버튼은 자동완성 바가 표시되고 `isUndoRedoEnabled`가 켜져 있을 때만 표시된다.
- undo/redo 버튼은 `UIButton`이 아니라 `SuggestionActionButtonView` 기반 `UIView`다. 자동완성 후보와 같은 직접 highlight 처리 방식을 유지해 `UIButton` 기본 탭 애니메이션을 피한다.
- `isPredictiveTextEnabled`가 false이면 `isUndoRedoEnabled` 값과 관계없이 undo/redo 기록과 실행은 비활성화된다.
- undo/redo 기록은 키보드가 disappear 되면 비운다.
- `textWillChange`는 더 이상 무조건 undo/redo 기록을 비우지 않는다. `textInput` 식별자가 바뀌거나, 식별자를 얻을 수 없는 상황에서 before/after context 변화가 커서 이동으로 설명되지 않을 때만 기록을 비운다.
- undo/redo 기록은 편집 직후의 before/after context를 위치 anchor로 저장한다. 사용자가 커서를 이동한 뒤 undo/redo를 누르면 접근 가능한 context 범위 안에서 원래 편집 위치로 커서를 옮긴 뒤 적용한다.
- undo/redo 위치 복원이 실패하면 현재 커서에 잘못 적용하지 않고 history를 무효화한다.
- 한글 조합 중에는 debounce 타이머가 끝나도 pending mutation을 undo stack에 확정하지 않는다. 천지인/나랏글/두벌식 모두 `HangeulKeyboardCoreViewController.composingBuffer`를 공유하므로 같은 hook으로 처리한다.
- 조합 확정 지연 중 조합이 끝나면 `commitDeferredUndoRedoGroupIfNeeded()`로 미뤄둔 pending group을 확정한다.
- 최근 작업 중 `git status --short`에는 설정 키 변경, `BaseKeyboardViewController`, `SuggestionBarView`, undo/redo manager/test, 작업 문서 변경이 표시된다.

## Decisions

- 큰 리팩토링보다 작은 선행 리팩토링을 먼저 진행한다.
- 선행 리팩토링은 리턴 버튼 동작을 바꾸지 않고 전용 처리 메서드만 만든다.
- undo/redo 기능은 `KeyboardUndoRedoManager`와 `SuggestionBarView` 우측 버튼 delegate를 통해 추가한다.
- 연속 입력은 pending mutation으로 묶고, 1초 debounce 이후 `commitPendingGroup()`으로 확정한다.
- debounce 확정 전에도 `canUndo`가 true가 되어 undo 버튼을 즉시 활성화한다.
- undo/redo 적용 뒤에는 `inputBuffer`를 초기화한다. 이는 외부 텍스트 삭제/복구가 자동완성 학습 버퍼에 섞이는 위험을 줄이기 위한 보수적 선택이다.
- 커서 이동만으로는 undo/redo history를 무효화하지 않는다. 텍스트필드 focus 변경 또는 커서 이동으로 설명되지 않는 외부 context 변경에서만 history를 무효화한다.
- 리턴 버튼 pan undo/redo는 제거한다. 추후 클립보드 내역은 리턴 버튼 위쪽 드래그나 별도 UI로 다시 설계한다.
- 자동완성 바 안의 undo/redo 액션도 후보 텍스트와 동일하게 `SuggestionBarView`의 touch hit-test에서 처리한다.
- 기능 추가 후 실제 책임이 드러난 상태에서 `BaseKeyboardViewController`의 큰 리팩토링을 진행한다.

## Open Questions

- 추후 클립보드 내역 UI를 리턴 버튼 위쪽 드래그로 열지, 자동완성 바 영역의 별도 컨트롤로 둘지는 아직 확정되지 않았다.
- 실제 텍스트 입력 앱에서 undo/redo 버튼 크기와 자동완성 후보 폭이 손에 맞는지 수동 확인이 필요하다.

## Verification Notes

- 선행 리팩토링 후 아래 명령을 실행했다.

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

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```
