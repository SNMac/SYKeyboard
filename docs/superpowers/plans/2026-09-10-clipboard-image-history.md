# 클립보드 기록 이미지 항목 지원 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 시스템 pasteboard에 텍스트 없이 이미지만 있을 때 그 이미지를 App Group 파일 저장소에 저장하고, 키보드 패널·앱 관리 화면에서 이미지 항목을 고르면 시스템 pasteboard에 원본 바이트를 복원해 이미지 붙여넣기를 지원하는 앱에서 붙여넣을 수 있게 한다.

**Architecture:** `ClipboardHistoryItem`에 `content`(text/image) enum을 넣고 식별자를 `id`로 일반화해 #54의 단일 목록·고정·한도 정책을 이미지에 그대로 적용한다. 원본·썸네일 파일은 새 `ClipboardImageStore`가 App Group `ClipboardImages/`에 해시 이름으로 두고, `ClipboardHistoryStore`가 항목 삭제 시 파일을 함께 지운다. 캡처는 `ClipboardHistoryPasteboardSynchronizer`가 `NSItemProvider.loadFileRepresentation`으로 파일을 받아 백그라운드에서 저장하고, 복원은 `BaseKeyboardViewController`가 `setData(_:forPasteboardType:)`로 한다.

**Tech Stack:** Swift 5, UIKit(`UIPasteboard.itemProviders`/`setData`, `UIListContentConfiguration`, `NSCache`), ImageIO(`CGImageSourceCreateThumbnailAtIndex`, `CGImageDestination`), CryptoKit(`SHA256` 스트리밍), `os_proc_available_memory`, SwiftUI `@AppStorage`·`ShareLink`, String Catalog, Swift Testing

**Spec:** `docs/superpowers/specs/2026-09-10-clipboard-image-history-design.md`

**Spec과의 차이:** 리베이스(develop `23e2d22e`, #129 병합) 후 클립보드 토글이 `KeyboardToolbarSettingsView`로 옮겨졌다. spec 3절의 `synchronizeIfNeeded(store:imageStore:...)`는 `imageStore` 파라미터 없이 `store.imageStore`를 쓴다. `ClipboardHistoryStore`가 `ClipboardImageStore`를 만들어 `public let imageStore`로 노출하므로 키보드·앱이 같은 저장소를 따로 주입할 필요가 없다. `onImageRecorded`는 `@MainActor` 주석 없이 메인 큐에서 호출하는 `(() -> Void)?`다. spec 4절의 `configure(state:thumbnailURL:)`는 패널의 `imageStore: ClipboardImageStore?` 프로퍼티로 대신한다(썸네일 경로와 상세 미리보기 디코드를 한 저장소가 제공한다). 미리보기 디코드는 `ClipboardImageStore.previewImage(for:maxPixelSize:)`로 Core에 두고 키보드·앱이 함께 쓴다.

## Global Constraints

- iOS 16+ / Swift 5 / Xcode 26. deprecated API 신규 사용 금지(`UIScreen.main` 포함).
- 작업 브랜치 `feat/#55-clipboard-image-history`(develop `23e2d22e` 기준). plan 커밋 뒤에 이어서 커밋한다.
- 커밋 메시지는 `type: #55 - subject` 형식, 한국어, 마침표 없음. 코드 Task는 `feat`, 검증 기록 Task는 `docs`. 커밋 본문 끝에 세션의 attribution 두 줄을 붙인다.
- 각 Task는 코드·테스트·이 계획 문서의 체크박스 갱신을 **하나의 커밋**으로 남긴다. 실행하지 않았거나 실패한 step을 미리 완료로 표시하지 않는다. 다음 Task는 직전 Task의 커밋 뒤에 시작한다.
- `Modules/SYKeyboardCore/`에 새 파일을 추가할 때마다 `SYKeyboard.xcodeproj/project.pbxproj`의 두 예외 목록(`SYKeyboardCore` 타깃, `SYKeyboard` 타깃)에 같은 경로를 알파벳순으로 넣는다. `SYKeyboardTests/`는 동기화 폴더라 테스트 파일은 등록이 필요 없다.
- production 타입에 `ForTesting` 메서드를 추가하지 않는다. 테스트 seam은 init 파라미터(`ClipboardHistoryStore(fileURL:imageStore:)`, `ClipboardImageStore(directoryURL:maxByteSize:maxPixelCount:)`)와 함수 파라미터(`availableMemory:`)로만 둔다.
- 세 extension VC, Firebase/AdMob, entitlements, `Info.plist`, `Secrets.xcconfig`, `.xcscheme`은 건드리지 않는다.
- 이미지당 한도: 파일 `12 * 1_024 * 1_024` 바이트, `24_000_000` 픽셀. 썸네일 긴 변 `240` px. 저장 타입 우선순위 `["public.jpeg", "public.heic", "public.png"]`.
- 텍스트 항목의 기존 동작(탭 삽입 후 패널 닫힘, 편집, URL 열기, 고정 규칙)은 바꾸지 않는다.
- 기준 시뮬레이터: iPhone 13 mini / iOS 18.6 (UDID `82146144-24DE-4F91-B25D-23D147A91142`). 로컬 Xcode 27.0에서 iOS 16.0 런타임은 XCTest 로딩이 실패(`dyld: Symbol not found: _os_log_compare_enablement`, 테스트 러너 `Early unexpected exit`)해 가장 가까운 iOS 16+ 런타임으로 조정했다. 최종 응답에 이 기기명·OS를 명시한다.
- 테스트 호스트가 iOS 16 붙여넣기 권한 알림으로 멈추면(`The test runner timed out while preparing to run tests`) 코드 실패로 기록하지 않고 시뮬레이터 화면에서 알림에 응답한 뒤 같은 명령을 다시 실행한다(CLAUDE.md "붙여넣기 권한 알림" 절).
- 빌드·테스트 뒤 `git status --short`에서 `.xcscheme`의 `RemotePath` 변경이 보이면 `git checkout -- SYKeyboard.xcodeproj/xcshareddata/xcschemes/<이름>.xcscheme`로 복원한다.
- 정확한 색·폰트·SF Symbol 이름·private subview 구조는 테스트로 고정하지 않는다. 2초 뒤 헤더 복구는 시간 경과 테스트를 만들지 않는다.
- String Catalog는 Xcode가 다시 저장하면 키 순서를 재정렬할 수 있다. 그 diff는 그대로 커밋한다.

관련 테스트 실행 명령(각 Task의 "Run"은 `-only-testing`만 바꿔 쓴다):

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/<SuiteTypeName> 2>&1 | grep -E "Test Suite|passed on|failed on|error:|TEST (SUCCEEDED|FAILED)"
```

extension 빌드 명령(Task 7·9에서 사용, `-only-testing` 없이):

```sh
for scheme in HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build -project SYKeyboard.xcodeproj -scheme "$scheme" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' 2>&1 \
    | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
done
```

---

## File Structure

| 파일 | 책임 | Task |
| --- | --- | --- |
| `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift`, `DefaultValues.swift`, `UserDefaultsManager.swift` (수정) | `isClipboardImageHistoryEnabled` 키·기본값 `true`·wrapper | 1 |
| `SYKeyboardTests/Storage/UserDefaultsContractTests.swift` (수정) | 키 문자열·기본값 계약 | 1 |
| `Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardImagePolicy.swift` (신규) | 바이트·픽셀 한도, 타입 우선순위, 썸네일·미리보기 크기, 메모리 여유 판정, 확장자 | 2 |
| `SYKeyboardTests/Utils/ClipboardImagePolicyTests.swift` (신규) | 정책 경계값 | 2 |
| `Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardHistoryPolicy.swift` (수정) | `ClipboardImageReference`, `ClipboardHistoryItem.Content`, 직접 구현한 Codable, `id`, Content 기반 삽입·`selectedIDs` 일괄 고정 | 3 |
| `Modules/SYKeyboardCore/Storage/ClipboardHistoryStore.swift` (수정) | `record(_ content:)`, `remove(ids:)`, `togglePins(selectedIDs:)`, `imageStore` 소유와 삭제 시 파일 정리 | 3, 4 |
| `Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift` (수정) | `id` 기반 snapshot(3), 이미지 셀·썸네일 캐시·헤더 안내·상세 미리보기(6) | 3, 6 |
| `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` (수정) | `text` 옵셔널 대응(3), 이미지 복원·패널 갱신 콜백·메모리 경고(7) | 3, 7 |
| `SYKeyboard/Presentation/KeyboardSettings/ClipboardHistorySettingsView.swift` (수정) | `id` 선택(3), 이미지 행·상세·복사(8) | 3, 8 |
| `SYKeyboardTests/Utils/ClipboardHistoryPolicyTests.swift`, `SYKeyboardTests/Storage/ClipboardHistoryStoreTests.swift` (수정) | `selectedIDs`/`remove(ids:)` 전환, 이미지 content 정책·저장 | 3, 4 |
| `Modules/SYKeyboardCore/Storage/ClipboardImageStore.swift` (신규) | App Group `ClipboardImages/` 원본·썸네일 저장, 스트리밍 해시, 미리보기 디코드, 파일 삭제 | 4 |
| `SYKeyboardTests/Storage/ClipboardImageStoreTests.swift` (신규) | 임시 디렉터리로 저장·해시·썸네일·한도·정리 | 4 |
| `Modules/SYKeyboardCore/Storage/ClipboardHistoryPasteboardSynchronizer.swift` (수정) | 텍스트 없을 때 이미지 파일 캡처 | 5 |
| `SYKeyboardTests/Storage/ClipboardHistoryPasteboardSynchronizerTests.swift` (수정) | 이미지 캡처·우선순위·설정·메모리 | 5 |
| `SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/Localizable.xcstrings` (수정) | Core 문구 ko/en | 6 |
| `SYKeyboardTests/Presentation/ClipboardHistoryPanelViewTests.swift` (수정) | 이미지 행 탭·헤더 안내·혼합 삭제 | 6 |
| `SYKeyboard/App/SYKeyboardApp.swift` (수정) | 변경 없음(`store.imageStore` 사용으로 호출부 동일). 확인만 한다 | 7 |
| `SYKeyboard/Presentation/KeyboardSettings/KeyboardToolbarSettingsView.swift` (수정) | "이미지도 기록" 하위 토글 | 8 |
| `SYKeyboard/Resources/Localizable.xcstrings` (수정) | 앱 문구 en | 8 |
| `SYKeyboard.xcodeproj/project.pbxproj` (수정) | 신규 Core 파일 2개 등록 | 2, 4 |
| `docs/superpowers/plans/2026-09-10-clipboard-image-history.md` (수정) | 검증 결과 기록 | 9 |

---

### Task 1: 이미지 기록 설정 키와 기본값

**Files:**
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift:29`
- Modify: `Modules/SYKeyboardCore/Storage/DefaultValues.swift:32`
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift:120`
- Test: `SYKeyboardTests/Storage/UserDefaultsContractTests.swift`

**Interfaces:**
- Produces: `UserDefaultsKeys.isClipboardImageHistoryEnabled: String`, `DefaultValues.isClipboardImageHistoryEnabled: Bool`, `UserDefaultsManager.isClipboardImageHistoryEnabled: Bool` (Task 5·8이 읽고 쓴다)

- [x] **Step 1: 계약 테스트 추가**

`UserDefaultsContractTests.swift`의 `testClipboardHistoryDefaultFallbackAndKey` 바로 뒤에 추가한다.

```swift
    @Test("이미지 클립보드 기록은 저장값이 없으면 true를 반환하고 공유 저장소 키를 유지")
    func testClipboardImageHistoryDefaultFallbackAndKey() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.isClipboardImageHistoryEnabled
        let originalValue = storage.object(forKey: key)

        storage.removeObject(forKey: key)
        defer { restore(originalValue, forKey: key, in: storage) }

        #expect(key == "isClipboardImageHistoryEnabled")
        #expect(DefaultValues.isClipboardImageHistoryEnabled == true)
        #expect(UserDefaultsManager.shared.isClipboardImageHistoryEnabled == true)

        UserDefaultsManager.shared.isClipboardImageHistoryEnabled = false

        #expect(storage.bool(forKey: key) == false)
        #expect(UserDefaultsManager.shared.isClipboardImageHistoryEnabled == false)
    }
```

- [x] **Step 2: 실패 확인**

Run: `-only-testing:SYKeyboardTests/UserDefaultsContractTests`
Expected: 컴파일 실패 `cannot find 'isClipboardImageHistoryEnabled'`

- [x] **Step 3: 키·기본값·wrapper 추가**

`UserDefaultsKeys.swift`의 `isClipboardHistoryEnabled` 줄 아래:

```swift
    /// 클립보드 기록에 이미지도 저장
    public static let isClipboardImageHistoryEnabled = "isClipboardImageHistoryEnabled"
```

`DefaultValues.swift`의 `isClipboardHistoryEnabled` 줄 아래:

```swift
    /// 이미지 클립보드 기록 기본값. 클립보드 기록이 켜져 있으면 이미지도 함께 저장한다
    public static let isClipboardImageHistoryEnabled: Bool = true
```

`UserDefaultsManager.swift`의 `isClipboardHistoryEnabled` 프로퍼티 아래:

```swift
    /// 클립보드 기록에 이미지도 저장
    @UserDefaultsWrapper(key: UserDefaultsKeys.isClipboardImageHistoryEnabled, defaultValue: DefaultValues.isClipboardImageHistoryEnabled)
    public var isClipboardImageHistoryEnabled: Bool
```

- [x] **Step 4: 통과 확인**

Run: `-only-testing:SYKeyboardTests/UserDefaultsContractTests`
Expected: 전부 `passed`, `TEST SUCCEEDED`

- [x] **Step 5: 커밋**

```sh
git add Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift Modules/SYKeyboardCore/Storage/DefaultValues.swift \
  Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift SYKeyboardTests/Storage/UserDefaultsContractTests.swift \
  docs/superpowers/plans/2026-09-10-clipboard-image-history.md
git commit -m "feat: #55 - 이미지 클립보드 기록 설정 키와 기본값 추가"
```

---

### Task 2: 이미지 저장 정책 `ClipboardImagePolicy`

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardImagePolicy.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj` (두 예외 목록의 `ClipboardHistoryPolicy.swift` 줄 바로 아래)
- Test: `SYKeyboardTests/Utils/ClipboardImagePolicyTests.swift`

