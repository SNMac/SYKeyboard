# 텍스트 클립보드 기록 및 붙여넣기 설계

## 목적

GitHub Issue #54에 따라 클립보드 기록 기능이 켜진 뒤 SY키보드가 확인한 시스템
pasteboard의 최신 텍스트를 App Group 로컬 저장소에 누적 저장하고, 사용자가 키보드
안에서 기록을 골라 현재 입력 위치에 붙여넣을 수 있게 한다.

한글·영문·한영 통합 세 keyboard extension에서 동일하게 동작하도록 구현은
`SYKeyboardCore` 안에서 끝내고, extension VC는 수정하지 않는다.

## 확인한 기준

- 작업 브랜치: `feat/#54-clipboard-history`, 기준 커밋 `8993a923`(develop).
- 세 extension의 `Info.plist`는 이미 `RequestsOpenAccess = true`다. Full Access가 꺼진
  경우의 안내 인프라(`needToShowFullAccessGuide`, `RequestFullAccessOverlayView`)가 있다.
- `SuggestionBarView`는 코드 기반이며 trailing 쪽에 undo/redo accessory
  (`SuggestionActionButtonView`, 폭 `KeyboardLayoutFigure.undoRedoButtonWidth` 44pt)가
  있다. 히트테스트는 `touchesBegan/Moved/Ended`의 frame 검사이고, 하이라이트 우선순위는
  `SuggestionHighlightPolicy.resolve(...)`가 `actionCount`를 받아 결정한다.
- 자동완성 OFF, `autocorrectionType == .no`, 텐키 상태에서는
  `KeyboardPresentationStatePolicy.shouldHideSuggestionBar`로 bar 전체가 숨겨진다.
- 심볼/숫자/텐키 키보드는 `KeyboardView.keyboardLayoutView` 안에 4변 제약으로 겹쳐
  있고 `BaseKeyboardViewController.updateShowingKeyboard()`가 `isHidden`으로 전환한다.
- `BaseKeyboardViewController.insertText(_:)`는 Smart Punctuation 없이 프록시에
  삽입하고 `inputBuffer`·undo/redo 기록을 반영한다. `undoRedoEditDidApply()`는 "직접
  변경된 텍스트 후 내부 입력 상태 동기화" 훅이며 한글 VC들이 조합 상태를 비우도록
  오버라이드하고 있다.
- `NGramPredictiveTextEngine`이 App Group 컨테이너(`DefaultValues.groupBundleID`)에
  binary plist를 `.atomic`으로 쓰는 선례가 있다. 공용 컨테이너 URL 헬퍼는 없다.
- 현재 환경에서 `selectionWillChange`/`selectionDidChange` 호출은 관찰되지 않았고,
  `textWillChange`/`textDidChange`는 필드 전환·탭·커서 이동 시 쌍으로 호출된다.
- `Modules/`에 파일을 추가하면 `project.pbxproj`의 `SYKeyboardCore`·`SYKeyboard` 예외
  목록에 알파벳순으로 등록해야 한다. Core에는 String Catalog가 없다.
- `UIPasteboard` 사용은 저장소 전체에 없다.

## 결정 사항

