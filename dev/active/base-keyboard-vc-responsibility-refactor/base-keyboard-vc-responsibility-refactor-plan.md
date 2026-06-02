# Base Keyboard VC Responsibility Refactor Plan

Last Updated: 2026-06-02

## Goal

- `BaseKeyboardViewController`의 책임을 유지보수성과 확장성에 무리가 없는 선에서 분리하고, 기능 동작은 임의로 변경하지 않는다.
- 실제 코드 품질 평가를 먼저 받은 뒤, 남은 리팩토링 범위와 우선순위를 다시 수립한다.

## Current State

- 브랜치명은 `feat/#31-undo-redo`이다.
- 이전 세션에서 undo/redo 기능 추가 후 `BaseKeyboardViewController`를 작은 단위로 리팩토링했다.
- 최근 리팩토링 커밋:
  - `e1e2fb8d refactor: #31 - Undo/Redo 코너값 계산 가독성 개선`
  - `4935f547 refactor: #31 - 심볼 입력 전환 정책 분리`
  - `41d54c0a refactor: #31 - 마침표 단축 입력 정책 분리`
  - `8e97c2a5 refactor: #31 - 키보드 정책 조건 분리`
  - `b1566957 refactor: #31 - 텍스트 프록시 래퍼 정리`
  - `b6bf173d refactor: #31 - 텍스트 치환 처리 단계 분리`
  - `f1bb9e3f refactor: #31 - 버튼과 제스처 처리 흐름 분리`
  - `a328efba refactor: #31 - suggestion 선택 흐름 분리`
  - `6329d808 refactor: #31 - undo redo 세션 상태 분리`
- 현재까지의 리팩토링은 큰 메서드에 뭉쳐 있던 코드를 private helper와 `KeyboardUndoRedoSession`으로 나누는 수준이다.
- 2026-05-22 작업 재개 후 `KeyboardPresentationStatePolicy`를 추가하여 return button 활성화 여부와 suggestion bar 숨김 여부의 순수 판단 로직을 `BaseKeyboardViewController`에서 분리했다.
- 2026-05-22 작업 재개 후 `KeyboardGesturePolicy`를 추가하여 text interaction gesture 추가 조건과 long press 분기 조건의 순수 판단 로직을 `BaseKeyboardViewController`에서 분리했다.
- 2026-05-22 작업 재개 후 `KeyboardPeriodShortcutPolicy`를 추가하여 period shortcut 수행 조건과 삭제 후 방지 상태 전환 로직을 `BaseKeyboardViewController`에서 분리했다.
- 2026-05-22 작업 재개 후 `KeyboardSymbolInputPolicy`를 추가하여 symbol keyboard 입력 후 기본 키보드 자동 전환과 symbol 입력 상태 표시 조건을 `BaseKeyboardViewController`에서 분리했다.
- 2026-06-01 작업 재개 후 `KeyboardHeightPolicy`를 추가하여 portrait/landscape 및 suggestion bar 표시 여부에 따른 순수 높이 계산 로직을 `BaseKeyboardViewController`에서 분리했다.
- 2026-06-01 `KeyboardHeightPolicy` 작업은 `1acbad42 refactor: #31 - 키보드 높이 계산 정책 분리`로 커밋했다.
- 2026-06-01 action binding 감사표를 작성해 Base의 feedback/input/switch/release 등록 순서, symbol extra action, switch gesture, view-owned shift action의 경계를 고정했다.
- 2026-06-01 감사표 기준으로 text interaction gesture 등록 대상 판단을 `KeyboardGesturePolicy`로 분리했다.
- 2026-06-01 text interaction 실행 중 보조키 입력, 단일 삭제 임시 저장/undo 기록 문자, 반복 삭제 수행 조건을 `KeyboardTextInteractionPolicy`로 분리했다.
- 2026-06-01 suggestion 선택 흐름 중 n-gram 후보 앞 공백 삽입 여부와 현재 단어 확정용 마지막 단어 추출을 `KeyboardSuggestionSelectionPolicy`로 분리했다.
- 2026-06-02 suggestion 갱신 흐름 중 자동완성 설정, selected text, whitespace 포함 선택 텍스트, `inputBuffer` fallback 판단을 `KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(...)`으로 분리했다.
- 2026-06-02 undo/redo controls 표시 여부 판단을 `KeyboardPresentationStatePolicy.shouldShowUndoRedoControls(...)`로 분리했다.
- 2026-06-02 undo/redo 기능 활성화 설정 조합 판단을 `KeyboardPresentationStatePolicy.isUndoRedoFeatureAvailable(...)`로 분리했다.
- `BaseKeyboardViewController`는 여전히 아래 책임을 함께 가진다.
  - 키보드 view wiring과 height 갱신
  - 버튼 action binding과 gesture recognizer binding
  - text interaction 실행
  - `textDocumentProxy` 조작과 `inputBuffer` 동기화
  - suggestion 표시/선택/학습 연결
  - undo/redo session 연결
  - extension lifecycle, focus/context change 대응