**Interfaces:**
- Produces:
  - `ClipboardImagePolicy.maxByteSize: Int`, `maxPixelCount: Int`, `thumbnailMaxPixelSize: Int`, `keyboardPreviewMaxPixelSize: Int`, `appPreviewMaxPixelSize: Int`, `preferredTypeIdentifiers: [String]`, `requiredAvailableMemory: Int`
  - `storableType(in types: [String]) -> String?`
  - `isStorable(byteSize: Int, pixelWidth: Int, pixelHeight: Int) -> Bool`
  - `hasEnoughMemory(available: Int) -> Bool`
  - `fileExtension(for typeIdentifier: String) -> String`

- [x] **Step 1: 테스트 파일 작성**

`SYKeyboardTests/Utils/ClipboardImagePolicyTests.swift`:

```swift
//
//  ClipboardImagePolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/10/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("클립보드 이미지 저장 정책 검증")
struct ClipboardImagePolicyTests {

    @Test("타입 우선순위는 JPEG, HEIC, PNG 순이고 TIFF·GIF만 있으면 nil")
    func test타입우선순위() {
        #expect(ClipboardImagePolicy.storableType(in: ["public.png", "public.jpeg"]) == "public.jpeg")
        #expect(ClipboardImagePolicy.storableType(in: ["public.png", "public.heic"]) == "public.heic")
        #expect(ClipboardImagePolicy.storableType(in: ["public.tiff", "public.png"]) == "public.png")
        #expect(ClipboardImagePolicy.storableType(in: ["public.tiff", "com.compuserve.gif"]) == nil)
        #expect(ClipboardImagePolicy.storableType(in: []) == nil)
    }

    @Test("바이트 한도는 12 MB까지, 픽셀 한도는 24,000,000까지 저장 가능")
    func test바이트픽셀한도_경계값() {
        let bytes = ClipboardImagePolicy.maxByteSize
        #expect(bytes == 12 * 1_024 * 1_024)
        #expect(ClipboardImagePolicy.isStorable(byteSize: bytes, pixelWidth: 4_000, pixelHeight: 6_000))
        #expect(ClipboardImagePolicy.isStorable(byteSize: bytes + 1, pixelWidth: 100, pixelHeight: 100) == false)
        #expect(ClipboardImagePolicy.isStorable(byteSize: 1, pixelWidth: 4_000, pixelHeight: 6_001) == false)
        #expect(ClipboardImagePolicy.isStorable(byteSize: 0, pixelWidth: 1, pixelHeight: 1) == false)
        #expect(ClipboardImagePolicy.isStorable(byteSize: 1, pixelWidth: 0, pixelHeight: 1) == false)
    }

    @Test("남은 메모리가 한도의 2배 + 8 MB 이상일 때만 캡처")
    func test메모리여유판정() {
        let required = ClipboardImagePolicy.maxByteSize * 2 + 8 * 1_024 * 1_024
        #expect(ClipboardImagePolicy.requiredAvailableMemory == required)
        #expect(ClipboardImagePolicy.hasEnoughMemory(available: required))
        #expect(ClipboardImagePolicy.hasEnoughMemory(available: required - 1) == false)
    }

    @Test("원본 파일 확장자는 타입에서 유도")
    func test확장자유도() {
        #expect(ClipboardImagePolicy.fileExtension(for: "public.jpeg") == "jpg")
        #expect(ClipboardImagePolicy.fileExtension(for: "public.heic") == "heic")
        #expect(ClipboardImagePolicy.fileExtension(for: "public.png") == "png")
        #expect(ClipboardImagePolicy.fileExtension(for: "public.tiff") == "img")
    }

    @Test("썸네일·미리보기 픽셀 크기는 키보드 메모리에 맞게 작다")
    func test썸네일미리보기크기() {
        #expect(ClipboardImagePolicy.thumbnailMaxPixelSize == 240)
        #expect(ClipboardImagePolicy.keyboardPreviewMaxPixelSize == 600)
        #expect(ClipboardImagePolicy.appPreviewMaxPixelSize == 1_200)
    }
}
```

- [x] **Step 2: 실패 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardImagePolicyTests`
Expected: 컴파일 실패 `cannot find 'ClipboardImagePolicy' in scope`

- [x] **Step 3: 정책 파일 작성과 pbxproj 등록**

`Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardImagePolicy.swift`:

```swift
//
//  ClipboardImagePolicy.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/10/26.
//

import Foundation

/// 클립보드 이미지 항목의 저장 한도·타입·크기 규칙. UI와 파일 시스템에 의존하지 않는다
///
/// 키보드 extension은 메모리 상한이 수십 MB라 원본을 통째로 디코드하지 않는다. 한도는 캡처 전에
/// 파일 크기와 헤더의 픽셀 수만 보고 판단하고, 표시는 작은 썸네일·미리보기만 디코드한다
public enum ClipboardImagePolicy {
    /// 이미지 파일 하나의 최대 바이트. 초과하면 저장하지 않는다
    public static let maxByteSize = 12 * 1_024 * 1_024
    /// 이미지 하나의 최대 픽셀 수(가로 × 세로). 초과하면 저장하지 않는다
    // ponytail: PNG는 ImageIO가 전체 디코드할 수 있어 24 MP에서 약 96 MB 피크가 가능. 실기기에서 종료되면 PNG 전용 상한을 추가
    public static let maxPixelCount = 24_000_000
    /// 목록 행 썸네일의 긴 변 픽셀
    public static let thumbnailMaxPixelSize = 240
    /// 키보드 상세 뷰 미리보기의 긴 변 픽셀. 디코드 시 최대 약 1.4 MB
    public static let keyboardPreviewMaxPixelSize = 600
    /// 앱 원문 시트 미리보기의 긴 변 픽셀
    public static let appPreviewMaxPixelSize = 1_200
    /// 저장에 쓸 pasteboard 타입 우선순위. 작은 쪽을 먼저 고르고 TIFF·GIF 등은 받지 않는다
    public static let preferredTypeIdentifiers = ["public.jpeg", "public.heic", "public.png"]
    /// 캡처 전 남아 있어야 하는 메모리. 파일 바이트가 일시적으로 두 번 올라올 수 있는 경우와 여유분을 더한다
    public static let requiredAvailableMemory = maxByteSize * 2 + 8 * 1_024 * 1_024

    /// pasteboard 첫 항목의 타입 목록에서 저장할 타입 하나. 우선순위 앞쪽부터 고르고 없으면 `nil`
    public static func storableType(in types: [String]) -> String? {
        return preferredTypeIdentifiers.first { types.contains($0) }
    }

    /// 바이트·픽셀 한도 안인지. 0 이하 값은 저장 불가
    public static func isStorable(byteSize: Int, pixelWidth: Int, pixelHeight: Int) -> Bool {
        return byteSize > 0 && byteSize <= maxByteSize
            && pixelWidth > 0 && pixelHeight > 0
            && pixelWidth * pixelHeight <= maxPixelCount
    }

    /// `os_proc_available_memory()` 값이 캡처에 충분한지
    public static func hasEnoughMemory(available: Int) -> Bool {
        return available >= requiredAvailableMemory
    }

    /// 원본 파일 확장자. 저장 대상이 아닌 타입은 `img`
    public static func fileExtension(for typeIdentifier: String) -> String {
        switch typeIdentifier {
        case "public.jpeg": return "jpg"
        case "public.heic": return "heic"
        case "public.png": return "png"
        default: return "img"
        }
    }
}
```

`project.pbxproj`에서 `SYKeyboardCore/Presentation/Utils/Policies/ClipboardHistoryPolicy.swift,` 줄이 두 번(SYKeyboardCore 타깃·SYKeyboard 타깃) 나온다. 각 줄 바로 아래에 같은 들여쓰기로 추가한다:

```
				SYKeyboardCore/Presentation/Utils/Policies/ClipboardImagePolicy.swift,
```

확인: `grep -c "ClipboardImagePolicy.swift" SYKeyboard.xcodeproj/project.pbxproj` → `2`

- [x] **Step 4: 통과 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardImagePolicyTests`
Expected: 5개 `passed`, `TEST SUCCEEDED`

- [x] **Step 5: 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardImagePolicy.swift \
  SYKeyboardTests/Utils/ClipboardImagePolicyTests.swift SYKeyboard.xcodeproj/project.pbxproj \
  docs/superpowers/plans/2026-09-10-clipboard-image-history.md
git commit -m "feat: #55 - 이미지 저장 한도·타입 정책 추가"
```

---

### Task 3: 기록 항목에 이미지 content와 `id` 식별자 도입

`text`가 식별자였던 구조를 `id`로 일반화한다. 이 Task가 끝나면 이미지 항목을 저장·정렬·고정·삭제할 수 있지만 아직 캡처·표시·복원은 없다. 텍스트 동작은 그대로다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardHistoryPolicy.swift`
- Modify: `Modules/SYKeyboardCore/Storage/ClipboardHistoryStore.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift` (snapshot 식별자, `makeCell`, `showDetail`)
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` (`ClipboardHistoryPanelDelegate` 확장의 델리게이트 5개, `// MARK: - Clipboard History` 아래)
- Modify: `SYKeyboard/Presentation/KeyboardSettings/ClipboardHistorySettingsView.swift` (선택·삭제·시트 식별을 `id`로)
- Test: `SYKeyboardTests/Utils/ClipboardHistoryPolicyTests.swift`, `SYKeyboardTests/Storage/ClipboardHistoryStoreTests.swift`

**Interfaces:**
- Produces:
  - `ClipboardImageReference(hash:typeIdentifier:byteSize:pixelWidth:pixelHeight:)`, `sizeDescription: String`
  - `ClipboardHistoryItem.Content` = `.text(String) | .image(ClipboardImageReference)`, `Content.id: String`
  - `ClipboardHistoryItem(content:createdAt:pinnedAt:)`, 기존 `init(text:createdAt:pinnedAt:)` 유지, `id`, `text: String?`, `image: ClipboardImageReference?`
  - `ClipboardHistoryPolicy.inserting(_ content: Content, into:now:)`, `isStorable(_ content:)`, `pinBatch(selectedIDs:in:)`, `togglingPins(selectedIDs:in:now:)`
  - `ClipboardHistoryStore.record(_ content: Content, now:)`, `remove(ids: Set<String>)`, `togglePins(selectedIDs:now:)`; `record(_ text: String, now:)`는 유지

- [x] **Step 1: 정책 테스트 갱신·추가**

`ClipboardHistoryPolicyTests.swift`에서 `selectedTexts:`를 전부 `selectedIDs:`로 바꾼다(텍스트 항목의 `id`는 텍스트라 값은 그대로다). 파일 끝 `item(_:createdAt:pinnedAt:)` helper 아래에 이미지 helper를 추가하고, 다음 테스트를 `test범위밖인덱스_고정토글은_nil` 뒤에 넣는다.

```swift
    @Test("같은 이미지를 다시 넣으면 기존 항목이 맨 앞으로 오고 고정 이미지는 바뀌지 않음")
    func test이미지중복은_맨앞이동_고정이면변경없음() {
        let items = [item("a", createdAt: 3), imageItem("h1", createdAt: 2), item("b", createdAt: 1)]

        let result = ClipboardHistoryPolicy.inserting(.image(reference("h1")), into: items, now: now)
        #expect(result?.map(\.id) == ["image/h1", "a", "b"])
        #expect(result?.first?.createdAt == now)

        let pinnedImage = [imageItem("h1", createdAt: 2, pinnedAt: 100), item("a", createdAt: 3)]
        #expect(ClipboardHistoryPolicy.inserting(.image(reference("h1")), into: pinnedImage, now: now) == nil)
    }

    @Test("이미지 content는 항상 저장 가능하고 텍스트 규칙은 그대로")
    func test이미지content는_저장가능() {
        #expect(ClipboardHistoryPolicy.isStorable(.image(reference("h1"))))
        #expect(ClipboardHistoryPolicy.isStorable(.text("  ")) == false)
        #expect(ClipboardHistoryPolicy.isStorable(.text("a")))
    }

    @Test("텍스트와 이미지가 섞여도 미고정 한도는 함께 세고 오래된 것부터 버림")
    func test혼합목록_미고정한도공유() {
        var items: [ClipboardHistoryItem] = []
        for index in 0..<ClipboardHistoryPolicy.maxItemCount {
            items.append(index.isMultiple(of: 2) ? item("t\(index)", createdAt: TimeInterval(index)) : imageItem("h\(index)", createdAt: TimeInterval(index)))
        }

        let result = ClipboardHistoryPolicy.inserting(.image(reference("new")), into: items, now: now)

        #expect(result?.count == ClipboardHistoryPolicy.maxItemCount)
        #expect(result?.first?.id == "image/new")
        #expect(result?.contains(where: { $0.id == "t0" }) == false)
    }

    @Test("이미지 항목은 id로 일괄 고정·해제되고 내용 편집은 nil")
    func test이미지항목_일괄고정과_편집불가() {
        let items = [item("a", createdAt: 2), imageItem("h1", createdAt: 1)]

        let pinned = ClipboardHistoryPolicy.togglingPins(selectedIDs: ["image/h1"], in: items, now: now)
        #expect(pinned?.map(\.id) == ["image/h1", "a"])
        #expect(pinned?.first?.isPinned == true)
        #expect(ClipboardHistoryPolicy.replacingText("image/h1", with: "x", in: items, now: now) == nil)
    }

    @Test("복사 시각이 같으면 id 순으로 정렬해 텍스트·이미지 순서를 고정")
    func test시각같으면_id순정렬() {
        let items = [item("b"), imageItem("h1"), item("a")]

        #expect(ClipboardHistoryPolicy.sorted(items).map(\.id) == ["a", "b", "image/h1"])
    }

    private func reference(_ hash: String) -> ClipboardImageReference {
        ClipboardImageReference(hash: hash, typeIdentifier: "public.png", byteSize: 1_024, pixelWidth: 10, pixelHeight: 10)
    }

    private func imageItem(
        _ hash: String,
        createdAt: TimeInterval = 0,
        pinnedAt: TimeInterval? = nil
    ) -> ClipboardHistoryItem {
        ClipboardHistoryItem(
            content: .image(reference(hash)),
            createdAt: Date(timeIntervalSince1970: createdAt),
            pinnedAt: pinnedAt.map { Date(timeIntervalSince1970: $0) }
        )
    }
```

기존 `test복사시각이같으면_텍스트순으로정렬` 계열 테스트(`sorted(items).map(\.text) == ["c", "a", "b"]`)는 결과가 같으므로 그대로 둔다.

- [x] **Step 2: 저장소 테스트 갱신·추가**

`ClipboardHistoryStoreTests.swift`에서 `remove(texts:` → `remove(ids:`, `togglePins(selectedTexts:` → `togglePins(selectedIDs:`로 바꾼다. 다음 테스트를 `test손상된파일이면_빈배열` 뒤에 넣는다.

