# BaseKeyboardViewController 삭제 드래그·반복 삭제·undo/redo Coordinator 추출 설계

- 이슈: #185 (선행: #184, PR #187)
- 기준 커밋: `develop` f14e15e0 (#187 머지 뒤 빌드 번호 변경 직후)
- 작업 브랜치: `refactor/#185-extract-delete-undo-coordinators` (worktree 없이 로컬 브랜치)
- 작성일: 2026-10-08

## 1. 목적

`Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`(2721줄)에서
삭제 touchDown·반복 삭제·삭제 pan·줄 경계 추론·보류 큐 drain과 undo/redo 접착 코드를 상태를 소유하는 별도 타입
두 개로 옮겨 본 파일을 약 1850줄로 줄인다. **사용자에게 보이는 동작, 입력 흐름, 콜백 안의 호출 순서, 프록시 읽기
횟수는 바꾸지 않는다.** #184에서 확정한 추출 방식(Coordinator + `weak` Host)과 검증 틀을 그대로 쓴다.

### 1-1. 대상

- `// MARK: - Private Methods`와 `TextInteractionGestureControllerDelegate` 구현·보조 extension 중 삭제·반복·undo 접착 코드
  약 850줄. 상태 타입(`DeleteMutationLifecycle`, `DeleteInteractionCoordinator`, `DeletePanTextModel`,
  `DeletePanBoundaryState`, `KeyboardUndoRedoSession`)은 이미 순수 타입이라 바뀌지 않는다.
- 두 영역의 접점은 세 곳뿐이다. `recordUndoRedoChange`가 먼저 `deleteMutationLifecycle.capture`를 시도하고 없으면 undo에
  기록하는 것, `processDeleteMutationResolution`이 확정된 draft를 `recordUndoRedoChange`로 넘기는 것,
  `performUndo`/`performRedo`가 `cancelPendingDeleteInteractions`를 먼저 부르는 것.
- 삭제 파이프라인은 프록시를 직접 쓰지 않는다. 모든 쓰기가 VC의 `open`/`public` 메서드(`deleteText`, `deleteBackward`,
  `repeatDeleteBackward`, `deleteButtonPanDeleteText`, `deleteButtonPanRestoreText`, `replaceText`)를 거친다.
  undo 적용(`applyUndoRedoEdit`, `restoreTextPositionIfPossible`)만 `textDocument`에 직접 쓴다.

### 1-2. 범위 결정

| 대상 | 결정 |
|---|---|
| Text Proxy Wrapper(`insertText`/`deleteText`/`replaceText`/`replaceSelectedText`/`insertReturnText`) | VC에 남긴다. `recordUndoRedoChange` 호출 5곳과 `deleteText()`의 `deletePanDeletedTextOverride` 읽기만 Coordinator 호출로 바꾼다. `inputBuffer`·`smartQuoteState`를 열지 않는다(#184 설계 §1-1의 이유 유지) |
| 커서 드래그 3개 메서드·인디케이터, 길게 누르기·숫자 입력·아포스트로피 전환, `handlePeriodShortcutOnDelete`, `updateSuggestions*` 3개 (약 150줄) | VC에 남긴다. 자판 전환 상태(`currentKeyboard`, `isSymbolInput`)와 `final public var` 플래그를 쓰기 때문이다. Coordinator가 맡는 호출(`startRepeatInputTimer`, `updateUndoRedoControls`)만 위임 한 줄로 바꾼다 |
| 추출 구조 | 삭제와 undo/redo를 **Coordinator 두 개**로 나눈다. 접점 세 곳은 VC를 경유한다. 이슈 체크리스트의 두 단계와 커밋이 1:1로 대응한다 |
| 제스처 delegate | VC가 그대로 받는다. `deleteButtonPanning`/`deleteButtonPanStopped`만 Coordinator 호출 한 줄이 된다 |

## 2. 구조

새 파일 2개, 수정하는 기존 파일 3개. 새 파일은 `project.pbxproj`의 `SYKeyboard`·`SYKeyboardCore` 두 타깃
membershipExceptions에 알파벳 순으로 등록한다.

| 파일 | 역할 |
|---|---|
| `Modules/SYKeyboardCore/Presentation/ViewController/Utils/TextDeletionCoordinator.swift` (신규) | 삭제 touchDown·반복 틱·pan 삭제/복구·줄 경계 추론·보류 큐 drain·반복 입력 타이머·삭제 드래그 인디케이터. `protocol TextDeletionHost` 포함 |
| `Modules/SYKeyboardCore/Presentation/ViewController/Utils/UndoRedoCoordinator.swift` (신규) | undo/redo 기록·그룹 확정·무효화·적용·컨트롤 갱신. `protocol UndoRedoHost` 포함 |
| `Modules/SYKeyboardCore/Presentation/ViewController/Utils/CachingTextDocumentProxy.swift` (수정) | `var contextSnapshot: KeyboardTextContextSnapshot` extension 추가. 앞·뒤 문맥을 그 순서로 한 번씩 읽는다. VC의 `currentTextContextSnapshot()`과 두 Coordinator가 같은 헬퍼를 쓴다 |
| `SuggestionSelectionCoordinator.swift`, `ClipboardHistoryCoordinator.swift` (수정) | `deinit { logger.debug("deinit") }`만 추가(§7) |

이름: 순수 타입 `DeleteInteractionCoordinator`가 이미 있어 "삭제 Coordinator"를 그 이름으로 쓸 수 없다.
`TextDeletionCoordinator`는 삭제 상호작용 전체(드래그·반복·확정)를 뜻하고 기존 `DeleteInteraction…`·`DeleteMutation…`·
`DeletePan…` 접두어와 구분된다. `UndoRedoCoordinator`는 `KeyboardUndoRedoSession`·`KeyboardUndoRedoManager`와 구분된다.

### 2-1. 참조 방향과 메모리 규칙

```
BaseKeyboardViewController ──strong(private lazy)──▶ TextDeletionCoordinator ──weak(host)──▶ VC
                           ──strong(private lazy)──▶ UndoRedoCoordinator     ──weak(host)──▶ VC
TextInteractionGestureController.delegate ──weak──▶ VC (바뀌지 않음)
```

- `host`는 `weak var host: …Host?`. 모든 진입점은 `guard let host else { return }`(값 반환은 `false`/`nil`)로 시작한다.
  `unowned`를 쓰지 않는다. `DispatchQueue.main.asyncAfter` 클로저 5개(경계 대기·동기화 대기·타임아웃·settling·
  released checkpoint)와 반복 타이머 sink가 Coordinator를 VC보다 오래 살릴 수 있다.
- 클로저는 지금처럼 `[weak self]`(타이머 sink는 `[weak self, weak button]`)를 유지하고 안에서 다시 `guard let self`,
  필요하면 `guard let host`를 한다. `timer: AnyCancellable`은 Coordinator 해제 시 자동 취소된다.
- Coordinator가 강하게 드는 것은 init에 주입된 뷰·`suggestionController`·설정뿐이고 이들은 Coordinator를 참조하지 않는다.
  `host.textDocument`와 `button`은 저장하지 않는다. `CachingTextDocumentProxy`를 따로 만들지 않는다.
  캐시 범위(`withReadCaching`)는 VC 콜백이 VC의 인스턴스에 켜는 것이기 때문이다.
- Coordinator는 `textDocumentProxy`를 직접 참조하지 않는다. CLAUDE.md의 grep 확인 규칙이 추출 뒤에도 성립해야 한다.
- 두 Coordinator와 Host 프로토콜은 모듈 안에서만 쓰므로 `internal`이다. Host 채택 extension은 본 파일 끝에 둔다.
- 햅틱·사운드는 `FeedbackManager.shared`를 Coordinator가 직접 부른다(#184의 `SuggestionSelectionCoordinator`와 같음).
- Coordinator는 자기 `Logger`(category `TextDeletionCoordinator`/`UndoRedoCoordinator`)를 갖는다. 옮겨지는 `.debug` 로그
  4줄의 category가 VC 타입명+주소에서 Coordinator 이름으로 바뀐다. 이것이 유일한 진단 출력 변화이며
  `KeyboardDiagnostics.log`·signpost는 그대로다.

### 2-2. 접근 제어 원칙

- VC 저장 프로퍼티 중 `private`에서 `internal`로 바뀌는 것은 없다. Coordinator로 옮긴 프로퍼티는 VC에서 삭제한다.
- Host 요구사항 중 VC의 `private` 메서드를 감싸는 것은 witness가 될 수 없으므로 VC 메서드와 다른 이름으로 선언하고,
  같은 파일의 Host 채택 extension이 한 줄로 전달한다. VC의 `open`/`public` 메서드는 같은 이름으로 witness가 된다.
- VC 공개 API 변화는 둘뿐이다. `isRepeatingInput`이 저장 프로퍼티(`public private(set) var`)에서 계산 프로퍼티
  (`public var isRepeatingInput: Bool { textDeletionCoordinator.isRepeatingInput }`)로, `deleteButtonPanPreviousCharacter`가
  `textDeletionCoordinator.panPreviousCharacter`를 돌려주는 것으로 바뀐다. 둘 다 읽기 전용이라 하위 VC 소스는 그대로다.

## 3. 인터페이스

### 3-1. `TextDeletionCoordinator`

init 주입(VC가 이미 가진 참조): `deleteDragIndicatorView: CursorDragIndicatorView`, `suggestionController: SuggestionService`
(단일 삭제의 대치 복구 `attemptRestoreReplacement`), `keyboardSettingsManager: UserDefaultsManager`(`repeatRate`), `host`.

소유하는 상태(VC에서 삭제, 12개): `deleteMutationLifecycle`, `deleteInteractionCoordinator`, `isDrainingPendingDeleteInteractions`,
`currentTextInputIdentifier`, `tempDeletedCharacters`, `deletePanTextModel`, `lastDeletePanEditTime`, `deletePanBoundaryState`,
`deletePanDeletedTextOverride`, `timer`, `isRepeatingInput`, `repeatInputTickCount`.
외부에 읽기로 여는 것은 `isRepeatingInput`(`private(set)`)과 `panPreviousCharacter: Character?`(`deletePanTextModel?.lastCharacter`) 둘뿐이다.

`protocol TextDeletionHost: AnyObject`

| 구분 | 요구사항 | VC 쪽 |
|---|---|---|
| 읽기 | `textDocument: CachingTextDocumentProxy`, `currentInputBuffer: String`, `isViewInWindow: Bool` | 다른 Host에 이미 있는 같은 이름. VC extension 하나가 여러 Host를 함께 만족한다 |
| 동작(같은 이름) | `textInteractionWillPerform(button:)`, `textInteractionDidPerform(button:)`, `deleteBackward()`, `repeatDeleteBackward()`, `deleteText()`, `replaceText(deleteCount:insert:)`, `deleteButtonPanDeleteText(hasPendingRestoreText:)`, `deleteButtonPanRestoreText(_:)`, `deleteButtonPanDidStop()`, `performRepeatTextInteraction(for:)` | `open`/`public final`이라 그대로 witness. 하위 VC 오버라이드가 지금처럼 불린다 |
| 동작(다른 이름) | `performDeleteTextInteraction(for:)` | `performTextInteraction(for:)`로 전달. 기본 인자(`insertSecondaryKeyIfAvailable`)가 있어 같은 이름으로는 witness가 안 된다 |
| | `recordEditForUndo(deletedText:insertedText:)` | VC private `recordUndoRedoChange(deletedText:insertedText:)`(reliability 기본값) |
| | `refreshSuggestions()` | `updateSuggestions()`. 이미 있음 |

프록시 쓰기 요구사항이 없다. 삭제 파이프라인의 쓰기는 전부 위 `open` 메서드를 거친다.

VC가 부르는 메서드. 호출 위치와 순서는 지금과 같고 각각이 옮겨 가는 VC 메서드 본문을 그대로 담는다.

| 호출 위치 | 메서드 | 옮겨 가는 본문 |
|---|---|---|
| `textWillChange`/`textDidChange` | `synchronizeInputIdentifier(_ id: ObjectIdentifier?)` | `synchronizeDeleteInteractionInputIdentifier`. 식별자는 VC의 `textInputIdentifier(for:)`가 계산해 넘긴다 |
| `textDidChange` | `completeAfterTextChange(currentContext:)` | `lifecycle.completeAfterTextChange` + `processDeleteMutationCallbackOutcome` + `resumePendingDeletePanBoundaryIfNeeded`. `selectedText`는 안에서 읽고, 앞·뒤 문맥은 VC가 커서 햅틱 판정에 쓴 스냅샷을 그대로 넘겨 읽기 횟수를 유지한다 |
| `viewWillDisappear`, `stopInputInteractionsForLanguageChange` | `stopRepeatInputTracking()` | 그대로 |
| `viewWillDisappear` | `resetInputIdentifier()` | `currentTextInputIdentifier = nil` |
| `performTextInteraction` 삭제 분기 | `performTouchDown(for:)` | released touchDown 체크포인트 → `beginTouchDown` 큐잉 판정 → `beginDeleteTouchDownRequest` → semantic hooks + `performDeleteButtonTextInteraction`. `!isRepeatingInput` 분기도 안에서 한다 |
| `performTextInteraction`/`performRepeatTextInteraction` 비삭제 분기, Host의 `interruptPendingDeleteInteractions` | `cancelPendingInteractions()` | `cancelPendingDeleteInteractions` + `finishCancelledDeletePanIfNeeded` |
| `performRepeatTextInteraction` 삭제 분기 | `performRepeatTick(for:)` | semantic hooks + `performRepeatDeleteTextInteraction`(24ff8984의 `reusing:` 재사용 포함) |
| `performInitialRepeatDeleteTextInteraction` | `performInitialRepeatDelete(for:)` | `actionForNextRepeat` 분기. `view.window` 확인은 VC에 남는다 |
| 삭제 버튼 release `UIAction` | `finishTouchDown()` | `lifecycle.finishTouchDown` + process |
| `textInteractionWillPerform` | `clearPanRestoreState()` | `tempDeletedCharacters.removeAll()` + `resetDeletePanTextModel()` |
| `repeatTextInteractionWillPerform` | `beginRepeatInput()` | `cancelTimer()` + `isRepeatingInput = true` |
| `repeatTextInteractionDidPerform` | `endRepeatInput(isDeleteButton:)` | 삭제면 `completeRepeatDeleteAtCurrentContext` → `stopRepeatInputTracking(preservingTouchDown:)` → pan 상태 비우기 |
| `textInteractableButtonLongPressing` | `startRepeatInputTimer(for:)` | 타이머 sink는 `host.isViewInWindow`·`host.performRepeatTextInteraction`를 쓴다 |
| `deleteButtonPanning` / `deleteButtonPanStopped` | `handlePan(to:)` / `handlePanStop()` | 인디케이터 표시·숨김 포함 본문 전체 |
| `deleteText()` | `takePanDeletedTextOverride() -> String?` | 값을 돌려주고 `nil`로 지운다. VC는 지금처럼 selection이 비었을 때만 쓴다 |
| `recordUndoRedoChange`(VC) | `captureMutation(deletedText:insertedText:reliability:) -> Bool` | `lifecycle.capture` 분기. `.awaitingTextChange`면 `true`, `.completion`이면 resolution 처리 후 `true`, `nil`이면 `false`(VC가 undo Coordinator에 기록) |

따로 적어 두는 미세 차이: 반복 타이머 sink의 `self?.view.window == nil`이 `host.isViewInWindow`(`viewIfLoaded?.window != nil`)로
바뀐다. 타이머가 도는 동안 뷰는 항상 로드돼 있으므로 결과는 같다. 타이머 sink의 `[weak self, weak button]` 캡처와
창 밖·버튼 해제 시 멈춤은 그대로 옮긴다.

### 3-2. `UndoRedoCoordinator`

init 주입: `suggestionBarView: SuggestionBarView`(컨트롤 갱신), `suggestionController: SuggestionService`(무효화 시
`clearReplacementHistory`), `keyboardSettingsManager: UserDefaultsManager`(`isUndoRedoEnabled`), `host`.

소유하는 상태: `undoRedoSession: KeyboardUndoRedoSession` 하나. `isUndoRedoFeatureAvailable`은 Coordinator의 private 계산
프로퍼티가 된다. 외부에 여는 읽기는 없다.

`protocol UndoRedoHost: AnyObject`

| 구분 | 요구사항 | VC 쪽 |
|---|---|---|
| 읽기 | `textDocument`, `isPreviewMode` | 이미 있음 |
| 읽기 | `shouldDeferUndoRedoCommit: Bool` | `open var`, 같은 이름. 한글 VC 오버라이드가 그대로 불린다 |
| 동작(같은 이름) | `undoRedoEditDidApply()` | `open`. `ClipboardHistoryHost`에도 있음 |
| 동작(다른 이름) | `refreshReturnButtonEnabled()`, `refreshSuggestions()`, `refreshClipboardControl()`, `interruptPendingDeleteInteractions()` | 모두 이미 있는 이름. `interruptPendingDeleteInteractions`는 VC가 `textDeletionCoordinator.cancelPendingInteractions()`로 전달 |

undo 적용만 `host.textDocument`에 직접 쓴다(`deleteBackward`/`insertText`/`adjustTextPosition`). 지금도 VC가 래퍼 없이 직접 쓰는 곳이다.

VC가 부르는 메서드:

| 호출 위치 | 메서드 | 옮겨 가는 본문 |
|---|---|---|
| `textWillChange` | `prepareForTextWillChange(inputIdentifier:)` | `undoRedoSession.prepareForTextWillChange(inputIdentifier:context:)`. 스냅샷은 안에서 `host.textDocument.contextSnapshot`으로 읽는다(캐시 범위 안이라 횟수 동일) |
| `textDidChange` | `invalidateHistoryIfNeededAfterTextChange(inputIdentifier:)` | `invalidateUndoRedoHistoryIfNeededAfterTextChange` |
| `viewWillDisappear` | `removeAllHistory()` | `undoRedoSession.removeAll()` + `updateUndoRedoControls()`. 지금 두 줄이 붙어 있는 자리 |
| `recordUndoRedoChange`(VC, 삭제 capture가 `false`일 때) | `record(deletedText:insertedText:)` | 기능 ON·`!isApplyingEdit` guard → `session.record`(closure는 `host?.shouldDeferUndoRedoCommit`, `self?.refreshControls`) → 컨트롤 갱신 |
| `commitUndoRedoGroupIfPossible` | `commitPendingGroup()` | `commitPendingUndoRedoGroup` |
| `commitUndoRedoGroupIgnoringCompositionDeferral` | `commitPendingGroupIgnoringDeferral()` | 그대로(기능 ON guard 포함) |
| `commitDeferredUndoRedoGroupIfNeeded` | `commitDeferredGroupIfNeeded()` | 그대로 |
| Host의 `undoLastEdit`/`redoLastEdit` | `undo()` / `redo()` | `performUndo`/`performRedo` + `applyUndoRedoEdit` + `restoreTextPositionIfPossible`. `interruptPendingDeleteInteractions`를 먼저 부르는 순서 유지 |
| `updateSuggestionBarHidden`, `moveCursorIfPossible` | `refreshControls()` | `updateUndoRedoControls`. 기록이 없으면 프록시를 읽지 않는 분기 유지, 끝에 `host.refreshClipboardControl()` |

VC에 남는 조합 지점 `recordUndoRedoChange(deletedText:insertedText:reliability:)`:

```swift
if textDeletionCoordinator.captureMutation(deletedText: deletedText, insertedText: insertedText, reliability: reliability) { return }
undoRedoCoordinator.record(deletedText: deletedText, insertedText: insertedText)
```

호출처 6곳(`insertText`, `deleteText`, `replaceText`, `replaceSelectedText`, `insertReturnText`, 삭제 Coordinator의
`recordEditForUndo`)은 바뀌지 않는다. `updateClipboardControl()`은 클립보드 글루라 VC에 남고 `refreshClipboardControl`로만 불린다.

### 3-3. VC에 남는 것

- Text Proxy Wrapper 전체, 커서 드래그(`primaryButtonCursorDragActivated`/`primaryButtonPanning`/`primaryButtonPanStopped`,
  `moveCursorIfPossible`, `isPrimaryCursorDragging`, `pendingCursorDragHapticContext`, `cursorDragIndicatorView`),
  길게 누르기 분기(`textInteractableButtonLongPressing`/`Stopped`, `performNumberInputLongPress`,
  `markSymbolInputAfterLongPressIfNeeded`, `switchToPrimaryAfterApostropheLongPressIfNeeded`), `handlePeriodShortcutOnDelete`,
  `updateSuggestions`/`updateSuggestionsForCursorContext`/`updateSuggestionsForCurrentContext`, `updateClipboardControl`,
  `textBeforeCursorSuffix`, `textInputIdentifier(for:)`.
- `currentTextContextSnapshot()`은 `textDocument.contextSnapshot`을 돌려주는 한 줄이 되거나 호출처가 직접 extension을 쓴다.
- `deleteDragIndicatorView`는 VC가 `private lazy var`로 소유하고 뷰 계층에 올리는 것도 VC(UI Methods)가 한다. Coordinator에는
  주입만 한다.

## 4. 호출 순서 보존

본문은 Coordinator로 가고 원래 자리에 호출 한 줄이 남는다. 아래 흐름이 추출 전후로 같아야 한다.

- **textWillChange** (`withReadCaching` 안): 식별자 훅 → `synchronizeTextInputTraits` → `textDeletionCoordinator.synchronizeInputIdentifier(id)`
  → `undoRedoCoordinator.prepareForTextWillChange(inputIdentifier: id)` → 전송 스냅샷 → `resetInputBuffer` → … 지금은
  `textInputIdentifier(for:)`를 세 번 부르지만 순수 함수라 한 번으로 줄인다. 프록시 읽기와 무관하다.
- **textDidChange** (`withReadCaching` 안): trait 동기화 → `synchronizeInputIdentifier(id)` → 전송 기록 →
  `let currentContext = textDocument.contextSnapshot`(VC) → 커서 햅틱 판정(VC) → `pendingCursorDragHapticContext = nil` →
  `textDeletionCoordinator.completeAfterTextChange(currentContext:)` → `undoRedoCoordinator.invalidateHistoryIfNeededAfterTextChange(inputIdentifier: id)`
  → `updateKeyboardType` → trait 비교 → … 삭제 확정이 프록시에 쓰면 캐시가 비워지고 그 뒤 undo 무효화가 새 값을 읽는 순서가 그대로다.
- **viewWillDisappear**: `stopRepeatInputTracking()` → 패널 닫기 → 삭제 확인 숨김 → `resetInputIdentifier()` →
  `lastNotifiedTextInputIdentifier = nil`(VC) → `removeAllHistory()` → 전송 스냅샷 폐기 → `resetInputBuffer` → NGram 저장.
- **삭제 touchDown**: `performTextInteraction` → `performTouchDown(for:)`(반복 중이 아니면 released 체크포인트 → `beginTouchDown`
  큐잉 판정 → `beginDeleteTouchDownRequest`; 이어서 hooks + 단일 삭제) → return. 버튼 release → `finishTouchDown()`.
- **반복 삭제**: 길게 누르기 → `repeatTextInteractionWillPerform`(VC `open`: `beginRepeatInput()`, 한글 VC는 이어서
  `performInitialRepeatDeleteTextInteraction`) → `startRepeatInputTimer(for:)` → 틱마다 `host.performRepeatTextInteraction` →
  `performRepeatTick(for:)`. 이전 resolution이 없는 틱은 앞·뒤 문맥·selection을 한 번만 읽어 `beginRepeatDeleteRequest(reusing:)`에
  넘긴다. 종료 → `repeatTextInteractionDidPerform` → `endRepeatInput(isDeleteButton:)`.
- **삭제 pan 왼쪽**: `deleteButtonPanning` → `handlePan(to: .left)` → 인디케이터 표시 → `enqueuePan` →
  `performDeleteButtonPanIfLifecycleReady` → 모델 준비 → U+FFFC 앞 멈춤 → `deletePanDeletedTextOverride` 설정 →
  `host.deleteButtonPanDeleteText` → (하위 VC 또는 기본 구현이 `deleteText()` → `takePanDeletedTextOverride`) → 모델 갱신·복구
  버퍼·`refreshSuggestions`·햅틱·사운드. 모델이 바닥나면 경계 요청 흐름(조용한 50ms → `deletePanExhaustedContextAction` 분기 →
  `deleteText()`·타임아웃 150ms·settling 50ms)이 Coordinator 안에서 지금 코드 그대로 돈다.
- **삭제 pan 오른쪽·종료**: `handlePan(to: .right)` → `tempDeletedCharacters.popLast` → `host.deleteButtonPanRestoreText`.
  `deleteButtonPanStopped` → `handlePanStop()` → 인디케이터 숨김 → `enqueuePanStop` 판정 → 즉시면 `finishDeleteButtonPanTracking`
  (→ `host.deleteButtonPanDidStop`), 아니면 경계 취소 또는 released 체크포인트 예약.
- **확정 처리** `processDeleteMutationResolution`: 복구 글자 추가 → 경계 상태 갱신 → 모델 재충전 → draft마다 `host.recordEditForUndo`
  → VC `recordUndoRedoChange` → `captureMutation`(보류 없음, `false`) → `undoRedoCoordinator.record` → 햅틱·사운드 → settling 또는 resolve·drain.
- **undo/redo 탭**: 바 → `SuggestionSelectionCoordinator` → `host.undoLastEdit` → VC → `undoRedoCoordinator.undo()` →
  `host.interruptPendingDeleteInteractions` → 디바운스 취소 → `canApplyUndo` → 적용(커서 복원 → 프록시 쓰기 → `undoRedoEditDidApply`
  → `refreshReturnButtonEnabled` → `refreshSuggestions`) → 반대 방향 문맥 갱신 → 컨트롤 갱신 → 햅틱.
- **클립보드 붙여넣기**: `ClipboardHistoryCoordinator` → `host.commitUndoRedoGroupIgnoringCompositionDeferral` → VC →
  `undoRedoCoordinator.commitPendingGroupIgnoringDeferral()`. 삽입 전후 두 번, 그대로.
- **비삭제 입력·undo·클립보드 열기**: 진행 중 삭제 취소는 모두 `cancelPendingInteractions()` 하나로 모인다.
- **미리보기**: undo 적용은 `host.isPreviewMode`로 막고, 삭제·반복 삭제는 지금처럼 VC의 `open` 메서드(`deleteBackward`,
  `repeatDeleteBackward`)가 `isPreview`를 본다. Coordinator는 미리보기 판정을 따로 하지 않는다.

## 5. 검증

코드를 옮기기 **전에** 현재 동작을 고정하는 테스트를 넣고 통과시킨 뒤, 추출 후 그 테스트를 수정 없이 통과시키는 것을 증거로 삼는다.

### 5-1. VC 동작 고정 테스트 (`SYKeyboardTests/Controller/BaseKeyboardViewControllerDeleteUndoBehaviorTests.swift`)

실제 `BaseKeyboardViewController` 서브클래스 + `textDocumentProxy` 오버라이드로 `CountingTextDocumentProxy`를 끼운다(#184 방식).
`TestPrimaryKeyboardView.deleteButton`이 실제 `DeleteButton`이라 진입점으로 쓴다. 반복 삭제는 `view.window != nil`을 요구하므로
그 테스트만 `UIWindow`에 올린다. 옮겨질 멤버(Coordinator 타입, 인디케이터 뷰)는 참조하지 않고, 하위 VC가 보는 `open` 훅
(`deleteButtonPanDidStop`) 호출 횟수와 프록시 `writes`·`readCounts`로 관찰한다.

| 항목 | 진입점 | 관찰 |
|---|---|---|
| 단일 삭제 탭과 release | `performTextInteraction(for: deleteButton)` → `deleteButton.sendActions(for: .touchUpInside)` → `textDidChange(nil)` | `writes == ["deleteBackward"]`, undo 가능(아래 undo 탭으로 삽입 복원) |
| 확정 전 두 번째 탭은 큐잉, callback 뒤 이어 감 | 탭 두 번 → `textDidChange` | 첫 callback 전 쓰기 1회, 뒤 2회 |
| 반복 삭제 틱의 프록시 읽기 횟수 | `repeatTextInteractionWillPerform` → `performRepeatTextInteraction(for:)` | 이전 resolution 없는 틱의 앞·뒤 문맥·selection 읽기 횟수를 **추출 전 측정값**으로 고정(24ff8984) |
| 확정 전 다음 틱은 지우지 않음 | 틱 두 번 → `textDidChange` → 틱 | 쓰기 1 → 2회 |
| 삭제 pan 왼쪽·오른쪽 | `deleteButtonPanning(_, to:)` / `deleteButtonPanStopped` | `deleteBackward` 뒤 `insertText(글자)`, 종료 시 `deleteButtonPanDidStop` 1회 |
| 첨부(U+FFFC) 앞 멈춤, 선택 영역 삭제 | 위와 같음, `proxy.beforeInput`/`selected` 설정 | 쓰기 없음 / `deleteBackward` 1회 뒤 undo가 선택 텍스트 삽입 |
| undo/redo | `insertText("가")` → `bar.suggestionDelegate?.suggestionBarDidTapUndo(bar)` → Redo | 쓰기 순서(`deleteBackward` → `insertText(가)`), 미리보기·설정 OFF면 쓰기 없음 |
| 삭제 중 필드 전환 | pan 시작 → `textWillChange(다른 UITextField)` | `deleteButtonPanDidStop` 1회, 이후 pan은 쓰기 없음 |
| 해제 | 위 동작을 거친 뒤 참조를 끊음 | `weak` VC가 `nil`(§7-2) |

제스처 delegate 메서드에 넘기는 `TextInteractionGestureController` 인자는 delegate 메서드가 쓰지 않으므로 테스트가 만든
인스턴스를 넘긴다. 줄 경계 추론·타임아웃·settling은 50\~150ms 타이머에 걸려 있어 단위 테스트에 넣지 않는다. 순수 로직은
`DeleteMutationLifecycleTests`(23개)가 이미 덮고, 전체 흐름은 §5-5 시뮬레이터로 본다. 관찰할 수 없는 항목을 억지로 넣지 않는다.

### 5-2. Coordinator 단위 테스트 (`SYKeyboardTests/Utils/TextDeletionCoordinatorTests.swift`, `UndoRedoCoordinatorTests.swift`)

가짜 Host가 호출을 순서대로 기록하고(`FakeSuggestionSelectionHost` 방식) `textDocument`는 `CachingTextDocumentProxy { proxy }`로
`CountingTextDocumentProxy`를 감싼다. 인디케이터 뷰는 테스트가 만든 인스턴스를 주입하므로 `isHidden`을 보는 것이 private 뷰 계층
고정이 아니다.

- 삭제: touchDown의 hook 순서(`textInteractionWillPerform` → `deleteBackward` → `textInteractionDidPerform`), 대치 복구 분기
  (`replaceText`), 보류 큐 drain, pan 삭제의 override 전달·복구·U+FFFC·selection, 식별자 변경 취소 시 `deleteButtonPanDidStop`과
  인디케이터 숨김, 반복 타이머가 `performRepeatTextInteraction`을 부르고 창 밖이면 멈춤, `captureMutation` 반환값 3가지,
  `recordEditForUndo` 경유, host 해제 뒤 호출 무해, Coordinator 해제(§7-2).
- undo: 기록 → undo의 Host 호출 순서(`interruptPendingDeleteInteractions` → 쓰기 → `undoRedoEditDidApply` →
  `refreshReturnButtonEnabled` → `refreshSuggestions` → `refreshClipboardControl`), 미리보기·설정 OFF 차단,
  `shouldDeferUndoRedoCommit`에 따른 지연 확정, 식별자 변경 무효화, `removeAllHistory`가 프록시를 읽지 않음, host 해제 뒤 무해,
  Coordinator 해제(§7-2).

### 5-3. 기존 테스트와 빌드

- `SYKeyboardTests` 전체(기준 1020개, 새 테스트만큼 증가) 통과. 4개 scheme 빌드. `iPhone 13 mini / iOS 18.6`.
- `BaseKeyboardViewControllerProxyReadTests`의 `textWillChange`/`textDidChange` 읽기 횟수 테스트가 콜백 안 읽기 보존을 추가로 고정한다.

### 5-4. 정적 확인

- `grep -rn "textDocumentProxy" Modules Keyboards | grep -v -E ":[0-9]+:[[:space:]]*//"` 결과가 `textDocument`를 만드는 한 줄뿐.
- VC 줄 수. 접근 수식어 없는 저장 프로퍼티 수가 기준(5)과 같음. 두 Coordinator가 `private lazy var`.

### 5-5. 시뮬레이터 확인

작업자가 `iPhone 13 mini / iOS 18.6` 시뮬레이터에 `HangeulKeyboard` scheme으로 키보드를 설치하고 Safari의 로컬 http 입력창
(여러 줄 textarea)에서 idb로 직접 확인한다. 통과한 항목은 완료로 기록하고 "실기기 미확인"으로 남기지 않는다.

- 삭제 드래그로 글자 삭제·복구, 줄 경계 넘기(이전 줄로 이어 지우기와 복구)
- 선택 영역(JS `setSelectionRange`로 만든 뒤) 드래그 삭제와 undo
- 길게 눌러 반복 삭제(한글 조합 중 포함), 손을 떼면 멈춤
- undo/redo 버튼
- 삭제 드래그 중 다른 입력창 탭
- 해제 확인(§7-3)

시뮬레이터로 확인할 수 없어 PR 본문에 "실기기 확인 필요"로 남기는 항목: 햅틱·삭제 사운드, 사진 첨부(U+FFFC) 앞 멈춤
(메시지 앱에 첨부가 가능하면 시뮬레이터에서 확인한다).

## 6. 작업 순서

단계마다 커밋 하나. 각 커밋에서 테스트와 빌드를 확인한다. 커밋 메시지는 `refactor: #185 - …`, 테스트만이면 `test: #185 - …`,
문서는 `docs: #185 - …`.

1. VC 동작 고정 테스트 추가(현재 코드에서 통과). 읽기 횟수는 측정값을 적어 고정
2. `CachingTextDocumentProxy.contextSnapshot` 추가와 VC 적용. `ProxyReadTests`로 읽기 횟수 유지 확인
3. #184 Coordinator 2개에 `deinit` 로그와 해제 테스트 추가(§7)
4. `UndoRedoCoordinator` 추출과 단위 테스트. 상태 하나, Host 요구사항이 적어 패턴을 먼저 작게 검증한다. 이 단계에서 VC의
   `recordUndoRedoChange`는 "lifecycle capture(아직 VC) → 없으면 Coordinator 기록" 형태
5. `TextDeletionCoordinator` 추출과 단위 테스트. `recordUndoRedoChange`가 최종 두 줄이 되고 `SuggestionSelectionHost`·
   `ClipboardHistoryHost`의 `interruptPendingDeleteInteractions`가 Coordinator 위임으로 바뀜
6. 전체 검증(§5-3\~§5-5, §7-3)과 결과 기록
7. 문서 갱신(§8)

## 7. 메모리 누수

### 7-1. #184 Coordinator 정적 검토 (2026-10-08)

- `SuggestionSelectionCoordinator`·`ClipboardHistoryCoordinator` 모두 `host`가 `weak`, `DispatchQueue.main.async` 2곳과
  오버레이 콜백 2곳이 `[weak self]`다.
- Coordinator를 가리키는 delegate(`SuggestionBarView.suggestionDelegate`, `SuggestionController.delegate`,
  `ClipboardHistoryPanelView.delegate`)와 두 gesture controller의 delegate는 전부 `weak var`다.
- `ClipboardHistoryCoordinator`의 `NotificationCenter` observer 3개는 selector 방식이라 iOS 9부터 해제 시 자동으로 끊긴다.
- 순환 참조 후보는 없었다. 다만 해제를 실제로 확인하는 테스트와 런타임 로그가 없다. VC는 `deinit`에서 `logger.debug`를 남기지만
  두 Coordinator는 남기지 않는다.

### 7-2. 보강

- 네 Coordinator 모두 `deinit { logger.debug("deinit") }`를 둔다. #184 두 파일에 넣는 유일한 변경이다.
- Coordinator 단위 해제 테스트(4개 타입): 가짜 Host와 Coordinator를 만들고 비동기 작업이 예약된 상태(삭제: 반복 타이머 시작·
  경계 대기 `asyncAfter`, 클립보드: 알림 observer 등록·`async` 예약)에서 참조를 끊었을 때 `weak` 참조가 `nil`이 되는지, 예약된
  클로저가 나중에 실행돼도 크래시와 부작용이 없는지.
- VC 수준 해제 테스트(§5-1): 실제 VC로 삭제 pan·반복 삭제·undo를 거친 뒤 참조를 끊어 `weak` VC가 `nil`인지. VC가 해제되면
  `private lazy var`로만 소유한 Coordinator도 따라 해제된다. UIKit이 테스트에서 `UIInputViewController`를 붙들면 그 사실과
  Coordinator 단위 해제 테스트로 대체했음을 기록한다.

### 7-3. 시뮬레이터 런타임 확인

- 키보드를 여러 번 띄웠다 내리며 `xcrun simctl spawn <UDID> log stream --level debug --predicate 'subsystem == "<extension bundle id>"'`로
  VC와 Coordinator 4개의 `deinit` 로그가 매번 나오는지 확인한다.
- 키보드 extension 프로세스에 `leaks <pid>`를 돌려 누수 0건을 확인한다. 프로세스는 키보드를 내린 뒤에도 잠시 남아 있으므로
  그 사이에 실행한다. 실행하지 못하면 이유를 기록한다.

## 8. 문서 갱신

코드 작업이 끝난 뒤 `README.md`와 `docs/architecture/` 7개 문서 전부를 최신 코드 기준으로 읽고 사실과 다른 문장을 고친다.
설계 배경을 길게 쓰지 않는다. 미리 확인한 변경 지점:

- `CLAUDE.md`: 아키텍처 절의 `BaseKeyboardViewController (~2700줄, …)` 줄 수와 책임 설명. 네 Coordinator와 Host 프로토콜을 한 줄로.
- `docs/architecture/전체 아키텍처.md`: VC 책임 목록(undo/redo·삭제 파이프라인 보유 주체), 버튼 이벤트 표(삭제 touchDown·pan·반복
  타이머 행), 라이프사이클 표(`textWillChange`/`textDidChange`/`viewWillDisappear`의 삭제·undo 호출 주체), Coordinator 목록.
- `docs/architecture/삭제와 실행취소 로직.md`: §1 보유 다이어그램, §2-4·§3·§4·§5의 "VC가" 주어와 메서드 이름, §6 테스트 표에
  새 테스트 추가.
- `docs/architecture/성능 고려 사항.md`: 반복 삭제 틱 재사용·타이머 항목의 위치(`TextDeletionCoordinator`), 테스트 표.
- `docs/architecture/자동완성 로직.md`: undo 버튼 연동 줄.
- `docs/architecture/한영 통합 키보드.md`: `stopInputInteractionsForLanguageChange` 설명.
- `README.md`: 전체 구조 flowchart에 `TextDeletionCoordinator`·`UndoRedoCoordinator` 노드와 간선, classDiagram에 합성 2개.
  트러블 슈팅 절은 과거 코드라고 명시돼 있어 손대지 않는다.
- `docs/architecture/한글 입력 로직.md`, `docs/architecture/README.md`: 읽은 뒤 바뀐 사실이 없으면 그대로 둔다.

마크다운의 범위 물결표는 `\~`로 쓴다.

## 9. 완료 기준

- §5·§7 전부 수행하고 결과(테스트 개수, 빌드 결과, 시뮬레이터 항목, 해제 확인, 미확인 항목과 이유)를 PR 본문 검증 항목에 적는다.
- 본 파일에 `private`에서 `internal`로 바뀐 저장 프로퍼티가 없다.
- PR 제목 `Refactor/#185 BaseKeyboardViewController에서 삭제 드래그·반복 삭제·undo/redo를 별도 타입으로 추출`, 연관 이슈 `- #185`.
  UI 변경이 없으므로 스크린샷 절은 뺀다. push와 PR 생성은 사용자가 지시할 때만 한다.