- 관련 파일:
  - `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`
  - `SYKeyboardTests/Utils/KeyboardControllerSimulator.swift`
  - `SYKeyboardTests/Controller/*ControllerTests.swift`
  - `SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift`
  - `SYKeyboardTests/Utils/KeyboardTextContextNavigatorTests.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/KeyboardUndoRedoManager.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/KeyboardGesturePolicy.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/KeyboardPeriodShortcutPolicy.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/KeyboardPresentationStatePolicy.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/KeyboardSymbolInputPolicy.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/KeyboardHeightPolicy.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/KeyboardTextInteractionPolicy.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/KeyboardSuggestionSelectionPolicy.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/TextInteractionGestureController.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/SwitchGestureController.swift`
  - `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift`

## Approach

1. 품질 평가를 먼저 진행한다.
   - `BaseKeyboardViewController`, 한글 subclass, gesture controller, suggestion, undo/redo, 테스트 헬퍼를 함께 본다.
   - 단순 라인 수보다 변경 이유, 책임 경계, 테스트 가능성, extension 런타임 비용을 기준으로 평가한다.
   - SOLID/OOP 원칙은 목적이 아니라 판단 도구로 사용한다. 기능 동일성과 단순성을 해치는 추출은 하지 않는다.
2. 테스트 코드 동기화 범위를 먼저 정한다.
   - `KeyboardControllerSimulator.swift`는 `HangeulKeyboardCoreViewController`의 버퍼 관리와 삭제 드래그 흐름을 의도적으로 복제한다.
   - 한글 조합/삭제/복구/undo 관련 컨트롤러 로직을 옮기거나 이름을 바꾸면 simulator도 함께 갱신한다.
   - simulator가 실제 컨트롤러와 계속 같은 규칙을 유지하도록, 변경 PR/커밋마다 대응 여부를 체크한다.
3. 책임 분리 후보를 평가한다.
   - 후보 A: text editing/input buffer adapter
     - `insertText`, `deleteText`, `replaceText`, `resetInputBuffer`와 특수 예외 경로를 더 명확히 한다.
     - selected text, return, undo/redo 직접 적용 예외 때문에 별도 타입 추출은 신중히 판단한다.
   - 후보 B: keyboard action binder
     - 버튼 목록, input action 생성, symbol 자동 전환, period shortcut binding을 다룬다.
     - control event 순서가 바뀌면 회귀 위험이 크므로 동작 보존 테스트/빌드가 필요하다.
     - 2026-06-01 감사 결과 별도 binder는 `buttonStateController`, settings, keyboard setter, gesture controller, proxy, symbol/period 상태, selector target까지 알아야 하므로 즉시 추출하지 않는다. 먼저 Base 내부 action binding 구역의 이름/순서 가독성 개선이나 순수 조건 분리 후보만 고른다.
     - 첫 후속 변경으로 text interaction gesture 등록 대상 조건만 기존 `KeyboardGesturePolicy`에 포함했다.
  - 후보 C: text interaction coordinator
     - `performTextInteraction`, `performRepeatTextInteraction`, delete/space/return 경계 처리를 다룬다.
     - 한글 subclass override hook과 충돌하지 않아야 한다.
     - 2026-06-01에는 coordinator 추출 대신 보조키/삭제/반복 삭제/undo 기록 문자열의 순수 판단만 `KeyboardTextInteractionPolicy`로 분리했다.
   - 후보 D: suggestion interaction coordinator
     - selected text, n-gram, current word confirmation, input buffer suggestion 경로를 다룬다.
     - `textDocumentProxy`와 `inputBuffer` 직접 접근을 줄일 수 있을 때만 추출한다.
     - 2026-06-01에는 coordinator 추출 대신 n-gram 앞 공백과 현재 단어 확정용 단어 추출의 순수 판단만 `KeyboardSuggestionSelectionPolicy`로 분리했다.
   - 후보 E: keyboard layout/lifecycle updater
     - suggestion bar hidden state, keyboard height, return button state, one-handed mode update를 다룬다.
     - UIKit extension lifecycle과 orientation 제약을 유지한다.
4. 설계 원칙을 느슨하지만 일관되게 적용한다.
   - Single Responsibility: 새 타입은 한 종류의 변경 이유만 가져야 한다.
   - Open/Closed: 입력기별 조합 정책은 subclass hook으로 열어두되, 공통 Base가 한글 세부 규칙을 알지 않게 한다.
   - Liskov: `HangeulKeyboardCoreViewController`가 Base hook을 override할 때 Base의 호출 순서를 깨지 않아야 한다.
   - Interface Segregation: 거대한 delegate/protocol을 만들지 않는다. 필요한 callback만 둔다.
   - Dependency Inversion: UIKit 시스템 객체를 억지로 숨기지 않는다. 테스트 가능한 순수 로직부터 분리한다.