```swift
    @Test("이미지 항목은 image 키로 저장되고 다시 읽으면 같은 참조와 id로 돌아옴")
    func test이미지항목_왕복저장() {
        let fixture = makeFixture(name: "image-roundtrip")
        let reference = ClipboardImageReference(hash: "abc", typeIdentifier: "public.jpeg", byteSize: 2_048, pixelWidth: 40, pixelHeight: 30)

        fixture.store.record("text", now: Date(timeIntervalSince1970: 1))
        fixture.store.record(.image(reference), now: Date(timeIntervalSince1970: 2))

        let items = fixture.store.load()
        #expect(items.map(\.id) == ["image/abc", "text"])
        #expect(items.first?.image == reference)
        #expect(items.first?.text == nil)
        #expect(items.last?.image == nil)
    }

    @Test("text 키만 있는 기존 파일과 image 키가 있는 파일을 함께 읽음")
    func test기존텍스트파일과_이미지항목_혼합읽기() throws {
        let fixture = makeFixture(name: "mixed-legacy")
        let legacy: [[String: Any]] = [
            ["text": "old", "createdAt": Date(timeIntervalSince1970: 1)],
            ["image": ["hash": "h", "typeIdentifier": "public.png", "byteSize": 10, "pixelWidth": 1, "pixelHeight": 1],
             "createdAt": Date(timeIntervalSince1970: 2)]
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: legacy, format: .binary, options: 0)
        try data.write(to: fixture.url)

        #expect(fixture.store.load().map(\.id) == ["old", "image/h"])
    }

    @Test("id로 삭제하면 텍스트·이미지 항목이 함께 지워짐")
    func testId삭제는_텍스트이미지_함께제거() {
        let fixture = makeFixture(name: "remove-ids")
        let reference = ClipboardImageReference(hash: "h", typeIdentifier: "public.png", byteSize: 10, pixelWidth: 1, pixelHeight: 1)
        fixture.store.record("a", now: Date(timeIntervalSince1970: 1))
        fixture.store.record(.image(reference), now: Date(timeIntervalSince1970: 2))
        fixture.store.record("b", now: Date(timeIntervalSince1970: 3))

        fixture.store.remove(ids: ["image/h", "a"])

        #expect(fixture.store.load().map(\.id) == ["b"])
    }
```

- [x] **Step 3: 실패 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPolicyTests`
Expected: 컴파일 실패 `cannot find 'ClipboardImageReference' in scope`

- [x] **Step 4: 모델과 정책 수정**

`ClipboardHistoryPolicy.swift`의 `ClipboardHistoryItem` 정의를 다음으로 바꾼다.

```swift
/// 클립보드 기록의 이미지 항목이 가리키는 파일. 경로는 해시와 타입에서 유도하므로 저장하지 않는다
public struct ClipboardImageReference: Codable, Equatable {
    /// 원본 바이트의 SHA-256 hex. 파일명이자 식별자
    public let hash: String
    /// `public.jpeg` / `public.heic` / `public.png`
    public let typeIdentifier: String
    public let byteSize: Int
    /// EXIF 회전을 적용한 표시 기준 크기
    public let pixelWidth: Int
    public let pixelHeight: Int

    public init(hash: String, typeIdentifier: String, byteSize: Int, pixelWidth: Int, pixelHeight: Int) {
        self.hash = hash
        self.typeIdentifier = typeIdentifier
        self.byteSize = byteSize
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }

    /// 목록 행에 보여주는 "1920×1080 · 1.2 MB"
    public var sizeDescription: String {
        let bytes = ByteCountFormatter.string(fromByteCount: Int64(byteSize), countStyle: .file)
        return "\(pixelWidth)×\(pixelHeight) · \(bytes)"
    }
}

/// 클립보드 기록 한 항목
public struct ClipboardHistoryItem: Codable, Equatable, Identifiable {
    public enum Content: Equatable {
        case text(String)
        case image(ClipboardImageReference)

        /// 텍스트는 텍스트 자체, 이미지는 "image/<hash>". 정책이 content 중복을 허용하지 않으므로 유일하다
        public var id: String {
            switch self {
            case .text(let text): return text
            case .image(let reference): return "image/" + reference.hash
            }
        }
    }

    public let content: Content
    public let createdAt: Date
    /// 고정한 시각. `nil`이면 미고정. 이 키가 없는 기존 파일은 미고정으로 읽힌다
    public let pinnedAt: Date?

    public var id: String { content.id }
    public var isPinned: Bool { pinnedAt != nil }
    /// `.text`일 때만 값이 있다
    public var text: String? {
        if case .text(let text) = content { return text }
        return nil
    }
    /// `.image`일 때만 값이 있다
    public var image: ClipboardImageReference? {
        if case .image(let reference) = content { return reference }
        return nil
    }

    public init(content: Content, createdAt: Date, pinnedAt: Date? = nil) {
        self.content = content
        self.createdAt = createdAt
        self.pinnedAt = pinnedAt
    }

    public init(text: String, createdAt: Date, pinnedAt: Date? = nil) {
        self.init(content: .text(text), createdAt: createdAt, pinnedAt: pinnedAt)
    }

    // MARK: - Codable

    /// `image` 키가 있으면 이미지, 없으면 `text`를 읽는다. `text` 키만 있는 #54 파일은 그대로 읽힌다
    private enum CodingKeys: String, CodingKey {
        case text, image, createdAt, pinnedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let image = try container.decodeIfPresent(ClipboardImageReference.self, forKey: .image) {
            content = .image(image)
        } else {
            content = .text(try container.decode(String.self, forKey: .text))
        }
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        pinnedAt = try container.decodeIfPresent(Date.self, forKey: .pinnedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch content {
        case .text(let text): try container.encode(text, forKey: .text)
        case .image(let reference): try container.encode(reference, forKey: .image)
        }
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(pinnedAt, forKey: .pinnedAt)
    }
}
```

`ClipboardHistoryPolicy` 안에서 다음을 바꾼다.

`inserting(_ text:)`를 Content 버전으로 바꾸고 String 버전은 얇게 남긴다:

```swift
    /// `content`를 미고정 기록 맨 앞에 넣은 결과. 저장하지 않을 내용이면 `nil`
    ///
    /// - 텍스트의 빈 문자열·공백·`maxTextLength` 초과는 `nil`. 이미지는 한도를 파일 저장소가 검사하므로 항상 저장 가능
    /// - 고정 항목과 같은 content면 고정을 유지하고 `nil`
    /// - 미고정에 같은 content가 있으면 제거한 뒤 맨 앞에 넣는다
    /// - 미고정이 `maxItemCount`를 넘으면 뒤에서 버린다
    static func inserting(
        _ content: ClipboardHistoryItem.Content,
        into items: [ClipboardHistoryItem],
        now: Date
    ) -> [ClipboardHistoryItem]? {
        guard isStorable(content),
              !items.contains(where: { $0.isPinned && $0.content == content }) else { return nil }

        let pinned = items.filter(\.isPinned)
        let unpinned = items.filter { !$0.isPinned && $0.content != content }
            + [ClipboardHistoryItem(content: content, createdAt: now)]
        let trimmedUnpinned = sorted(unpinned).prefix(maxItemCount)
        return sorted(pinned + trimmedUnpinned)
    }

    static func inserting(_ text: String, into items: [ClipboardHistoryItem], now: Date) -> [ClipboardHistoryItem]? {
        return inserting(.text(text), into: items, now: now)
    }

    /// 텍스트는 빈 값·공백·길이 초과가 아니어야 하고, 이미지는 항상 저장 가능하다
    public static func isStorable(_ content: ClipboardHistoryItem.Content) -> Bool {
        switch content {
        case .text(let text):
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.count <= maxTextLength
        case .image:
            return true
        }
    }
```

`insertingPinned`는 텍스트 전용으로 두되 비교를 content로 바꾼다: `items.contains(where: { $0.text == text && $0.isPinned })` → `items.contains(where: { $0.content == .text(text) && $0.isPinned })`, `items.filter { $0.text != text }` → `items.filter { $0.content != .text(text) }`. map 안의 `$0.text == text ? ClipboardHistoryItem(text: $0.text, ...)`는 `$0.content == .text(text) ? ClipboardHistoryItem(text: text, createdAt: $0.createdAt, pinnedAt: now) : $0`로.

`replacingText`: `items.firstIndex(where: { $0.text == oldText })`와 `items.firstIndex(where: { $0.text == newText })`는 `text`가 옵셔널이어도 컴파일된다. 대상이 이미지면 `text`가 `nil`이라 `oldText`와 같을 수 없으므로 자동으로 `nil`이다. 변경 없음.

`togglingPin`: `ClipboardHistoryItem(text: target.text, ...)` → `ClipboardHistoryItem(content: target.content, createdAt: target.createdAt, pinnedAt: ...)`.

`pinBatch`·`togglingPins`: 파라미터 `selectedTexts` → `selectedIDs`, 본문 `selectedTexts.contains($0.text)` → `selectedIDs.contains($0.id)`, `let targetTexts = batch.targets.map(\.text)` → `let targetIDs = batch.targets.map(\.id)`, `targetTexts.firstIndex(of: item.text)` → `targetIDs.firstIndex(of: item.id)`, 항목 생성은 `ClipboardHistoryItem(content: item.content, ...)`. doc comment의 "선택한 텍스트"를 "선택한 항목"으로.

`sorted`: 동률 비교 `lhs.text < rhs.text` 두 곳 → `lhs.id < rhs.id`. doc comment "텍스트 순" → "id 순".

- [x] **Step 5: 저장소 수정**

`ClipboardHistoryStore.swift`:

- 클래스 doc의 "텍스트 기록"을 "텍스트·이미지 기록"으로.
- `load()`의 중복 제거를 `seen.insert($0.id).inserted`로, 주석 "텍스트는 정책상 유일해야" → "id는 정책상 유일해야".
- `record`:

```swift
    /// `content`를 기록 맨 앞에 저장한다. 정책상 저장 대상이 아니면 아무것도 하지 않는다
    public func record(_ content: ClipboardHistoryItem.Content, now: Date = Date()) {
        guard let items = ClipboardHistoryPolicy.inserting(content, into: load(), now: now) else { return }
        save(items)
    }

    public func record(_ text: String, now: Date = Date()) {
        record(.text(text), now: now)
    }
```

- `togglePins(selectedTexts:)` → `togglePins(selectedIDs: Set<String>, now:)`, 내부 호출도 `selectedIDs:`.
- `remove(texts:)` → 다음으로 교체:

```swift
    /// 지정한 id의 항목을 삭제한다. 없는 id는 무시한다.
    /// 인덱스가 아니라 id로 받아, 확인을 기다리는 사이 파일 순서가 바뀌어도 다른 항목을 지우지 않는다
    public func remove(ids: Set<String>) {
        save(load().filter { !ids.contains($0.id) })
    }
```

- [x] **Step 6: 호출부 컴파일 수정 (동작 변화 없음)**

`ClipboardHistoryPanelView.swift`:
- `dataSource` 클로저 파라미터 `text` → `id`, `makeCell(in:at:text:)` → `makeCell(in:at:id:)`, 본문 `items.first(where: { $0.text == text })` → `items.first(where: { $0.id == id })`. `content.text = item.text`는 옵셔널 대입이라 그대로 컴파일된다. doc comment "텍스트가 유일하므로 텍스트를 행 식별자로" → "id가 유일하므로 id를 행 식별자로".
- `applySnapshot`: `snapshot.appendItems(items.map(\.text))` → `items.map(\.id)`, `previousItems.map { ($0.text, $0.isPinned) }` → `($0.id, $0.isPinned)`, `previousPinState[item.text]` → `previousPinState[item.id]`, `.map(\.text)` → `.map(\.id)`.
- `showDetail(at:)`: `text: items[index].text` → `text: items[index].text ?? ""`, `openableURL(in: items[index].text)` → `items[index].text.flatMap(ClipboardHistoryPolicy.openableURL) != nil`. (Task 6에서 이미지 분기로 바꾼다.)

`BaseKeyboardViewController.swift` 델리게이트:
- `didSelectItemAt`: `let text = panel.items[index].text` → `guard let text = panel.items[index].text else { return }` (guard 문에 합친다).
- `didDeleteItemsAt`: `let texts = Set(indices.compactMap { ... panel.items[$0].text : nil })` → `let ids = Set(indices.compactMap { panel.items.indices.contains($0) ? panel.items[$0].id : nil })`, `remove(texts: texts)` → `remove(ids: ids)`. 주석 "텍스트로 바꿔" → "id로 바꿔".
- `didRequestCopyAt`: `pasteboard.string = panel.items[index].text` 앞에 `guard let text = panel.items[index].text else { return }`를 두고 `pasteboard.string = text`.
- `didRequestOpenURLAt`: `let url = ClipboardHistoryPolicy.openableURL(in: panel.items[index].text)` → `let text = panel.items[index].text, let url = ClipboardHistoryPolicy.openableURL(in: text)`.

`ClipboardHistorySettingsView.swift`:
- 주석 "텍스트는 정책상 중복이 없어 id로 쓴다" → "id는 정책상 중복이 없다".
- `selectedItems`: `selection.contains($0.text)` → `selection.contains($0.id)`. `pinBatch`: `selectedTexts: selection` → `selectedIDs: selection`.
- `DeletionSource.row(String)`의 값은 id. `.row(item.text)` 두 곳 → `.row(item.id)`, `deletionConfirmation(self, source: .row(item.text))` → `.row(item.id)`.
- `togglePins(selectedTexts: [item.text])` → `togglePins(selectedIDs: [item.id])`, bottomBar의 `Set(items.map(\.text))` → `Set(items.map(\.id))`, `togglePins(selectedTexts: selection)` → `togglePins(selectedIDs: selection)`.
- `func togglePins(selectedTexts:)` → `func togglePins(selectedIDs: Set<String>)`, 내부 `store?.togglePins(selectedIDs: selectedIDs)`.
- `reload()`: `selection.intersection(items.map(\.text))` → `items.map(\.id)`, `if case .row(let text)? ..., !items.contains(where: { $0.text == text })` → `.row(let id)?`, `$0.id == id`.
- `remove(_:)`: `store?.remove(texts: Set(removing.map(\.text)))` → `store?.remove(ids: Set(removing.map(\.id)))`.
- `replaceText(of:with:)`: `store?.replaceText(item.text, ...)` → `guard let oldText = item.text else { return }` 뒤 `store?.replaceText(oldText, with: newText)`; `refreshDetailItem(text: newText)` → `refreshDetailItem(id: newText)`.
- `togglePinFromDetail`: `togglePins(selectedIDs: [item.id])`, `refreshDetailItem(id: item.id)`.
- `copyFromDetail`: `guard let text = item.text else { return }` 추가, `pasteboard.string = text`, `store?.record(text)`, `refreshDetailItem(id: item.id)`. (Task 8에서 이미지 분기로 바꾼다.)
- `func refreshDetailItem(text:)` → `func refreshDetailItem(id: String)`, 본문 `items.first { $0.id == id } ?? detailItem`.
- 시트의 `canSave: { ClipboardHistoryPolicy.replacingText(item.text, ...) }` → `canSave: { newText in item.text.flatMap { ClipboardHistoryPolicy.replacingText($0, with: newText, in: items, now: .distantPast) } != nil }`.
- `ClipboardHistoryDetailView`(앱 하단 private struct): `private var text: String { item.text ?? "" }`를 추가하고 `item.text` 사용처(`linkStyledText`의 `AttributedString(item.text)`·`openableURL(in: item.text)`, `ShareLink(item: item.text)`, `draft = item.text`)를 `text`로 바꾼다.

- [x] **Step 7: 통과 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPolicyTests -only-testing:SYKeyboardTests/ClipboardHistoryStoreTests -only-testing:SYKeyboardTests/ClipboardHistoryPanelViewTests -only-testing:SYKeyboardTests/ClipboardHistoryPasteboardSynchronizerTests`
Expected: 전부 `passed`, `TEST SUCCEEDED`. 앱 타깃도 함께 컴파일되므로 `error:` 0건.

- [x] **Step 8: 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardHistoryPolicy.swift \
  Modules/SYKeyboardCore/Storage/ClipboardHistoryStore.swift \
  Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboard/Presentation/KeyboardSettings/ClipboardHistorySettingsView.swift \
  SYKeyboardTests/Utils/ClipboardHistoryPolicyTests.swift SYKeyboardTests/Storage/ClipboardHistoryStoreTests.swift \
  docs/superpowers/plans/2026-09-10-clipboard-image-history.md
git commit -m "feat: #55 - 클립보드 기록 항목에 이미지 content와 id 식별자 도입"
```

---

### Task 4: App Group 이미지 파일 저장소 `ClipboardImageStore`와 삭제 시 파일 정리

**Files:**
- Create: `Modules/SYKeyboardCore/Storage/ClipboardImageStore.swift`
- Modify: `Modules/SYKeyboardCore/Storage/ClipboardHistoryStore.swift` (`imageStore` 소유, `save` 시 파일 차집합 정리)
- Modify: `SYKeyboard.xcodeproj/project.pbxproj` (두 예외 목록의 `ClipboardHistoryStore.swift` 줄 바로 아래)
- Test: `SYKeyboardTests/Storage/ClipboardImageStoreTests.swift`, `SYKeyboardTests/Storage/ClipboardHistoryStoreTests.swift`

**Interfaces:**
- Consumes: `ClipboardImagePolicy`(Task 2), `ClipboardImageReference`(Task 3)
- Produces:
  - `ClipboardImageStore(directoryURL: URL, maxByteSize: Int = ClipboardImagePolicy.maxByteSize, maxPixelCount: Int = ClipboardImagePolicy.maxPixelCount)`, `convenience init?()`
  - `store(temporaryFileURL: URL, typeIdentifier: String) -> ClipboardImageReference?`
  - `originalURL(for:) -> URL`, `thumbnailURL(for:) -> URL`
  - `previewImage(for reference: ClipboardImageReference, maxPixelSize: Int) -> CGImage?`
  - `removeFiles(for hashes: Set<String>)`, `removeAllFiles()`
  - `ClipboardHistoryStore.imageStore: ClipboardImageStore?`, `init(fileURL:imageStore:)`

- [ ] **Step 1: 이미지 저장소 테스트 파일 작성**

`SYKeyboardTests/Storage/ClipboardImageStoreTests.swift`:

```swift
//
//  ClipboardImageStoreTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/10/26.
//

import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import SYKeyboardCore

@Suite("클립보드 이미지 파일 저장소 검증")
struct ClipboardImageStoreTests {

