# Base Keyboard VC Responsibility Refactor Context

Last Updated: 2026-06-01

## Relevant Files

- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`: 공통 키보드 컨트롤러이며 리팩토링의 중심 파일이다.
- `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`: 한글 조합 버퍼, processor reset, 삭제/undo hook을 가진 subclass다.
- `SYKeyboardTests/Utils/KeyboardControllerSimulator.swift`: `HangeulKeyboardCoreViewController`의 버퍼 관리와 삭제 드래그 흐름을 시스템 의존성 없이 복제하는 테스트 helper다.
- `SYKeyboardTests/Controller/DubeolsikControllerTests.swift`: 두벌식 컨트롤러 레벨 조합/삭제 흐름을 검증한다.
- `SYKeyboardTests/Controller/NaratgeulControllerTests.swift`: 나랏글 컨트롤러 레벨 조합/삭제 흐름을 검증한다.
- `SYKeyboardTests/Controller/CheonjiinControllerTests.swift`: 천지인 컨트롤러 레벨 조합/삭제 흐름을 검증한다.
- `SYKeyboardTests/Controller/HangeulDeleteButtonDragControllerTests.swift`: 삭제 버튼 드래그 복구와 버퍼 동기화 회귀를 검증한다.
- `SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift`: undo/redo 기록 단위와 redo 초기화를 검증한다.
- `SYKeyboardTests/Utils/KeyboardTextContextNavigatorTests.swift`: cursor 이동 후 undo/redo 위치 복원 로직을 검증한다.
- `Modules/SYKeyboardCore/Presentation/Utils/KeyboardUndoRedoManager.swift`: undo/redo manager와 `KeyboardUndoRedoSession`이 있다.
- `Modules/SYKeyboardCore/Presentation/Utils/KeyboardGesturePolicy.swift`: text interaction pan/long press gesture 추가와 long press 동작 선택 조건을 검증 가능한 순수 정책으로 분리한 타입이다.
- `Modules/SYKeyboardCore/Presentation/Utils/KeyboardPeriodShortcutPolicy.swift`: space double tap period shortcut 수행 조건과 삭제 후 방지 상태 전환을 검증 가능한 순수 정책으로 분리한 타입이다.
- `Modules/SYKeyboardCore/Presentation/Utils/KeyboardPresentationStatePolicy.swift`: return button 활성화와 suggestion bar 숨김 조건을 검증 가능한 순수 정책으로 분리한 타입이다.
- `Modules/SYKeyboardCore/Presentation/Utils/KeyboardSymbolInputPolicy.swift`: symbol keyboard 입력 후 기본 키보드 자동 전환과 symbol 입력 상태 표시 조건을 검증 가능한 순수 정책으로 분리한 타입이다.
- `Modules/SYKeyboardCore/Presentation/Utils/KeyboardHeightPolicy.swift`: portrait/landscape 및 suggestion bar 표시 여부에 따른 keyboard view와 hstack 높이 계산을 검증 가능한 순수 정책으로 분리한 타입이다.
- `SYKeyboardTests/Utils/KeyboardHeightPolicyTests.swift`: keyboard height 계산 정책의 portrait/landscape, suggestion bar 표시/숨김 케이스를 검증한다.
- `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/TextInteractionGestureController.swift`: text interaction pan/long press gesture handling을 담당한다.
- `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/SwitchGestureController.swift`: keyboard switch/one-handed mode gesture handling을 담당한다.
- `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift`: suggestion 표시와 undo/redo action touch handling을 담당한다.
- `dev/active/suggestion-bar-undo-redo/`: undo/redo 기능 추가와 1차 리팩토링 기록이 남아 있는 이전 active task 문서다.

## Facts Checked

- `git status --short --untracked-files=all`는 문서 생성 전 비어 있었다.
- 2026-05-22 작업 재개 시점의 `git status --short --untracked-files=all`는 `dev/active/base-keyboard-vc-responsibility-refactor/` 문서 3종만 untracked로 표시했다.
- 작업 재개 시점의 브랜치는 `feat/#31-undo-redo`이며, 일반 checkout(`git rev-parse --git-dir`와 `git rev-parse --git-common-dir`가 모두 `.git`)이다.
- 최근 리팩토링 커밋은 아래 순서로 존재한다.
  - `ad98772 refactor: #31 - undo redo 세션 상태 분리`
  - `1656d60 refactor: #31 - suggestion 선택 흐름 분리`
  - `f2d569d refactor: #31 - 버튼과 제스처 처리 흐름 분리`
  - `16fbc8c refactor: #31 - 텍스트 치환 처리 단계 분리`
  - `9aa9577 refactor: #31 - 텍스트 프록시 래퍼 정리`