5. 작은 단위로만 구현한다.
   - 각 커밋은 동작 변경 없는 구조 변경 하나만 담는다.
   - 추출 후에도 call order, control event, feedback, suggestion update, undo boundary를 diff로 확인한다.
   - 기능 변경이 필요해 보이면 리팩토링 커밋에 섞지 말고 사용자 확인 후 별도 작업으로 분리한다.

## Risks

- `BaseKeyboardViewController`는 iOS keyboard extension의 런타임 경계라 무리한 추상화가 입력 지연이나 lifecycle 회귀로 이어질 수 있다.
- `textDocumentProxy`는 UIKit 시스템 객체라 테스트 double이 어렵다. 억지 adapter 추출은 오히려 책임을 흐릴 수 있다.
- `KeyboardControllerSimulator.swift`는 실제 컨트롤러 로직을 복제하므로, 컨트롤러 변경 후 테스트 helper가 뒤처지면 테스트가 거짓 안정감을 줄 수 있다.
- 한글 입력/삭제/조합, 삭제 버튼 드래그 복구, undo/redo 적용 후 조합 reset은 회귀 위험이 높다.
- selected text 자동 교체, return 입력, undo/redo 직접 적용은 일반 text wrapper와 다른 예외 경로다. 통합 추상화 시 기능이 바뀔 수 있다.
- 버튼 action과 gesture recognizer는 `touchDown`, `touchUpInside`, long press, pan 순서가 중요하다.
- delete 입력은 `.touchDown`, symbol extra action은 base input 뒤 `.touchUpInside`, switch pan은 overlay가 없을 때 synthetic `.touchUpInside`를 만들 수 있다. action binding을 옮길 때 이 세 가지를 별도 체크포인트로 둔다.
- 접근성 label/traits는 이전 작업에서 의도적으로 제외했다. 별도 요청 없이 되살리지 않는다.

## Verification

- 2026-05-22 `KeyboardPresentationStatePolicy` 추가 전 RED 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests
```

결과: 권한 있는 환경에서 실행했으며 `KeyboardPresentationStatePolicy` 미정의로 실패했다.

- 2026-05-22 `KeyboardPresentationStatePolicy` 추가 후 GREEN 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests
```

결과: `TEST SUCCEEDED`.

- 2026-05-22 `KeyboardGesturePolicy` 추가 전 RED 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardGesturePolicyTests
```

결과: 권한 있는 환경에서 실행했으며 `KeyboardGesturePolicy` 미정의로 실패했다.

- 2026-05-22 `KeyboardGesturePolicy` 추가 후 GREEN 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardGesturePolicyTests
```

결과: `TEST SUCCEEDED`.

- 2026-05-22 정책 테스트 묶음 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests \
  -only-testing:SYKeyboardTests/KeyboardGesturePolicyTests
```

결과: `TEST SUCCEEDED`.

- 2026-05-22 `KeyboardPeriodShortcutPolicy` 추가 전 RED 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardPeriodShortcutPolicyTests
```

결과: 권한 있는 환경에서 실행했으며 `KeyboardPeriodShortcutPolicy` 미정의로 실패했다.

- 2026-05-22 `KeyboardPeriodShortcutPolicy` 추가 후 GREEN 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardPeriodShortcutPolicyTests
```

결과: `TEST SUCCEEDED`.

- 2026-05-22 `KeyboardSymbolInputPolicy` 추가 전 RED 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardSymbolInputPolicyTests
```

결과: 권한 있는 환경에서 실행했으며 `KeyboardSymbolInputPolicy` 미정의로 실패했다.

- 2026-05-22 `KeyboardSymbolInputPolicy` 추가 후 GREEN 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardSymbolInputPolicyTests
```

결과: `TEST SUCCEEDED`.

- 2026-06-01 `KeyboardHeightPolicy` 추가 전 RED 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardHeightPolicyTests
```

결과: sandbox 실행은 SwiftPM/Xcode 캐시 및 CoreSimulator 권한 문제로 실패했다. 권한 있는 환경에서 실행했으며 `KeyboardHeightPolicy` 미정의로 실패했다.

- 2026-06-01 `KeyboardHeightPolicy` 추가 후 GREEN 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardHeightPolicyTests
```

결과: `TEST SUCCEEDED`.

- 2026-06-01 정책 테스트 묶음 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests \
  -only-testing:SYKeyboardTests/KeyboardGesturePolicyTests \
  -only-testing:SYKeyboardTests/KeyboardPeriodShortcutPolicyTests \
  -only-testing:SYKeyboardTests/KeyboardSymbolInputPolicyTests \
  -only-testing:SYKeyboardTests/KeyboardHeightPolicyTests
```

