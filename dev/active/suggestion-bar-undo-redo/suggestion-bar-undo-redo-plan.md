# Suggestion Bar Undo Redo Plan

Last Updated: 2026-05-22

## Goal

- 자동완성 바 우측에 undo/redo 버튼을 추가하고, 기능 추가 뒤 `BaseKeyboardViewController`의 큰 리팩토링을 진행한다.

## Current State

- 브랜치명은 `feat/#31-undo-redo`이다.
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`는 1000줄이 넘으며 버튼 액션, 텍스트 프록시 래퍼, 제스처 delegate, suggestion 연동이 한 파일에 모여 있다.
- 리턴 버튼 단일/반복 입력은 `performReturnButtonTextInteraction()`과 `performRepeatReturnButtonTextInteraction(for:)`로 분리되어 있다.
- 리턴 버튼 drag undo/redo 설계는 폐기했다. QWERTY 배열에서 redo 드래그가 불편하고, 추후 클립보드 UI와 제스처 책임이 충돌할 수 있기 때문이다.
- undo/redo는 자동완성 바가 보이고 `isUndoRedoEnabled`가 켜진 경우에만 우측 버튼으로 제공한다.
- 한글 키보드에서는 단일/반복 백스페이스 시작 시 조합 중이어도 기존 pending undo group을 강제로 확정한다. `안녕핫 -> 백스페이스 -> 안녕하 -> undo`가 전체 삭제가 아니라 `안녕핫` 복구로 동작해야 하기 때문이다.
- undo/redo 적용 후에는 한글 조합 버퍼와 processor 상태를 초기화한다. undo/redo 뒤 새 한글 입력이 이전 조합 상태와 이어 붙는 현상을 막기 위한 처리다.
- undo/redo 액션 버튼의 접근성 label/traits 코드는 의도적으로 제외한다. 사용자가 접근성 관련 코드를 일부러 뺐으므로, 리팩토링에서 되살리지 않는다.

## Approach

1. 동작 변경 없는 작은 선행 리팩토링을 먼저 적용한다.
   - 리턴 버튼 일반 입력과 반복 입력의 진입점을 별도 메서드로 분리한다.
   - 새 진입점은 당장은 기존처럼 `insertReturnText()`만 호출한다.
   - 이후 undo/redo 기능은 이 진입점 안에 추가한다.
2. 자동완성 바 undo/redo 기능을 추가한다.
   - `KeyboardUndoRedoManager`가 키보드 세션 동안 텍스트 변경 기록을 보관한다.
   - 입력 중 변경은 pending undo 단위로 묶고, 0.8초 debounce가 지나면 undo stack에 확정한다.
   - 스페이스/엔터 입력은 현재 undo group을 즉시 확정하는 명시적 편집 경계로 처리한다.
   - 입력과 삭제가 전환되면 기존 pending group을 확정하고 새 group을 시작한다.
   - debounce 확정 전에도 pending 변경이 있으면 undo 버튼은 활성화한다.
   - redo stack은 undo 이후 새 입력이 발생하면 비운다.
   - undo/redo 적용 후에는 커서/외부 텍스트와 `inputBuffer`가 섞이지 않도록 `resetInputBuffer()`를 호출한다.
   - `isPredictiveTextEnabled == true && isUndoRedoEnabled == true`일 때만 기록, 버튼 표시, undo/redo 수행을 허용한다.
3. 기능 추가가 끝난 뒤 `BaseKeyboardViewController`의 큰 리팩토링을 별도 단계로 진행한다.
   - 실제로 생긴 책임 기준으로 분리한다.
   - 후보 영역은 리턴 버튼 처리, undo/redo 세션 상태, 텍스트 프록시 래퍼와 입력 버퍼, 버튼 액션 세팅, 제스처 delegate, suggestion 연동이다.
   - 한글 조합 버퍼와 undo/redo 기록 경계의 연결은 `HangeulKeyboardCoreViewController`에 남기고, 공통 Base 리팩토링에서는 입력기별 조합 정책을 일반화하지 않는다.
   - 접근성 label/traits 제거는 현재 의도된 상태로 보고, 별도 요청 없이 리팩토링 중 재추가하지 않는다.

## Risks

- 자동완성 바는 후보 3개를 전제로 구성되어 있어 undo/redo 버튼 추가 시 작은 화면에서 후보 영역이 줄어들 수 있다.
- undo/redo가 `textDocumentProxy`를 직접 조작하면 `inputBuffer`와 suggestion replacement history가 어긋날 수 있다.
- 반복 입력 경로에서 리턴 버튼 feedback과 일반 입력 경로의 후처리 순서가 달라지면 회귀가 생길 수 있다.
- 키보드 extension은 입력 지연에 민감하므로 undo/redo 상태 추적은 가볍게 유지해야 한다.
- 현재 undo/redo 기록은 세션 메모리 전용이며 키보드 dismiss 시 `viewWillDisappear`에서 비운다.
- 한글 조합 중에는 pending group 확정을 지연하므로, space가 천지인/나랏글/두벌식 조합 확정으로 쓰이는 경우에도 조합 버퍼가 비워진 뒤 확정해야 한다.
- 백스페이스 시작은 한글 조합 중이어도 undo 기록 경계로 취급한다. 조합 표시/삭제 동작은 유지하되, 기록만 이전 입력 group과 분리해야 한다.
- 리팩토링에서 `applyUndoRedoEdit`, `undoRedoEditDidApply`, `commitUndoRedoGroupIgnoringCompositionDeferral` 호출 순서를 바꾸면 한글 undo 후 재입력 조합 버그가 재발할 수 있다.

## Verification

- 선행 리팩토링 후 실행할 검증 명령:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboardCore \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 기능 추가 뒤 실행할 검증 명령:

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

- 수동 확인이 필요한 경우:
  - 실제 텍스트 입력 앱에서 자동완성 바 표시 여부, undo/redo 버튼 활성화, 삭제, 스페이스, 리턴, symbol keyboard 자동 전환을 확인한다.
  - 한글 키보드에서 `안녕핫 -> 백스페이스 -> 안녕하 -> undo -> 안녕핫` 복구와, undo/redo 이후 새 한글 입력이 이전 조합과 섞이지 않는지 확인한다.

## Done Criteria

- 선행 리팩토링은 리턴 버튼 동작 변경 없이 전용 처리 진입점을 만든다.
- undo/redo 기능 추가 시 자동완성 ON/OFF, undo/redo 설정 ON/OFF, 버튼 활성화 상태, 일반 리턴 입력, 반복 입력 경로가 모두 의도대로 동작한다.
- undo group은 스페이스, 엔터, 입력↔삭제 전환, 백스페이스 시작에서 예측 가능한 경계로 나뉜다.
- 한글 undo/redo 후 내부 조합 버퍼가 남지 않는다.
- 큰 리팩토링은 기능 추가와 별도 변경으로 진행하고, 각 단계마다 빌드 또는 테스트 결과를 기록한다.