| 항목 | 결정 |
| --- | --- |
| pasteboard 읽기 시점 | `viewWillAppear`, `textWillChange`, 클립보드 버튼 탭. `textDidChange`·selection 콜백은 사용하지 않는다. |
| 자동완성 OFF | 클립보드 기록은 자동완성 ON 전제의 중첩 설정. 별도 진입점을 두지 않는다. |
| 패널 위치 | 자판 영역 대체. `keyboardLayoutView` 안에 겹쳐 두고 `isHidden`으로 전환한다. suggestion bar는 유지된다. |
| 항목 탭 | 붙여넣기 후 패널을 닫고 자판으로 복귀한다. |
| 개별 삭제 | 평소 모드에서 trailing swipe. 편집 모드에서는 iOS 기본 동작대로 스와이프가 막힌다. |
| 다중·전체 삭제 | 헤더의 "편집"으로 편집 모드 진입. 시스템 다중 선택 컨트롤(체크마크)을 쓰고 "전체 선택"·"n개 삭제"·"완료" 버튼을 둔다. 확인 알림은 없다. |
| 원문 전체 보기 | 행 길게 누르기 → 패널 위 상세 뷰(스크롤 가능한 읽기 전용 `UITextView` + "붙여넣기"·"닫기"). |
| 항목 고정 | leading swipe(또는 상세 뷰 버튼)로 고정/해제. 고정 항목은 고정 시각 최신순으로 맨 위에 오고 자동 정리에서 제외되며, 사용자가 직접 삭제(스와이프·편집 모드)할 때만 지워진다. 고정은 최대 20개이고 꽉 차면 미고정 행에 고정 액션을 만들지 않는다. 고정된 텍스트를 다시 복사해도 바뀌지 않는다. 해제하면 원래 복사 시각 순서의 미고정 자리로 돌아간다. |
| 기본값 | `isClipboardHistoryEnabled = false`. |
| 한도 | 미고정 최근 20개 + 고정 20개, 항목당 2,000자. 초과 텍스트는 잘라 저장하지 않고 버린다. |

## 범위 밖