- `KeyboardControllerSimulator.swift` 파일 주석은 컨트롤러의 해당 로직을 수정할 경우 이 파일도 함께 수정하라고 명시한다.
- `KeyboardControllerSimulator.swift`는 `committedBuffer`, `composingBuffer`, `protectedCommittedCount`, `lastInputText`, `isPulledFromProtected`, `tempDeletedCharacters`, `shouldSkipNextDeletePanRestore`, `nextDeletePanRestoreReplacement`, `suggestionCurrentWord`를 직접 관리한다.
- `KeyboardControllerSimulator.swift`는 `deleteButtonTouchDown`, `dragDeleteLeft`, `dragRestoreRight`, `finishRepeatDelete`로 삭제 버튼 touchDown/drag/반복 삭제 후처리 흐름을 시뮬레이션한다.
- 이전 리팩토링은 주로 helper 추출과 `KeyboardUndoRedoSession` 추가에 머물렀다. `BaseKeyboardViewController`의 구조적 책임은 여전히 크다.
- 사용자는 앞으로 키보드 코드 전반의 품질 평가를 받은 뒤 남은 리팩토링 계획을 수립할 예정이다.
- 사용자는 기능이 임의로 수정/변경되면 안 된다고 재강조했다.
- `BaseKeyboardViewController.swift`는 1,459줄이며, `HangeulKeyboardCoreViewController.swift`는 689줄, `KeyboardControllerSimulator.swift`는 413줄이다.
- `BaseKeyboardViewController`의 공개 override/hook은 lifecycle, 키보드 타입 갱신, text interaction 전후 hook, 입력/삭제/반복 입력, 삭제 드래그, undo/redo 지연 확정 hook을 모두 포함한다.
- `BaseKeyboardViewController`의 private helper는 action binding, gesture forwarding, layout/update, text interaction dispatch, undo/redo 적용, suggestion selection, repeat timer까지 포함한다.
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/`에는 현재 `BaseKeyboardViewController.swift`만 있다.
- `SYKeyboard.xcodeproj/project.pbxproj`의 `Modules` synchronized root는 Core 파일을 target별 `membershipExceptions`에 나열한다. 새 Core Swift 파일은 `SYKeyboard` target 예외와 `SYKeyboardCore` target 예외 양쪽에 추가해야 한다.
- 2026-06-01 작업 재개 시점의 `git status --short --untracked-files=all`는 비어 있었다.
- 2026-06-01 작업 중 uncommitted 변경 파일은 `BaseKeyboardViewController.swift`, `SYKeyboard.xcodeproj/project.pbxproj`, `KeyboardHeightPolicy.swift`, `KeyboardHeightPolicyTests.swift`, active task 문서 3종이다.
- 2026-06-01 현재 최근 리팩토링 커밋은 아래 순서로 확인했다.
  - `e1e2fb8d refactor: #31 - Undo/Redo 코너값 계산 가독성 개선`
  - `4935f547 refactor: #31 - 심볼 입력 전환 정책 분리`
  - `41d54c0a refactor: #31 - 마침표 단축 입력 정책 분리`
  - `8e97c2a5 refactor: #31 - 키보드 정책 조건 분리`
  - `b1566957 refactor: #31 - 텍스트 프록시 래퍼 정리`

## Decisions