    @Test("PNG 임시 파일을 저장하면 해시 이름의 원본과 썸네일이 생기고 참조가 돌아옴")
    func testPNG저장은_해시원본과썸네일생성() throws {
        let fixture = makeFixture(name: "png")
        defer { fixture.cleanUp() }
        let temporary = try makeImageFile(width: 640, height: 480, type: .png, name: "src")
        let expectedHash = SHA256.hash(data: try Data(contentsOf: temporary)).map { String(format: "%02x", $0) }.joined()
        let expectedSize = try FileManager.default.attributesOfItem(atPath: temporary.path)[.size] as? Int

        let reference = try #require(fixture.store.store(temporaryFileURL: temporary, typeIdentifier: "public.png"))

        #expect(reference.hash == expectedHash)
        #expect(reference.typeIdentifier == "public.png")
        #expect(reference.byteSize == expectedSize)
        #expect(reference.pixelWidth == 640)
        #expect(reference.pixelHeight == 480)
        #expect(fixture.store.originalURL(for: reference).lastPathComponent == "\(expectedHash).png")
        #expect(fixture.store.thumbnailURL(for: reference).lastPathComponent == "\(expectedHash).thumb.jpg")
        #expect(FileManager.default.fileExists(atPath: fixture.store.originalURL(for: reference).path))
        #expect(FileManager.default.fileExists(atPath: fixture.store.thumbnailURL(for: reference).path))
        // 임시 파일은 옮겨져 사라진다
        #expect(FileManager.default.fileExists(atPath: temporary.path) == false)

        // 썸네일은 긴 변이 정책 크기 이하
        let source = try #require(CGImageSourceCreateWithURL(fixture.store.thumbnailURL(for: reference) as CFURL, nil))
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let width = try #require(properties[kCGImagePropertyPixelWidth] as? Int)
        let height = try #require(properties[kCGImagePropertyPixelHeight] as? Int)
        #expect(max(width, height) == ClipboardImagePolicy.thumbnailMaxPixelSize)
        #expect(width > height)
    }

    @Test("같은 바이트를 두 번 저장하면 파일은 하나이고 두 번째도 같은 참조")
    func test같은바이트_두번저장은_파일하나() throws {
        let fixture = makeFixture(name: "dedupe")
        defer { fixture.cleanUp() }
        let first = try makeImageFile(width: 20, height: 20, type: .jpeg, name: "a")
        let second = try makeImageFile(width: 20, height: 20, type: .jpeg, name: "b")

        let firstReference = try #require(fixture.store.store(temporaryFileURL: first, typeIdentifier: "public.jpeg"))
        let secondReference = try #require(fixture.store.store(temporaryFileURL: second, typeIdentifier: "public.jpeg"))

        #expect(firstReference == secondReference)
        let files = try FileManager.default.contentsOfDirectory(atPath: fixture.directoryURL.path)
        #expect(files.sorted() == ["\(firstReference.hash).jpg", "\(firstReference.hash).thumb.jpg"])
    }

    @Test("바이트 한도를 넘는 파일은 저장하지 않고 파일을 남기지 않음")
    func test바이트한도초과는_저장안함() throws {
        let fixture = makeFixture(name: "too-big", maxByteSize: 1_024)
        defer { fixture.cleanUp() }
        let temporary = try makeImageFile(width: 400, height: 400, type: .png, name: "big")

        #expect(fixture.store.store(temporaryFileURL: temporary, typeIdentifier: "public.png") == nil)
        #expect(try FileManager.default.contentsOfDirectory(atPath: fixture.directoryURL.path).isEmpty)
    }

    @Test("픽셀 한도를 넘는 이미지는 헤더만 읽고 저장하지 않음")
    func test픽셀한도초과는_저장안함() throws {
        let fixture = makeFixture(name: "too-many-pixels", maxPixelCount: 100)
        defer { fixture.cleanUp() }
        let temporary = try makeImageFile(width: 20, height: 20, type: .png, name: "pixels")

        #expect(fixture.store.store(temporaryFileURL: temporary, typeIdentifier: "public.png") == nil)
        #expect(try FileManager.default.contentsOfDirectory(atPath: fixture.directoryURL.path).isEmpty)
    }

    @Test("이미지가 아닌 파일은 저장하지 않음")
    func test손상파일은_저장안함() throws {
        let fixture = makeFixture(name: "corrupt")
        defer { fixture.cleanUp() }
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).png")
        try Data("not an image".utf8).write(to: temporary)

        #expect(fixture.store.store(temporaryFileURL: temporary, typeIdentifier: "public.png") == nil)
        #expect(try FileManager.default.contentsOfDirectory(atPath: fixture.directoryURL.path).isEmpty)
    }

    @Test("EXIF 회전이 있는 JPEG는 표시 기준으로 폭·높이를 바꿔 기록")
    func testEXIF회전은_폭높이교환() throws {
        let fixture = makeFixture(name: "orientation")
        defer { fixture.cleanUp() }
        let temporary = try makeImageFile(width: 60, height: 40, type: .jpeg, name: "rotated", orientation: 6)

        let reference = try #require(fixture.store.store(temporaryFileURL: temporary, typeIdentifier: "public.jpeg"))

        #expect(reference.pixelWidth == 40)
        #expect(reference.pixelHeight == 60)
    }

    @Test("미리보기는 긴 변을 요청 크기까지만 디코드")
    func test미리보기는_요청크기까지만() throws {
        let fixture = makeFixture(name: "preview")
        defer { fixture.cleanUp() }
        let temporary = try makeImageFile(width: 800, height: 200, type: .png, name: "wide")
        let reference = try #require(fixture.store.store(temporaryFileURL: temporary, typeIdentifier: "public.png"))

        let preview = try #require(fixture.store.previewImage(for: reference, maxPixelSize: 100))

        #expect(preview.width == 100)
        #expect(preview.height == 25)
    }

    @Test("해시로 지우면 원본·썸네일이 함께 지워지고 없는 해시는 무시")
    func test해시삭제는_원본썸네일함께제거() throws {
        let fixture = makeFixture(name: "remove")
        defer { fixture.cleanUp() }
        let keep = try #require(fixture.store.store(temporaryFileURL: try makeImageFile(width: 10, height: 10, type: .png, name: "keep"), typeIdentifier: "public.png"))
        let gone = try #require(fixture.store.store(temporaryFileURL: try makeImageFile(width: 11, height: 11, type: .png, name: "gone"), typeIdentifier: "public.png"))

        fixture.store.removeFiles(for: [gone.hash, "missing"])

        let files = try FileManager.default.contentsOfDirectory(atPath: fixture.directoryURL.path)
        #expect(files.sorted() == ["\(keep.hash).png", "\(keep.hash).thumb.jpg"])

        fixture.store.removeAllFiles()
        #expect(try FileManager.default.contentsOfDirectory(atPath: fixture.directoryURL.path).isEmpty)
    }
}

// MARK: - Fixture

private struct ImageStoreFixture {
    let store: ClipboardImageStore
    let directoryURL: URL

    func cleanUp() {
        try? FileManager.default.removeItem(at: directoryURL)
    }
}

private func makeFixture(
    name: String,
    maxByteSize: Int = ClipboardImagePolicy.maxByteSize,
    maxPixelCount: Int = ClipboardImagePolicy.maxPixelCount
) -> ImageStoreFixture {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-\(name)", isDirectory: true)
    return ImageStoreFixture(
        store: ClipboardImageStore(directoryURL: directoryURL, maxByteSize: maxByteSize, maxPixelCount: maxPixelCount),
        directoryURL: directoryURL
    )
}

/// 단색 비트맵을 ImageIO로 인코드한 임시 파일. `orientation`은 EXIF 방향 값(1~8)
private func makeImageFile(width: Int, height: Int, type: UTType, name: String, orientation: Int? = nil) throws -> URL {
    let context = try #require(CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ))
    context.setFillColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let image = try #require(context.makeImage())
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("\(UUID().uuidString)-\(name).\(type.preferredFilenameExtension ?? "img")")
    let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil))
    var properties: [CFString: Any] = [:]
    if let orientation { properties[kCGImagePropertyOrientation] = orientation }
    CGImageDestinationAddImage(destination, image, properties as CFDictionary)
    #expect(CGImageDestinationFinalize(destination))
    return url
}
```

- [ ] **Step 2: 저장소 파일 정리 테스트 추가**

`ClipboardHistoryStoreTests.swift`의 `makeFixture(name:)`를 `imageStore`를 받도록 바꾸고 파일 정리 테스트를 추가한다.

```swift
private struct StoreFixture {
    let store: ClipboardHistoryStore
    let url: URL
    let imageDirectoryURL: URL

    func imageFiles() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: imageDirectoryURL.path).sorted()
    }
}

private func makeFixture(name: String) -> StoreFixture {
    let base = "SYKeyboardTests-\(UUID().uuidString)-\(name)"
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(base).plist")
    let imageDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(base, isDirectory: true)
    let imageStore = ClipboardImageStore(directoryURL: imageDirectoryURL)
    return StoreFixture(store: ClipboardHistoryStore(fileURL: url, imageStore: imageStore), url: url, imageDirectoryURL: imageDirectoryURL)
}