결과: `TEST SUCCEEDED`.

- 2026-06-01 `KeyboardSuggestionSelectionPolicyTests` RED:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests
```

결과: 첫 sandbox 실행은 SwiftPM/Xcode 캐시 및 CoreSimulator 권한 문제로 실패했다. 권한 있는 환경에서 `KeyboardSuggestionSelectionPolicy` 미정의 컴파일 실패를 확인했다.

- 2026-06-01 `KeyboardSuggestionSelectionPolicyTests` GREEN:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests
```

결과: `TEST SUCCEEDED`.

- 2026-06-01 suggestion 선택 정책 연결 후 전체 `SYKeyboard` 테스트 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

결과: `TEST SUCCEEDED`.

- 2026-06-01 `KeyboardTextInteractionPolicy` 추가 전 RED 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests
```

결과: 권한 있는 환경에서 실행했으며 `KeyboardTextInteractionPolicy` 미정의로 실패했다.

- 2026-06-01 `KeyboardTextInteractionPolicy` 추가 후 GREEN 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests
```

결과: `TEST SUCCEEDED`.

- 2026-06-01 `KeyboardTextInteractionPolicy.deletedTextForSingleBackward` 추가 전 RED 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests
```

결과: 권한 있는 환경에서 실행했으며 `deletedTextForSingleBackward` 미정의로 실패했다.

- 2026-06-01 `KeyboardTextInteractionPolicy.deletedTextForSingleBackward` 추가 후 GREEN 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests
```

결과: `TEST SUCCEEDED`.

- 문서/계획만 변경한 경우:

```sh
git diff --check -- dev/active/base-keyboard-vc-responsibility-refactor
git status --short --untracked-files=all
```

- `BaseKeyboardViewController` 또는 Core 코드 변경 후 최소 검증:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboardCore \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 한글 조합/삭제/드래그/undo 경계 변경 후 권장 검증:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/DubeolsikControllerTests \
  -only-testing:SYKeyboardTests/NaratgeulControllerTests \
  -only-testing:SYKeyboardTests/CheonjiinControllerTests \
  -only-testing:SYKeyboardTests/HangeulDeleteButtonDragControllerTests \
  -only-testing:SYKeyboardTests/KeyboardUndoRedoManagerTests \
  -only-testing:SYKeyboardTests/KeyboardTextContextNavigatorTests
```

- 최종 통합 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

2026-05-22 결과: `TEST SUCCEEDED`.
2026-05-22 `KeyboardPeriodShortcutPolicy` 연결 후 재확인 결과: `TEST SUCCEEDED`.
2026-05-22 `KeyboardSymbolInputPolicy` 연결 후 재확인 결과: `TEST SUCCEEDED`.
2026-06-01 `KeyboardHeightPolicy` 연결 후 재확인 결과: `TEST SUCCEEDED`.
2026-06-01 `KeyboardTextInteractionPolicy` 연결 후 재확인 결과: `TEST SUCCEEDED`.
2026-06-01 `KeyboardTextInteractionPolicy.deletedTextForSingleBackward` 연결 후 재확인 결과: `TEST SUCCEEDED`.
2026-06-02 `KeyboardSuggestionSelectionPolicy.suggestionUpdateAction` 연결 후 재확인 결과: `TEST SUCCEEDED`.
2026-06-02 `KeyboardPresentationStatePolicy.shouldShowUndoRedoControls` 연결 후 재확인 결과: `TEST SUCCEEDED`.
2026-06-02 `KeyboardPresentationStatePolicy.isUndoRedoFeatureAvailable` 연결 후 재확인 결과: `TEST SUCCEEDED`.

- 수동 확인이 필요한 경우:
  - 실제 텍스트 입력 앱에서 한글/영문 키보드 extension을 열고 입력, 삭제, 반복 삭제, 삭제 드래그, 스페이스, 리턴, 자동완성 선택, undo/redo를 확인한다.

## Done Criteria

- 품질 평가 결과가 문서화되어 있고, 남은 리팩토링 범위가 우선순위로 정리되어 있다.
- `BaseKeyboardViewController`의 책임 경계가 현재보다 명확해졌지만, 기능 동작은 바뀌지 않는다.
- `KeyboardControllerSimulator.swift` 등 복제/보조 테스트 코드가 실제 컨트롤러 변경과 동기화되어 있다.
- 변경별 검증 명령과 결과가 기록되어 있다.
- 추가 리팩토링을 하지 않는 결정도 근거와 함께 문서화되어 있다.