- 새 세션에서는 바로 대규모 추출을 시작하지 않는다. 먼저 품질 평가 결과와 현재 테스트 구조를 확인한다.
- `KeyboardControllerSimulator.swift`는 향후 한글 controller 책임 분리 시 반드시 함께 갱신할 대상이다.
- SOLID/OOP는 엄격한 규칙이 아니라 유지보수성과 확장성 판단 기준으로 사용한다.
- `BaseKeyboardViewController`의 책임 분리는 작은 커밋 단위로 진행하고, 각 커밋은 동작 변경 없는 구조 변경이어야 한다.
- `textDocumentProxy` wrapper는 selected text, return, undo/redo 예외 경로가 있어 별도 타입 추출을 즉시 진행하지 않는다.
- 한글 조합 정책은 공통 Base로 끌어올리지 않는다. 입력기별 조합/삭제 특성은 `HangeulKeyboardCoreViewController`와 processor 쪽 책임으로 유지한다.
- 접근성 label/traits는 undo/redo 작업 중 의도적으로 제외한 상태이므로, 리팩토링 중 되살리지 않는다.
- 현재 checkout이 이미 `feat/#31-undo-redo` 작업 브랜치이고 active 문서가 같은 workspace에 있으므로, 별도 worktree를 만들지 않고 현재 workspace에서 진행한다.
- 첫 코드 변경은 동작 변경 없는 책임 분리만 허용한다. action binding은 Swift 접근 제어 때문에 단순 파일 분리만으로는 어렵고, 새 binder 타입을 만들면 closure/dependency가 많아질 수 있으므로 먼저 더 작은 update/lifecycle helper 분리 가능성을 확인한다.
- 첫 코드 변경으로 `KeyboardPresentationStatePolicy`를 추가했다. return button 활성화와 suggestion bar 숨김 조건은 순수 정책으로 검증하고, Base는 UIKit view 반영만 담당하도록 좁혔다.
- `extractLastWord(from:)`는 `rg`로 참조가 없음을 확인한 뒤 제거했다. 현재 suggestion 학습/선택 흐름은 `SuggestionController`와 `inputBuffer` 직접 경로를 사용한다.
- 두 번째 코드 변경으로 `KeyboardGesturePolicy`를 추가했다. text interaction pan/long press gesture 추가 조건과 long press 반복 입력/숫자 입력 분기 조건은 순수 정책으로 검증하고, Base는 gesture 등록과 controller 호출 순서를 유지한다.
- `setKeyboardHeight()`의 suggestion bar 표시 조건도 `KeyboardPresentationStatePolicy.shouldHideSuggestionBar(...)`를 재사용하도록 정리했다. 높이 계산 순서와 constraint 적용 순서는 유지했다.
- 세 번째 코드 변경으로 `KeyboardPeriodShortcutPolicy`를 추가했다. space double tap에서 trailing space를 period로 치환할지, 삭제 후 다음 shortcut을 방지/해제할지는 순수 정책으로 검증하고, Base는 기존 `touchDownRepeat` action과 `replaceText(deleteCount:insert:)` 호출 순서를 유지한다.
- 네 번째 코드 변경으로 `KeyboardSymbolInputPolicy`를 추가했다. symbol keyboard의 작은따옴표, space/return, 일반 symbol key 입력 후 상태 판단은 순수 정책으로 검증하고, Base는 기존 `touchUpInside` action 등록 순서를 유지한다.
- 다섯 번째 코드 변경으로 `KeyboardHeightPolicy`를 추가했다. `setKeyboardHeight()`의 orientation/suggestion bar 기반 높이 계산은 순수 정책으로 검증하고, Base는 기존처럼 window orientation 확인과 constraint 생성/갱신만 담당한다.
- 2026-06-01 `KeyboardHeightPolicyTests` 첫 GREEN 시도는 테스트 파일의 `CGFloat` 리터럴에 `CoreFoundation` import가 없어 컴파일 실패했다. 원인은 테스트 코드 import 누락이었고, `CoreFoundation` import 추가 후 같은 targeted 테스트가 통과했다.

## Quality Assessment - 2026-05-22