- 시스템 복사 이벤트 직접 수신, 기능 활성화 이전의 iOS 클립보드 기록 가져오기.
- 이미지·파일·색상·URL 객체 저장(#55). `Item`에 대비 필드를 미리 넣지 않는다.
- `UIPasteControl`, 온보딩 페이지 추가. (앱 안의 기록 화면과 기록 삭제는 6-1절로 범위에 들어왔다.)
- App Store 개인정보 표시(privacy nutrition label) 갱신은 코드 밖 작업이며 PR 본문의
  확인 항목으로만 남긴다.

## 1. 저장소와 정책

### `ClipboardHistoryPolicy`

`Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardHistoryPolicy.swift`.
UI 의존 없는 `enum`이며 테스트 대상이다.

```swift
enum ClipboardHistoryPolicy {
    static let maxItemCount = 20
    static let maxTextLength = 2_000

    /// 저장하지 않을 텍스트면 nil. 중복은 제거 후 맨 앞에 두고 개수 초과분은 뒤에서 버린다.
    static func inserting(_ text: String, into items: [ClipboardHistoryItem], now: Date) -> [ClipboardHistoryItem]?
}
```

- 빈 문자열, 공백·개행만 있는 문자열, `count > maxTextLength`는 `nil`이다. 잘라서
  저장하면 붙여넣기 결과가 원본과 달라지므로 자르지 않는다.
- `text`가 같은 항목이 있으면 제거한 뒤 새 항목을 맨 앞에 넣는다. 결과가
  `maxItemCount`를 넘으면 뒤에서 버린다.

### `ClipboardHistoryItem`

`Codable` struct. 필드는 `text: String`, `createdAt: Date`, `pinnedAt: Date?`다. `pinnedAt`이 `nil`이면 미고정이며, 키가 없는 기존 파일은 미고정으로 읽힌다. 배열 순서가 표시 순서다(고정 최신순 → 미고정 최신순).

### `ClipboardHistoryStore`

`Modules/SYKeyboardCore/Storage/ClipboardHistoryStore.swift`.

- 파일: App Group 컨테이너의 `clipboard_history.plist`. `[ClipboardHistoryItem]`을
  `PropertyListEncoder(.binary)`로 인코딩해 `.atomic`으로 쓴다.
- designated init은 `fileURL`을 받는다. convenience init이 `DefaultValues.groupBundleID`
  컨테이너 URL을 만든다. 컨테이너 URL을 얻지 못하면 `nil`을 반환해 기능을 비활성
  상태로 두고 `fatalError`하지 않는다(Full Access가 꺼지면 컨테이너 접근이 실패할 수 있다).
- 메모리 캐시를 두지 않고 매 연산마다 읽고 쓴다. 최대 40KB 수준이라 메인 스레드
  동기 처리로 충분하고, extension 3개가 같은 파일을 쓰므로 캐시가 있으면 stale 문제가
  생긴다.
  `// ponytail: 매 연산 파일 I/O, 항목 수·길이 한도를 올리면 캐시+백그라운드 저장으로 전환`
- API:
  - `func load() -> [ClipboardHistoryItem]`: 파일이 없거나 디코딩에 실패하면 빈 배열.
  - `func record(_ text: String)`: `Policy.inserting`이 `nil`이면 아무것도 하지 않는다.
  - `func remove(at indices: [Int])`, `func removeAll()`: 파일을 삭제하지 않고 빈 배열을
    저장한다.
- 마지막으로 확인한 `changeCount`는 App Group `UserDefaults`에
  `lastSeenPasteboardChangeCount: Int`(기본값 `-1`)로 저장한다. 프로세스 로컬에 두면
  키보드가 뜰 때마다 같은 클립보드를 다시 읽어 iOS 16 권한 배너가 매번 뜬다. 세 extension이
  같은 값을 공유해 한 번만 읽는다. 기기 재시작으로 `changeCount`가 작아져도 `!=` 비교라
  최대 한 번 더 읽을 뿐이다.

### 설정 키

`UserDefaultsKeys`, `DefaultValues`, `UserDefaultsManager`(Core)에 각각 추가한다.

- `isClipboardHistoryEnabled: Bool = false`
- `lastSeenPasteboardChangeCount: Int = -1`

`UserDefaultsContractTests`에 두 키의 문자열·기본값·fallback 계약을 추가한다.

## 2. pasteboard 동기화 흐름

`BaseKeyboardViewController.swift` 안의 `// MARK: - Clipboard History` `private extension`에 둔다.
`updateShowingKeyboard()`·`updateSuggestions()`·`cancelPendingDeleteInteractions()` 등 필요한
helper가 모두 같은 파일의 `private extension`에 있어 별도 파일에서는 호출할 수 없다.
Base 본체에 추가하는 저장 프로퍼티는 다음 둘이다.

```swift
final let clipboardHistoryStore = ClipboardHistoryStore()   // Optional
var isClipboardPanelVisible = false
```

### `synchronizeClipboardHistoryIfNeeded()`

1. `UserDefaultsManager.shared.isClipboardHistoryEnabled && hasFullAccess
   && !BaseKeyboardViewController.isPreview`가 아니면 반환한다.
2. `UIPasteboard.general.changeCount`를 읽어 `lastSeenPasteboardChangeCount`와 같으면
   반환한다. 이 비교는 권한 배너를 띄우지 않는다.
3. 다르면 먼저 `lastSeenPasteboardChangeCount`를 갱신한다. 이후 읽기가 실패하거나
   저장 대상이 아니어도 같은 값을 반복해 읽지 않는다.
4. `UIPasteboard.general.hasStrings`가 true이고 pasteboard가
   `org.nspasteboard.ConcealedType` 타입을 포함하지 않을 때만(비밀번호 관리자의
   비밀 항목 제외) `.string`을 읽고 `clipboardHistoryStore?.record(text)`를 호출한다.
   iOS 기본 '암호' 앱은 이 타입 없이 `public.utf8-plain-text`만 넣는 것을 실기기 로그로 확인했다(만료 시간은 공개 API로 읽을 수 없다). 따라서 '암호' 앱에서 복사한 비밀번호는 제외하지 못하며, 이 제한을 PR 본문에 명시한다.

### 호출 시점

- `viewWillAppear`: 기존 `setKeyboardHeight()` 뒤.
- `textWillChange`: 기존 `updateSuggestionBarHidden()` 뒤. 이 시점에
  `isClipboardPanelVisible`이면 `closeClipboardPanel()`도 호출한다.
- 클립보드 버튼 탭: 패널을 열기 직전.
- `viewWillDisappear`: 동기화는 하지 않고 패널만 닫는다.
- 앱: `UIApplication.didBecomeActiveNotification`(앱 실행·포그라운드 복귀)과 클립보드 기록 관리
  화면의 `reload()`에서도 같은 규칙으로 동기화한다. 동기화 로직은
  `ClipboardHistoryPasteboardSynchronizer`(Core, public)에 있고 키보드와 앱이 공유한다.
  `lastSeenPasteboardChangeCount`를 공유하므로 같은 클립보드를 두 번 읽지 않는다.
  앱에서 `.string`을 읽을 때도 iOS 16 권한 배너가 뜰 수 있으며 '다른 앱에서 붙여넣기' 설정은
  앱과 extension이 공유한다.

### Full Access가 꺼진 경우

- 동기화를 건너뛴다. 버튼 탭 시 패널은 `.fullAccessRequired` 상태를 보여준다.
- 설정 열기 버튼은 두지 않는다. 딥링크 코드는 extension 타깃에 있어 Core에서 호출할
  수 없고, 키보드 진입 시 `RequestFullAccessOverlayView`가 이미 안내한다.

### iOS 16 붙여넣기 권한 배너

코드로 막을 수 없다. 앱 설정 토글 caption에 "설정 ➡️ SY키보드 ➡️ '다른 앱에서
붙여넣기'를 '허용'으로 바꾸면 확인 알림 없이 저장됩니다"를 넣어 안내한다.
키보드 extension 프로세스에서 배너가 안정적으로 표시되는지는 실기기에서 확인한다.

## 3. suggestion bar 버튼

### `SuggestionBarView`

- arranged subview 맨 앞에 `clipboardButton`(`SuggestionActionButtonView`, 폭
  `undoRedoButtonWidth`)과 `clipboardDivider`(1pt × `suggestionButtonDividerHeight`)를
  추가한다. 둘 다 `isHidden = true`로 시작한다.
- 아이콘: 패널이 닫혀 있으면 `doc.on.clipboard`, 열려 있으면 `keyboard`. 열린 상태에서
  다시 탭하면 자판으로 돌아간다는 뜻이다.
- `undoRedoButtons`를 `actionButtons = [clipboardButton, undoButton, redoButton]`로
  넓히고 `undoRedoButton(at:)`을 `actionButton(at:)`으로 바꾼다.
  `SuggestionHighlightPolicy.resolve`는 `actionCount`를 받으므로 수정하지 않는다.
- `updateDividers()`에 규칙 하나를 추가한다: `clipboardButton` 또는 `suggestionButton1`이
  하이라이트면 `clipboardDivider`를 `.clear`로 둔다.
- 추가 API: `func updateClipboardControl(isVisible: Bool, isPanelVisible: Bool)`.
- `SuggestionBarDelegate`에 `func suggestionBarDidTapClipboard(_ view: SuggestionBarView)`
  추가.

### 표시 조건

`KeyboardPresentationStatePolicy`에 추가한다.

```swift
static func shouldShowClipboardControl(isSuggestionBarHidden: Bool, isClipboardHistoryEnabled: Bool) -> Bool {
    return !isSuggestionBarHidden && isClipboardHistoryEnabled
}
```

bar가 보일 때는 자동완성 ON이 보장되므로 중첩 설정 조건이 함께 충족된다.
`BaseKeyboardViewController.updateUndoRedoControls()`와 같은 자리에서
`updateClipboardControl()`을 호출한다.

## 4. 기록 패널

### `ClipboardHistoryPanelView`

`Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift`.
저장소를 모르는 표시 전용 뷰다.

구성:

- 헤더 줄(높이 고정): 평소에는 왼쪽 "클립보드 기록" 라벨, 오른쪽 "편집" 버튼.
  편집 모드에서는 왼쪽 "전체 선택"(모두 선택되면 "선택 해제"), 오른쪽 "n개 삭제"와
  "완료". "n개 삭제"는 선택 0개면 비활성. 항목이 0개면 "편집"도 비활성.
- `UITableView`(plain, 배경 투명). 셀은 `UIListContentConfiguration`으로 텍스트 2줄
  tail 생략. `allowsMultipleSelectionDuringEditing = true`.
- 상세 뷰(패널 전체를 덮는 subview, 기본 숨김): 상단 "원문" 라벨과 "닫기", 가운데
  읽기 전용 `UITextView`(스크롤), 하단 "붙여넣기".
- 빈 상태 라벨 "복사한 텍스트가 여기에 표시됩니다", Full Access 안내 라벨
  "전체 접근 허용이 필요합니다". 두 상태에서는 헤더의 "편집"을 숨긴다.

상태 입력:

```swift
enum State { case fullAccessRequired, empty, items([ClipboardHistoryItem]) }
func configure(state: State)
func resetPresentation()   // 편집 모드 해제, 상세 뷰 닫기, 스크롤 맨 위
```

`configure`는 편집 모드를 유지한 채 목록만 갱신하되, 항목이 0개가 되면 편집 모드를
해제한다.

동작:

- 평소 모드 행 탭 → `delegate.clipboardPanel(_:didSelectItemAt:)`.
- 평소 모드 trailing swipe → `UIContextualAction(style: .destructive)`(`trash.fill`
  아이콘, 제목 "삭제"는 접근성용) → `delegate.clipboardPanel(_:didDeleteItemsAt: [index])`.
- 평소 모드 행 길게 누르기(`UILongPressGestureRecognizer`, `minimumPressDuration` 기본값)
  → 상세 뷰 표시. 편집 모드에서는 무시한다.
- 상세 뷰 헤더의 "브라우저에서 열기"(`safari` 아이콘)는 항목 전체가 http/https URL 하나일 때만
  보인다(`ClipboardHistoryPolicy.openableURL(in:)`). 누르면
  `delegate.clipboardPanel(_:didRequestOpenURLAt:)` → Base가 설정 이동과 같은 responder chain
  경로로 `UIApplication.open`을 호출한다. 브라우저가 뜨면 호스트 앱을 떠나므로 키보드는
  시스템이 내린다. 이 경로는 Apple 문서에 없는 동작이며 설정 이동 버튼과 같은 수준으로 취급한다.
- 상세 뷰 "붙여넣기" → 먼저 `didTogglePin`과 같은 경로의 `didRequestCopyAt`으로 항목을 시스템
  pasteboard에 복사한 뒤(Full Access 필요, `changeCount`를 갱신해 재기록하지 않음) 행 탭과 같은
  `didSelectItemAt`으로 붙여넣는다. 붙여넣은 항목이 현재 클립보드가 된다. 행 탭은 복사하지 않는다.
  "닫기" → 상세 뷰만 닫는다.
- 편집 모드 행 탭 → 선택 토글(붙여넣기 안 함). "n개 삭제" → 전부 선택이면
  `delegate.clipboardPanelDidDeleteAll(_:)`, 아니면 `didDeleteItemsAt:`(선택 인덱스).
  "완료" → 편집 모드 해제.

델리게이트:

```swift
protocol ClipboardHistoryPanelDelegate: AnyObject {
    func clipboardPanel(_ view: ClipboardHistoryPanelView, didSelectItemAt index: Int)
    func clipboardPanel(_ view: ClipboardHistoryPanelView, didDeleteItemsAt indices: [Int])
    func clipboardPanelDidDeleteAll(_ view: ClipboardHistoryPanelView)
}
```

색상은 `SYKeyboardAssets`의 기존 키보드 배경·버튼 색을 재사용한다. 정확한 색·폰트·
SF Symbol 이름은 테스트로 고정하지 않는다.

### 로컬라이징

`SYKeyboardCore`는 정적 라이브러리(`MACH_O_TYPE = staticlib`)라 Core 타깃에 둔
String Catalog는 extension·앱 번들에 복사되지 않고, `Bundle(for:)`도 호스트의 main
번들을 돌려준다. 그래서 Core 코드가 쓰는 문자열은 Core가 XIB를 읽는 곳과 같은 로컬 SPM
패키지 `SYKeyboardAssets`의 `Sources/SYKeyboardAssets/Resources/Localizable.xcstrings`에
두고 `String(localized:bundle: SYKBDAssets.bundle)`로 읽는다. SPM은 정적 링크여도 리소스
번들(`SYKeyboardAssets_SYKeyboardAssets.bundle`)을 앱과 세 extension에 각각 복사하므로
배포 문제가 없고, `Package.swift`에는 `defaultLocalization: "ko"`가 필요하다. 앱 설정
화면이 직접 쓰는 문자열은 앱의 `Localizable.xcstrings`에 넣는다. 모든 새 문자열에 en
번역을 추가한다.

Assets 카탈로그의 항목은 `extractionState`를 `manual`로 둔다. 패키지 타깃의 소스는
번들 접근자뿐이라 Xcode 추출기가 사용처(Core)를 보지 못하고, 비워 두면 빌드 때
`stale`로 표시된다.

(초안은 `Modules/SYKeyboardCore/Resources/Localizable.xcstrings`를 만들어
`Bundle(for:)`로 읽는 방식이었으나 영어 기기에서 세 키보드 모두 한국어로만 표시됐고,
그다음 extension 공용 `Keyboards/Common` 카탈로그와 앱 카탈로그에 중복해 넣는 방식을
거쳐 위 방식으로 정리했다. 같은 이유로 extension마다 두던 전체 접근 허용 안내
`RequestFullAccessOverlayView`와 그 설정 코드도 Core(`BaseKeyboardViewController`)로
옮겨 `Keyboards/Common`을 없앴다.)

## 5. `KeyboardView`·`BaseKeyboardViewController` 연결

### `KeyboardView`

- `lazy var clipboardHistoryPanelView`를 추가하고 심볼/숫자/텐키 키보드와 같은 4변
  제약으로 `keyboardLayoutView`에 넣는다. `isHidden = true`로 시작한다. 높이·한 손 모드·
  가로 모드는 자동으로 따라간다.

### `BaseKeyboardViewController`

- `setDelegates()`에서 `clipboardHistoryPanelView.delegate = self`.
- `updateShowingKeyboard()` 끝에서 `isClipboardPanelVisible`이면 자판 뷰를 모두 숨기고
  패널만 보인다. 그렇지 않으면 패널을 숨긴다.
- `suggestionBarDidTapClipboard`:
  - 열려 있으면 `closeClipboardPanel()`.
  - 닫혀 있으면 `synchronizeClipboardHistoryIfNeeded()` → `reloadClipboardPanel()` →
    `isClipboardPanelVisible = true` → `updateShowingKeyboard()` →
    `updateClipboardControl()`.
- `reloadClipboardPanel()`: `hasFullAccess`가 false거나 store가 `nil`이면
  `.fullAccessRequired`, `load()`가 비면 `.empty`, 아니면 `.items`.
- `closeClipboardPanel()`: `isClipboardPanelVisible = false`, `resetPresentation()`,
  `updateShowingKeyboard()`, `updateClipboardControl()`.
- `clipboardPanel(_:didSelectItemAt:)`:
  1. `commitUndoRedoGroupIgnoringCompositionDeferral()`
  2. `insertText(item.text)`
  3. `commitUndoRedoGroupIfPossible()`
  4. `undoRedoEditDidApply()` — 이 훅의 계약이 "직접 변경된 텍스트 후 내부 상태
     동기화"이고 한글 VC들이 조합 상태를 비우도록 이미 오버라이드하고 있어 새 훅과
     하위 VC 수정이 필요 없다. 훅 주석에 붙여넣기 경로도 명시한다.
  5. `closeClipboardPanel()`, `updateSuggestions()`.
  붙여넣기가 undo 1단위가 되는지는 구현 시 `UndoRedoSession` 동작으로 확인한다.
- `didDeleteItemsAt` / `DidDeleteAll`: store에 반영한 뒤 `reloadClipboardPanel()`.
- `viewWillDisappear`, `textWillChange`: `closeClipboardPanel()`.

### 세 extension VC

수정하지 않는다.

## 6. 앱 설정 화면

`SYKeyboard/Presentation/KeyboardSettings/PredictiveTextSettingsView.swift`의
`if isPredictiveTextEnabled` 블록 안, Undo/Redo 토글 아래에 추가한다.

- `@AppStorage(UserDefaultsKeys.isClipboardHistoryEnabled, store: UserDefaultsManager.shared.storage)`
- 라벨 "클립보드 기록", caption "복사한 텍스트를 키보드에서 붙여넣기\n설정 ➡️ SY키보드
  ➡️ '다른 앱에서 붙여넣기'를 '허용'으로 바꾸면 확인 알림 없이 저장됩니다".
- 기존 토글과 같은 `Analytics.setUserProperty`/`logEvent`와 `hideKeyboard()`.
- 토글을 꺼도 기록은 지우지 않는다.

## 6-1. 앱의 클립보드 기록 관리 화면

`SYKeyboard/Presentation/KeyboardSettings/ClipboardHistorySettingsView.swift`.
클립보드 기록 토글이 ON일 때만 그 아래에 `NavigationLink("클립보드 기록 관리")`가 보인다.

- 키보드 패널과 같은 목록(고정 최신순 → 미고정 최신순), 고정 행은 `pin.circle.fill`.
  행 탭은 원문 전체를 보는 상세 화면이다(붙여넣기는 없다).
- leading swipe 고정/해제, trailing swipe 삭제(`trash.fill`), 편집 모드 다중 선택과 하단
  툴바의 "전체 선택" · "n개 고정" · "n개 삭제". 규칙은 키보드 패널과 같다.
- "n개 고정"은 선택 중 미고정 항목만 고정하며 n은 그 개수다(선택 수를 세는 "n개 삭제"와
  다르다). 선택이 전부 고정이면 "n개 고정 해제"로 바뀌어 모두 해제한다. 대상이 없거나
  현재 고정 수와 합쳐 한도를 넘기면 비활성. 선택은 유지된다. 키보드 패널에는 두지 않는다.
  규칙은 `ClipboardHistoryPolicy.pinBatch(selectedTexts:in:)`에 있고 뷰는 결과만 읽는다.
  저장은 `ClipboardHistoryStore.togglePins(selectedTexts:)`가 파일을 한 번 읽고 한 번 쓴다.
  함께 고정한 항목은 고정 시각을 목록 순서대로 1ms씩 앞당겨 목록에서 보던 순서 그대로 위에 온다.
- "n개 삭제"는 하단 바에서 `role: .destructive`만으로 빨간색이 되지 않으므로 `.tint(.red)`를 준다.
  "편집"/"완료" 버튼은 두 문구 중 넓은 폭으로 고정해 전환할 때 위치가 흔들리지 않게 한다.
- 원문 하프 시트의 툴바에는 항목 전체가 http/https URL일 때만 "브라우저에서 열기"(`safari`)를
  복사 버튼 왼쪽에 두고 `openURL` 환경값으로 연다.
- Core 코드가 쓰는 문자열은 "로컬라이징" 절에 따라 Assets 카탈로그에 `manual`로 둔다.
- 툴바 `+`("추가") → "고정 항목 추가" 시트의 `TextEditor`에 직접 입력해 저장한다.
  저장한 항목은 `recordPinned`로 고정 항목이 되어 맨 위에 온다. 공백만이거나 2,000자
  초과면 저장이 비활성이고, 고정 20개가 차면 "추가" 자체가 비활성이다.
- 목록은 `onAppear`와 앱 재활성화 시 `store.load()`로 다시 읽는다.
- 목록 footer(빈 상태에서는 안내 아래)에 현재 개수와 한도(고정 n/20 · 최근 n/20)와 정리 규칙을 표시한다.
- 앱은 `SYKeyboardCore`를 framework로 링크하므로 `ClipboardHistoryStore`·`ClipboardHistoryItem`·
  `ClipboardHistoryPolicy`는 `public`이다.

## 7. 오류 처리

- 컨테이너 URL 실패, 파일 읽기·디코딩 실패: 빈 목록으로 취급하고 crash하지 않는다.
- 파일 쓰기 실패: 무시하고 다음 기회에 다시 쓴다. `lastSeenPasteboardChangeCount`는 이미
  갱신됐으므로 같은 텍스트를 재시도하지 않는다. 이는 의도한 단순화다.
- `.string`이 `nil`(권한 거부 등): 저장하지 않는다.
- 패널이 열린 상태에서 다른 extension이 파일을 바꾼 경우: 다음 `reloadClipboardPanel()`
  에서 반영된다. 삭제 인덱스는 항상 직전 `load()` 결과 기준이며, 삭제 직전에 다시
  `load()`해 길이를 확인하고 범위 밖 인덱스는 무시한다.

## 8. 테스트와 검증

Swift Testing, `SYKeyboardTests/`.

- `ClipboardHistoryPolicyTests`: 빈 문자열·공백만·2,001자는 `nil`, 2,000자는 저장,
  중복은 맨 앞으로 이동하며 개수 유지, 21번째 추가 시 가장 오래된 항목 제거, 순서 보존.
- `ClipboardHistoryStoreTests`: 임시 디렉터리 `fileURL`로 `record → load` 왕복,
  `remove(at:)`, `removeAll()`, 손상된 파일이면 빈 배열, 범위 밖 인덱스 무시.
- `KeyboardPresentationStatePolicyTests`: `shouldShowClipboardControl` 4조합.
- `UserDefaultsContractTests`: `isClipboardHistoryEnabled`,
  `lastSeenPasteboardChangeCount` 계약.
- `SuggestionBarViewPreviewHighlightTests`와 같은 방식으로 클립보드 버튼 위치 터치 시
  후보 하이라이트가 잡히지 않는 케이스 1건.
- 빌드: `SYKeyboard` 테스트, `HangeulKeyboard`·`EnglishKeyboard`·`HangeulEnglishKeyboard`
  scheme 빌드. 기준 시뮬레이터는 CLAUDE.md의 `iPhone 13 mini / iOS 16.0`이며 없으면
  가장 가까운 iOS 16+ 시뮬레이터로 조정하고 결과에 기기명을 적는다.
- 실기기 확인(자동 테스트로 대체 불가): 권한 배너 표시 여부와 "다른 앱에서 붙여넣기"
  설정 후 사라짐, 복사 → 키보드 재등장·필드 전환·버튼 탭에서 기록 반영, 한글 조합 중
  붙여넣기 후 다음 자모가 새 글자로 시작, 붙여넣기 undo 1단위, 편집 모드 체크마크와
  라벨 들여쓰기, 스와이프 삭제, 길게 누르기 상세 뷰, Full Access OFF 안내, 한 손 모드·
  가로 모드에서 패널 폭·높이. 관찰하지 못한 항목은 미확인으로 기록한다.

## 9. 파일 목록

새 파일 (`Modules/SYKeyboardCore/`, pbxproj `SYKeyboardCore`·`SYKeyboard` 예외 목록에
알파벳순 등록):

- `Presentation/Utils/Policies/ClipboardHistoryPolicy.swift`
- `Presentation/View/ClipboardHistoryPanelView.swift`
- `Resources/Localizable.xcstrings`
- `Storage/ClipboardHistoryStore.swift`

새 테스트 (`SYKeyboardTests/`, pbxproj 등록 불필요):

- `Storage/ClipboardHistoryStoreTests.swift`
- `Utils/ClipboardHistoryPolicyTests.swift`

수정 파일:

- `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift`, `DefaultValues.swift`,
  `UserDefaultsManager.swift`
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardPresentationStatePolicy.swift`
- `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift`
- `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift`
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- `SYKeyboard/Presentation/KeyboardSettings/PredictiveTextSettingsView.swift`
- `SYKeyboard/Resources/Localizable.xcstrings`
- `SYKeyboardTests/Storage/UserDefaultsContractTests.swift`
- `SYKeyboardTests/Utils/KeyboardPresentationStatePolicyTests.swift`
- `SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift`
- `SYKeyboard.xcodeproj/project.pbxproj`

건드리지 않는 것: 세 extension VC, Firebase/AdMob, entitlements, `Info.plist`,
`Secrets.xcconfig`, `.xcscheme`.