/// 이미지 저장소 디렉터리에 해시 이름의 원본·썸네일 빈 파일을 만들어 실제 저장을 흉내 낸다
private func makeStoredImage(hash: String, in fixture: StoreFixture) throws -> ClipboardImageReference {
    try FileManager.default.createDirectory(at: fixture.imageDirectoryURL, withIntermediateDirectories: true)
    let reference = ClipboardImageReference(hash: hash, typeIdentifier: "public.png", byteSize: 10, pixelWidth: 1, pixelHeight: 1)
    try Data("o".utf8).write(to: fixture.store.imageStore!.originalURL(for: reference))
    try Data("t".utf8).write(to: fixture.store.imageStore!.thumbnailURL(for: reference))
    return reference
}
```

테스트(`testId삭제는_텍스트이미지_함께제거` 뒤):

```swift
    @Test("이미지 항목을 지우면 원본·썸네일 파일도 지워지고 남은 항목의 파일은 유지")
    func test이미지항목삭제는_파일도삭제() throws {
        let fixture = makeFixture(name: "delete-files")
        let keep = try makeStoredImage(hash: "keep", in: fixture)
        let gone = try makeStoredImage(hash: "gone", in: fixture)
        fixture.store.record(.image(keep), now: Date(timeIntervalSince1970: 1))
        fixture.store.record(.image(gone), now: Date(timeIntervalSince1970: 2))

        fixture.store.remove(ids: ["image/gone"])

        #expect(fixture.store.load().map(\.id) == ["image/keep"])
        #expect(try fixture.imageFiles() == ["keep.png", "keep.thumb.jpg"])
    }

    @Test("미고정 한도에 밀려난 이미지 항목의 파일도 지워짐")
    func test트리밍된이미지는_파일도삭제() throws {
        let fixture = makeFixture(name: "trim-files")
        let oldest = try makeStoredImage(hash: "oldest", in: fixture)
        fixture.store.record(.image(oldest), now: Date(timeIntervalSince1970: 0))
        for index in 1...ClipboardHistoryPolicy.maxItemCount {
            fixture.store.record("t\(index)", now: Date(timeIntervalSince1970: TimeInterval(index)))
        }

        #expect(fixture.store.load().contains(where: { $0.id == "image/oldest" }) == false)
        #expect(try fixture.imageFiles().isEmpty)
    }

    @Test("전체 삭제는 이미지 디렉터리도 비움")
    func test전체삭제는_이미지파일도삭제() throws {
        let fixture = makeFixture(name: "remove-all-files")
        let reference = try makeStoredImage(hash: "h", in: fixture)
        fixture.store.record(.image(reference))
        fixture.store.record("a")

        fixture.store.removeAll()

        #expect(fixture.store.load().isEmpty)
        #expect(try fixture.imageFiles().isEmpty)
    }

    @Test("텍스트만 바뀐 저장은 이미지 파일을 건드리지 않음")
    func test텍스트만변경은_이미지파일유지() throws {
        let fixture = makeFixture(name: "text-only-save")
        let reference = try makeStoredImage(hash: "h", in: fixture)
        fixture.store.record(.image(reference), now: Date(timeIntervalSince1970: 1))

        fixture.store.record("a", now: Date(timeIntervalSince1970: 2))
        fixture.store.remove(ids: ["a"])

        #expect(try fixture.imageFiles() == ["h.png", "h.thumb.jpg"])
    }
```

- [ ] **Step 3: 실패 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardImageStoreTests`
Expected: 컴파일 실패 `cannot find 'ClipboardImageStore' in scope`

- [ ] **Step 4: 이미지 저장소 작성과 pbxproj 등록**

`Modules/SYKeyboardCore/Storage/ClipboardImageStore.swift`:

```swift
//
//  ClipboardImageStore.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/10/26.
//

import CryptoKit
import Foundation
import ImageIO
import OSLog
import UniformTypeIdentifiers

/// 클립보드 이미지의 원본과 썸네일을 App Group 컨테이너의 `ClipboardImages/`에 해시 이름으로 저장하는 저장소
///
/// UIKit을 쓰지 않는다. 한 번에 올리는 메모리는 64 KB 해시 버퍼와 썸네일 디코드뿐이다.
/// 세 keyboard extension과 앱이 같은 디렉터리를 쓰며, 파일명이 해시라 동시에 같은 이미지를 저장해도 같은 파일이다
public final class ClipboardImageStore {

    // MARK: - Properties

    private let directoryURL: URL
    private let maxByteSize: Int
    private let maxPixelCount: Int
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "ClipboardImageStore"
    )

    private static let hashChunkSize = 64 * 1_024

    // MARK: - Initializer

    init(
        directoryURL: URL,
        maxByteSize: Int = ClipboardImagePolicy.maxByteSize,
        maxPixelCount: Int = ClipboardImagePolicy.maxPixelCount
    ) {
        self.directoryURL = directoryURL
        self.maxByteSize = maxByteSize
        self.maxPixelCount = maxPixelCount
    }

    /// App Group 컨테이너를 얻지 못하면 `nil`. 호출 측은 이미지 저장을 건너뛴다
    public convenience init?() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: DefaultValues.groupBundleID
        ) else { return nil }
        self.init(directoryURL: containerURL.appendingPathComponent("ClipboardImages", isDirectory: true))
    }

    // MARK: - Public Methods

    /// 임시 파일의 이미지를 검사·해시·저장하고 참조를 돌려준다. 저장 대상이 아니면 `nil`이고 새 파일을 남기지 않는다.
    /// 백그라운드 스레드에서 부른다. 임시 파일은 성공 시 옮겨져 사라진다
    public func store(temporaryFileURL: URL, typeIdentifier: String) -> ClipboardImageReference? {
        // 1. 파일 크기. 바이트를 메모리에 올리지 않는다
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: temporaryFileURL.path),
              let byteSize = attributes[.size] as? Int,
              byteSize > 0, byteSize <= maxByteSize else { return nil }

        // 2. 헤더의 픽셀 크기. 회전(5~8)이면 표시 기준으로 폭·높이를 바꾼다
        guard let source = CGImageSourceCreateWithURL(temporaryFileURL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let rawWidth = properties[kCGImagePropertyPixelWidth] as? Int,
              let rawHeight = properties[kCGImagePropertyPixelHeight] as? Int else { return nil }
        let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
        let (pixelWidth, pixelHeight) = orientation >= 5 ? (rawHeight, rawWidth) : (rawWidth, rawHeight)
        guard pixelWidth > 0, pixelHeight > 0, pixelWidth * pixelHeight <= maxPixelCount else { return nil }

        // 3. 스트리밍 해시
        guard let hash = ClipboardImageStore.sha256Hex(of: temporaryFileURL) else { return nil }
        let reference = ClipboardImageReference(
            hash: hash,
            typeIdentifier: typeIdentifier,
            byteSize: byteSize,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight
        )

        // 4. 원본 이동. 이미 있으면 같은 바이트이므로 건너뛴다
        let originalURL = originalURL(for: reference)
        let originalExisted = FileManager.default.fileExists(atPath: originalURL.path)
        if !originalExisted {
            do {
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                try FileManager.default.moveItem(at: temporaryFileURL, to: originalURL)
            } catch {
                // 다른 프로세스가 먼저 저장했으면 성공으로 본다
                guard FileManager.default.fileExists(atPath: originalURL.path) else {
                    logger.error("클립보드 이미지 원본 저장 실패: \(error.localizedDescription)")
                    return nil
                }
            }
        }

        // 5. 썸네일. 실패하면 이번에 옮긴 원본을 지운다
        let thumbnailURL = thumbnailURL(for: reference)
        if !FileManager.default.fileExists(atPath: thumbnailURL.path),
           !writeThumbnail(from: originalURL, to: thumbnailURL) {
            if !originalExisted { try? FileManager.default.removeItem(at: originalURL) }
            logger.error("클립보드 이미지 썸네일 생성 실패")
            return nil
        }

        return reference
    }

    public func originalURL(for reference: ClipboardImageReference) -> URL {
        return directoryURL.appendingPathComponent(
            "\(reference.hash).\(ClipboardImagePolicy.fileExtension(for: reference.typeIdentifier))"
        )
    }

    public func thumbnailURL(for reference: ClipboardImageReference) -> URL {
        return directoryURL.appendingPathComponent("\(reference.hash).thumb.jpg")
    }

    /// 원본을 긴 변 `maxPixelSize`까지만 디코드한 미리보기. 회전을 적용한다. 파일이 없거나 손상됐으면 `nil`
    public func previewImage(for reference: ClipboardImageReference, maxPixelSize: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(originalURL(for: reference) as CFURL, nil) else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, ClipboardImageStore.thumbnailOptions(maxPixelSize: maxPixelSize))
    }

    /// 항목이 지워질 때 원본·썸네일을 함께 지운다. 없는 파일은 무시한다
    public func removeFiles(for hashes: Set<String>) {
        guard !hashes.isEmpty,
              let files = try? FileManager.default.contentsOfDirectory(atPath: directoryURL.path) else { return }
        for file in files where hashes.contains(String(file.prefix { $0 != "." })) {
            try? FileManager.default.removeItem(at: directoryURL.appendingPathComponent(file))
        }
    }

    public func removeAllFiles() {
        try? FileManager.default.removeItem(at: directoryURL)
    }
}

// MARK: - Private Methods

private extension ClipboardImageStore {
    /// 64 KB씩 읽어 계산한 SHA-256 hex. 파일을 통째로 올리지 않는다
    static func sha256Hex(of url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try? handle.read(upToCount: hashChunkSize), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    static func thumbnailOptions(maxPixelSize: Int) -> CFDictionary {
        return [
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: false
        ] as CFDictionary
    }

    /// ImageIO 다운샘플링으로 썸네일을 만들어 JPEG로 쓴다. JPEG·HEIC는 축소 디코드라 작고 PNG는 전체 디코드일 수 있다
    func writeThumbnail(from originalURL: URL, to thumbnailURL: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(originalURL as CFURL, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(
                source, 0, ClipboardImageStore.thumbnailOptions(maxPixelSize: ClipboardImagePolicy.thumbnailMaxPixelSize)
              ),
              let destination = CGImageDestinationCreateWithURL(
                thumbnailURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil
              ) else { return false }
        CGImageDestinationAddImage(destination, thumbnail, [kCGImageDestinationLossyCompressionQuality: 0.7] as CFDictionary)
        return CGImageDestinationFinalize(destination)
    }
}
```

`project.pbxproj`에서 `SYKeyboardCore/Storage/ClipboardHistoryStore.swift,` 줄 두 곳 바로 아래에 추가한다:

```
				SYKeyboardCore/Storage/ClipboardImageStore.swift,
```

확인: `grep -c "ClipboardImageStore.swift" SYKeyboard.xcodeproj/project.pbxproj` → `2`

- [ ] **Step 5: `ClipboardHistoryStore`에 파일 정리 연결**

```swift
    // MARK: - Properties

    private let fileURL: URL
    /// 이미지 원본·썸네일 저장소. App Group 컨테이너를 못 얻었으면 `nil`이고 이미지 항목은 저장되지 않는다
    public let imageStore: ClipboardImageStore?
    ...

    // MARK: - Initializer

    init(fileURL: URL, imageStore: ClipboardImageStore? = nil) {
        self.fileURL = fileURL
        self.imageStore = imageStore
    }

    /// App Group 컨테이너를 얻지 못하면 `nil`. 호출 측은 기능을 비활성 상태로 둔다
    public convenience init?() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: DefaultValues.groupBundleID
        ) else { return nil }
        self.init(fileURL: containerURL.appendingPathComponent("clipboard_history.plist"), imageStore: ClipboardImageStore())
    }
```

모든 변경 메서드가 `load()` 결과를 두 번 읽지 않도록 한 번 읽어 `save(items, previous:)`에 넘긴다:

```swift
    public func record(_ content: ClipboardHistoryItem.Content, now: Date = Date()) {
        let previous = load()
        guard let items = ClipboardHistoryPolicy.inserting(content, into: previous, now: now) else { return }
        save(items, previous: previous)
    }

    public func recordPinned(_ text: String, now: Date = Date()) {
        let previous = load()
        guard let items = ClipboardHistoryPolicy.insertingPinned(text, into: previous, now: now) else { return }
        save(items, previous: previous)
    }

    public func togglePin(at index: Int, now: Date = Date()) {
        let previous = load()
        guard let items = ClipboardHistoryPolicy.togglingPin(at: index, in: previous, now: now) else { return }
        save(items, previous: previous)
    }

    public func replaceText(_ oldText: String, with newText: String, now: Date = Date()) {
        let previous = load()
        guard let items = ClipboardHistoryPolicy.replacingText(oldText, with: newText, in: previous, now: now) else { return }
        save(items, previous: previous)
    }

    public func togglePins(selectedIDs: Set<String>, now: Date = Date()) {
        let previous = load()
        guard let items = ClipboardHistoryPolicy.togglingPins(selectedIDs: selectedIDs, in: previous, now: now) else { return }
        save(items, previous: previous)
    }

    public func remove(ids: Set<String>) {
        let previous = load()
        save(previous.filter { !ids.contains($0.id) }, previous: previous)
    }

    public func removeAll() {
        save([], previous: load())
        imageStore?.removeAllFiles()
    }
```

`save`:

```swift
private extension ClipboardHistoryStore {
    /// 목록을 쓰고, 목록에서 사라진 이미지의 파일을 지운다. 어느 경로로 항목이 빠지든 여기서 한 번에 정리된다
    func save(_ items: [ClipboardHistoryItem], previous: [ClipboardHistoryItem]) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        do {
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // 쓰기 실패는 무시하고 다음 기회에 다시 쓴다. changeCount는 이미 갱신됐으므로 같은 내용을 재시도하지 않는다
            logger.error("클립보드 기록 저장 실패: \(error.localizedDescription)")
            return
        }
        let removedHashes = Set(previous.compactMap(\.image?.hash)).subtracting(items.compactMap(\.image?.hash))
        imageStore?.removeFiles(for: removedHashes)
    }
}
```

- [ ] **Step 6: 통과 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardImageStoreTests -only-testing:SYKeyboardTests/ClipboardHistoryStoreTests`
Expected: 전부 `passed`, `TEST SUCCEEDED`

- [ ] **Step 7: 커밋**

```sh
git add Modules/SYKeyboardCore/Storage/ClipboardImageStore.swift Modules/SYKeyboardCore/Storage/ClipboardHistoryStore.swift \
  SYKeyboard.xcodeproj/project.pbxproj SYKeyboardTests/Storage/ClipboardImageStoreTests.swift \
  SYKeyboardTests/Storage/ClipboardHistoryStoreTests.swift docs/superpowers/plans/2026-09-10-clipboard-image-history.md
git commit -m "feat: #55 - App Group 이미지 파일 저장소와 항목 삭제 시 파일 정리 추가"
```

---

### Task 5: pasteboard 이미지 캡처

**Files:**
- Modify: `Modules/SYKeyboardCore/Storage/ClipboardHistoryPasteboardSynchronizer.swift`
- Test: `SYKeyboardTests/Storage/ClipboardHistoryPasteboardSynchronizerTests.swift`

**Interfaces:**
- Consumes: `ClipboardHistoryStore.imageStore`, `ClipboardImageStore.store(temporaryFileURL:typeIdentifier:)`(Task 4), `ClipboardImagePolicy.storableType`/`hasEnoughMemory`(Task 2), `UserDefaultsManager.isClipboardImageHistoryEnabled`(Task 1)
- Produces: `synchronizeIfNeeded(store:pasteboard:settings:availableMemory:onImageRecorded:)`. 기존 호출 `synchronizeIfNeeded(store:)`는 기본값으로 그대로 컴파일된다. `onImageRecorded`는 이미지 항목이 기록된 직후 메인 큐에서 한 번 호출된다

- [ ] **Step 1: 테스트 추가**

`ClipboardHistoryPasteboardSynchronizerTests.swift`의 fixture를 이미지 저장소와 설정 복원까지 다루도록 바꾼다.

```swift
private struct SyncFixture {
    let store: ClipboardHistoryStore
    let fileURL: URL
    let imageDirectoryURL: URL
    let pasteboard: UIPasteboard
    let originalChangeCount: Any?
    let originalImageEnabled: Any?