| Area | Current Responsibility | Assessment | Next Action |
| --- | --- | --- | --- |
| Lifecycle/context change | `viewDidLoad`, `viewWillAppear`, `textWillChange`, `textDidChange`, `viewWillDisappear`에서 buffer, undo/redo, suggestion, layout 갱신을 직접 호출한다. | Base의 실제 extension 경계라 완전 분리는 부적절하다. 다만 context change 시 호출 순서를 문서화하고 helper 이름을 정리할 수 있다. | 호출 순서 변경 없이 유지. |
| Keyboard layout/update | `updateShowingKeyboard`, `updateReturnButtonType`, `updateReturnButtonEnabled`, `updateSuggestionBarHidden`, `setKeyboardHeight`가 같은 파일에 있다. | UI 상태 갱신 책임으로 응집도는 높지만 Base 파일을 크게 만든다. 외부 의존성은 view와 settings 중심이라 비교적 안전한 분리 후보이다. `KeyboardPresentationStatePolicy`와 `KeyboardHeightPolicy`로 순수 조건/계산 일부는 분리했다. | UIKit view 반영 순서는 유지하고, 추가 추출은 action binding 감사 후 판단한다. |
| Action binding | `setTextInteractableButtonAction`, `addInputAction...`, `setSwitchButtonAction`, gesture 추가가 button/control event 순서를 직접 관리한다. | 분리 효과는 크지만 `currentKeyboard`, `isSymbolInput`, period shortcut, gesture controller, selector target 등 결합이 많다. | 별도 타입 추출 전 private helper 이름 정리 또는 작은 binder 설계가 필요하다. |
| Text interaction dispatch | `performTextInteraction`, `performRepeatTextInteraction`, delete pan, repeat timer가 입력 이벤트의 핵심 순서를 담당한다. | 한글 subclass hook과 직접 연결되므로 위험도가 높다. | action/layout 정리 후, 테스트 기준을 먼저 고정하고 진행한다. |
| Text proxy/input buffer | `insertText`, `deleteText`, `replaceText`, `resetInputBuffer`가 suggestion/undo와 함께 움직인다. | 단순 adapter 추출 시 예외 경로가 늘어날 가능성이 높다. | 현 단계 보류. 직접 `textDocumentProxy` 사용 예외만 계속 추적한다. |
| Suggestion selection | 선택 텍스트, n-gram, 현재 단어 확정, inputBuffer 후보 선택이 helper로 나뉘어 있다. | 이미 1차 분리는 되어 있으나 Base의 `inputBuffer`와 proxy에 강하게 묶여 있다. | 별도 coordinator는 보류, helper별 테스트 가능성만 검토한다. |
| Undo/redo | `KeyboardUndoRedoSession`은 분리되어 있으나 Base가 적용, context 복원, controls 갱신을 맡는다. | session 분리는 적절하다. UI/proxy 적용부는 Base에 남는 것이 자연스럽다. | 유지. |
| Hangeul buffers | subclass가 조합/확정/protected buffer와 삭제 드래그 상태를 관리한다. | Base로 올리면 입력기별 정책을 침범한다. | Base 리팩토링과 분리하고 simulator 동기화표를 별도 관리한다. |

## Hangeul Controller / Simulator Sync Points

| Controller Method/State | Simulator Counterpart | Sync Rule |
| --- | --- | --- |
| `committedBuffer`, `composingBuffer` | same names | 한글 조합/삭제 결과 변경 시 양쪽 기대 상태를 함께 확인한다. |
| `protectedCommittedCount` | same name | 스페이스/리턴/확정 보호 경계 변경 시 controller 테스트를 우선 갱신한다. |
| `isPulledFromProtected` | same name | protected 글자를 composing으로 끌어오는 삭제 경계 변경 시 함께 갱신한다. |
| `deleteBackward`, `repeatDeleteBackward` | `delete`, `repeatDelete` | 반복 삭제 후 processor reset/조합 복구 순서를 맞춘다. |
| `deleteButtonPanDeleteText` | `dragDeleteLeft` | touchDown 선삭제 후 첫 pan 복구 중복 방지 상태를 함께 확인한다. |
| `deleteButtonPanRestoreText` | `dragRestoreRight` | 복구된 글자가 composing/committed/current word에 반영되는지 함께 확인한다. |
| `applyCompositionResult` | same name | `replaceText(deleteCount:insert:)` 기준의 삭제/삽입 개수를 동일하게 유지한다. |

## Open Questions

- 품질 평가는 현재 Codex 코드 리뷰 형식으로 1차 진행했다. 필요하면 별도 사람 리뷰나 정적 분석을 추가한다.
- `BaseKeyboardViewController`에서 가장 먼저 분리할 책임은 keyboard layout/update helper로 잡았고, 현재는 return/suggestion/gesture/period/symbol/height 정책까지 작은 순수 타입으로 분리했다.
- `KeyboardControllerSimulator.swift`가 실제 `HangeulKeyboardCoreViewController`와 얼마나 중복되는지 확인했으며, 현 단계에서는 중복 제거보다 동기화표를 유지하는 쪽이 안전하다.
- 테스트 helper를 더 실제 controller 로직에 가깝게 만들지, 아니면 순수 domain/service 추출 후 테스트가 그 타입을 직접 검증하게 할지는 미정이다.
- `SuggestionBarView`와 suggestion selection coordinator를 분리할지 여부는 selected text / n-gram / inputBuffer coupling을 더 확인한 뒤 판단한다.

## Handoff Notes

