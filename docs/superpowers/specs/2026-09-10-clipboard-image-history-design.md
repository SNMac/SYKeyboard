# 클립보드 기록 이미지 항목 지원 설계

## 목적

GitHub Issue #55에 따라 #54의 텍스트 클립보드 기록을 확장해, 시스템 pasteboard에
텍스트 없이 이미지만 있을 때 그 이미지를 App Group 파일 저장소에 저장하고, 사용자가
키보드 패널이나 앱 관리 화면에서 이미지 항목을 고르면 시스템 pasteboard에 원본
바이트를 복원해 이미지 붙여넣기를 지원하는 앱에서 붙여넣을 수 있게 한다.

커스텀 키보드 extension은 `UITextDocumentProxy`로 텍스트만 삽입할 수 있으므로 이미지
항목 선택은 "입력창 직접 삽입"이 아니라 "시스템 pasteboard에 복원"으로 동작한다.
동영상·GIF·일반 파일 첨부는 범위 밖이다.

## 확인한 기준

- 기준 브랜치 `develop`, 기준 커밋 `b94f2e96`(#54 병합).
- #54 구현은 `text`가 곧 항목 식별자다. `ClipboardHistoryItem.id`, diffable snapshot
  식별자, 텍스트 기준 삭제(`remove(texts:)`), 편집 병합(`replacingText`), 앱 관리 화면의
  `Set<String>` 선택이 모두 텍스트에 기댄다.
- `ClipboardHistoryStore`는 캐시 없이 매 연산마다 App Group의 `clipboard_history.plist`를
  읽고 쓴다. 세 extension과 앱이 같은 파일을 공유한다.
- `ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded`는 `changeCount` →
  concealed 타입 → `hasStrings` → `string` 순으로 확인하며 키보드(`viewWillAppear`,
  `textWillChange`, 클립보드 버튼 탭)와 앱(활성화 시)이 함께 호출한다.
- `UIPasteboard.hasImages`·`changeCount`·`types`·`itemProviders` 확인은 iOS 16 붙여넣기
  권한 알림을 띄우지 않는다. 이미지 데이터 읽기는 텍스트 읽기와 같은 알림 대상이다.
  pasteboard 쓰기는 알림 대상이 아니다.
- `UIPasteboard.setData(_:forPasteboardType:)`는 UIImage 재인코딩 없이 원본 바이트를
  pasteboard에 놓는다. Context7의 UIKit 문서로 `hasImages`, `itemProviders`(iOS 11+),
  `data(forPasteboardType:)`, `setData(_:forPasteboardType:)`를 확인했다. ImageIO 썸네일
  API는 Context7에 없어 WWDC18 Image and Graphics Best Practices의 downsampling 기법을
  기준으로 삼았다.
- 키보드 extension 메모리 상한은 기기별로 다르지만 수십 MB 수준이고 초과 시 즉시
  종료된다. `os_proc_available_memory()`(iOS 13+)로 남은 메모리를 알 수 있다.
- `BaseKeyboardViewController.didReceiveMemoryWarning`은 예측 엔진 캐시를 해제하는
  훅이 이미 있다.
- `NGramPredictiveTextEngine`이 백그라운드 큐에서 App Group 파일을 저장하는 선례가
  있다.
- #54 설계 문서는 "이미지 저장(#55)에 대비한 필드를 `Item`에 미리 넣지 않는다"고
  정했다. 이번 변경이 그 확장을 담당한다.
- `Modules/`에 파일을 추가하면 `project.pbxproj`의 `SYKeyboardCore`·`SYKeyboard` 예외
  목록에 알파벳순으로 등록해야 한다.

## 결정 사항

| 항목 | 결정 |
| --- | --- |
| 결합 구조 | 단일 목록. `ClipboardHistoryItem`에 `content` enum(text/image)을 넣고 식별자를 `id`로 일반화한다. 이미지도 고정·일괄 고정 대상이다. |
| 이미지 식별 | 원본 바이트의 SHA-256(스트리밍 계산). 바이트가 같은 이미지를 다시 복사하면 텍스트와 같은 규칙으로 기존 항목이 맨 위로 오고 고정 항목은 그대로다. 파일명도 해시라 중복 파일이 생기지 않는다. 시각적 유사 판별은 하지 않는다. |
| 개수 한도 | 텍스트와 공유. 미고정 20개·고정 20개 안에 텍스트와 이미지가 함께 들어간다. |
| 이미지당 한도 | 파일 12 MB, 24,000,000픽셀. 초과하면 저장하지 않는다. |
| 혼합 우선순위 | pasteboard에 텍스트가 있으면 텍스트만 저장한다. 텍스트가 없고 이미지가 있을 때만 이미지를 저장한다. |
| 저장 타입 | `public.jpeg` → `public.heic` → `public.png` 우선순위로 하나. TIFF·GIF 등은 받지 않는다. |
| 설정 | "클립보드 기록" 아래 "이미지도 기록" 하위 토글, 기본 켜짐. 끄면 새 이미지만 저장하지 않고 기존 이미지 항목은 유지한다. 삭제는 관리 화면에서 한다. |
| 키보드 패널 이미지 탭 | pasteboard에 복원하고 패널을 유지한다. 헤더의 "클립보드 기록" 제목 자리에 안내 문구를 약 2초 보여준 뒤 되돌린다. 항목은 맨 위로 올라간다. 입력창 탭 시 기존 `textWillChange` 경로로 패널이 닫힌다. |
| 썸네일 | 긴 변 240 px JPEG. 패널은 썸네일만 읽고 해시 키 `NSCache`(상한 40)에 둔다. 메모리 경고 시 비운다. |
| 메모리 안전장치 | 캡처 전 `os_proc_available_memory()`가 한도의 2배 + 여유보다 작으면 이번 캡처를 건너뛴다. `changeCount`는 갱신하므로 재시도하지 않는다. |
| 파일 정리 | `ClipboardHistoryStore.save`가 저장 전후 이미지 해시 차집합의 원본·썸네일을 지운다. |

## 범위 밖

- 동영상, GIF, 일반 파일, 여러 이미지가 든 pasteboard의 두 번째 이후 항목.
- 시각적 유사 이미지 중복 판별, 이미지 편집, 이미지 항목의 원문 편집.
- 토글 OFF 시 자동 삭제, "이미지 기록 모두 삭제" 버튼.
- 고아 파일 정기 정리. 항목 삭제 경로에서 파일을 함께 지우므로 정상 동작에서는 생기지
  않는다.

## 1. 모델·정책

### `ClipboardImageReference`

`Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardHistoryPolicy.swift`에 둔다.

```swift
public struct ClipboardImageReference: Codable, Equatable {
    public let hash: String            // SHA-256 hex. 파일명이자 식별자
    public let typeIdentifier: String  // "public.jpeg" | "public.heic" | "public.png"
    public let byteSize: Int
    public let pixelWidth: Int         // EXIF 회전을 적용한 표시 기준 크기
    public let pixelHeight: Int
}
```

파일 경로는 해시와 타입에서 유도하므로 저장하지 않는다. 이슈 본문의 `lastUsedAt`은
텍스트처럼 재기록 시 `createdAt`이 갱신되어 맨 위로 오므로 두지 않는다.

### `ClipboardHistoryItem`

```swift
public struct ClipboardHistoryItem: Codable, Equatable, Identifiable {
    public enum Content: Equatable {
        case text(String)
        case image(ClipboardImageReference)
    }
    public let content: Content
    public let createdAt: Date
    public let pinnedAt: Date?

    /// 텍스트는 텍스트 자체, 이미지는 "image/<hash>"
    public var id: String
    public var text: String?                    // .text일 때만
    public var image: ClipboardImageReference?  // .image일 때만
    public var isPinned: Bool
}
```

- 기존 `init(text:createdAt:pinnedAt:)`를 유지하고 `init(content:createdAt:pinnedAt:)`를
  추가한다.
- Codable은 직접 구현한다. 키는 `text`, `image`, `createdAt`, `pinnedAt`. 디코드는
  `image` 키가 있으면 이미지, 없으면 `text`를 읽는다. 인코드는 텍스트면 `text`만,
  이미지면 `image`만 쓴다. `text` 키만 있는 기존 파일은 마이그레이션 없이 읽힌다.
- 텍스트 `id`와 이미지 `id`("image/" 접두)의 충돌은 사용자가 정확히 그 문자열을
  복사할 때만 생긴다. `load()`가 `id` 기준으로 첫 항목만 남기므로 snapshot이 crash하지
  않는다.

### `ClipboardHistoryPolicy` 변경

- `inserting(_:into:now:)`, `insertingPinned(_:into:now:)`는 `Content`를 받는다. 빈
  문자열·공백·`maxTextLength` 검사는 `.text`일 때만 적용한다. 중복 비교는
  `$0.content == content`.
- `sorted`의 동률 비교는 `text` 대신 `id`.
- `pinBatch(selectedTexts:in:)` → `pinBatch(selectedIDs:in:)`,
  `togglingPins(selectedTexts:in:now:)` → `togglingPins(selectedIDs:in:now:)`.
- `replacingText(_:with:in:now:)`는 대상 항목이 `.text`가 아니면 `nil`. `openableURL`은
  변경 없음.
- 고정 한도 `maxPinnedCount`, 미고정 한도 `maxItemCount`, 정렬 규칙은 텍스트·이미지
  구분 없이 그대로 적용된다.

### `ClipboardImagePolicy` (신규)

`Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardImagePolicy.swift`. UI 의존
없는 순수 타입이다.

```swift
public enum ClipboardImagePolicy {
    public static let maxByteSize = 12 * 1_024 * 1_024
    public static let maxPixelCount = 24_000_000
    public static let thumbnailMaxPixelSize = 240
    public static let preferredTypeIdentifiers = ["public.jpeg", "public.heic", "public.png"]
    /// 캡처 전 남아 있어야 하는 메모리. 파일 바이트가 일시적으로 두 번 올라올 수 있는 경우를 대비한다
    public static let requiredAvailableMemory = maxByteSize * 2 + 8 * 1_024 * 1_024

    /// pasteboard 타입 목록에서 저장할 타입 하나. 우선순위 앞쪽부터 고르고 없으면 nil
    public static func storableType(in types: [String]) -> String?
    /// 바이트·픽셀 한도 안인지. 0 이하 값은 저장 불가
    public static func isStorable(byteSize: Int, pixelWidth: Int, pixelHeight: Int) -> Bool
    public static func hasEnoughMemory(available: Int) -> Bool
    /// 원본 파일 확장자. jpg / heic / png
    public static func fileExtension(for typeIdentifier: String) -> String
}
```

### 설정 키

- `UserDefaultsKeys.isClipboardImageHistoryEnabled = "isClipboardImageHistoryEnabled"`
- `DefaultValues.isClipboardImageHistoryEnabled: Bool = true`
- `UserDefaultsManager.isClipboardImageHistoryEnabled` (`@UserDefaultsWrapper`)
- `UserDefaultsContractTests`에 키·기본값 계약을 추가한다.

## 2. 이미지 파일 저장소 `ClipboardImageStore`

`Modules/SYKeyboardCore/Storage/ClipboardImageStore.swift`. Foundation·ImageIO·CryptoKit·
UniformTypeIdentifiers만 쓰고 UIKit은 쓰지 않는다.

### 파일 배치

App Group 컨테이너 아래 `ClipboardImages/` 하나다.

```
ClipboardImages/
  <hash>.jpg          원본 (확장자는 typeIdentifier에서 유도)
  <hash>.thumb.jpg    썸네일 (항상 JPEG, 긴 변 240 px, 품질 0.7)
```

### 공개 API

```swift
public final class ClipboardImageStore {
    init(directoryURL: URL)
    public convenience init?()   // App Group 컨테이너를 못 얻으면 nil

    /// 임시 파일의 이미지를 검사·해시·저장하고 참조를 돌려준다. 저장 대상이 아니면 nil.
    /// 백그라운드 스레드에서 부른다. 실패 시 파일을 남기지 않는다
    public func store(temporaryFileURL: URL, typeIdentifier: String) -> ClipboardImageReference?

    public func originalURL(for reference: ClipboardImageReference) -> URL
    public func thumbnailURL(for reference: ClipboardImageReference) -> URL

    /// 항목이 지워질 때 원본·썸네일을 함께 지운다. 없는 파일은 무시한다
    public func removeFiles(for hashes: Set<String>)
    public func removeAllFiles()
}
```

### `store(temporaryFileURL:typeIdentifier:)` 순서

각 단계가 실패하면 즉시 `nil`이고 새로 만든 파일은 지운다.

1. `FileManager` 속성으로 파일 크기를 읽어 `maxByteSize` 검사. 바이트를 메모리에 올리지
   않는다.
2. `CGImageSourceCreateWithURL` + `CGImageSourceCopyPropertiesAtIndex`로 픽셀 크기를
   헤더에서 읽어 `maxPixelCount` 검사. `kCGImagePropertyOrientation`이 5~8이면 폭·높이를
   바꿔 기록한다.
3. `FileHandle`로 64 KB씩 읽어 CryptoKit `SHA256`을 스트리밍 계산한다. 상수 메모리다.
4. 디렉터리가 없으면 만든다. 원본 경로에 같은 해시 파일이 있으면 쓰기를 건너뛰고,
   없으면 임시 파일을 `moveItem`으로 옮긴다. 이동 실패 시 대상이 이미 존재하면 성공으로
   본다.
5. 썸네일 파일이 없으면 `CGImageSourceCreateThumbnailAtIndex`로 만든다. 옵션은
   `kCGImageSourceThumbnailMaxPixelSize: 240`, `kCGImageSourceCreateThumbnailFromImageAlways:
   true`, `kCGImageSourceCreateThumbnailWithTransform: true`. `CGImageDestination`으로 JPEG
   품질 0.7로 쓴다. 실패하면 이번에 옮긴 원본을 지우고 `nil`이다.
6. `ClipboardImageReference`를 돌려준다.

### 파일 정리 책임

`ClipboardHistoryStore`는 생성자에서 `ClipboardImageStore?`를 받는다. `save(_:)`가
저장 전 목록과 저장 후 목록의 이미지 해시 차집합을 구해 `removeFiles(for:)`를 부른다.
`record`·`remove`·`removeAll`·트리밍 어느 경로로 빠지든 한 곳에서 처리된다.
`removeAll`은 `removeAllFiles()`를 부른다. 텍스트 항목만 바뀐 저장은 파일 삭제를
호출하지 않는다.

### 동시성

세 extension과 앱이 같은 디렉터리를 쓴다. 파일명이 해시라 두 프로세스가 같은 이미지를
동시에 저장해도 같은 파일이다. plist는 기존처럼 atomic 쓰기이고 마지막 쓰기가 이긴다.
정리에서 이미 없는 파일의 삭제 실패는 무시한다.

### 메모리

이 클래스가 한 번에 올리는 것은 64 KB 해시 버퍼와 썸네일 디코드뿐이다. JPEG·HEIC는
축소 디코드라 작고, PNG는 ImageIO가 전체 디코드할 수 있어 24 MP PNG에서 약 96 MB 피크가
날 수 있다. 실기기 계측(6절)에서 종료가 확인되면 PNG 전용 픽셀 상한 상수를 추가한다.

## 3. 동기화·복원 흐름

### `ClipboardHistoryPasteboardSynchronizer` 확장

```swift
public static func synchronizeIfNeeded(
    store: ClipboardHistoryStore,
    imageStore: ClipboardImageStore?,
    pasteboard: UIPasteboard = .general,
    settings: UserDefaultsManager = .shared,
    availableMemory: () -> Int = { Int(os_proc_available_memory()) },
    onImageRecorded: (@MainActor () -> Void)? = nil
)
```

1. `changeCount` 비교·갱신. 기존과 같다.
2. concealed 타입 검사. 기존과 같다.
3. `hasStrings`면 텍스트를 기록하고 끝낸다. 기존과 같다.
4. 텍스트가 없고 `hasImages`이며 `settings.isClipboardImageHistoryEnabled`이고 `imageStore`가
   있을 때만 이미지 경로로 간다.
5. `ClipboardImagePolicy.storableType(in: pasteboard.types)`로 타입을 고른다. 없으면 끝낸다.
6. `ClipboardImagePolicy.hasEnoughMemory(available: availableMemory())`가 거짓이면 끝낸다.
7. `pasteboard.itemProviders.first?.loadFileRepresentation(forTypeIdentifier:)`를 부른다.
   완료 클로저는 백그라운드 스레드에서 오며 시스템 임시 파일은 클로저가 끝나면
   사라지므로, 그 안에서 `imageStore.store(temporaryFileURL:typeIdentifier:)`를 실행해
   이동까지 마친다.
8. 참조를 얻으면 메인 큐로 넘어가 `store.record(.image(reference))`를 부르고
   `onImageRecorded`를 호출한다. 파일 저장만 백그라운드에서 하고 plist 기록은 메인에서
   해 같은 프로세스 안의 연산 순서를 단순하게 유지한다.

`loadFileRepresentation`이 pasteboard 항목에서 우리 프로세스 메모리를 거치지 않는지는
문서로 확정되지 않는다. 6단계의 메모리 안전장치와 6절의 실기기 계측으로 보완한다.

### 키보드 `BaseKeyboardViewController`

- `clipboardImageStore: ClipboardImageStore?`를 `clipboardHistoryStore` 옆에 두고
  `ClipboardHistoryStore(imageStore:)`로 주입한다.
- `synchronizeClipboardHistoryIfNeeded()`는 `onImageRecorded`에서 `isClipboardPanelVisible`이면
  `reloadClipboardPanel()`을 부른다. 패널이 닫혀 있으면 다음에 열 때 읽는다.
- `reloadClipboardPanel()`은 `configure(state:thumbnailURL:)`에 `clipboardImageStore`의
  썸네일 경로 클로저를 넘긴다.
- `didReceiveMemoryWarning`에 `clipboardHistoryPanelView.purgeThumbnailCache()`를 추가한다.

### 복원: 이미지 항목 선택

`clipboardPanel(_:didSelectItemAt:)`에서 `item.content`로 분기한다. `.text`는 기존
그대로다. `.image(reference)`는 다음 순서다.

1. `Data(contentsOf: originalURL, options: .mappedIfSafe)`로 원본을 메모리 맵으로 연다.
2. `UIPasteboard.general.setData(data, forPasteboardType: reference.typeIdentifier)`.
3. `keyboardSettingsManager.lastSeenPasteboardChangeCount = pasteboard.changeCount`. 우리가
   쓴 값을 다음 동기화에서 다시 캡처하지 않는다. 기존 `didRequestCopyAt`과 같은 규칙이다.
4. `clipboardHistoryStore.record(.image(reference))`로 맨 위로 올린다. 고정 항목은 정책상
   그대로다.
5. `reloadClipboardPanel()` 후 `clipboardHistoryPanelView.showTransientMessage(...)`로 헤더
   안내를 띄운다. 패널은 닫지 않고 `updateSuggestions()`도 부르지 않는다.
6. 파일 읽기에 실패하면(앱에서 지운 뒤 키보드가 옛 목록을 들고 있는 경우) 해당 항목을
   `remove(ids:)`로 지우고 패널을 다시 읽는다.

`didRequestCopyAt`(상세 뷰의 복사 버튼)도 이미지면 같은 복원 경로를 탄다.
`didRequestOpenURLAt`과 편집은 이미지에서 호출되지 않는다.

### 앱 `SYKeyboardApp`·`ClipboardHistorySettingsView`

앱 활성화 시 동기화 호출에 `imageStore`를 함께 넘긴다. `ClipboardHistorySettingsView.
synchronizeAndReload()`는 `onImageRecorded`에서 `reload()`를 불러 화면이 열려 있는 동안
저장이 끝나면 목록을 갱신한다.

## 4. UI

### 키보드 패널 `ClipboardHistoryPanelView`

- diffable snapshot 식별자와 `makeCell`의 항목 검색을 `text`에서 `id`로 바꾼다.
  `applySnapshot`의 고정 상태 비교도 `id` 기준이다.
- `configure(state:thumbnailURL:)`로 썸네일 경로 클로저를 받는다. 테스트는 임시
  디렉터리를 주입한다.
- 이미지 셀: `UIListContentConfiguration`에 `image`를 넣고 `imageProperties.maximumSize`와
  `reservedLayoutSize`를 44×44로 고정해 텍스트 셀과 행 높이를 맞춘다. `text`는 "이미지",
  `secondaryText`는 "1920×1080 · 1.2 MB"(`ByteCountFormatter`).
- 썸네일 캐시: 해시 키 `NSCache<NSString, UIImage>`, `countLimit = 40`. 없으면
  `UIImage(contentsOfFile:)`로 읽어 넣는다. `purgeThumbnailCache()`가 비운다. 같은 해시는
  같은 바이트이므로 삭제된 해시를 따로 빼지 않는다.
- `showTransientMessage(_ text: String)`: `titleLabel.text`를 바꾸고 2초 뒤
  `DispatchWorkItem`으로 되돌린다. `configure`, `resetPresentation`, `beginItemEditing`은
  대기 중인 복구를 취소하고 즉시 제목으로 되돌린다. 편집 모드에서는 `titleLabel`이
  숨겨지므로 안내를 띄우지 않는다.
- 상세 뷰 `ClipboardHistoryDetailView`: `update(item:preview:isPinned:canPin:canOpenURL:)`.
  이미지면 `textView`를 숨기고 aspect fit `UIImageView`에 미리보기를 보여주며 붙여넣기
  버튼을 숨기고 복사·고정·닫기만 둔다. 미리보기는 원본을
  `CGImageSourceCreateThumbnailAtIndex`로 긴 변 600 px까지만 디코드한다(최대 약 1.4 MB).
  이 수치는 출력 비트맵 크기일 뿐이며, 다운샘플 과정에서 PNG 원본은 ImageIO가 전체
  디코드할 수 있다(2절 메모리 참고). 그래서 키보드는 미리보기를 디코드하기 전에
  `hasEnoughMemory`로 남은 메모리를 확인한다.
- 편집 모드의 선택·일괄 삭제·일괄 고정·스와이프 액션은 인덱스 기반이라 그대로다.
- 빈 상태 문구는 "복사한 텍스트나 이미지가 여기에 표시됩니다."로 바꾼다.

### 앱 관리 화면 `ClipboardHistorySettingsView`

- `selection: Set<String>`은 `id`를 담는다. `togglePins`, `requestRemove`, `remove`는 `id`
  집합으로 store를 부른다.
- `row(for:)`: 이미지면 썸네일 44 pt `Image(uiImage:)`를 왼쪽에 두고 "이미지" + 크기
  캡션을 보여준다. 앱 프로세스는 메모리 여유가 있어 캐시 없이 동기 로드한다.
- 상세 시트: 이미지면 `ScrollView` 안에 긴 변이 화면 폭 × scale인 다운샘플 이미지를
  보여주고, 툴바는 고정·`ShareLink(item: originalURL)`·복사(복원)만 둔다. 편집 버튼은
  숨긴다.
- 원문 편집 `replaceText`와 `+` 추가 시트는 텍스트 전용 그대로다. 삭제 확인 문구는
  개수 기준이라 그대로다.
- 앱의 복사 버튼도 키보드와 같은 규칙으로 `setData` 후 `lastSeenPasteboardChangeCount`를
  갱신하고 `record`로 맨 위에 올린다.

### 설정 토글 `KeyboardToolbarSettingsView`

"클립보드 기록" 토글이 켜져 있을 때 그 아래에 "이미지도 기록" 토글을
`@AppStorage(UserDefaultsKeys.isClipboardImageHistoryEnabled, store:)`로 둔다. 캡션은
"복사한 이미지를 저장하고 탭하면 클립보드로 복원합니다"만 둔다. 이미지당 한도(12 MB·
24메가픽셀)와 토글 OFF 규칙 설명은 "클립보드 기록 관리" 화면의 목록 최하단(footer)과
빈 상태에 두고, "이미지도 기록"이 켜져 있을 때만 보인다(`ClipboardHistorySettingsView.
imageLimitDescription`). 기존 토글처럼 Analytics 이벤트(`clipboard_image_history`)를 남긴다.

### 로컬라이징

Core 문구는 `SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/Localizable.xcstrings`,
앱 문구는 `SYKeyboard/Resources/Localizable.xcstrings`에 한/영을 넣는다.

- Core: "이미지", "이미지를 복사했습니다. 입력창을 길게 눌러 붙여넣기",
  "복사한 텍스트나 이미지가 여기에 표시됩니다."
- 앱: "이미지도 기록"과 캡션, "이미지"

### `project.pbxproj`

`ClipboardImagePolicy.swift`, `ClipboardImageStore.swift`를 `SYKeyboardCore`·`SYKeyboard`
타깃의 `membershipExceptions`에 알파벳순으로 추가한다.

## 5. 오류 처리

- App Group 컨테이너를 못 얻으면 `ClipboardImageStore()`가 `nil`이고 이미지 캡처를
  건너뛴다. 텍스트 기록은 기존대로 동작한다.
- 한도 초과·손상 파일·썸네일 실패는 저장하지 않고 파일을 남기지 않는다. `changeCount`는
  갱신돼 같은 pasteboard를 반복해 읽지 않는다.
- 원본 파일이 없는 항목을 복원하려 하면 항목을 지우고 목록을 다시 읽는다.
- 파일 삭제 실패는 로그만 남긴다. 다음 저장에서 차집합에 다시 포함되지 않으므로 고아
  파일이 될 수 있으나 범위 밖으로 둔다.

## 6. 테스트와 검증

### 단위 테스트 (Swift Testing)

| Suite | 검증 |
| --- | --- |
| `ClipboardImagePolicyTests` (신규) | 타입 우선순위(JPEG > HEIC > PNG, TIFF·GIF 제외), 바이트 12 MB·픽셀 24 MP 경계값, 남은 메모리 판정, 확장자 유도 |
| `ClipboardHistoryPolicyTests` (확장) | 이미지 content 재삽입 시 맨 위 이동, 고정 이미지 재복사 유지, 텍스트·이미지 혼합 정렬과 미고정 트리밍, 이미지 항목 `replacingText`가 `nil`, `id` 기준 일괄 고정·해제와 한도 |
| `ClipboardHistoryStoreTests` (확장) | `text` 키만 있는 기존 파일 디코드, 이미지 항목 왕복 저장, 이미지 항목 삭제·트리밍·전체 삭제 시 원본·썸네일 파일 삭제, 텍스트만 바뀐 저장은 파일 삭제 없음 |
| `ClipboardImageStoreTests` (신규) | 테스트에서 `CGImageDestination`으로 만든 작은 PNG·JPEG 임시 파일 저장 → 해시 파일명·썸네일 생성·참조 값, 같은 파일 두 번 저장 시 파일 하나, 한도 초과는 `nil`이고 파일 미생성, 손상 파일은 `nil`, 회전 메타데이터의 폭·높이 교환 |
| `ClipboardHistoryPasteboardSynchronizerTests` (확장) | 이미지만 있는 pasteboard(`setData`)에서 이미지 기록(완료 콜백을 `withCheckedContinuation`으로 대기), 텍스트+이미지는 텍스트만, 이미지 설정 OFF면 기록 없음, 메모리 부족 판정 시 기록 없이 `changeCount`만 갱신 |
| `ClipboardHistoryPanelViewTests` (확장) | 이미지 항목 `configure` 후 셀 구성, 탭 시 `didSelectItemAt` 인덱스, `showTransientMessage` 직후 제목 변경과 `configure`/`resetPresentation` 시 즉시 복구, 텍스트·이미지 혼합 삭제 스냅샷 crash 없음 |
| `UserDefaultsContractTests` (확장) | `isClipboardImageHistoryEnabled` 키·기본값 |

2초 뒤 자동 복구는 시간 경과 테스트를 금지하는 지침에 따라 단위 테스트로 고정하지
않고 실기기 확인 항목으로 둔다.

### 빌드

`SYKeyboard` 테스트 실행 후 `HangeulKeyboard`·`EnglishKeyboard`·`HangeulEnglishKeyboard`
세 scheme 빌드. 기준은 iPhone 13 mini / iOS 18.6이고 없으면 가장 가까운 iOS 16+
시뮬레이터로 조정해 기록한다. 빌드 후 `.xcscheme`의 `RemotePath` 변경은 되돌린다.

### 실기기 수동 확인 (자동 테스트로 대체 불가)

1. 사진 앱에서 12 MP 사진 복사 → 키보드 열기 → 패널에 썸네일 표시 → 메시지 앱에서 길게
   눌러 붙여넣기 성공.
2. 스크린샷(PNG) 복사 → 저장 확인.
3. 대형 PNG(20 MP 이상) 복사 → Xcode 메모리 게이지로 키보드 피크 확인. 종료되면 PNG
   전용 픽셀 상한 도입.
4. 웹페이지에서 텍스트+이미지 영역 복사 → 텍스트만 저장.
5. 이미지 탭 후 헤더 안내 2초 표시와 복구, 입력창 탭 시 패널 닫힘.
6. 이미지 paste 미지원 입력 필드(예: 검색창)에서 붙여넣기 메뉴 동작 기록.
7. "이미지도 기록" OFF → 새 이미지 미저장, 기존 이미지 항목 유지.
8. 앱 관리 화면에서 이미지 항목 삭제 → App Group `ClipboardImages/` 파일 삭제 확인.
9. 앱 원문 시트에서 공유·복사·고정 동작.
10. iOS 16 기기에서 이미지 캡처 시 붙여넣기 권한 알림이 텍스트와 같은 방식으로 뜨는지.

## 7. 파일 목록

신규

- `Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardImagePolicy.swift`
- `Modules/SYKeyboardCore/Storage/ClipboardImageStore.swift`
- `SYKeyboardTests/Utils/ClipboardImagePolicyTests.swift`
- `SYKeyboardTests/Storage/ClipboardImageStoreTests.swift`

변경

- `Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardHistoryPolicy.swift`
- `Modules/SYKeyboardCore/Storage/ClipboardHistoryStore.swift`
- `Modules/SYKeyboardCore/Storage/ClipboardHistoryPasteboardSynchronizer.swift`
- `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift`, `DefaultValues.swift`,
  `UserDefaultsManager.swift`
- `Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift`
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- `SYKeyboard/App/SYKeyboardApp.swift`
- `SYKeyboard/Presentation/KeyboardSettings/ClipboardHistorySettingsView.swift`
- `SYKeyboard/Presentation/KeyboardSettings/KeyboardToolbarSettingsView.swift`
- `SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/Localizable.xcstrings`
- `SYKeyboard/Resources/Localizable.xcstrings`
- `SYKeyboard.xcodeproj/project.pbxproj`
- `SYKeyboardTests/Utils/ClipboardHistoryPolicyTests.swift`
- `SYKeyboardTests/Storage/ClipboardHistoryStoreTests.swift`
- `SYKeyboardTests/Storage/ClipboardHistoryPasteboardSynchronizerTests.swift`
- `SYKeyboardTests/Presentation/ClipboardHistoryPanelViewTests.swift`
- `SYKeyboardTests/Storage/UserDefaultsContractTests.swift`