    func restore() {
        let storage = UserDefaultsManager.shared.storage
        if let originalChangeCount {
            storage.set(originalChangeCount, forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
        } else {
            storage.removeObject(forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
        }
        if let originalImageEnabled {
            storage.set(originalImageEnabled, forKey: UserDefaultsKeys.isClipboardImageHistoryEnabled)
        } else {
            storage.removeObject(forKey: UserDefaultsKeys.isClipboardImageHistoryEnabled)
        }
        UIPasteboard.remove(withName: pasteboard.name)
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.removeItem(at: imageDirectoryURL)
    }
}

private func makeFixture(name: String) -> SyncFixture {
    let base = "SYKeyboardTests-\(UUID().uuidString)-\(name)"
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(base).plist")
    let imageDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(base, isDirectory: true)
    let pasteboard = UIPasteboard(name: UIPasteboard.Name("SYKeyboardTests.\(name).\(UUID().uuidString)"), create: true)!
    let storage = UserDefaultsManager.shared.storage
    let originalChangeCount = storage.object(forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
    let originalImageEnabled = storage.object(forKey: UserDefaultsKeys.isClipboardImageHistoryEnabled)
    storage.removeObject(forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
    storage.removeObject(forKey: UserDefaultsKeys.isClipboardImageHistoryEnabled)
    let store = ClipboardHistoryStore(fileURL: url, imageStore: ClipboardImageStore(directoryURL: imageDirectoryURL))
    return SyncFixture(
        store: store, fileURL: url, imageDirectoryURL: imageDirectoryURL, pasteboard: pasteboard,
        originalChangeCount: originalChangeCount, originalImageEnabled: originalImageEnabled
    )
}

/// 8×8 PNG 바이트. ImageIO로 인코드해 pasteboard에 넣는다
private func makePNGData() -> Data {
    let context = CGContext(
        data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    let data = NSMutableData()
    let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    CGImageDestinationFinalize(destination)
    return data as Data
}
```

파일 상단 import에 `import ImageIO`, `import UniformTypeIdentifiers`를 추가한다. 테스트(`testConcealed항목은_기록하지않음` 뒤):

```swift
    @Test("텍스트 없이 이미지만 있으면 파일로 받아 이미지 항목을 기록하고 완료 콜백을 부름")
    func test이미지만있으면_이미지항목기록() async throws {
        let fixture = makeFixture(name: "image")
        defer { fixture.restore() }
        fixture.pasteboard.setData(makePNGData(), forPasteboardType: "public.png")

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
                store: fixture.store,
                pasteboard: fixture.pasteboard,
                availableMemory: { .max },
                onImageRecorded: { continuation.resume() }
            )
        }

        let items = fixture.store.load()
        let reference = try #require(items.first?.image)
        #expect(items.count == 1)
        #expect(reference.typeIdentifier == "public.png")
        #expect(reference.pixelWidth == 8)
        #expect(FileManager.default.fileExists(atPath: fixture.store.imageStore!.originalURL(for: reference).path))
        #expect(FileManager.default.fileExists(atPath: fixture.store.imageStore!.thumbnailURL(for: reference).path))
        #expect(UserDefaultsManager.shared.lastSeenPasteboardChangeCount == fixture.pasteboard.changeCount)
    }

    @Test("텍스트와 이미지가 함께 있으면 텍스트만 기록")
    func test텍스트와이미지_함께면_텍스트만기록() {
        let fixture = makeFixture(name: "text-and-image")
        defer { fixture.restore() }
        fixture.pasteboard.setItems([["public.utf8-plain-text": "hello", "public.png": makePNGData()]])

        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
            store: fixture.store, pasteboard: fixture.pasteboard, availableMemory: { .max }
        )

        #expect(fixture.store.load().map(\.id) == ["hello"])
    }

    @Test("이미지 기록 설정이 꺼져 있으면 이미지를 기록하지 않고 changeCount만 갱신")
    func test이미지설정OFF는_기록없음() {
        let fixture = makeFixture(name: "image-disabled")
        defer { fixture.restore() }
        UserDefaultsManager.shared.isClipboardImageHistoryEnabled = false
        fixture.pasteboard.setData(makePNGData(), forPasteboardType: "public.png")

        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
            store: fixture.store, pasteboard: fixture.pasteboard, availableMemory: { .max }
        )

        #expect(fixture.store.load().isEmpty)
        #expect(UserDefaultsManager.shared.lastSeenPasteboardChangeCount == fixture.pasteboard.changeCount)
    }

    @Test("남은 메모리가 부족하면 이미지를 기록하지 않고 changeCount만 갱신")
    func test메모리부족은_기록없음() {
        let fixture = makeFixture(name: "low-memory")
        defer { fixture.restore() }
        fixture.pasteboard.setData(makePNGData(), forPasteboardType: "public.png")

        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
            store: fixture.store, pasteboard: fixture.pasteboard, availableMemory: { 0 }
        )

        #expect(fixture.store.load().isEmpty)
        #expect(UserDefaultsManager.shared.lastSeenPasteboardChangeCount == fixture.pasteboard.changeCount)
    }
```

기존 두 테스트는 `imageStore`가 있어도 동작이 같으므로 그대로 둔다.

- [ ] **Step 2: 실패 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPasteboardSynchronizerTests`
Expected: 컴파일 실패 `extra arguments at positions #3, #4 in call`

- [ ] **Step 3: 동기화 구현**

`ClipboardHistoryPasteboardSynchronizer.swift` 전체를 다음으로 바꾼다.

```swift
//
//  ClipboardHistoryPasteboardSynchronizer.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/9/26.
//

import UIKit
import os

/// 시스템 pasteboard의 최신 텍스트 또는 이미지를 클립보드 기록에 반영한다. 키보드 extension과 앱이 함께 쓴다
///
/// `changeCount`와 `hasStrings`·`hasImages`·`types` 확인은 iOS 16 붙여넣기 권한 알림을 띄우지 않고,
/// `.string` 읽기와 이미지 데이터 읽기만 띄울 수 있다. 설정 ON·Full Access·미리보기 여부 확인은 호출 측 책임이다.
/// 텍스트가 있으면 텍스트만 기록하고, 텍스트가 없을 때만 이미지를 기록한다
public enum ClipboardHistoryPasteboardSynchronizer {

    /// 비밀번호 관리자가 비밀 항목에 붙이는 pasteboard 타입. 이 타입이 있으면 기록하지 않는다
    public static let concealedPasteboardType = "org.nspasteboard.ConcealedType"

    /// pasteboard의 `changeCount`가 마지막 확인값과 다를 때만 내용을 읽어 `store`에 기록한다
    ///
    /// - Parameters:
    ///   - availableMemory: 캡처 전 남은 메모리(바이트). 기본은 `os_proc_available_memory()`
    ///   - onImageRecorded: 이미지 항목이 기록된 직후 메인 큐에서 한 번 호출된다. 텍스트 기록이나 건너뜀에서는 부르지 않는다
    public static func synchronizeIfNeeded(
        store: ClipboardHistoryStore,
        pasteboard: UIPasteboard = .general,
        settings: UserDefaultsManager = .shared,
        availableMemory: () -> Int = { Int(os_proc_available_memory()) },
        onImageRecorded: (() -> Void)? = nil
    ) {
        let changeCount = pasteboard.changeCount
        guard changeCount != settings.lastSeenPasteboardChangeCount else { return }
        // 읽기 실패나 저장 제외여도 같은 값을 반복해 읽지 않도록 먼저 갱신한다
        settings.lastSeenPasteboardChangeCount = changeCount

        guard !pasteboard.contains(pasteboardTypes: [concealedPasteboardType]) else { return }

        if pasteboard.hasStrings {
            if let text = pasteboard.string { store.record(text) }
            return
        }

        guard pasteboard.hasImages,
              settings.isClipboardImageHistoryEnabled,
              let imageStore = store.imageStore,
              let typeIdentifier = ClipboardImagePolicy.storableType(in: pasteboard.types),
              ClipboardImagePolicy.hasEnoughMemory(available: availableMemory()),
              let itemProvider = pasteboard.itemProviders.first else { return }

        // 파일로 받아 프로세스 메모리에 바이트를 올리지 않는다. 완료 클로저는 백그라운드 스레드에서 오며
        // 시스템 임시 파일은 클로저가 끝나면 사라지므로 그 안에서 이동까지 끝낸다
        itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, _ in
            guard let url,
                  let reference = imageStore.store(temporaryFileURL: url, typeIdentifier: typeIdentifier) else { return }
            DispatchQueue.main.async {
                store.record(.image(reference))
                onImageRecorded?()
            }
        }
    }
}
```

`os_proc_available_memory`가 `import os`로 보이지 않으면 `import Darwin`으로 바꾼다(둘 다 시스템 모듈이며 의존성 추가가 아니다).

- [ ] **Step 4: 통과 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPasteboardSynchronizerTests`
Expected: 6개 `passed`, `TEST SUCCEEDED`

`test이미지만있으면_이미지항목기록`이 완료 콜백 없이 멈추거나 `url`이 `nil`로 오면 `loadFileRepresentation`이 이 pasteboard 항목을 지원하지 않는 경우다. 그때는 `itemProvider.loadDataRepresentation(forTypeIdentifier:)`로 받아 `FileManager.default.temporaryDirectory` 아래 UUID 이름 파일에 쓴 뒤 같은 `imageStore.store(...)`를 부르는 것으로 바꾸고, 이 경우 바이트가 프로세스 메모리에 한 번 올라오므로 `hasEnoughMemory` 안전장치를 유지한다는 주석을 남긴다. 어느 쪽을 썼는지 검증 결과에 기록한다.

- [ ] **Step 5: 커밋**

```sh
git add Modules/SYKeyboardCore/Storage/ClipboardHistoryPasteboardSynchronizer.swift \
  SYKeyboardTests/Storage/ClipboardHistoryPasteboardSynchronizerTests.swift \
  docs/superpowers/plans/2026-09-10-clipboard-image-history.md
git commit -m "feat: #55 - pasteboard 이미지 항목을 파일로 받아 기록에 저장"
```

---

### Task 6: 키보드 패널의 이미지 행·헤더 안내·상세 미리보기

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift`
- Modify: `SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/Localizable.xcstrings`
- Test: `SYKeyboardTests/Presentation/ClipboardHistoryPanelViewTests.swift`

**Interfaces:**
- Consumes: `ClipboardImageStore.thumbnailURL(for:)`/`previewImage(for:maxPixelSize:)`(Task 4), `ClipboardImageReference.sizeDescription`(Task 3), `ClipboardImagePolicy.keyboardPreviewMaxPixelSize`(Task 2)
- Produces:
  - `ClipboardHistoryPanelView.imageStore: ClipboardImageStore?` (소유자가 설정. `nil`이면 이미지 행에 자리표시 아이콘)
  - `showTransientMessage(_ message: String)`: 헤더 제목을 `message`로 바꾸고 2초 뒤 되돌린다. 편집 모드면 무시
  - `purgeThumbnailCache()`
  - `titleLabel`은 테스트가 읽도록 `private(set)`가 아닌 internal `let`으로 둔다(값 검증만 한다)
  - 상세 뷰 `onPaste`는 이미지에서도 `didRequestCopyAt` → `didSelectItemAt` 순서로 델리게이트를 부른다(Task 7이 복원으로 처리)

- [ ] **Step 1: 패널 테스트 추가**

`ClipboardHistoryPanelViewTests.swift`의 helper 아래에 이미지 helper를 추가하고 테스트 4개를 `testResetPresentation은_편집모드해제` 뒤에 넣는다.

```swift
private func imageItem(_ hash: String) -> ClipboardHistoryItem {
    ClipboardHistoryItem(
        content: .image(ClipboardImageReference(hash: hash, typeIdentifier: "public.png", byteSize: 1_024, pixelWidth: 8, pixelHeight: 8)),
        createdAt: Date()
    )
}
```

```swift
    @Test("이미지 행을 탭하면 텍스트 행과 같은 델리게이트로 인덱스를 전달")
    func test이미지행탭은_인덱스전달() {
        let (panel, spy) = makePanel(items: [unpinned("a"), imageItem("h1")])

        panel.tableView(panel.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))

        #expect(spy.selectedIndices == [1])
        #expect(panel.tableView.numberOfRows(inSection: 0) == 2)
    }

    @Test("헤더 안내는 제목 자리에 보였다가 configure·resetPresentation에서 즉시 제목으로 돌아옴")
    func test헤더안내_표시와_즉시복구() {
        let (panel, _) = makePanel(items: [imageItem("h1")])
        let title = panel.titleLabel.text

        panel.showTransientMessage("copied")
        #expect(panel.titleLabel.text == "copied")

        panel.configure(state: .items([imageItem("h1")]))
        #expect(panel.titleLabel.text == title)

        panel.showTransientMessage("copied")
        panel.resetPresentation()
        #expect(panel.titleLabel.text == title)
    }

    @Test("편집 모드에서는 헤더 안내를 띄우지 않음")
    func test편집모드는_헤더안내없음() {
        let (panel, _) = makePanel(items: [imageItem("h1")])
        let title = panel.titleLabel.text

        panel.beginItemEditing()
        panel.showTransientMessage("copied")

        #expect(panel.titleLabel.text == title)
    }

    @Test("텍스트·이미지가 섞인 목록에서 일부를 지우고 다시 configure해도 행 수가 새 목록을 따름")
    func test혼합목록_삭제후configure() {
        let (panel, spy) = makePanel(items: [unpinned("a"), imageItem("h1"), unpinned("b")])

        panel.requestDelete(at: [1], deleteAll: false)
        panel.configure(state: .items([unpinned("a"), unpinned("b")]))
        panel.layoutIfNeeded()

        #expect(spy.deletedIndices == [[1]])
        #expect(panel.tableView.numberOfRows(inSection: 0) == 2)
        #expect(panel.items.map(\.id) == ["a", "b"])
    }
```

- [ ] **Step 2: 실패 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPanelViewTests`
Expected: 컴파일 실패 `'titleLabel' is inaccessible due to 'private' protection level` 또는 `has no member 'showTransientMessage'`

- [ ] **Step 3: 패널 구현**

`ClipboardHistoryPanelView.swift`:

(a) 프로퍼티. `weak var delegate` 아래에 추가하고 `titleLabel`의 `private let`을 `let`으로 바꾼다.

```swift
    /// 썸네일·미리보기 파일을 찾는 저장소. 소유자가 설정한다. `nil`이면 이미지 행에 자리표시 아이콘만 보인다
    var imageStore: ClipboardImageStore?

    /// 해시별 썸네일. 같은 해시는 같은 바이트라 무효화가 필요 없다. 메모리 경고 시 소유자가 `purgeThumbnailCache()`로 비운다
    private let thumbnailCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = ClipboardHistoryPolicy.maxItemCount + ClipboardHistoryPolicy.maxPinnedCount
        return cache
    }()
    /// 헤더 안내를 제목으로 되돌리는 예약 작업
    private var pendingTitleRestore: DispatchWorkItem?

    private static let transientMessageDuration: TimeInterval = 2
    private static let thumbnailSize = CGSize(width: 44, height: 44)
    private static let imagePlaceholderSymbolName = "photo"