- 다음 세션 첫 작업은 action binding 감사표 작성이다. `touchDown`, `touchUpInside`, `touchDownRepeat`, long press, pan gesture의 등록 순서와 조건을 버튼 타입별로 정리한 뒤 추출 여부를 판단한다.
- 리팩토링 계획을 세울 때 `KeyboardControllerSimulator.swift`를 별도 테스트 debt로 취급하지 말고 핵심 동기화 대상으로 포함한다.
- 새 타입을 만들기 전에 해당 타입이 알아야 하는 상태를 목록화한다. `textDocumentProxy`, `inputBuffer`, `suggestionController`, `undoRedoSession`, `keyboardSettingsManager`, subclass hook 중 3개 이상을 알아야 하면 추출을 보류한다.
- 기능 변경이 필요해 보이면 리팩토링이 아니라 별도 feature/fix로 문서화하고 사용자 확인을 받는다.
- 품질 평가 결과가 나오기 전에는 큰 이동, 파일 분리, protocol 추가를 시작하지 않는다.

## Verification Notes

- 이 문서는 handoff 목적의 문서 작업이다. 코드 변경은 하지 않았다.
- 2026-05-22 `KeyboardPresentationStatePolicyTests` RED:
  - 첫 sandbox 실행은 SwiftPM/Xcode 캐시 및 CoreSimulator 권한 문제로 실패했다.
  - 권한 있는 환경에서 `KeyboardPresentationStatePolicy` 미정의 컴파일 실패를 확인했다.
- 2026-05-22 `KeyboardPresentationStatePolicyTests` GREEN:
  - `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests`
  - 결과: `TEST SUCCEEDED`.
- 2026-05-22 `KeyboardGesturePolicyTests` RED:
  - 권한 있는 환경에서 `KeyboardGesturePolicy` 미정의 컴파일 실패를 확인했다.
- 2026-05-22 `KeyboardGesturePolicyTests` GREEN:
  - `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/KeyboardGesturePolicyTests`
  - 결과: `TEST SUCCEEDED`.
- 2026-05-22 정책 테스트 묶음 확인:
  - `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests -only-testing:SYKeyboardTests/KeyboardGesturePolicyTests`
  - 결과: `TEST SUCCEEDED`.
- 2026-05-22 `KeyboardPeriodShortcutPolicyTests` RED:
  - 권한 있는 환경에서 `KeyboardPeriodShortcutPolicy` 미정의 컴파일 실패를 확인했다.
- 2026-05-22 `KeyboardPeriodShortcutPolicyTests` GREEN:
  - `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/KeyboardPeriodShortcutPolicyTests`
  - 결과: `TEST SUCCEEDED`.
- 2026-05-22 전체 `SYKeyboard` 테스트 확인:
  - `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`
  - 결과: `TEST SUCCEEDED`.
- 2026-05-22 `KeyboardPeriodShortcutPolicy` 연결 후 전체 `SYKeyboard` 테스트 확인:
  - `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`
  - 결과: `TEST SUCCEEDED`.
- 2026-05-22 `KeyboardSymbolInputPolicyTests` RED:
  - 권한 있는 환경에서 `KeyboardSymbolInputPolicy` 미정의 컴파일 실패를 확인했다.
- 2026-05-22 `KeyboardSymbolInputPolicyTests` GREEN:
  - `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/KeyboardSymbolInputPolicyTests`
  - 결과: `TEST SUCCEEDED`.
- 2026-05-22 `KeyboardSymbolInputPolicy` 연결 후 전체 `SYKeyboard` 테스트 확인:
  - `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`
  - 결과: `TEST SUCCEEDED`.
- 2026-06-01 `KeyboardHeightPolicyTests` RED:
  - 첫 sandbox 실행은 SwiftPM/Xcode 캐시 및 CoreSimulator 권한 문제로 실패했다.
  - 권한 있는 환경에서 `KeyboardHeightPolicy` 미정의 컴파일 실패를 확인했다.
- 2026-06-01 `KeyboardHeightPolicyTests` GREEN:
  - `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/KeyboardHeightPolicyTests`
  - 첫 GREEN 시도는 테스트의 `CoreFoundation` import 누락으로 실패했다.
  - import 수정 후 결과: `TEST SUCCEEDED`.
- 2026-06-01 정책 테스트 묶음 확인:
  - `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests -only-testing:SYKeyboardTests/KeyboardGesturePolicyTests -only-testing:SYKeyboardTests/KeyboardPeriodShortcutPolicyTests -only-testing:SYKeyboardTests/KeyboardSymbolInputPolicyTests -only-testing:SYKeyboardTests/KeyboardHeightPolicyTests`
  - 결과: `TEST SUCCEEDED`.
- 2026-06-01 전체 `SYKeyboard` 테스트 확인:
  - `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`
  - 결과: `TEST SUCCEEDED`.
- 변경 후 실행할 확인:

```sh
git diff --check -- dev/active/base-keyboard-vc-responsibility-refactor
git status --short --untracked-files=all
```
