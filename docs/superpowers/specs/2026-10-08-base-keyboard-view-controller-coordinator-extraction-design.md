# BaseKeyboardViewController 후보 선택·클립보드·전체 접근 안내 Coordinator 추출 설계

- 이슈: #184 (후속: #185)
- 기준 커밋: `develop` c68a3a1f (#186 머지 직후)
- 작업 브랜치: `refactor/#184-extract-suggestion-clipboard-coordinators` (worktree 없이 로컬 브랜치)
- 작성일: 2026-10-08

## 1. 목적

`Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`(3219줄)에서
결합도가 낮은 세 영역을 상태를 소유하는 별도 타입으로 옮겨 본 파일을 약 2600줄로 줄인다.
**사용자에게 보이는 동작, 입력 흐름, 콜백 안의 호출 순서, 프록시 읽기 횟수는 바꾸지 않는다.**

### 1-1. 배경

- 6개월 전 1139줄이던 파일이 3219줄, 143커밋으로 커졌다. 저장 프로퍼티 50개 중 31개를 3개 이상 섹션이 공유한다.
- extension을 다른 파일로 나누는 방식은 쓰지 않는다. Swift `private`는 파일 범위라 공유 프로퍼티 10개(`inputBuffer` 포함)와
  함수 약 23개를 `internal`로 올려야 한다. `SYKeyboard` 앱 타깃은 Base와 하위 VC를 한 모듈로 컴파일하므로 그 안에서는
  하위 VC에 노출되고, `@testable import`인 테스트가 조합 상태를 직접 건드리기 쉬워진다.
- 대신 `KeyboardUndoRedoManager`, `HangeulEnglishKeyboardModeCoordinator`처럼 상태를 가진 타입으로 뽑는다.

### 1-2. 범위

포함(약 570줄):

| 현재 `// MARK:` 섹션 | 가는 곳 |
|---|---|
| Cursor Context Suggestions | VC에 남는다(§3-3) |
| Sent Text Recording(`SentTextSnapshot` 포함) | `SuggestionSelectionCoordinator` |
| SuggestionControllerDelegate | `SuggestionSelectionCoordinator` |
| SuggestionBarDelegate | `SuggestionSelectionCoordinator` |
| ClipboardHistoryPanelDelegate 뒤의 후보 선택 처리 private extension(`synchronizeTextInputTraits`부터 `handleInputBufferSuggestion`까지) | `SuggestionSelectionCoordinator`(단 `replaceSelectedText`는 VC에 남는다) |
| Suggestion Removal | `SuggestionSelectionCoordinator` |
| Clipboard History | `ClipboardHistoryCoordinator` |
| ClipboardHistoryPanelDelegate | `ClipboardHistoryCoordinator` |
| Full Access Guide | `RequestFullAccessOverlayView.install(...)` + `UIResponder` extension |

제외(이번 PR에서 건드리지 않음):

- Text Proxy Wrapper Methods / Helper Methods: undo·삭제 내부 상태 7개를 열어야 한다.
- UI Methods / Button Action Methods / Update Methods: 프로퍼티 23개를 열어야 한다.
- Private Methods, TextInteractionGestureControllerDelegate(삭제 드래그·반복 삭제·undo/redo 접착 코드): #185.
- SwitchGestureControllerDelegate(12줄): 그대로 둔다.

## 2. 구조

새 파일 3개, 수정하는 기존 타입 1개. 새 파일은 `project.pbxproj`의 `SYKeyboard`·`SYKeyboardCore` 두 타깃
membershipExceptions에 알파벳 순으로 등록한다.

| 파일 | 역할 |
|---|---|
| `Modules/SYKeyboardCore/Presentation/Utils/Coordinators/SuggestionSelectionCoordinator.swift` | 후보 탭 처리, 전송 기록, 후보 삭제 확인 오버레이. `SuggestionControllerDelegate`, `SuggestionBarDelegate` 채택 |
| `Modules/SYKeyboardCore/Presentation/Utils/Coordinators/ClipboardHistoryCoordinator.swift` | 패널 열기·닫기, pasteboard 동기화·복사·이미지 복원, 알림 3개 처리. `ClipboardHistoryPanelDelegate` 채택. selector observer를 위해 `NSObject` 상속 |
| `Modules/SYKeyboardCore/Presentation/Utils/Extensions/UIResponder+Extension.swift` | `openURLThroughResponderChain(_:)`. 클립보드 URL 열기와 설정 이동이 함께 쓴다 |
| `Modules/SYKeyboardCore/Presentation/View/Components/Overlays/RequestFullAccessOverlayView.swift`(수정) | `install(in:onClose:onOpenSettings:)` 추가. 제약 설치와 버튼 액션 연결을 뷰 안으로 |

VC는 두 Coordinator를 `private lazy var`로 **강하게** 소유한다. Host 프로토콜 채택은 본 파일 끝의 짧은 extension에 둔다.
`setupUI`의 delegate 연결 중 `suggestionController.delegate`, `suggestionBarView.delegate`, `clipboardHistoryPanelView.delegate`가
Coordinator로 바뀐다. 두 Coordinator와 Host 프로토콜은 모듈 안에서만 쓰므로 `internal`이다.

### 2-1. 참조 방향과 메모리 규칙

```
BaseKeyboardViewController ──strong──▶ SuggestionSelectionCoordinator ──weak(host)──▶ VC
                           ──strong──▶ ClipboardHistoryCoordinator    ──weak(host)──▶ VC
SuggestionBarView.delegate / SuggestionController.delegate / ClipboardHistoryPanelView.delegate ──weak──▶ Coordinator
```

- Host는 `weak var host: ...Host?`. 모든 진입점은 `guard let host else { return }`(값 반환 메서드는 `false`/`nil`)로 시작한다.
  `unowned`를 쓰지 않는다. `DispatchQueue.main.async`, 알림, 패널 delegate가 Coordinator를 참조하므로 VC보다 오래 살 수 있다.
- **`host.textDocument`는 저장하지 않고 호출마다 접근한다.** `CachingTextDocumentProxy`를 따로 만들지 않는다.
  캐시 범위(`withReadCaching`)는 VC 콜백이 VC의 인스턴스에 켜는 것이고, 쓰기가 캐시를 비우는 것도 그 인스턴스다.
  VC 해제 뒤 `textDocument` 접근은 Debug에서 `assertionFailure`로 멈추므로, `guard let host`가 먼저 걸러야 한다.
- `DispatchQueue.main.async` 클로저는 `[weak self]`를 유지하고 안에서 다시 `guard let host`를 한다.
  VC 해제 뒤 늦게 온 알림·비동기 작업은 지금처럼 아무 일도 하지 않는다.
- Coordinator는 `textDocumentProxy`를 직접 참조하지 않는다. CLAUDE.md의 grep 확인 규칙이 추출 뒤에도 성립해야 한다.

## 3. 인터페이스

### 3-1. `SuggestionSelectionCoordinator`

init 주입(VC가 이미 가진 참조를 넘긴다): `suggestionController: SuggestionService`, `suggestionBarView: SuggestionBarView`,
`keyboardSettingsManager: UserDefaultsManager`.

`protocol SuggestionSelectionHost: AnyObject`

| 구분 | 요구사항 | 현재 VC 멤버 |
|---|---|---|
| 읽기 | `textDocument: CachingTextDocumentProxy` | 그대로 |
| 읽기 | `inputBuffer: String` | `private var` → Host getter로만 노출 |
| 읽기 | `generalSuggestionBaseText: String`, `learnableInputBuffer: String` | Cursor Context Suggestions(VC에 남음) |
| 읽기 | `isPreview: Bool` | `BaseKeyboardViewController.isPreview` |
| 읽기 | `overlayContainerView: UIView` | `view` |
| 동작 | `insertText(_:)`, `replaceText(deleteCount:insert:)` | public 래퍼 |
| 동작 | `replaceTextWithSmartInsertDeleteSpacing(deleteCount:insert:)`, `textWithSmartInsertDeleteLeadingSpace(deleteCount:insert:) -> String` | Helper |
| 동작 | `replaceSelectedText(_:with:)` | **VC로 이동**(Text Proxy Wrapper 섹션). `inputBuffer.append`와 `recordUndoRedoChange`를 하므로 쓰기 래퍼와 같은 성격 |
| 동작 | `suggestionDidApply()` | `open` 훅. 하위 VC 오버라이드가 그대로 불린다 |
| 동작 | `updateSuggestions()`, `updateSuggestionPreviewHighlight()` | Update Methods |
| 동작 | `performUndo()`, `performRedo()`, `cancelPendingDeleteInteractions()` | Private Methods / TextInteraction. #185에서 위임 한 줄로 바뀐다 |
| 동작 | `toggleClipboardPanel()` | VC가 `clipboardHistoryCoordinator.togglePanel()`로 전달 |

Coordinator가 소유하는 상태(VC에서 삭제):

| 상태 | 외부 접근 |
|---|---|
| `currentAutocorrectionType: UITextAutocorrectionType?` | `private(set)`. VC가 스마트 입력 판정(`shouldHideSuggestionBar`, 스마트 문장부호)에서 읽는다 |
| `isMathExpressionCompletionAllowed: Bool` | private. `shouldShowMathResults()`로만 노출 |
| `pendingSentTextSnapshot: SentTextSnapshot?` | private. `SentTextSnapshot`은 파일 안 `private struct` |
| `suggestionRemovalConfirmView`, `pendingSuggestionRemovalWord` | private |

VC가 부르는 메서드(호출 위치와 순서는 현재와 같다):

- `synchronizeTextInputTraits()`: `textWillChange`/`textDidChange`의 `withReadCaching` 안 첫 호출
- `shouldShowMathResults() -> Bool`: `viewDidLoad`, `updateSuggestionsForCurrentContext`
- `captureSentTextSnapshot()`: `textWillChange`에서 `pendingSentTextSnapshot = makeSentTextSnapshot()` 자리
- `recordSentTextIfNeeded()`: `textDidChange`
- `hideSuggestionRemovalConfirmation()`: `viewWillDisappear`
- `applyMathResultSuggestionAction(_:) -> Bool`: 스페이스로 수식 결과 적용(Text Interaction Methods)
- `currentAutocorrectionType`

### 3-2. `ClipboardHistoryCoordinator`

init 주입: `clipboardHistoryStore: ClipboardHistoryStore?`, `clipboardHistoryPanelView: ClipboardHistoryPanelView`,
`keyboardSettingsManager: UserDefaultsManager`.

`protocol ClipboardHistoryHost: AnyObject`

| 구분 | 요구사항 | 현재 VC 멤버 |
|---|---|---|
| 읽기 | `hasFullAccess: Bool`, `isPreview: Bool` | `UIInputViewController.hasFullAccess`, static |
| 읽기 | `isViewInWindow: Bool` | `viewIfLoaded?.window != nil` |
| 동작 | `insertText(_:)` | public 래퍼 |
| 동작 | `commitUndoRedoGroupIgnoringCompositionDeferral()`, `undoRedoEditDidApply()` | 그대로(`undoRedoEditDidApply`는 `open` 훅) |
| 동작 | `updateShowingKeyboard()`, `updateClipboardControl()`, `updateReturnButtonEnabled()`, `updateSuggestions()` | Update Methods |
| 동작 | `cancelPendingDeleteInteractions()` | TextInteraction |
| 동작 | `openURL(_:)` | VC가 `openURLThroughResponderChain`을 부른다 |

프록시 읽기는 없다. 소유 상태: `isPanelVisible`(`private(set)`, VC가 `updateShowingKeyboard`·`updateClipboardControl`에서 읽는다), 알림 observer.
`isClipboardHistoryAvailable`(설정 ON·Full Access·미리보기 아님)은 Coordinator의 private 계산 프로퍼티가 된다.

VC가 부르는 메서드:

- `registerNotificationObservers()`: `viewDidLoad`에서 지금 observer 3개를 등록하는 자리. 등록 시점을 바꾸지 않기 위해 init이 아니라 명시 호출로 한다
- `synchronizeIfNeeded()`: `viewWillAppear`, `textWillChange`
- `closePanelIfNeeded()`: `textWillChange`, `viewWillDisappear`
- `togglePanel()`: Suggestion Coordinator의 `toggleClipboardPanel` 요청
- `isPanelVisible`

### 3-3. VC에 남는 것

- `inputBuffer`, `inputBufferLeadingContext`와 Cursor Context Suggestions의 세 멤버(`captureInputBufferLeadingContextIfNeeded`,
  `generalSuggestionBaseText`, `learnableInputBuffer`). 이미 `KeyboardSuggestionSelectionPolicy`에 위임하는 접착 코드고
  Text Proxy Wrapper·라이프사이클도 쓰므로 VC의 조합 상태로 둔다. 별도 struct로 감싸지 않는다.
- `replaceSelectedText(_:with:)`: Text Proxy Wrapper 섹션으로 이동.
- `currentDocumentIdentifier()`: `textDocument.documentIdentifier`가 같은 KVC 읽기를 하므로 Coordinator는 그것을 쓴다. VC의 함수는 다른 호출처가 없으면 삭제한다.
- `requestFullAccessOverlayView`(lazy)와 `needToShowFullAccessGuide`. `viewDidLoad` 마지막의 `setupRequestFullAccessOverlayView()`가
  `requestFullAccessOverlayView.install(in: view, onClose: {...}, onOpenSettings: {...})` 한 호출로 바뀐다.

### 3-4. 접근 제어 원칙

- VC 저장 프로퍼티 중 `private`에서 `internal`로 바뀌는 것은 없다. Coordinator로 옮긴 프로퍼티는 VC에서 삭제된다.
- Host 요구사항을 채우기 위해 VC 메서드의 `private`를 떼는 경우는 Host 프로토콜 채택 extension이 같은 파일에 있으므로 생기지 않는다.
  Host 채택 extension 안에서 `private` 멤버에 접근해 전달한다.

## 4. 호출 순서 보존

함수 본문이 Coordinator로 가고 원래 자리에는 `coordinator.메서드()` 호출이 남는다. 아래 흐름이 추출 전후로 같아야 한다.

- **viewDidLoad**: `setupUI`(delegate 연결) → observer 등록(`registerNotificationObservers`) → `updateShowingKeyboard` → …
  → `suggestionController.isShowMathResultsEnabled = suggestionSelectionCoordinator.shouldShowMathResults()` → … → 전체 접근 오버레이 설치(마지막).
- **textWillChange**: `withReadCaching { synchronizeTextInputTraits(); … ; captureSentTextSnapshot(); … ; closePanelIfNeeded(); synchronizeIfNeeded() }`.
- **textDidChange**: `withReadCaching { synchronizeTextInputTraits(); … ; recordSentTextIfNeeded(); … }`.
- **후보 탭**: 바 → Coordinator → `host.cancelPendingDeleteInteractions()` → 수식 → 선택 텍스트 → NGram → 현재 단어 확정 → 입력 버퍼 순서
  → `host.insertText` 등 → `host.suggestionDidApply()` → `host.updateSuggestions()`.
- **후보 길게 누르기**: `shouldBeginRemovalAt`에서 미리보기면 `false`, 아니면 확인 오버레이 표시 후 `true`.
- **클립보드 항목 탭(텍스트)**: 커밋 → `insertText` → `undoRedoEditDidApply` → 커밋 → pasteboard 복사·`changeCount` 갱신 → `store.record` → 패널 닫기
  → `updateReturnButtonEnabled` → `updateSuggestions`.
- **클립보드 항목 탭(이미지)**: pasteboard에 원본 복원 → `changeCount` 갱신 → `store.record` → 다음 런루프에서 패널 재조회·토스트.
- **스페이스로 수식 적용**: `suggestionSelectionCoordinator.applyMathResultSuggestionAction(action)`.
- **viewWillDisappear**: `closePanelIfNeeded()`, `hideSuggestionRemovalConfirmation()`.
- **미리보기**: `isPreview`는 Host로 읽는다. 앱의 미리보기 VC가 static 플래그를 켜는 방식은 그대로다.

## 5. 검증

코드를 옮기기 **전에** 현재 동작을 고정하는 테스트를 넣고 통과시킨 뒤, 추출 후 그 테스트를 수정 없이 통과시키는 것을 증거로 삼는다.

### 5-1. VC 동작 고정 테스트 (`SYKeyboardTests/Controller/`)

실제 `BaseKeyboardViewController` 서브클래스 + `textDocumentProxy` 오버라이드로 `CountingTextDocumentProxy`를 끼운다(#186 테스트 방식).
production 진입점은 `SuggestionBarView`/`ClipboardHistoryPanelView`의 delegate 호출, `textWillChange`/`textDidChange`, 오버레이 버튼 액션이다.

- 후보 탭: NGram 후보 선택 시 앞 공백 삽입 여부에 따른 프록시 쓰기 순서, index 0 현재 단어 확정 시 프록시 쓰기 없음, 선택 텍스트 후보 대치
- 후보 탭 시 프록시 읽기 횟수(추출 전 값을 기대값으로 고정)
- 클립보드 패널 열기·닫기: 자판 뷰와 패널의 `isHidden`, 클립보드 버튼 상태
- 클립보드 항목(텍스트) 탭: `insertText` 쓰기 1회와 패널 닫힘
- 후보 길게 누르기: 확인 오버레이 표시, 취소 시 숨김, 미리보기에서는 시작하지 않음
- 전체 접근 안내: 닫기 탭 시 `isClosed`와 숨김
- 전송 판정: `textWillChange`(버퍼 있음) → 프록시를 비우고 `textDidChange` → 문장 종료 결과가 관찰 가능한 경로로 확인. 관찰할 수 없으면 5-2로 보낸다

관찰할 수 없는 항목을 억지로 넣지 않는다. CLAUDE.md 테스트 지침(production 진입점 호출, `ForTesting` 금지, private 상태 고정 금지)을 따른다.

### 5-2. Coordinator 단위 테스트 (`SYKeyboardTests/Utils/`)

가짜 Host가 호출을 순서대로 기록한다. 각 처리 경로, 미리보기 차단, `host`가 `nil`인 뒤 호출해도 크래시와 부작용이 없음.

### 5-3. 기존 테스트와 빌드

- `SYKeyboardTests` 전체(기준 894개) 통과. 4개 scheme 빌드. `iPhone 13 mini / iOS 18.6`.
- `BaseKeyboardViewControllerProxyReadTests`의 "수식 모드가 아닌 후보 갱신 알림" 테스트는 VC의 delegate 메서드를 직접 부르므로 Coordinator를 거치도록 호출 경로만 바꾼다. 기대값(프록시 읽기 0회)은 그대로다.

### 5-4. 정적 확인

- `grep -rn "textDocumentProxy" Modules Keyboards | grep -v -E ":[0-9]+:[[:space:]]*//"` 결과가 `textDocument`를 만드는 한 줄뿐.
- VC 저장 프로퍼티 중 `internal`로 바뀐 것이 없음(`private` 선언 수 비교).
- 본 파일 줄 수.

### 5-5. 시뮬레이터 확인

구현자가 `iPhone 13 mini / iOS 18.6` 시뮬레이터에서 키보드 extension을 실제 입력 앱(메시지 더미 대화, 로컬 http 서버의 웹 입력창)에
설치해 직접 확인한다. 시뮬레이터에서 통과한 항목은 완료로 기록하고 "실기기 미확인"으로 남기지 않는다.

시뮬레이터로 직접 확인하는 항목:

- 후보 탭: NGram 후보 삽입과 앞 공백, 현재 단어 확정, 선택 텍스트 후보 대치
- 후보 길게 누르기: 삭제 확인 오버레이 표시, 취소, 확인 뒤 후보에서 사라짐
- 수식 후보: 입력 중 수식의 결과 후보 탭, 스페이스로 적용
- 전송 뒤 NGram 기록: 메시지 앱에서 전송한 다음 입력에서 마지막 단어가 후보로 올라옴
- 클립보드 패널: 열기·닫기, 텍스트 항목 탭으로 붙여넣기와 패널 닫힘, 다른 앱에서 복사한 뒤 돌아왔을 때 목록 갱신
- 전체 접근 안내: Full Access를 끈 상태에서 오버레이 표시, 닫기, 설정 이동 버튼으로 앱이 열림
- 미리보기: 메인 앱 미리보기 키보드에서 클립보드 버튼이 패널을 열지 않고 후보 길게 누르기가 시작되지 않음

시뮬레이터로 확인할 수 없어 PR 본문에 "실기기 확인 필요"로 남기는 항목:

- 햅틱(후보 삭제 확인 오버레이 표시 시)
- 클립보드 이미지 항목 복원: 시뮬레이터에서 이미지 복사가 가능하면 확인하고, 불가하면 남긴다

## 6. 작업 순서

단계마다 커밋 하나. 각 커밋에서 테스트와 빌드를 확인한다. 커밋 메시지는 `refactor: #184 - …`, 테스트만이면 `test: #184 - …`, 문서는 `docs: #184 - …`.

1. VC 동작 고정 테스트 추가(현재 코드에서 통과)
2. `UIResponder+Extension`과 `RequestFullAccessOverlayView.install` 도입, VC의 Full Access Guide 섹션 교체
3. `ClipboardHistoryCoordinator` 추출과 단위 테스트. 프록시 읽기가 없고 Host 메서드가 적어 패턴을 가장 작게 검증한다
4. `SuggestionSelectionCoordinator` 추출과 단위 테스트, `ProxyReadTests` 호출 경로 조정
5. 전체 검증(5-3, 5-4, 5-5)
6. 문서 갱신(§7)

## 7. 문서 갱신

코드 작업이 끝난 뒤 아래를 새 구조에 맞춘다. 사실과 다른 문장을 고치는 것이 목적이며, 설계 배경을 길게 쓰지 않는다.

- `CLAUDE.md`: 아키텍처 절의 `BaseKeyboardViewController (~2400줄, …)` 줄 수와 책임 설명. 두 Coordinator와 Host 프로토콜을 한 줄로 추가.
- `docs/architecture/전체 아키텍처.md`: VC 책임 목록의 "`SuggestionBarDelegate`/`SuggestionControllerDelegate` 구현" 문장, 라이프사이클 표의
  `synchronizeClipboardHistoryIfNeeded`·`makeSentTextSnapshot`·`recordSentTextIfNeeded` 호출 주체.
- `docs/architecture/자동완성 로직.md`: §6 "후보 탭 처리 — SuggestionBarDelegate"의 구현 위치, 흐름도의 delegate 방향.
- `docs/architecture/삭제와 실행취소 로직.md`: `openClipboardPanel`이 Coordinator에서 `host.cancelPendingDeleteInteractions()`를 부른다는 설명.
- `docs/architecture/한영 통합 키보드.md`: `isClipboardPanelVisible` 참조와 전체 접근 안내 오버레이 설치 주체.
- `README.md`: 전체 구조 다이어그램의 `Toolbar → BaseVC`, `ClipboardPanel → BaseVC` 간선을 Coordinator 경유로, ViewController 클래스
  다이어그램에 두 Coordinator 합성 추가.

## 8. 완료 기준

- §5 전부 수행하고 결과(테스트 개수, 빌드 결과, 수동 확인 항목)를 PR 본문 검증 항목에 적는다. 하지 못한 항목은 이유를 남긴다.
- 본 파일에 `private`에서 `internal`로 바뀐 저장 프로퍼티가 없다.
- PR 제목 `Refactor/#184 BaseKeyboardViewController에서 후보 선택·클립보드·전체 접근 안내를 별도 타입으로 추출`, 연관 이슈 `- #184`.
  UI 변경이 없으므로 스크린샷 절은 뺀다.

## 9. 후속 (#185)

삭제 드래그·반복 삭제·undo/redo 접착 코드는 이 설계의 Host 패턴과 검증 틀을 재사용한다. 그때 §3-1의 `performUndo`, `performRedo`,
`cancelPendingDeleteInteractions`와 §3-2의 `commitUndoRedoGroupIgnoringCompositionDeferral`은 VC에서 새 Coordinator로 위임하는 한 줄이 되고,
이 설계의 Coordinator는 바뀌지 않는다.