```

`titleLabel` 초기화에 두 줄을 더한다(안내 문구가 길어 좁은 화면에서 줄여 보인다):

```swift
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
```

(b) Internal 메서드. `resetPresentation()` 안 `hideDeleteConfirmation(animated: false)` 뒤에 `restoreTitle()`을, `configure(state:)`의 `hideDeleteConfirmation()` 뒤에 `restoreTitle()`을, `beginItemEditing()`의 `isItemEditing = true` 앞에 `restoreTitle()`을 추가한다. `configure`의 `.empty` 문구를 바꾼다:

```swift
            messageLabel.text = String(localized: "복사한 텍스트나 이미지가 여기에 표시됩니다.", bundle: SYKBDAssets.bundle)
```

`cancelPendingDeletion()` 뒤에 추가:

```swift
    /// 헤더 제목 자리에 `message`를 잠깐 보여준 뒤 되돌린다. 이미지 복원처럼 패널을 유지한 채 결과를 알릴 때 쓴다.
    /// 편집 모드에서는 제목이 숨겨져 있으므로 띄우지 않는다
    func showTransientMessage(_ message: String) {
        guard !isItemEditing else { return }
        pendingTitleRestore?.cancel()
        titleLabel.text = message
        let workItem = DispatchWorkItem { [weak self] in self?.restoreTitle() }
        pendingTitleRestore = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + ClipboardHistoryPanelView.transientMessageDuration,
            execute: workItem
        )
    }

    func purgeThumbnailCache() {
        thumbnailCache.removeAllObjects()
    }
```

(c) Private 메서드. `updateHeader()` 앞에 추가:

```swift
    func restoreTitle() {
        pendingTitleRestore?.cancel()
        pendingTitleRestore = nil
        titleLabel.text = String(localized: "클립보드 기록", bundle: SYKBDAssets.bundle)
    }

    /// 캐시에 없으면 썸네일 파일을 읽어 넣는다. 파일이 없으면 `nil`
    func thumbnail(for reference: ClipboardImageReference) -> UIImage? {
        let key = reference.hash as NSString
        if let cached = thumbnailCache.object(forKey: key) { return cached }
        guard let url = imageStore?.thumbnailURL(for: reference),
              let image = UIImage(contentsOfFile: url.path) else { return nil }
        thumbnailCache.setObject(image, forKey: key)
        return image
    }
```

`showDetail(at:)`을 content로 분기한다:

```swift
    func showDetail(at index: Int) {
        guard items.indices.contains(index) else { return }
        detailIndex = index
        let item = items[index]
        let canPin = ClipboardHistoryPolicy.canPin(items)
        switch item.content {
        case .text(let text):
            detailView.update(
                text: text,
                isPinned: item.isPinned,
                canPin: canPin,
                canOpenURL: ClipboardHistoryPolicy.openableURL(in: text) != nil
            )
        case .image(let reference):
            // 원본을 상세 뷰 크기까지만 디코드한다. 파일이 없으면 자리표시 아이콘
            let preview = imageStore?
                .previewImage(for: reference, maxPixelSize: ClipboardImagePolicy.keyboardPreviewMaxPixelSize)
                .map { UIImage(cgImage: $0) }
            detailView.update(image: preview, isPinned: item.isPinned, canPin: canPin)
        }
        setDetailHidden(false, animated: true)
    }
```

`makeCell(in:at:id:)`을 content로 분기한다:

```swift
    func makeCell(in tableView: UITableView, at indexPath: IndexPath, id: String) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ClipboardHistoryPanelView.cellIdentifier, for: indexPath)
        guard let item = items.first(where: { $0.id == id }) else { return cell }
        var content = cell.defaultContentConfiguration()
        content.textProperties.font = .systemFont(ofSize: 15)
        switch item.content {
        case .text(let text):
            content.text = text
            content.textProperties.numberOfLines = 2
            content.textProperties.lineBreakMode = .byTruncatingTail
        case .image(let reference):
            // 썸네일만 읽는다. 원본은 목록에서 열지 않는다
            content.image = thumbnail(for: reference)
                ?? UIImage(systemName: ClipboardHistoryPanelView.imagePlaceholderSymbolName)
            content.imageProperties.maximumSize = ClipboardHistoryPanelView.thumbnailSize
            content.imageProperties.reservedLayoutSize = ClipboardHistoryPanelView.thumbnailSize
            content.imageProperties.cornerRadius = 4
            content.text = String(localized: "이미지", bundle: SYKBDAssets.bundle)
            content.secondaryText = reference.sizeDescription
            content.secondaryTextProperties.font = .systemFont(ofSize: 12)
            content.secondaryTextProperties.color = .secondaryLabel
        }
        cell.contentConfiguration = content
        cell.accessoryView = item.isPinned ? makePinAccessoryView() : nil
        cell.backgroundColor = .clear
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .suggestionButtonPressed
        cell.selectedBackgroundView = selectedBackgroundView

        return cell
    }
```

(d) `ClipboardHistoryDetailView`(private). `textView` 아래에 이미지 뷰를 추가한다:

```swift
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true

        return imageView
    }()
```

`setupUI()`의 `[blurView, headerStackView, textView, pasteButton]`에 `imageView`를 넣고(`textView` 뒤), 제약을 추가한다:

```swift
            imageView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 4),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
            imageView.bottomAnchor.constraint(
                equalTo: pasteButton.topAnchor,
                constant: -ClipboardHistoryDetailView.pasteButtonBottomSpacing
            ),
```

기존 `update(text:isPinned:canPin:canOpenURL:)` 첫 줄에 텍스트 모드 전환을 넣고, 이미지용 `update`를 추가한다:

```swift
    func update(text: String, isPinned: Bool, canPin: Bool, canOpenURL: Bool) {
        setImageMode(false)
        ...기존 본문 그대로...
    }

    /// 이미지 항목. 본문 대신 미리보기를 보여주고, 버튼은 "복사"가 된다(키보드는 입력창에 이미지를 넣을 수 없다)
    func update(image: UIImage?, isPinned: Bool, canPin: Bool) {
        setImageMode(true)
        imageView.image = image ?? UIImage(systemName: "photo")
        openURLTapGesture.isEnabled = false
        pinButton.isHidden = !isPinned && !canPin
        pinButton.configuration?.title = isPinned
        ? String(localized: "고정 해제", bundle: SYKBDAssets.bundle)
        : String(localized: "고정", bundle: SYKBDAssets.bundle)
    }
```

private extension에 추가:

```swift
    func setImageMode(_ isImage: Bool) {
        imageView.isHidden = !isImage
        textView.isHidden = isImage
        if !isImage { imageView.image = nil }
        pasteButton.configuration?.title = isImage
        ? String(localized: "복사", bundle: SYKBDAssets.bundle)
        : String(localized: "붙여넣기", bundle: SYKBDAssets.bundle)
    }
```

`detailView`의 `onPaste` 클로저 주석을 "붙여넣기(텍스트) 또는 복사(이미지) 직후"로 고치고, 델리게이트 호출 순서(`didRequestCopyAt` → `didSelectItemAt`)는 그대로 둔다.

(e) `ClipboardHistoryPanelView` 클래스 doc의 "행 탭은 붙여넣기"를 "행 탭은 붙여넣기(텍스트) 또는 pasteboard 복원(이미지)"으로 고친다.

- [ ] **Step 4: Core 문자열 추가**

`SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/Localizable.xcstrings`의 `"strings"` 객체에 다음 세 항목을 넣는다(키 정렬은 Xcode가 다시 맞춘다). `"복사"` 키가 이미 있으면 추가하지 않는다.

```json
    "복사" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Copy"
          }
        }
      }
    },
    "복사한 텍스트나 이미지가 여기에 표시됩니다." : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Copied text and images will appear here."
          }
        }
      }
    },
    "이미지" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Image"
          }
        }
      }
    },
    "이미지를 복사했습니다. 입력창을 길게 눌러 붙여넣기" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Image copied. Long-press the text field to paste"
          }
        }
      }
    },
```

`"복사한 텍스트가 여기에 표시됩니다."` 항목은 더 이상 쓰지 않으므로 삭제한다. 확인: `python3 -c "import json;json.load(open('SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/Localizable.xcstrings'))"`가 오류 없이 끝난다.

- [ ] **Step 5: 통과 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPanelViewTests`
Expected: 기존 15개 + 새 4개 전부 `passed`, `TEST SUCCEEDED`

- [ ] **Step 6: 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift \
  SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/Localizable.xcstrings \
  SYKeyboardTests/Presentation/ClipboardHistoryPanelViewTests.swift \
  docs/superpowers/plans/2026-09-10-clipboard-image-history.md
git commit -m "feat: #55 - 키보드 패널에 이미지 썸네일 행·상세 미리보기·복사 안내 추가"
```

---

### Task 7: 키보드에서 이미지 항목 선택 시 pasteboard 복원

VC 델리게이트는 순수 타입이 아니고 `UIInputViewController` 없이 만들 수 없으므로 단위 테스트를 추가하지 않는다. 세 extension scheme 빌드와 Task 9의 실기기 확인으로 검증한다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` (`didReceiveMemoryWarning`, `clipboardHistoryPanelView.delegate = self` 부근, `Clipboard History` 확장, 델리게이트 확장)
- 확인만: `SYKeyboard/App/SYKeyboardApp.swift:171-175` (`synchronizeIfNeeded(store:)` 호출은 기본값으로 이미지 캡처까지 한다. 변경 없음)

**Interfaces:**
- Consumes: `ClipboardHistoryPanelView.imageStore`/`showTransientMessage`/`purgeThumbnailCache`(Task 6), `ClipboardHistoryStore.imageStore`/`record(_ content:)`/`remove(ids:)`(Task 3·4), `synchronizeIfNeeded(store:onImageRecorded:)`(Task 5)

- [ ] **Step 1: 패널 연결과 메모리 경고**

`clipboardHistoryPanelView.delegate = self` 줄 바로 아래:

```swift
        clipboardHistoryPanelView.imageStore = clipboardHistoryStore?.imageStore
```

`didReceiveMemoryWarning()`:

```swift
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // 언어별로 캐시해 둔 예측 엔진 중 지금 쓰지 않는 것부터 버린다
        suggestionController.releaseInactiveLanguageEngines()
        // 클립보드 패널 썸네일은 파일에서 다시 읽을 수 있다
        clipboardHistoryPanelView.purgeThumbnailCache()
    }
```

- [ ] **Step 2: 동기화 완료 시 패널 갱신**

`synchronizeClipboardHistoryIfNeeded()`를 다음으로 바꾼다.

```swift
    /// pasteboard의 `changeCount`가 마지막 확인값과 다를 때만 텍스트 또는 이미지를 읽어 기록에 저장합니다.
    ///
    /// 호출 시점: `viewWillAppear`, `textWillChange`, 클립보드 버튼 탭. `textDidChange`와 selection 콜백은 쓰지 않습니다.
    /// 앱도 활성화 시 같은 `ClipboardHistoryPasteboardSynchronizer`를 호출한다.
    /// 이미지는 백그라운드에서 파일로 저장된 뒤 기록되므로, 그사이 패널이 열려 있으면 완료 시 다시 읽는다
    func synchronizeClipboardHistoryIfNeeded() {
        guard isClipboardHistoryAvailable, let clipboardHistoryStore else { return }
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: clipboardHistoryStore) { [weak self] in
            guard let self, self.isClipboardPanelVisible else { return }
            self.reloadClipboardPanel()
        }
    }
```

- [ ] **Step 3: 복원 경로**

`Clipboard History` private extension의 `reloadClipboardPanel()` 뒤에 추가:

```swift
    /// 이미지 항목은 입력창에 넣을 수 없으므로 시스템 pasteboard에 원본 바이트를 복원하고 패널을 유지한 채 안내한다.
    /// 우리가 쓴 값을 다음 동기화에서 다시 기록하지 않도록 changeCount를 갱신한다
    func restoreImageToPasteboard(_ reference: ClipboardImageReference) {
        guard isClipboardHistoryAvailable,
              let clipboardHistoryStore,
              let imageStore = clipboardHistoryStore.imageStore else { return }
        // 메모리 맵으로 열어 힙에 올리지 않는다. 앱에서 지운 뒤 키보드가 옛 목록을 들고 있으면 항목을 정리한다
        guard let data = try? Data(contentsOf: imageStore.originalURL(for: reference), options: .mappedIfSafe) else {
            clipboardHistoryStore.remove(ids: [ClipboardHistoryItem.Content.image(reference).id])
            reloadClipboardPanel()
            return
        }
        let pasteboard = UIPasteboard.general
        pasteboard.setData(data, forPasteboardType: reference.typeIdentifier)
        keyboardSettingsManager.lastSeenPasteboardChangeCount = pasteboard.changeCount

        // 방금 쓴 항목을 최근 복사한 것처럼 미고정 맨 위로 올린다. 고정 항목은 정책상 그대로다
        clipboardHistoryStore.record(.image(reference))
        reloadClipboardPanel()
        clipboardHistoryPanelView.showTransientMessage(
            String(localized: "이미지를 복사했습니다. 입력창을 길게 눌러 붙여넣기", bundle: SYKBDAssets.bundle)
        )
    }
```

`BaseKeyboardViewController.swift` 상단에 `import SYKeyboardAssets`가 없으면 추가한다(`SYKBDAssets.bundle` 사용).

- [ ] **Step 4: 델리게이트 분기**

`clipboardPanel(_:didSelectItemAt:)`:

```swift
    final func clipboardPanel(_ panel: ClipboardHistoryPanelView, didSelectItemAt index: Int) {
        guard panel.items.indices.contains(index) else { return }
        switch panel.items[index].content {
        case .image(let reference):
            restoreImageToPasteboard(reference)
        case .text(let text):
            // 붙여넣기를 undo 1단위로 만든다: 앞선 입력 그룹을 닫고, 삽입 후 다시 닫는다
            commitUndoRedoGroupIgnoringCompositionDeferral()
            insertText(text)
            undoRedoEditDidApply()
            commitUndoRedoGroupIgnoringCompositionDeferral()

            // 방금 쓴 항목을 최근 복사한 것처럼 미고정 맨 위로 올린다. 고정 항목은 정책상 그대로다.
            // 시스템 pasteboard는 바꾸지 않는다
            clipboardHistoryStore?.record(text)

            closeClipboardPanelIfNeeded()
            updateReturnButtonEnabled()
            updateSuggestions()
        }
    }
```

`clipboardPanel(_:didRequestCopyAt:)`: 상세 뷰의 이미지 "복사"는 이어서 오는 `didSelectItemAt`가 복원하므로 여기서는 텍스트만 처리한다. Task 3에서 넣은 `guard let text = panel.items[index].text else { return }`가 그 역할을 하며 주석만 보강한다:

```swift
    /// 텍스트 항목을 시스템 pasteboard에 복사한다. 이미지는 이어지는 `didSelectItemAt`의 복원 경로가 처리한다.
    /// 우리가 쓴 값을 다음 동기화에서 다시 기록하지 않도록 changeCount를 갱신한다
```

- [ ] **Step 5: 빌드 확인**

Run(테스트 전체 + 세 extension 빌드):

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' 2>&1 \
  | grep -E "failed on|error:|TEST (SUCCEEDED|FAILED)"
for scheme in HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build -project SYKeyboard.xcodeproj -scheme "$scheme" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' 2>&1 \
    | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
done
git status --short
```

Expected: `TEST SUCCEEDED`, 세 scheme `BUILD SUCCEEDED`, `error:` 0건. `.xcscheme` `RemotePath` 변경이 보이면 복원한다.

- [ ] **Step 6: 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  docs/superpowers/plans/2026-09-10-clipboard-image-history.md
git commit -m "feat: #55 - 키보드에서 이미지 항목 선택 시 pasteboard 복원"
```

---

### Task 8: 앱 관리 화면의 이미지 항목과 "이미지도 기록" 토글

**Files:**
- Modify: `SYKeyboard/Presentation/KeyboardSettings/ClipboardHistorySettingsView.swift`
- Modify: `SYKeyboard/Presentation/KeyboardSettings/KeyboardToolbarSettingsView.swift` (`isClipboardHistoryEnabled` 토글과 `NavigationLink` 사이)
- Modify: `SYKeyboard/Resources/Localizable.xcstrings`

**Interfaces:**
- Consumes: `ClipboardHistoryStore.imageStore`, `ClipboardImageStore.thumbnailURL`/`originalURL`/`previewImage`, `ClipboardImagePolicy.appPreviewMaxPixelSize`, `UserDefaultsKeys.isClipboardImageHistoryEnabled`

SwiftUI 뷰는 단위 테스트 대상이 아니다(저장소 규칙). 앱 빌드와 Task 9의 실기기 확인으로 검증한다.

- [ ] **Step 1: 목록 행**

`ClipboardHistorySettingsView`의 `row(for:)`를 다음으로 바꾼다.

```swift
    func row(for item: ClipboardHistoryItem) -> some View {
        HStack {
            switch item.content {
            case .text(let text):
                Text(text)
                    .lineLimit(2)
            case .image(let reference):
                thumbnail(for: reference)
                VStack(alignment: .leading, spacing: 2) {
                    Text("이미지")
                    Text(reference.sizeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if item.isPinned {
                Image(systemName: "pin.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }

    /// 썸네일 파일만 읽는다. 앱 프로세스는 메모리 여유가 있어 캐시 없이 동기 로드한다
    @ViewBuilder
    func thumbnail(for reference: ClipboardImageReference) -> some View {
        if let url = store?.imageStore?.thumbnailURL(for: reference),
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Image(systemName: "photo")
                .frame(width: 44, height: 44)
        }
    }
```

빈 상태 문구 `Text("복사한 텍스트가 여기에 표시됩니다.")`를 `Text("복사한 텍스트나 이미지가 여기에 표시됩니다.")`로 바꾼다.

- [ ] **Step 2: 복사(복원)**

`copyFromDetail(_:)`을 다음으로 바꾼다.

```swift
    /// 복사한 항목을 최근 복사한 것처럼 목록 맨 위로 올린다. 동기화가 방금 쓴 pasteboard를 다시 읽지 않도록 changeCount를 맞춘다.
    /// 이미지는 원본 바이트를 그대로 pasteboard에 놓는다. 파일이 없으면 아무것도 하지 않는다
    func copyFromDetail(_ item: ClipboardHistoryItem) {
        let pasteboard = UIPasteboard.general
        switch item.content {
        case .text(let text):
            pasteboard.string = text
        case .image(let reference):
            guard let url = store?.imageStore?.originalURL(for: reference),
                  let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return }
            pasteboard.setData(data, forPasteboardType: reference.typeIdentifier)
        }
        UserDefaultsManager.shared.lastSeenPasteboardChangeCount = pasteboard.changeCount
        store?.record(item.content)
        reload()
        refreshDetailItem(id: item.id)
    }
```

`synchronizeAndReload()`는 이미지 저장 완료 시 다시 읽도록 바꾼다:

```swift
    func synchronizeAndReload() {
        if let store, UserDefaultsManager.shared.isClipboardHistoryEnabled {
            ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: store, onImageRecorded: reload)
        }
        reload()
    }
```

- [ ] **Step 3: 원문 시트의 이미지 모드**

private `ClipboardHistoryDetailView`에 프로퍼티와 미리보기를 추가한다. `init`은 memberwise라 호출부(`ClipboardHistoryDetailView(item:canPin:canSave:onTogglePin:onCopy:onSave:)`)에 `imageStore: store?.imageStore`를 `item:` 다음 인자로 넣는다.

```swift
private struct ClipboardHistoryDetailView: View {
    let item: ClipboardHistoryItem
    let imageStore: ClipboardImageStore?
    ...기존 프로퍼티...

    private var text: String { item.text ?? "" }

    /// 원본을 시트 폭에 맞는 크기까지만 디코드한다
    private var previewImage: UIImage? {
        guard let reference = item.image else { return nil }
        return imageStore?
            .previewImage(for: reference, maxPixelSize: ClipboardImagePolicy.appPreviewMaxPixelSize)
            .map { UIImage(cgImage: $0) }
    }
```

`body`의 `Group`을 다음으로 바꾼다.

```swift
            Group {
                if isEditing {
                    TextEditor(text: $draft)
                        // 시트 배경 위에 흰 사각형이 뜨지 않도록 편집기 배경을 비운다
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal)
                } else if item.image != nil {
                    ScrollView {
                        if let previewImage {
                            Image(uiImage: previewImage)
                                .resizable()
                                .scaledToFit()
                                .padding()
                        } else {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                    }
                } else {
                    ScrollView {
                        // 텍스트 전체가 URL이면 일반 링크처럼 파란 밑줄로 보이고 탭하면 브라우저로 연다
                        Text(linkStyledText)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
            }
            .navigationTitle(isEditing ? "원문 편집" : (item.image != nil ? "이미지" : "원문"))
```

툴바의 비편집 분기에서 공유·편집을 content에 맞춘다:

```swift
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        if item.isPinned || canPin {
                            Button(action: onTogglePin) {
                                Label(
                                    item.isPinned ? "고정 해제" : "고정",
                                    systemImage: item.isPinned ? "pin.fill" : "pin"
                                )
                            }
                        }
                        if let reference = item.image, let url = imageStore?.originalURL(for: reference) {
                            ShareLink(item: url) {
                                Label("공유", systemImage: "square.and.arrow.up")
                            }
                        } else {
                            ShareLink(item: text) {
                                Label("공유", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: onCopy) {
                            Label("복사", systemImage: "doc.on.doc")
                        }
                        // 이미지는 편집하지 않는다
                        if item.image == nil {
                            Button {
                                draft = text
                                isEditing = true
                            } label: {
                                Label("편집", systemImage: "pencil.line")
                            }
                        }
                    }
```

- [ ] **Step 4: 설정 토글**

`KeyboardToolbarSettingsView`의 `isClipboardHistoryEnabled` `@AppStorage` 아래에 추가:

```swift
    @AppStorage(UserDefaultsKeys.isClipboardImageHistoryEnabled, store: UserDefaultsManager.shared.storage)
    private var isClipboardImageHistoryEnabled = DefaultValues.isClipboardImageHistoryEnabled
```

`if isClipboardHistoryEnabled {` 블록 안, `NavigationLink` 앞에 추가(기존 토글처럼 `hideKeyboard()`를 부른다):

```swift
                Toggle(isOn: $isClipboardImageHistoryEnabled, label: {
                    Text("이미지도 기록")
                    Text("복사한 이미지를 저장하고 탭하면 클립보드로 복원합니다. 이미지당 12 MB까지. 끄면 새로 복사한 이미지를 저장하지 않으며, 저장된 이미지는 클립보드 기록 관리에서 삭제할 수 있습니다.")
                        .font(.caption)
                })
                .onChange(of: isClipboardImageHistoryEnabled) { newValue in
                    Analytics.setUserProperty(newValue.analyticsValue,
                                              forName: "pref_clipboard_image_history")
                    Analytics.logEvent("clipboard_image_history", parameters: [
                        "view": "KeyboardToolbarSettingsView",
                        "enabled": newValue.analyticsValue
                    ])
                    hideKeyboard()
                }
```

기존 "클립보드 기록" 캡션의 "복사한 텍스트를"은 그대로 둔다(텍스트 기록의 설명이고 이미지는 하위 토글이 설명한다).

- [ ] **Step 5: 앱 문자열 추가**

`SYKeyboard/Resources/Localizable.xcstrings`의 `"strings"`에 추가한다(앱 카탈로그는 `extractionState` 없이 자동 추출 형식이다). 이미 있는 키("이미지", "복사")는 건너뛴다.

```json
    "복사한 텍스트나 이미지가 여기에 표시됩니다." : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Copied text and images will appear here."
          }
        }
      }
    },
    "이미지" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Image"
          }
        }
      }
    },
    "이미지도 기록" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Include Images"
          }
        }
      }
    },
    "복사한 이미지를 저장하고 탭하면 클립보드로 복원합니다. 이미지당 12 MB까지. 끄면 새로 복사한 이미지를 저장하지 않으며, 저장된 이미지는 클립보드 기록 관리에서 삭제할 수 있습니다." : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Saves copied images and restores one to the clipboard when tapped. Up to 12 MB per image. When off, newly copied images are not saved; saved images can be deleted in Manage Clipboard History."
          }
        }
      }
    },
```

`"복사한 텍스트가 여기에 표시됩니다."` 앱 항목은 삭제한다. 확인: `python3 -c "import json;json.load(open('SYKeyboard/Resources/Localizable.xcstrings'))"`.

- [ ] **Step 6: 빌드 확인**

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expected: `BUILD SUCCEEDED`, `error:` 0건

- [ ] **Step 7: 커밋**

```sh
git add SYKeyboard/Presentation/KeyboardSettings/ClipboardHistorySettingsView.swift \
  SYKeyboard/Presentation/KeyboardSettings/KeyboardToolbarSettingsView.swift \
  SYKeyboard/Resources/Localizable.xcstrings docs/superpowers/plans/2026-09-10-clipboard-image-history.md
git commit -m "feat: #55 - 앱 관리 화면 이미지 항목과 이미지 기록 토글 추가"
```

---

### Task 9: 최종 검증과 기록

**Files:**
- Modify: `docs/superpowers/plans/2026-09-10-clipboard-image-history.md`

- [ ] **Step 1: 전체 테스트와 네 scheme 빌드**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' 2>&1 \
  | grep -E "passed on|failed on|error:|TEST (SUCCEEDED|FAILED)" | sort | uniq -c | sort -rn | head
for scheme in HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build -project SYKeyboard.xcodeproj -scheme "$scheme" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' 2>&1 \
    | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
done
git status --short
```

Expected: `TEST SUCCEEDED`, `failed on` 0건, 세 scheme `BUILD SUCCEEDED`. `.xcscheme` `RemotePath` 변경은 복원한다.

- [ ] **Step 2: 결과 기록**

아래 "검증 결과" 절에 실제 실행 명령, 기기명/OS, `passed on` 줄 수(테스트 개수)와 `failed on` 줄 수, 빌드 결과, Task 5에서 `loadFileRepresentation`과 `loadDataRepresentation` 중 무엇을 썼는지를 적는다. 실기기 확인 항목은 확인하지 못했으면 "미확인"과 차단 이유를 그대로 남긴다.

- [ ] **Step 3: 커밋**

```sh
git add docs/superpowers/plans/2026-09-10-clipboard-image-history.md
git commit -m "docs: #55 - 구현 계획에 검증 결과 기록"
```

---

## 검증 결과

(Task 9에서 기록)

### 실기기 확인 항목 (자동 테스트로 대체 불가)

| 항목 | 결과 |
| --- | --- |
| 사진 앱에서 12 MP 사진 복사 → 키보드 열기 → 패널에 썸네일·크기 표시 → 메시지 앱에서 입력창 길게 눌러 붙여넣기 성공 | 미확인 |
| 스크린샷(PNG) 복사 → 저장 확인 | 미확인 |
| 20 MP 이상 PNG 복사 → Xcode 메모리 게이지로 키보드 피크 확인. 종료되면 PNG 전용 픽셀 상한 도입 | 미확인 |
| 웹페이지에서 텍스트+이미지 영역 복사 → 텍스트만 저장 | 미확인 |
| 이미지 탭 → pasteboard 복원, 헤더 안내 약 2초 표시 후 제목 복구(좁은 화면에서 문구가 잘리지 않고 축소), 입력창 탭 시 패널 닫힘 | 미확인 |
| 이미지 paste 미지원 입력 필드(검색창 등)에서 붙여넣기 메뉴 동작 기록 | 미확인 |
| "이미지도 기록" OFF → 새 이미지 미저장, 기존 이미지 항목 유지 | 미확인 |
| 앱 관리 화면에서 이미지 항목 삭제 → App Group `ClipboardImages/` 원본·썸네일 삭제 확인 | 미확인 |
| 앱 원문 시트에서 이미지 미리보기·공유(파일)·복사(복원)·고정 동작, 편집 버튼 없음 | 미확인 |
| iOS 16 기기에서 이미지 캡처 시 붙여넣기 권한 알림이 텍스트와 같은 방식으로 뜸 | 미확인 |
| 키보드 상세 뷰(길게 누르기)에서 이미지 미리보기와 "복사" 버튼 → 복원·헤더 안내 | 미확인 |
| 같은 이미지 재복사 시 항목이 맨 위로 이동하고 파일이 늘지 않음, 고정 이미지는 자리 유지 | 미확인 |
| 영어 기기에서 이미지 관련 패널·앱 문구가 영문 표시 | 미확인 |
