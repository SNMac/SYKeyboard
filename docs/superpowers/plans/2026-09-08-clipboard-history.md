# 텍스트 클립보드 기록 및 붙여넣기 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 클립보드 기록 설정을 켜면 키보드가 확인한 pasteboard 텍스트를 App Group 파일에 누적 저장하고, suggestion bar 왼쪽 클립보드 버튼으로 여는 패널에서 골라 현재 입력 위치에 붙여넣을 수 있게 한다.

**Architecture:** 저장 정책(`ClipboardHistoryPolicy`)·저장소(`ClipboardHistoryStore`)·패널 뷰(`ClipboardHistoryPanelView`)를 모두 `SYKeyboardCore`에 두고, `BaseKeyboardViewController`가 `isClipboardPanelVisible` 플래그 하나로 패널을 `keyboardLayoutView` 안의 자판 뷰들과 `isHidden`으로 전환한다. 세 extension VC는 수정하지 않는다. pasteboard는 `viewWillAppear`·`textWillChange`·클립보드 버튼 탭에서 `changeCount`가 바뀌었을 때만 읽는다.

**Tech Stack:** Swift 5, UIKit(`UIPasteboard`, `UITableView` 편집 모드·swipe action, `UIListContentConfiguration`, `UIButton.Configuration`), `PropertyListEncoder`(binary, atomic write), SwiftUI `@AppStorage`, String Catalog, Swift Testing(`@Suite`, `@Test`, `#expect`)

**Spec:** `docs/superpowers/specs/2026-09-08-clipboard-history-design.md`

## Global Constraints

- iOS 16+ / Swift 5 / Xcode 26. deprecated API 신규 사용 금지.
- 작업 브랜치 `feat/#54-clipboard-history`. 스펙 커밋 `a27f326e` 뒤에 이어서 커밋한다.
- 커밋 메시지는 `type: #54 - subject` 형식, 한국어, 마침표 없음. 코드 Task는 `feat`, 검증 기록 Task는 `docs`.
- 각 Task는 코드·테스트·이 계획 문서의 체크박스 갱신을 **하나의 커밋**으로 남긴다. 실행하지 않았거나 실패한 step을 미리 완료로 표시하지 않는다. 다음 Task는 직전 Task의 커밋 뒤에 시작한다.
- `Modules/SYKeyboardCore/`에 새 파일을 추가할 때마다 `SYKeyboard.xcodeproj/project.pbxproj`의 두 예외 목록(`target = 5BB373502ED5AA18006AB083 /* SYKeyboardCore */`와 `target = 5B7B3F552C569B7800F7C093 /* SYKeyboard */`)에 같은 경로를 알파벳순으로 넣는다. 등록하지 않으면 `cannot find ... in scope`로 컴파일이 실패한다. `SYKeyboardTests/`는 동기화 폴더라 테스트 파일은 등록이 필요 없다.
- production 타입에 `ForTesting` 메서드를 추가하지 않는다. 테스트 seam은 `ClipboardHistoryStore(fileURL:)`처럼 init 파라미터로만 둔다.
- 세 extension VC, Firebase/AdMob, entitlements, `Info.plist`, `Secrets.xcconfig`, `.xcscheme`은 건드리지 않는다.
- 기준 시뮬레이터: iPhone 13 mini / iOS 16.0 (로컬에 존재함, UDID `CBD992D3-5364-4F69-AC5F-0077ADF1A292`).
- 빌드·테스트 뒤 `git status --short`에서 `.xcscheme`의 `RemotePath` 변경이 보이면 `git checkout -- SYKeyboard.xcodeproj/xcshareddata/xcschemes/<이름>.xcscheme`로 복원한다. `RemotePath` 외 항목이 바뀌었다면 되돌리지 말고 보고한다.
- 정확한 색·폰트·SF Symbol 이름·private subview 구조는 테스트로 고정하지 않는다.
- `String Catalog`(`.xcstrings`)는 Xcode가 다시 저장하면 키 순서를 재정렬할 수 있다. 그 diff는 그대로 커밋한다.

관련 테스트 실행 명령(각 Task의 "Run"은 이 명령에 `-only-testing`을 바꿔 쓴다):

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/<SuiteTypeName> 2>&1 | grep -E "Test Suite|✔|✘|error:|TEST (SUCCEEDED|FAILED)"
```

extension 빌드 명령(Task 7·9에서 사용, `-only-testing` 없이):

```sh
for scheme in HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build -project SYKeyboard.xcodeproj -scheme "$scheme" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' 2>&1 \
    | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
done
```

---

## File Structure

| 파일 | 책임 | Task |
| --- | --- | --- |
| `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift` (수정) | `isClipboardHistoryEnabled`, `lastSeenPasteboardChangeCount` 키 | 1 |
| `Modules/SYKeyboardCore/Storage/DefaultValues.swift` (수정) | 두 키의 기본값 `false`, `-1` | 1 |
| `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift` (수정) | 두 키의 wrapper 프로퍼티 | 1 |
| `SYKeyboardTests/Storage/UserDefaultsContractTests.swift` (수정) | 키 문자열·기본값·fallback 계약 | 1 |
| `Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardHistoryPolicy.swift` (신규) | `ClipboardHistoryItem` 모델, 중복 제거·개수·길이 규칙 | 2 |
| `SYKeyboardTests/Utils/ClipboardHistoryPolicyTests.swift` (신규) | 정책 테스트 | 2 |
| `Modules/SYKeyboardCore/Storage/ClipboardHistoryStore.swift` (신규) | App Group plist 읽기·쓰기, `record`/`remove`/`removeAll` | 3 |
| `SYKeyboardTests/Storage/ClipboardHistoryStoreTests.swift` (신규) | 임시 파일로 저장소 왕복 테스트 | 3 |
| `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardPresentationStatePolicy.swift` (수정) | `shouldShowClipboardControl` | 4 |
| `SYKeyboardTests/Utils/KeyboardPresentationStatePolicyTests.swift` (수정) | 표시 조건 4조합 | 4 |
| `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift` (수정) | 클립보드 버튼·divider·델리게이트 메서드·히트테스트 | 5 |
| `SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift` (수정) | 클립보드 버튼 탭 전달과 후보 하이라이트 무관 | 5 |
| `Modules/SYKeyboardCore/Resources/Localizable.xcstrings` (신규) | Core 패널 문자열 ko/en | 6 |
| `Modules/SYKeyboardCore/Presentation/Utils/Extensions/Bundle+Extension.swift` (수정) | `Bundle.sykeyboardCore` | 6 |
| `Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift` (신규) | 헤더·테이블·편집 모드·swipe·길게 누르기 상세 뷰 | 6 |
| `SYKeyboardTests/Presentation/ClipboardHistoryPanelViewTests.swift` (신규) | 행 탭·편집 모드 삭제 의미 | 6 |
| `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift` (수정) | 패널을 `keyboardLayoutView`에 추가 | 7 |
| `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` (수정) | 저장 프로퍼티, pasteboard 동기화, 패널 열기/닫기, 패널 델리게이트, 호출 지점. helper가 `private extension`에 있어 별도 파일로 뺄 수 없다 | 7 |
| `SYKeyboard/Presentation/KeyboardSettings/PredictiveTextSettingsView.swift` (수정) | 중첩 토글 | 8 |
| `SYKeyboard/Resources/Localizable.xcstrings` (수정) | 앱 토글 문자열 en | 8 |
| `docs/superpowers/plans/2026-09-08-clipboard-history.md` (수정) | 검증 결과 기록 | 9 |

---

### Task 1: 설정 키와 기본값

**Files:**
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift`
- Modify: `Modules/SYKeyboardCore/Storage/DefaultValues.swift`
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift`
- Test: `SYKeyboardTests/Storage/UserDefaultsContractTests.swift`

**Interfaces:**
- Produces: `UserDefaultsKeys.isClipboardHistoryEnabled: String`, `UserDefaultsKeys.lastSeenPasteboardChangeCount: String`, `DefaultValues.isClipboardHistoryEnabled: Bool = false`, `DefaultValues.lastSeenPasteboardChangeCount: Int = -1`, `UserDefaultsManager.shared.isClipboardHistoryEnabled: Bool`, `UserDefaultsManager.shared.lastSeenPasteboardChangeCount: Int`

- [x] **Step 1: 계약 테스트 추가**

`UserDefaultsContractTests.swift`의 `testLetterColumnWidthMultiplierDefaultFallbackAndKey` 뒤(struct 닫는 `}` 앞)에 추가:

```swift
    @Test("클립보드 기록은 저장값이 없으면 false를 반환하고 공유 저장소 키를 유지")
    func testClipboardHistoryDefaultFallbackAndKey() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.isClipboardHistoryEnabled
        let originalValue = storage.object(forKey: key)

        storage.removeObject(forKey: key)
        defer { restore(originalValue, forKey: key, in: storage) }

        #expect(key == "isClipboardHistoryEnabled")
        #expect(DefaultValues.isClipboardHistoryEnabled == false)
        #expect(UserDefaultsManager.shared.isClipboardHistoryEnabled == false)
    }

    @Test("마지막 pasteboard changeCount는 저장값이 없으면 -1을 반환하고 공유 저장소 키를 유지")
    func testLastSeenPasteboardChangeCountDefaultFallbackAndKey() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.lastSeenPasteboardChangeCount
        let originalValue = storage.object(forKey: key)

        storage.removeObject(forKey: key)
        defer { restore(originalValue, forKey: key, in: storage) }

        #expect(key == "lastSeenPasteboardChangeCount")
        #expect(DefaultValues.lastSeenPasteboardChangeCount == -1)
        #expect(UserDefaultsManager.shared.lastSeenPasteboardChangeCount == -1)

        UserDefaultsManager.shared.lastSeenPasteboardChangeCount = 7

        #expect(storage.integer(forKey: key) == 7)
        #expect(UserDefaultsManager.shared.lastSeenPasteboardChangeCount == 7)
    }
```

- [x] **Step 2: 실패 확인**

Run: 위 테스트 명령에 `-only-testing:SYKeyboardTests/UserDefaultsContractTests`
Expected: 컴파일 실패 `type 'UserDefaultsKeys' has no member 'isClipboardHistoryEnabled'`

- [x] **Step 3: 키·기본값·wrapper 추가**

`UserDefaultsKeys.swift`의 `isShowMathResultsEnabled` 선언 바로 뒤에:

```swift
    /// 클립보드 기록
    public static let isClipboardHistoryEnabled = "isClipboardHistoryEnabled"
```

같은 파일 `isRequestFullAccessOverlayClosed` 선언 바로 뒤에:

```swift
    /// 마지막으로 확인한 pasteboard changeCount 저장용
    public static let lastSeenPasteboardChangeCount = "lastSeenPasteboardChangeCount"
```

`DefaultValues.swift`의 `isShowMathResultsEnabled` 바로 뒤에:

```swift
    /// 클립보드 기록 기본값. 클립보드 내용을 저장하므로 사용자가 직접 켠다
    public static let isClipboardHistoryEnabled: Bool = false
```

같은 파일 `isRequestFullAccessOverlayClosed` 바로 뒤에:

```swift
    /// 마지막으로 확인한 pasteboard changeCount 기본값. 아직 확인한 적 없음을 뜻한다
    public static let lastSeenPasteboardChangeCount: Int = -1
```

`UserDefaultsManager.swift`의 `isShowMathResultsEnabled` wrapper 바로 뒤에:

```swift
    /// 클립보드 기록
    @UserDefaultsWrapper(key: UserDefaultsKeys.isClipboardHistoryEnabled, defaultValue: DefaultValues.isClipboardHistoryEnabled)
    public var isClipboardHistoryEnabled: Bool
```

같은 파일 `isRequestFullAccessOverlayClosed` wrapper 바로 뒤에:

```swift
    /// 마지막으로 확인한 pasteboard changeCount
    @UserDefaultsWrapper(key: UserDefaultsKeys.lastSeenPasteboardChangeCount, defaultValue: DefaultValues.lastSeenPasteboardChangeCount)
    public var lastSeenPasteboardChangeCount: Int
```

- [x] **Step 4: 통과 확인**

Run: 같은 명령
Expected: `UserDefaultsContractTests` 전체 PASS (기존 12개 + 신규 2개)

- [x] **Step 5: 커밋**

```sh
git add Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift \
        Modules/SYKeyboardCore/Storage/DefaultValues.swift \
        Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift \
        SYKeyboardTests/Storage/UserDefaultsContractTests.swift \
        docs/superpowers/plans/2026-09-08-clipboard-history.md
git commit -m "feat: #54 - 클립보드 기록 설정 키와 마지막 pasteboard changeCount 저장값 추가"
```

---

### Task 2: 기록 항목 모델과 저장 정책

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardHistoryPolicy.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj` (두 예외 목록)
- Test: `SYKeyboardTests/Utils/ClipboardHistoryPolicyTests.swift`

**Interfaces:**
- Produces:
  - `struct ClipboardHistoryItem: Codable, Equatable { let text: String; let createdAt: Date; init(text:createdAt:) }`
  - `enum ClipboardHistoryPolicy { static let maxItemCount = 20; static let maxTextLength = 2_000; static func inserting(_ text: String, into items: [ClipboardHistoryItem], now: Date) -> [ClipboardHistoryItem]? }`

- [x] **Step 1: 정책 테스트 작성**

`SYKeyboardTests/Utils/ClipboardHistoryPolicyTests.swift`:

```swift
//
//  ClipboardHistoryPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/8/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("클립보드 기록 저장 정책 검증")
struct ClipboardHistoryPolicyTests {

    private let now = Date(timeIntervalSince1970: 1_000)

    @Test("빈 문자열과 공백·개행만 있는 문자열은 저장하지 않음")
    func test빈문자열과공백은_저장하지않음() {
        #expect(ClipboardHistoryPolicy.inserting("", into: [], now: now) == nil)
        #expect(ClipboardHistoryPolicy.inserting(" \n\t", into: [], now: now) == nil)
    }

    @Test("최대 길이까지는 저장하고 넘으면 잘라 저장하지 않고 버림")
    func test최대길이초과는_버림() {
        let limit = String(repeating: "가", count: ClipboardHistoryPolicy.maxTextLength)
        let over = limit + "나"

        #expect(ClipboardHistoryPolicy.inserting(limit, into: [], now: now)?.first?.text == limit)
        #expect(ClipboardHistoryPolicy.inserting(over, into: [], now: now) == nil)
    }

    @Test("새 텍스트는 맨 앞에 들어가고 기존 순서는 유지")
    func test새텍스트는_맨앞에삽입() {
        let items = [item("a"), item("b")]

        let result = ClipboardHistoryPolicy.inserting("c", into: items, now: now)

        #expect(result?.map(\.text) == ["c", "a", "b"])
        #expect(result?.first?.createdAt == now)
    }

    @Test("같은 텍스트는 중복 저장하지 않고 맨 앞으로 이동")
    func test중복텍스트는_맨앞으로이동() {
        let items = [item("a"), item("b"), item("c")]

        let result = ClipboardHistoryPolicy.inserting("b", into: items, now: now)

        #expect(result?.map(\.text) == ["b", "a", "c"])
    }

    @Test("최대 개수를 넘으면 가장 오래된 항목을 버림")
    func test최대개수초과시_가장오래된항목제거() {
        let items = (0..<ClipboardHistoryPolicy.maxItemCount).map { item("\($0)") }

        let result = ClipboardHistoryPolicy.inserting("new", into: items, now: now)

        #expect(result?.count == ClipboardHistoryPolicy.maxItemCount)
        #expect(result?.first?.text == "new")
        #expect(result?.last?.text == "\(ClipboardHistoryPolicy.maxItemCount - 2)")
    }

    private func item(_ text: String) -> ClipboardHistoryItem {
        ClipboardHistoryItem(text: text, createdAt: Date(timeIntervalSince1970: 0))
    }
}
```

- [x] **Step 2: 실패 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPolicyTests`
Expected: 컴파일 실패 `cannot find 'ClipboardHistoryPolicy' in scope`

- [x] **Step 3: 정책 파일 작성**

`Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardHistoryPolicy.swift`:

```swift
//
//  ClipboardHistoryPolicy.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/8/26.
//

import Foundation

/// 클립보드 기록 한 항목
struct ClipboardHistoryItem: Codable, Equatable {
    let text: String
    let createdAt: Date

    init(text: String, createdAt: Date) {
        self.text = text
        self.createdAt = createdAt
    }
}

/// 클립보드 기록의 저장 규칙(중복 제거·개수·길이 제한)
enum ClipboardHistoryPolicy {
    /// 보관하는 최대 항목 수
    static let maxItemCount = 20
    /// 항목 하나의 최대 문자 수. 초과하면 잘라 저장하지 않고 버린다.
    /// 잘라서 저장하면 붙여넣기 결과가 원본과 달라진다
    static let maxTextLength = 2_000

    /// `text`를 기록 맨 앞에 넣은 결과. 저장하지 않을 텍스트면 `nil`
    ///
    /// - 빈 문자열, 공백·개행만 있는 문자열, `maxTextLength` 초과는 `nil`
    /// - 같은 텍스트가 있으면 제거한 뒤 맨 앞에 넣는다
    /// - `maxItemCount`를 넘는 항목은 뒤에서 버린다
    static func inserting(
        _ text: String,
        into items: [ClipboardHistoryItem],
        now: Date
    ) -> [ClipboardHistoryItem]? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              text.count <= maxTextLength else { return nil }

        var result = items.filter { $0.text != text }
        result.insert(ClipboardHistoryItem(text: text, createdAt: now), at: 0)
        return Array(result.prefix(maxItemCount))
    }
}
```

- [x] **Step 4: pbxproj 두 예외 목록에 등록**

`CursorDragAccelerationPolicy.swift` 줄 바로 앞에 같은 들여쓰기로 삽입한다. 두 목록 모두에 있어야 하므로 `/g`로 두 번 치환된다:

```sh
perl -0pi -e 's#(\t+)(SYKeyboardCore/Presentation/Utils/Policies/CursorDragAccelerationPolicy\.swift,\n)#$1SYKeyboardCore/Presentation/Utils/Policies/ClipboardHistoryPolicy.swift,\n$1$2#g' SYKeyboard.xcodeproj/project.pbxproj
grep -c "Policies/ClipboardHistoryPolicy.swift" SYKeyboard.xcodeproj/project.pbxproj
```

Expected: `2`

- [x] **Step 5: 통과 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPolicyTests`
Expected: 5개 PASS

- [x] **Step 6: 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/ClipboardHistoryPolicy.swift \
        SYKeyboardTests/Utils/ClipboardHistoryPolicyTests.swift \
        SYKeyboard.xcodeproj/project.pbxproj \
        docs/superpowers/plans/2026-09-08-clipboard-history.md
git commit -m "feat: #54 - 클립보드 기록 항목 모델과 저장 정책 추가"
```

---

### Task 3: App Group plist 저장소

**Files:**
- Create: `Modules/SYKeyboardCore/Storage/ClipboardHistoryStore.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Test: `SYKeyboardTests/Storage/ClipboardHistoryStoreTests.swift`

**Interfaces:**
- Consumes: `ClipboardHistoryPolicy.inserting(_:into:now:)`, `ClipboardHistoryItem`, `DefaultValues.groupBundleID`
- Produces: `final class ClipboardHistoryStore { init(fileURL: URL); convenience init?(); func load() -> [ClipboardHistoryItem]; func record(_ text: String, now: Date = Date()); func remove(at indices: [Int]); func removeAll() }`

- [x] **Step 1: 저장소 테스트 작성**

`SYKeyboardTests/Storage/ClipboardHistoryStoreTests.swift`:

```swift
//
//  ClipboardHistoryStoreTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/8/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("클립보드 기록 저장소 검증")
struct ClipboardHistoryStoreTests {

    @Test("기록 후 다시 읽으면 같은 텍스트가 최신순으로 반환")
    func test기록후_다시읽으면_최신순반환() {
        let fixture = makeFixture(name: "roundtrip")

        fixture.store.record("first", now: Date(timeIntervalSince1970: 1))
        fixture.store.record("second", now: Date(timeIntervalSince1970: 2))

        #expect(fixture.store.load().map(\.text) == ["second", "first"])
        #expect(fixture.store.load().first?.createdAt == Date(timeIntervalSince1970: 2))
    }

    @Test("정책상 저장하지 않는 텍스트는 파일을 만들지 않음")
    func test저장대상이아니면_파일을만들지않음() {
        let fixture = makeFixture(name: "skip")

        fixture.store.record("   ")

        #expect(FileManager.default.fileExists(atPath: fixture.url.path) == false)
        #expect(fixture.store.load().isEmpty)
    }

    @Test("인덱스 삭제는 해당 항목만 제거하고 범위 밖 인덱스는 무시")
    func test인덱스삭제는_해당항목만제거() {
        let fixture = makeFixture(name: "remove")
        fixture.store.record("a", now: Date(timeIntervalSince1970: 1))
        fixture.store.record("b", now: Date(timeIntervalSince1970: 2))
        fixture.store.record("c", now: Date(timeIntervalSince1970: 3))

        fixture.store.remove(at: [1, 99])

        #expect(fixture.store.load().map(\.text) == ["c", "a"])
    }

    @Test("전체 삭제 후에는 빈 배열")
    func test전체삭제후_빈배열() {
        let fixture = makeFixture(name: "remove-all")
        fixture.store.record("a")

        fixture.store.removeAll()

        #expect(fixture.store.load().isEmpty)
    }

    @Test("손상된 파일이면 빈 배열을 반환하고 crash하지 않음")
    func test손상된파일이면_빈배열() throws {
        let fixture = makeFixture(name: "corrupt")
        try Data("not a plist".utf8).write(to: fixture.url)

        #expect(fixture.store.load().isEmpty)
    }
}

private struct StoreFixture {
    let store: ClipboardHistoryStore
    let url: URL
}

private func makeFixture(name: String) -> StoreFixture {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-\(name).plist")
    return StoreFixture(store: ClipboardHistoryStore(fileURL: url), url: url)
}
```

- [x] **Step 2: 실패 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryStoreTests`
Expected: 컴파일 실패 `cannot find 'ClipboardHistoryStore' in scope`

- [x] **Step 3: 저장소 작성**

`Modules/SYKeyboardCore/Storage/ClipboardHistoryStore.swift`:

```swift
//
//  ClipboardHistoryStore.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/8/26.
//

import Foundation
import OSLog

/// 클립보드 텍스트 기록을 App Group 컨테이너의 plist 파일에 저장하는 저장소
///
/// 메모리 캐시 없이 매 연산마다 파일을 읽고 쓴다. 세 keyboard extension이 같은 파일을
/// 공유하므로 캐시가 있으면 다른 extension이 바꾼 내용을 놓친다. 최대 20개 × 2,000자라
/// 메인 스레드 동기 처리로 충분하다.
// ponytail: 매 연산 파일 I/O. 항목 수·길이 한도를 올리면 캐시 + 백그라운드 저장으로 전환
final class ClipboardHistoryStore {

    // MARK: - Properties

    private let fileURL: URL
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "ClipboardHistoryStore"
    )

    // MARK: - Initializer

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// App Group 컨테이너를 얻지 못하면 `nil`. 호출 측은 기능을 비활성 상태로 둔다
    convenience init?() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: DefaultValues.groupBundleID
        ) else { return nil }
        self.init(fileURL: containerURL.appendingPathComponent("clipboard_history.plist"))
    }

    // MARK: - Internal Methods

    /// 저장된 기록(최신순). 파일이 없거나 손상됐으면 빈 배열
    func load() -> [ClipboardHistoryItem] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? PropertyListDecoder().decode([ClipboardHistoryItem].self, from: data)) ?? []
    }

    /// `text`를 기록 맨 앞에 저장한다. 정책상 저장 대상이 아니면 아무것도 하지 않는다
    func record(_ text: String, now: Date = Date()) {
        guard let items = ClipboardHistoryPolicy.inserting(text, into: load(), now: now) else { return }
        save(items)
    }

    /// 지정한 인덱스의 항목을 삭제한다. 범위 밖 인덱스는 무시한다
    func remove(at indices: [Int]) {
        let removing = Set(indices)
        let remaining = load().enumerated()
            .filter { !removing.contains($0.offset) }
            .map(\.element)
        save(remaining)
    }

    func removeAll() {
        save([])
    }
}

// MARK: - Private Methods

private extension ClipboardHistoryStore {
    func save(_ items: [ClipboardHistoryItem]) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        do {
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // 쓰기 실패는 무시하고 다음 기회에 다시 쓴다. changeCount는 이미 갱신됐으므로 같은 텍스트를 재시도하지 않는다
            logger.error("클립보드 기록 저장 실패: \(error.localizedDescription)")
        }
    }
}
```

- [x] **Step 4: pbxproj 등록**

```sh
perl -0pi -e 's#(\t+)(SYKeyboardCore/Storage/DefaultValues\.swift,\n)#$1SYKeyboardCore/Storage/ClipboardHistoryStore.swift,\n$1$2#g' SYKeyboard.xcodeproj/project.pbxproj
grep -c "Storage/ClipboardHistoryStore.swift" SYKeyboard.xcodeproj/project.pbxproj
```

Expected: `2`

- [x] **Step 5: 통과 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryStoreTests`
Expected: 5개 PASS

- [x] **Step 6: 커밋**

```sh
git add Modules/SYKeyboardCore/Storage/ClipboardHistoryStore.swift \
        SYKeyboardTests/Storage/ClipboardHistoryStoreTests.swift \
        SYKeyboard.xcodeproj/project.pbxproj \
        docs/superpowers/plans/2026-09-08-clipboard-history.md
git commit -m "feat: #54 - App Group plist 기반 클립보드 기록 저장소 추가"
```

---

### Task 4: 클립보드 버튼 표시 정책

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardPresentationStatePolicy.swift`
- Test: `SYKeyboardTests/Utils/KeyboardPresentationStatePolicyTests.swift`

**Interfaces:**
- Produces: `KeyboardPresentationStatePolicy.shouldShowClipboardControl(isSuggestionBarHidden: Bool, isClipboardHistoryEnabled: Bool) -> Bool`

- [x] **Step 1: 테스트 추가**

`KeyboardPresentationStatePolicyTests.swift`의 `testUndoRedo기능활성화조건` 뒤에:

```swift
    @Test("클립보드 버튼은 suggestion bar가 보이고 클립보드 기록 설정이 켜진 경우에만 표시")
    func test클립보드버튼표시조건() {
        #expect(
            KeyboardPresentationStatePolicy.shouldShowClipboardControl(
                isSuggestionBarHidden: false,
                isClipboardHistoryEnabled: true
            ) == true
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldShowClipboardControl(
                isSuggestionBarHidden: true,
                isClipboardHistoryEnabled: true
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldShowClipboardControl(
                isSuggestionBarHidden: false,
                isClipboardHistoryEnabled: false
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldShowClipboardControl(
                isSuggestionBarHidden: true,
                isClipboardHistoryEnabled: false
            ) == false
        )
    }
```

- [x] **Step 2: 실패 확인**

Run: `-only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests`
Expected: 컴파일 실패 `has no member 'shouldShowClipboardControl'`

- [x] **Step 3: 정책 추가**

`KeyboardPresentationStatePolicy.swift`의 `isUndoRedoFeatureAvailable` 함수 뒤(enum 닫는 `}` 앞)에:

```swift
    /// suggestion bar가 보일 때는 자동완성이 켜져 있으므로 클립보드 설정만 추가로 본다
    static func shouldShowClipboardControl(
        isSuggestionBarHidden: Bool,
        isClipboardHistoryEnabled: Bool
    ) -> Bool {
        return !isSuggestionBarHidden && isClipboardHistoryEnabled
    }
```

- [x] **Step 4: 통과 확인**

Run: 같은 명령
Expected: suite 전체 PASS

- [x] **Step 5: 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardPresentationStatePolicy.swift \
        SYKeyboardTests/Utils/KeyboardPresentationStatePolicyTests.swift \
        docs/superpowers/plans/2026-09-08-clipboard-history.md
git commit -m "feat: #54 - 자동완성 바 클립보드 버튼 표시 정책 추가"
```

---

### Task 5: suggestion bar 클립보드 버튼

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift`
- Test: `SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift`

**Interfaces:**
- Produces:
  - `SuggestionBarDelegate.suggestionBarDidTapClipboard(_ bar: SuggestionBarView)`
  - `SuggestionBarView.updateClipboardControl(isVisible: Bool, isPanelVisible: Bool)`

- [x] **Step 1: 테스트 추가**

`SuggestionBarViewPreviewHighlightTests.swift`의 spy를 다음으로 교체:

```swift
@MainActor
private final class SuggestionBarRollbackDelegateSpy: SuggestionBarDelegate {
    private(set) var selectedIndexes: [Int] = []
    private(set) var clipboardTapCount = 0

    func suggestionBar(
        _ bar: SuggestionBarView,
        didSelectSuggestionAt index: Int
    ) {
        selectedIndexes.append(index)
    }

    func suggestionBarDidTapUndo(_ bar: SuggestionBarView) {}
    func suggestionBarDidTapRedo(_ bar: SuggestionBarView) {}
    func suggestionBarDidTapClipboard(_ bar: SuggestionBarView) {
        clipboardTapCount += 1
    }
}
```

struct 안 `test긴후보에서시작한드래그도_종료위치후보를선택` 뒤에 두 테스트 추가:

```swift
    @Test("클립보드 버튼 탭은 delegate에 전달되고 후보 하이라이트를 만들지 않음")
    func test클립보드버튼탭은_delegate전달_후보하이라이트없음() {
        let keyboardHStackView = UIStackView()
        let bar = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        let delegate = SuggestionBarRollbackDelegateSpy()
        bar.suggestionDelegate = delegate
        bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        bar.updateSuggestions(currentWord: nil, suggestions: ["가", "나", "다"])
        bar.updateClipboardControl(isVisible: true, isPanelVisible: false)
        bar.layoutIfNeeded()

        let buttons = typedSuggestionButtonViews(in: bar)
        // 클립보드 버튼은 bar 왼쪽 끝 44pt 영역을 차지한다
        let point = CGPoint(x: KeyboardLayoutFigure.undoRedoButtonWidth / 2, y: 24)

        bar.beginTouchInteraction(at: point)

        #expect(buttons.allSatisfy { !$0.isHighlighted })

        bar.endTouchInteraction(at: point, playsFeedback: false)

        #expect(delegate.clipboardTapCount == 1)
        #expect(delegate.selectedIndexes.isEmpty)
        #expect(keyboardHStackView.isUserInteractionEnabled)
    }

    @Test("클립보드 버튼이 숨겨져 있으면 같은 위치 탭은 첫 후보를 선택")
    func test클립보드버튼숨김시_같은위치탭은_첫후보선택() {
        let bar = SuggestionBarView(keyboardHStackView: UIStackView())
        let delegate = SuggestionBarRollbackDelegateSpy()
        bar.suggestionDelegate = delegate
        bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        bar.updateSuggestions(currentWord: nil, suggestions: ["가", "나", "다"])
        bar.updateClipboardControl(isVisible: false, isPanelVisible: false)
        bar.layoutIfNeeded()

        let point = CGPoint(x: KeyboardLayoutFigure.undoRedoButtonWidth / 2, y: 24)
        bar.beginTouchInteraction(at: point)
        bar.endTouchInteraction(at: point, playsFeedback: false)

        #expect(delegate.clipboardTapCount == 0)
        #expect(delegate.selectedIndexes == [0])
    }
```

- [x] **Step 2: 실패 확인**

Run: `-only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests`
Expected: 컴파일 실패 `has no member 'updateClipboardControl'`

- [x] **Step 3: SuggestionBarView 수정**

(a) 델리게이트 프로토콜에 메서드 추가 (`suggestionBarDidTapRedo` 뒤):

```swift
    /// 클립보드 버튼이 탭되었을 때 호출됩니다.
    func suggestionBarDidTapClipboard(_ bar: SuggestionBarView)
```

(b) `// MARK: - Properties` 블록에서 `undoRedoButtons` computed property를 다음으로 교체하고 심볼 이름 상수를 추가:

```swift
    private var clipboardViews: [UIView] {
        return [clipboardButton, clipboardDivider]
    }

    /// 히트테스트·하이라이트 대상 accessory 버튼. 인덱스가 `SuggestionHighlightPolicy`의 action 인덱스다
    private var actionButtons: [SuggestionActionButtonView] {
        return [clipboardButton, undoButton, redoButton]
    }

    private static let clipboardClosedSymbolName = "doc.on.clipboard"
    private static let clipboardOpenSymbolName = "keyboard"
```

(c) `// MARK: - UI Components`의 `buttonContainerHStackView` 선언 뒤, `suggestionButton1` 앞에 추가:

```swift
    private lazy var clipboardButton: SuggestionActionButtonView = {
        let button = makeActionButton(systemName: SuggestionBarView.clipboardClosedSymbolName)

        return button
    }()

    private let clipboardDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        view.isHidden = true

        return view
    }()
```

(d) `undoButton`/`redoButton`의 `makeUndoRedoButton(systemName:)` 호출을 `makeActionButton(systemName:)`으로 바꾸고, private extension의 `makeUndoRedoButton` 함수 이름도 `makeActionButton`으로 바꾼다.

(e) `endTouchInteraction(at:playsFeedback:)`의 `else if let action = undoRedoButton(at: point)` 분기를 다음으로 교체:

```swift
        } else if let action = actionButton(at: point) {
            switch action {
            case clipboardButton:
                suggestionDelegate?.suggestionBarDidTapClipboard(self)
            case undoButton:
                suggestionDelegate?.suggestionBarDidTapUndo(self)
            case redoButton:
                suggestionDelegate?.suggestionBarDidTapRedo(self)
            default:
                break
            }
            playSelectionFeedbackIfNeeded(playsFeedback)
        }
```

(f) `updateUndoRedoControls(isVisible:canUndo:canRedo:)` 뒤에 추가:

```swift
    /// 자동완성 바 좌측의 클립보드 버튼 표시와 아이콘을 갱신합니다.
    ///
    /// 패널이 열려 있으면 키보드 아이콘으로 바꿔 다시 탭하면 자판으로 돌아감을 알립니다.
    func updateClipboardControl(isVisible: Bool, isPanelVisible: Bool) {
        clipboardViews.forEach { $0.isHidden = !isVisible }
        clipboardButton.isEnabled = isVisible
        clipboardButton.updateImage(
            systemName: isPanelVisible
            ? SuggestionBarView.clipboardOpenSymbolName
            : SuggestionBarView.clipboardClosedSymbolName
        )
        updateDividers()
    }
```

(g) `setHierarchy()`의 배열 맨 앞에 `clipboardButton, clipboardDivider`를 넣는다:

```swift
        [clipboardButton,
         clipboardDivider,
         suggestionButton1,
         leftDivider,
         ...
```

(h) `setConstraints()`에서 divider 배열을 `[clipboardDivider, leftDivider, rightDivider, undoRedoLeadingDivider, undoRedoMiddleDivider]`로, 고정폭 버튼 배열을 `[clipboardButton, undoButton, redoButton]`으로 바꾼다.

(i) private extension의 `undoRedoButton(at:)`을 다음으로 교체:

```swift
    func actionButton(at point: CGPoint) -> SuggestionActionButtonView? {
        for button in actionButtons {
            guard !button.isHidden, button.isEnabled else { continue }
            let buttonFrame = button.convert(button.bounds, to: self)
            if buttonFrame.contains(point) {
                return button
            }
        }
        return nil
    }
```

(j) `updateHighlight(at:)`에서 `undoRedoButton(at:)` → `actionButton(at:)`, `undoRedoButtons.firstIndex` → `actionButtons.firstIndex`. `applyHighlights()`에서 `actionCount: undoRedoButtons.count` → `actionCount: actionButtons.count`, `for (index, button) in undoRedoButtons.enumerated()` → `actionButtons.enumerated()`.

(k) `updateDividers()` 맨 앞(`leftDivider` 대입 앞)에 추가:

```swift
        clipboardDivider.backgroundColor = (clipboardButton.isHighlighted || btn1Highlighted)
        ? .clear
        : .suggestionDividerColor
```

(l) `SuggestionActionButtonView`의 `init(systemName:)` 뒤에 추가:

```swift
    func updateImage(systemName: String) {
        imageView.image = UIImage(systemName: systemName)
    }
```

- [x] **Step 4: 통과 확인**

Run: `-only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests`
Expected: 4개 PASS. 이어서 `-only-testing:SYKeyboardTests/SuggestionHighlightPolicyTests`도 PASS(정책 변경 없음 확인).

- [x] **Step 5: 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift \
        SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift \
        docs/superpowers/plans/2026-09-08-clipboard-history.md
git commit -m "feat: #54 - 자동완성 바 왼쪽에 클립보드 버튼 추가"
```

---

### Task 6: 기록 패널 뷰와 Core String Catalog

**Files:**
- Create: `Modules/SYKeyboardCore/Resources/Localizable.xcstrings`
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Extensions/Bundle+Extension.swift`
- Create: `Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Test: `SYKeyboardTests/Presentation/ClipboardHistoryPanelViewTests.swift`

**Interfaces:**
- Consumes: `ClipboardHistoryItem`, `FeedbackManager.shared.playHaptic()`, `UIColor.suggestionButtonPressed`
- Produces:
  - `protocol ClipboardHistoryPanelDelegate: AnyObject { func clipboardPanel(_:didSelectItemAt: Int); func clipboardPanel(_:didDeleteItemsAt: [Int]); func clipboardPanelDidDeleteAll(_:) }`
  - `final class ClipboardHistoryPanelView: UIView { enum State { case fullAccessRequired, empty, items([ClipboardHistoryItem]) }; weak var delegate; private(set) var items; let tableView: UITableView; func configure(state:); func resetPresentation(); func beginItemEditing(); func endItemEditing(); func toggleSelectAll(); func deleteSelectedItems() }`
  - `Bundle.sykeyboardCore: Bundle`

- [x] **Step 1: 패널 테스트 작성**

`SYKeyboardTests/Presentation/ClipboardHistoryPanelViewTests.swift`:

```swift
//
//  ClipboardHistoryPanelViewTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/8/26.
//

import UIKit
import Testing

@testable import SYKeyboardCore

@Suite("클립보드 기록 패널 편집 동작 검증")
@MainActor
struct ClipboardHistoryPanelViewTests {

    @Test("행 탭은 해당 인덱스의 붙여넣기를 요청")
    func test행탭은_인덱스전달() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])

        panel.tableView(panel.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))

        #expect(spy.selectedIndices == [1])
    }

    @Test("편집 모드에서 행 탭은 선택만 하고 붙여넣기를 요청하지 않음")
    func test편집모드행탭은_붙여넣기요청없음() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])

        panel.beginItemEditing()
        panel.tableView(panel.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))

        #expect(panel.tableView.isEditing)
        #expect(spy.selectedIndices.isEmpty)
    }

    @Test("편집 모드에서 전체 선택 후 삭제하면 전체 삭제를 요청")
    func test전체선택후삭제는_전체삭제요청() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])

        panel.beginItemEditing()
        panel.toggleSelectAll()
        panel.deleteSelectedItems()

        #expect(spy.deleteAllCount == 1)
        #expect(spy.deletedIndices.isEmpty)
    }

    @Test("편집 모드에서 일부 선택 후 삭제하면 선택 인덱스만 오름차순으로 요청")
    func test일부선택후삭제는_선택인덱스만요청() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])

        panel.beginItemEditing()
        panel.tableView.selectRow(at: IndexPath(row: 2, section: 0), animated: false, scrollPosition: .none)
        panel.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        panel.deleteSelectedItems()

        #expect(spy.deletedIndices == [[0, 2]])
        #expect(spy.deleteAllCount == 0)
    }

    @Test("선택이 없으면 삭제를 요청하지 않음")
    func test선택없으면_삭제요청없음() {
        let (panel, spy) = makePanel(texts: ["a"])

        panel.beginItemEditing()
        panel.deleteSelectedItems()

        #expect(spy.deletedIndices.isEmpty)
        #expect(spy.deleteAllCount == 0)
    }

    @Test("항목이 없으면 편집 모드로 들어가지 않음")
    func test항목없으면_편집모드진입없음() {
        let (panel, _) = makePanel(texts: [])
        panel.configure(state: .empty)

        panel.beginItemEditing()

        #expect(panel.tableView.isEditing == false)
    }

    @Test("resetPresentation은 편집 모드를 해제")
    func testResetPresentation은_편집모드해제() {
        let (panel, _) = makePanel(texts: ["a"])
        panel.beginItemEditing()

        panel.resetPresentation()

        #expect(panel.tableView.isEditing == false)
    }
}

@MainActor
private func makePanel(texts: [String]) -> (ClipboardHistoryPanelView, ClipboardHistoryPanelDelegateSpy) {
    let panel = ClipboardHistoryPanelView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
    let spy = ClipboardHistoryPanelDelegateSpy()
    panel.delegate = spy
    let items = texts.map { ClipboardHistoryItem(text: $0, createdAt: Date()) }
    panel.configure(state: items.isEmpty ? .empty : .items(items))
    panel.layoutIfNeeded()
    return (panel, spy)
}

@MainActor
private final class ClipboardHistoryPanelDelegateSpy: ClipboardHistoryPanelDelegate {
    private(set) var selectedIndices: [Int] = []
    private(set) var deletedIndices: [[Int]] = []
    private(set) var deleteAllCount = 0

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didSelectItemAt index: Int) {
        selectedIndices.append(index)
    }

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didDeleteItemsAt indices: [Int]) {
        deletedIndices.append(indices)
    }

    func clipboardPanelDidDeleteAll(_ panel: ClipboardHistoryPanelView) {
        deleteAllCount += 1
    }
}
```

- [x] **Step 2: 실패 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPanelViewTests`
Expected: 컴파일 실패 `cannot find 'ClipboardHistoryPanelView' in scope`

- [x] **Step 3: Core String Catalog 생성**

```sh
python3 - <<'PY'
import json, pathlib
strings = {
    "클립보드 기록": "Clipboard History",
    "편집": "Edit",
    "완료": "Done",
    "전체 선택": "Select All",
    "선택 해제": "Deselect All",
    "삭제": "Delete",
    "붙여넣기": "Paste",
    "닫기": "Close",
    "원문": "Full Text",
    "복사한 텍스트가 여기에 표시됩니다": "Copied text will appear here",
    "전체 접근 허용이 필요합니다": "Requires Allow Full Access",
}
catalog = {
    "sourceLanguage": "ko",
    "strings": {
        ko: {"localizations": {"en": {"stringUnit": {"state": "translated", "value": en}}}}
        for ko, en in strings.items()
    },
    "version": "1.0",
}
path = pathlib.Path("Modules/SYKeyboardCore/Resources/Localizable.xcstrings")
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2, separators=(",", " : "), sort_keys=True) + "\n")
PY
```

- [x] **Step 4: Bundle 헬퍼 추가**

`Bundle+Extension.swift`의 `primaryLanguage` 프로퍼티 뒤(extension 닫는 `}` 앞)에:

```swift
    /// SYKeyboardCore framework 번들. Core의 String Catalog를 읽을 때 사용한다
    static let sykeyboardCore = Bundle(for: KeyboardView.self)
```

- [x] **Step 5: 패널 뷰 작성**

`Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift`:

```swift
//
//  ClipboardHistoryPanelView.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/8/26.
//

import UIKit

import SYKeyboardAssets

/// `ClipboardHistoryPanelView`의 사용자 상호작용을 수신하는 델리게이트
protocol ClipboardHistoryPanelDelegate: AnyObject {
    /// 항목을 탭하거나 상세 뷰에서 붙여넣기를 눌렀을 때 호출됩니다.
    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didSelectItemAt index: Int)
    /// 스와이프 삭제 또는 편집 모드에서 일부 항목을 삭제했을 때 호출됩니다. 인덱스는 오름차순입니다.
    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didDeleteItemsAt indices: [Int])
    /// 편집 모드에서 전체 선택 후 삭제했을 때 호출됩니다.
    func clipboardPanelDidDeleteAll(_ panel: ClipboardHistoryPanelView)
}

/// 클립보드 기록 목록을 자판 영역에 표시하는 패널
///
/// 저장소를 모르는 표시 전용 뷰다. 상태는 `configure(state:)`로 받고 결정은 델리게이트가 한다.
///
/// ## 동작
/// - 평소: 행 탭은 붙여넣기, trailing swipe는 개별 삭제, 길게 누르기는 원문 상세 뷰
/// - 편집 모드(`UITableView.isEditing`): 행 탭은 선택 토글, "전체 선택"·"삭제 (n)"·"완료"
final class ClipboardHistoryPanelView: UIView {

    enum State: Equatable {
        case fullAccessRequired
        case empty
        case items([ClipboardHistoryItem])
    }

    // MARK: - Properties

    weak var delegate: ClipboardHistoryPanelDelegate?

    /// 현재 표시 중인 항목(최신순). 델리게이트 인덱스는 이 배열 기준이다
    private(set) var items: [ClipboardHistoryItem] = []

    private var detailIndex: Int?

    private static let cellIdentifier = "ClipboardHistoryCell"
    private static let headerHeight: CGFloat = 36

    // MARK: - UI Components

    private let headerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 4
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 4)
        stackView.isLayoutMarginsRelativeArrangement = true

        return stackView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "클립보드 기록", bundle: .sykeyboardCore)
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label

        return label
    }()

    private lazy var selectAllButton = makeHeaderButton(title: "") { [weak self] in
        self?.toggleSelectAll()
    }

    private lazy var deleteButton: UIButton = {
        let button = makeHeaderButton(title: "") { [weak self] in
            self?.deleteSelectedItems()
        }
        button.configuration?.baseForegroundColor = .systemRed

        return button
    }()

    private lazy var editButton = makeHeaderButton(
        title: String(localized: "편집", bundle: .sykeyboardCore)
    ) { [weak self] in
        self?.beginItemEditing()
    }

    private lazy var doneButton = makeHeaderButton(
        title: String(localized: "완료", bundle: .sykeyboardCore)
    ) { [weak self] in
        self?.endItemEditing()
    }

    /// 테스트에서 `UITableViewDelegate` 메서드를 직접 호출할 수 있도록 internal로 둔다
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ClipboardHistoryPanelView.cellIdentifier)

        return tableView
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true

        return label
    }()

    private lazy var detailView: ClipboardHistoryDetailView = {
        let view = ClipboardHistoryDetailView()
        view.isHidden = true
        view.onClose = { [weak self] in self?.hideDetail() }
        view.onPaste = { [weak self] in
            guard let self, let index = self.detailIndex else { return }
            self.hideDetail()
            self.delegate?.clipboardPanel(self, didSelectItemAt: index)
        }

        return view
    }()

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal Methods

    /// 패널 상태를 갱신합니다. 편집 모드는 유지하되 항목이 없어지면 해제합니다.
    func configure(state: State) {
        switch state {
        case .fullAccessRequired:
            items = []
            messageLabel.text = String(localized: "전체 접근 허용이 필요합니다", bundle: .sykeyboardCore)
        case .empty:
            items = []
            messageLabel.text = String(localized: "복사한 텍스트가 여기에 표시됩니다", bundle: .sykeyboardCore)
        case .items(let newItems):
            items = newItems
        }
        messageLabel.isHidden = !items.isEmpty
        tableView.isHidden = items.isEmpty
        if items.isEmpty { endItemEditing() }
        tableView.reloadData()
        updateHeader()
    }

    /// 편집 모드와 상세 뷰를 닫고 스크롤을 맨 위로 되돌립니다. 패널을 닫을 때 호출합니다.
    func resetPresentation() {
        hideDetail()
        endItemEditing()
        tableView.setContentOffset(.zero, animated: false)
    }

    // 헤더 버튼 동작. 테스트에서 직접 호출할 수 있도록 internal로 둔다

    func beginItemEditing() {
        guard !items.isEmpty, !tableView.isEditing else { return }
        tableView.setEditing(true, animated: true)
        updateHeader()
    }

    func endItemEditing() {
        guard tableView.isEditing else { return }
        tableView.setEditing(false, animated: true)
        updateHeader()
    }

    func toggleSelectAll() {
        guard tableView.isEditing else { return }
        if isAllSelected {
            tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: false) }
        } else {
            (0..<items.count).forEach {
                tableView.selectRow(at: IndexPath(row: $0, section: 0), animated: false, scrollPosition: .none)
            }
        }
        updateHeader()
    }

    func deleteSelectedItems() {
        guard tableView.isEditing else { return }
        let indices = (tableView.indexPathsForSelectedRows ?? []).map(\.row).sorted()
        guard !indices.isEmpty else { return }

        if indices.count == items.count {
            delegate?.clipboardPanelDidDeleteAll(self)
        } else {
            delegate?.clipboardPanel(self, didDeleteItemsAt: indices)
        }
    }
}

// MARK: - UI Methods

private extension ClipboardHistoryPanelView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        )
        updateHeader()
    }

    func setStyles() {
        self.backgroundColor = .clear
    }

    func setHierarchy() {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        [titleLabel, selectAllButton, spacer, deleteButton, editButton, doneButton].forEach {
            headerStackView.addArrangedSubview($0)
        }
        [headerStackView, tableView, messageLabel, detailView].forEach { self.addSubview($0) }
    }

    func setConstraints() {
        [headerStackView, tableView, messageLabel, detailView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: self.topAnchor),
            headerStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            headerStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            headerStackView.heightAnchor.constraint(equalToConstant: ClipboardHistoryPanelView.headerHeight),

            tableView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            messageLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -16),

            detailView.topAnchor.constraint(equalTo: self.topAnchor),
            detailView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            detailView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            detailView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}

// MARK: - Private Methods

private extension ClipboardHistoryPanelView {
    var isAllSelected: Bool {
        !items.isEmpty && (tableView.indexPathsForSelectedRows?.count ?? 0) == items.count
    }

    func updateHeader() {
        let isEditing = tableView.isEditing
        titleLabel.isHidden = isEditing
        editButton.isHidden = isEditing || items.isEmpty
        selectAllButton.isHidden = !isEditing
        deleteButton.isHidden = !isEditing
        doneButton.isHidden = !isEditing

        let selectedCount = tableView.indexPathsForSelectedRows?.count ?? 0
        selectAllButton.configuration?.title = isAllSelected
        ? String(localized: "선택 해제", bundle: .sykeyboardCore)
        : String(localized: "전체 선택", bundle: .sykeyboardCore)
        deleteButton.configuration?.title = String(localized: "삭제", bundle: .sykeyboardCore) + " (\(selectedCount))"
        deleteButton.isEnabled = selectedCount > 0
    }

    func makeHeaderButton(title: String, handler: @escaping () -> Void) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in handler() })
        button.setContentCompressionResistancePriority(.required, for: .horizontal)

        return button
    }

    func showDetail(at index: Int) {
        guard items.indices.contains(index) else { return }
        detailIndex = index
        detailView.update(text: items[index].text)
        detailView.isHidden = false
    }

    func hideDetail() {
        detailIndex = nil
        detailView.isHidden = true
    }

    @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began, !tableView.isEditing else { return }
        let point = recognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        FeedbackManager.shared.playHaptic()
        showDetail(at: indexPath.row)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ClipboardHistoryPanelView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ClipboardHistoryPanelView.cellIdentifier, for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = items[indexPath.row].text
        content.textProperties.font = .systemFont(ofSize: 15)
        content.textProperties.numberOfLines = 2
        content.textProperties.lineBreakMode = .byTruncatingTail
        cell.contentConfiguration = content
        cell.backgroundColor = .clear
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .suggestionButtonPressed
        cell.selectedBackgroundView = selectedBackgroundView

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateHeader()
            return
        }
        tableView.deselectRow(at: indexPath, animated: false)
        FeedbackManager.shared.playHaptic()
        delegate?.clipboardPanel(self, didSelectItemAt: indexPath.row)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing { updateHeader() }
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: String(localized: "삭제", bundle: .sykeyboardCore)
        ) { [weak self] _, _, completion in
            guard let self else { completion(false); return }
            self.delegate?.clipboardPanel(self, didDeleteItemsAt: [indexPath.row])
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - Supporting Views

/// 길게 누른 항목의 원문 전체를 스크롤로 보여주는 상세 뷰
private final class ClipboardHistoryDetailView: UIView {

    // MARK: - Properties

    var onClose: (() -> Void)?
    var onPaste: (() -> Void)?

    // MARK: - UI Components

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))

    private let headerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 4)
        stackView.isLayoutMarginsRelativeArrangement = true

        return stackView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "원문", bundle: .sykeyboardCore)
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label

        return label
    }()

    private lazy var closeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = String(localized: "닫기", bundle: .sykeyboardCore)
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)

        return UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in self?.onClose?() })
    }()

    private let textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = .label
        textView.textContainerInset = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        return textView
    }()

    private lazy var pasteButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "붙여넣기", bundle: .sykeyboardCore)
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20)

        return UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in self?.onPaste?() })
    }()

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal Methods

    func update(text: String) {
        textView.text = text
        textView.setContentOffset(.zero, animated: false)
    }
}

// MARK: - UI Methods

private extension ClipboardHistoryDetailView {
    func setupUI() {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        [titleLabel, spacer, closeButton].forEach { headerStackView.addArrangedSubview($0) }
        [blurView, headerStackView, textView, pasteButton].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: self.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            headerStackView.topAnchor.constraint(equalTo: self.topAnchor),
            headerStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            headerStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            headerStackView.heightAnchor.constraint(equalToConstant: 36),

            textView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4),
            textView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4),
            textView.bottomAnchor.constraint(equalTo: pasteButton.topAnchor, constant: -4),

            pasteButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            pasteButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8)
        ])
    }
}
```

- [x] **Step 6: pbxproj 등록 (3개 경로)**

```sh
perl -0pi -e 's#(\t+)(SYKeyboardCore/Presentation/View/Components/Buttons/Bases/BaseKeyboardButton\.swift,\n)#$1SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift,\n$1$2#g' SYKeyboard.xcodeproj/project.pbxproj
perl -0pi -e 's#(\t+)(SYKeyboardCore/Storage/ClipboardHistoryStore\.swift,\n)#$1SYKeyboardCore/Resources/Localizable.xcstrings,\n$1$2#g' SYKeyboard.xcodeproj/project.pbxproj
grep -c "View/ClipboardHistoryPanelView.swift" SYKeyboard.xcodeproj/project.pbxproj
grep -c "SYKeyboardCore/Resources/Localizable.xcstrings" SYKeyboard.xcodeproj/project.pbxproj
```

Expected: 각각 `2`

- [x] **Step 7: 통과 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPanelViewTests`
Expected: 7개 PASS

- [x] **Step 8: 커밋**

```sh
git add Modules/SYKeyboardCore/Resources/Localizable.xcstrings \
        Modules/SYKeyboardCore/Presentation/Utils/Extensions/Bundle+Extension.swift \
        Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift \
        SYKeyboardTests/Presentation/ClipboardHistoryPanelViewTests.swift \
        SYKeyboard.xcodeproj/project.pbxproj \
        docs/superpowers/plans/2026-09-08-clipboard-history.md
git commit -m "feat: #54 - 클립보드 기록 패널 뷰와 Core String Catalog 추가"
```

---

### Task 7: 키보드 연결과 pasteboard 동기화

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`

**Interfaces:**
- Consumes: `ClipboardHistoryStore`, `ClipboardHistoryPanelView`/`Delegate`, `SuggestionBarView.updateClipboardControl(isVisible:isPanelVisible:)`, `SuggestionBarDelegate.suggestionBarDidTapClipboard(_:)`, `KeyboardPresentationStatePolicy.shouldShowClipboardControl(isSuggestionBarHidden:isClipboardHistoryEnabled:)`, `UserDefaultsManager.isClipboardHistoryEnabled`/`lastSeenPasteboardChangeCount`
- Produces: `BaseKeyboardViewController.synchronizeClipboardHistoryIfNeeded()`, `toggleClipboardPanel()`, `closeClipboardPanelIfNeeded()`, `updateClipboardControl()`, `isClipboardPanelVisible: Bool`, `clipboardHistoryStore: ClipboardHistoryStore?`, `clipboardHistoryPanelView: ClipboardHistoryPanelView`

이 Task는 UIKit lifecycle과 `UIPasteboard`에 묶여 있어 단위 테스트 대신 세 extension scheme 빌드와 기존 전체 테스트로 검증한다.
`updateShowingKeyboard()`·`updateSuggestions()`·`updateReturnButtonEnabled()`·`cancelPendingDeleteInteractions()`·`updateUndoRedoControls()`는
모두 Base 파일의 `private extension`에 있으므로 클립보드 흐름도 같은 파일에 둔다. 새 파일을 만들지 않는다.

- [x] **Step 1: KeyboardView에 패널 추가**

`KeyboardView.swift`의 `tenkeyKeyboardView` 선언 뒤에:

```swift
    /// 클립보드 기록 패널. 자판 자리에 겹쳐 두고 `isHidden`으로 전환한다
    lazy var clipboardHistoryPanelView: ClipboardHistoryPanelView = {
        let panelView = ClipboardHistoryPanelView()
        panelView.isHidden = true

        return panelView
    }()
```

`setHierarchy()`와 `setConstraints()` 두 곳의 `+ [symbolKeyboardView, numericKeyboardView, tenkeyKeyboardView]`를 모두 `+ [symbolKeyboardView, numericKeyboardView, tenkeyKeyboardView, clipboardHistoryPanelView]`로 바꾼다.

- [x] **Step 2: BaseKeyboardViewController 본체 수정**

(a) `// MARK: - UI Components`의 `tenkeyKeyboardView` 선언 뒤에:

```swift
    /// 클립보드 기록 패널
    final lazy var clipboardHistoryPanelView: ClipboardHistoryPanelView = keyboardView.clipboardHistoryPanelView
    /// 클립보드 기록 저장소. App Group 컨테이너를 얻지 못하면 `nil`이고 기능은 비활성 상태다
    final let clipboardHistoryStore: ClipboardHistoryStore? = ClipboardHistoryStore()
    /// 클립보드 기록 패널 표시 여부
    final var isClipboardPanelVisible = false
```

(b) `viewWillAppear`의 `if !BaseKeyboardViewController.isPreview { setKeyboardHeight() }` 뒤에:

```swift
        synchronizeClipboardHistoryIfNeeded()
```

(c) `textWillChange`의 마지막 `updateSuggestionBarHidden()` 뒤에:

```swift
        closeClipboardPanelIfNeeded()
        synchronizeClipboardHistoryIfNeeded()
```

(d) `viewWillDisappear`의 `stopRepeatInputTracking()` 뒤에:

```swift
        closeClipboardPanelIfNeeded()
```

(e) `undoRedoEditDidApply()`의 주석을 다음으로 바꾼다:

```swift
    /// undo/redo 또는 클립보드 붙여넣기로 텍스트가 직접 변경된 후 내부 입력 상태를 동기화하기 위한 hook입니다.
    ///
    /// 한글 VC는 이 hook에서 조합 상태를 비운다. 붙여넣기 뒤에 다음 자모가 새 글자로 시작하는 근거다.
    ///
    /// > 하위 클래스에서 오버라이드 시 반드시 `super`로 호출 필요
```

(f) `setDelegates()`에 추가:

```swift
        clipboardHistoryPanelView.delegate = self
```

(g) `updateShowingKeyboard()` 끝(`tenkeyKeyboardView.isHidden = ...` 뒤)에:

```swift
        if isClipboardPanelVisible {
            primaryKeyboardViews.forEach { $0.isHidden = true }
            symbolKeyboardView.isHidden = true
            numericKeyboardView.isHidden = true
            tenkeyKeyboardView.isHidden = true
        }
        clipboardHistoryPanelView.isHidden = !isClipboardPanelVisible
```

(h) `updateUndoRedoControls()` 끝에:

```swift
        updateClipboardControl()
```

그리고 `updateUndoRedoControls()` 바로 뒤에 새 메서드:

```swift
    func updateClipboardControl() {
        let shouldShowClipboard = KeyboardPresentationStatePolicy.shouldShowClipboardControl(
            isSuggestionBarHidden: suggestionBarView.isHidden,
            isClipboardHistoryEnabled: keyboardSettingsManager.isClipboardHistoryEnabled
        )
        suggestionBarView.updateClipboardControl(
            isVisible: shouldShowClipboard,
            isPanelVisible: isClipboardPanelVisible
        )
    }
```

(i) `extension BaseKeyboardViewController: SuggestionBarDelegate`에 추가:

```swift
    final func suggestionBarDidTapClipboard(_ bar: SuggestionBarView) {
        toggleClipboardPanel()
    }
```

- [x] **Step 3: 클립보드 흐름을 Base 본체에 추가**

`extension BaseKeyboardViewController: SuggestionBarDelegate { ... }` 블록 바로 뒤, `private extension BaseKeyboardViewController { func synchronizeTextInputTraits()` 앞에 다음 두 블록을 넣는다:

```swift
// MARK: - Clipboard History

private extension BaseKeyboardViewController {

    /// 클립보드 기록 기능 사용 가능 여부. 설정 ON, Full Access, 미리보기 아님
    var isClipboardHistoryAvailable: Bool {
        return keyboardSettingsManager.isClipboardHistoryEnabled
        && hasFullAccess
        && !BaseKeyboardViewController.isPreview
    }

    /// pasteboard의 `changeCount`가 마지막 확인값과 다를 때만 텍스트를 읽어 기록에 저장합니다.
    ///
    /// `changeCount`와 `hasStrings` 확인은 iOS 16 붙여넣기 권한 알림을 띄우지 않고, `.string` 읽기만 띄울 수 있습니다.
    /// 호출 시점: `viewWillAppear`, `textWillChange`, 클립보드 버튼 탭. `textDidChange`와 selection 콜백은 쓰지 않습니다.
    func synchronizeClipboardHistoryIfNeeded() {
        guard isClipboardHistoryAvailable, let clipboardHistoryStore else { return }

        let pasteboard = UIPasteboard.general
        let changeCount = pasteboard.changeCount
        guard changeCount != keyboardSettingsManager.lastSeenPasteboardChangeCount else { return }
        // 읽기 실패나 저장 제외여도 같은 값을 반복해 읽지 않도록 먼저 갱신한다
        keyboardSettingsManager.lastSeenPasteboardChangeCount = changeCount

        guard pasteboard.hasStrings, let text = pasteboard.string else { return }
        clipboardHistoryStore.record(text)
    }

    /// 클립보드 버튼 탭. 열려 있으면 닫고, 닫혀 있으면 동기화 후 엽니다.
    func toggleClipboardPanel() {
        if isClipboardPanelVisible {
            closeClipboardPanelIfNeeded()
        } else {
            openClipboardPanel()
        }
    }

    /// 패널을 닫고 자판으로 돌아갑니다. 이미 닫혀 있으면 아무것도 하지 않습니다.
    func closeClipboardPanelIfNeeded() {
        guard isClipboardPanelVisible else { return }
        isClipboardPanelVisible = false
        clipboardHistoryPanelView.resetPresentation()
        updateShowingKeyboard()
        updateClipboardControl()
    }

    func openClipboardPanel() {
        cancelPendingDeleteInteractions()
        synchronizeClipboardHistoryIfNeeded()
        reloadClipboardPanel()
        isClipboardPanelVisible = true
        updateShowingKeyboard()
        updateClipboardControl()
    }

    func reloadClipboardPanel() {
        guard hasFullAccess, let clipboardHistoryStore else {
            clipboardHistoryPanelView.configure(state: .fullAccessRequired)
            return
        }
        let items = clipboardHistoryStore.load()
        clipboardHistoryPanelView.configure(state: items.isEmpty ? .empty : .items(items))
    }
}

// MARK: - ClipboardHistoryPanelDelegate

extension BaseKeyboardViewController: ClipboardHistoryPanelDelegate {
    final func clipboardPanel(_ panel: ClipboardHistoryPanelView, didSelectItemAt index: Int) {
        guard panel.items.indices.contains(index) else { return }
        let text = panel.items[index].text

        // 붙여넣기를 undo 1단위로 만든다: 앞선 입력 그룹을 닫고, 삽입 후 다시 닫는다
        commitUndoRedoGroupIgnoringCompositionDeferral()
        insertText(text)
        undoRedoEditDidApply()
        commitUndoRedoGroupIgnoringCompositionDeferral()

        closeClipboardPanelIfNeeded()
        updateReturnButtonEnabled()
        updateSuggestions()
    }

    final func clipboardPanel(_ panel: ClipboardHistoryPanelView, didDeleteItemsAt indices: [Int]) {
        clipboardHistoryStore?.remove(at: indices)
        reloadClipboardPanel()
    }

    final func clipboardPanelDidDeleteAll(_ panel: ClipboardHistoryPanelView) {
        clipboardHistoryStore?.removeAll()
        reloadClipboardPanel()
    }
}
```

- [x] **Step 4: 세 extension scheme 빌드**

Run: Global Constraints의 extension 빌드 명령
Expected: 세 scheme 모두 `BUILD SUCCEEDED`

- [x] **Step 5: 전체 테스트**

Run: `-only-testing` 없이 `xcodebuild test -scheme SYKeyboard ...`
Expected: `TEST SUCCEEDED`. 실패가 있으면 이 Task 변경과의 관련을 확인하고 고친 뒤 다시 실행한다.

- [x] **Step 6: scheme 부수 변경 확인**

```sh
git status --short
```

`.xcscheme`이 보이면 `git diff`로 `RemotePath`만 바뀌었는지 확인하고 `git checkout -- <파일>`로 복원한다.

- [x] **Step 7: 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift \
        Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
        docs/superpowers/plans/2026-09-08-clipboard-history.md
git commit -m "feat: #54 - 키보드에 클립보드 기록 패널 연결과 pasteboard 동기화 추가"
```

---

### Task 8: 앱 설정 토글

**Files:**
- Modify: `SYKeyboard/Presentation/KeyboardSettings/PredictiveTextSettingsView.swift`
- Modify: `SYKeyboard/Resources/Localizable.xcstrings`

**Interfaces:**
- Consumes: `UserDefaultsKeys.isClipboardHistoryEnabled`, `DefaultValues.isClipboardHistoryEnabled`

- [x] **Step 1: 토글 추가**

`PredictiveTextSettingsView.swift`의 `isShowMathResultsEnabled` `@AppStorage` 뒤에:

```swift
    @AppStorage(UserDefaultsKeys.isClipboardHistoryEnabled, store: UserDefaultsManager.shared.storage)
    private var isClipboardHistoryEnabled = DefaultValues.isClipboardHistoryEnabled
```

`if isPredictiveTextEnabled { ... }` 블록 안, Undo/Redo `Toggle`의 `.onChange` 뒤(블록 닫는 `}` 앞)에:

```swift
            Toggle(isOn: $isClipboardHistoryEnabled, label: {
                Text("클립보드 기록")
                Text("복사한 텍스트를 키보드 상단 클립보드 버튼으로 붙여넣기\n(설정 ➡️ SY키보드 ➡️ '다른 앱에서 붙여넣기'를 '허용'으로 바꾸면 확인 알림 없이 저장됩니다)")
                    .font(.caption)
            })
            .onChange(of: isClipboardHistoryEnabled) { newValue in
                Analytics.setUserProperty(newValue.analyticsValue,
                                          forName: "pref_clipboard_history")
                Analytics.logEvent("clipboard_history", parameters: [
                    "view": "InputSettingsView",
                    "enabled": newValue.analyticsValue
                ])
                hideKeyboard()
            }
```

- [x] **Step 2: 앱 String Catalog에 en 추가**

```sh
python3 - <<'PY'
import json, pathlib
path = pathlib.Path("SYKeyboard/Resources/Localizable.xcstrings")
catalog = json.loads(path.read_text())
new = {
    "클립보드 기록": "Clipboard History",
    "복사한 텍스트를 키보드 상단 클립보드 버튼으로 붙여넣기\n(설정 ➡️ SY키보드 ➡️ '다른 앱에서 붙여넣기'를 '허용'으로 바꾸면 확인 알림 없이 저장됩니다)":
        "Paste copied text with the clipboard button above the keyboard\n(Settings ➡️ SYKeyboard ➡️ set “Paste from Other Apps” to “Allow” to save without confirmation alerts)",
}
for ko, en in new.items():
    catalog["strings"][ko] = {"localizations": {"en": {"stringUnit": {"state": "translated", "value": en}}}}
path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2, separators=(",", " : "), sort_keys=True) + "\n")
PY
git diff --stat SYKeyboard/Resources/Localizable.xcstrings
```

Expected: 두 키가 추가된다. 정렬 차이로 다른 줄이 움직여도 기존 값은 바뀌지 않아야 한다(`git diff`에서 `-`로 사라지는 `"value"` 줄이 없어야 함).

- [x] **Step 3: 앱 빌드와 계약 테스트**

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expected: `BUILD SUCCEEDED`. 이어서 `-only-testing:SYKeyboardTests/UserDefaultsContractTests` PASS.

- [x] **Step 4: 커밋**

```sh
git add SYKeyboard/Presentation/KeyboardSettings/PredictiveTextSettingsView.swift \
        SYKeyboard/Resources/Localizable.xcstrings \
        docs/superpowers/plans/2026-09-08-clipboard-history.md
git commit -m "feat: #54 - 앱 설정에 클립보드 기록 토글 추가"
```

---

### Task 9: 최종 검증과 기록

**Files:**
- Modify: `docs/superpowers/plans/2026-09-08-clipboard-history.md`

- [x] **Step 1: 전체 테스트와 네 scheme 빌드**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' 2>&1 \
  | grep -E "Executed|error:|TEST (SUCCEEDED|FAILED)"
for scheme in HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build -project SYKeyboard.xcodeproj -scheme "$scheme" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' 2>&1 \
    | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
done
git status --short
```

Expected: `TEST SUCCEEDED`, 세 scheme `BUILD SUCCEEDED`. `.xcscheme` `RemotePath` 변경은 복원한다.

- [x] **Step 2: 결과 기록**

아래 "검증 결과" 절에 실제 실행 명령, 기기명/OS, 테스트 실행 개수와 통과 여부, 빌드 결과를 적는다. 실기기 확인 항목은 확인하지 못했으면 "미확인"과 차단 이유를 그대로 남긴다.

- [x] **Step 3: 커밋**

```sh
git add docs/superpowers/plans/2026-09-08-clipboard-history.md
git commit -m "docs: #54 - 구현 계획에 검증 결과 기록"
```

---

## 검증 결과

- 시뮬레이터: iPhone 13 mini, iOS 16.0
- 실행 명령:
  ```sh
  xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
  for scheme in HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
    xcodebuild build -project SYKeyboard.xcodeproj -scheme "$scheme" \
      -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
  done
  ```
- `xcodebuild test -scheme SYKeyboard`: 이번 Xcode 버전 출력에는 고전적인 `Executed N tests` 요약 줄이 없어 `' passed on'` / `' failed on'` 줄 수를 직접 집계했다. 602개 테스트 케이스 모두 통과(`passed`), 실패(`failed`) 0건, `error:` 0건, `** TEST SUCCEEDED **`
- `HangeulKeyboard` 빌드: `error:` 0건, `** BUILD SUCCEEDED **`
- `EnglishKeyboard` 빌드: `error:` 0건, `** BUILD SUCCEEDED **`
- `HangeulEnglishKeyboard` 빌드: `error:` 0건, `** BUILD SUCCEEDED **`
- 위 네 실행 직후 `git status --short`는 변경 없음(clean) — extension 빌드가 `.xcscheme`의 `RemotePath`를 덮어쓰지 않았으므로 복원할 파일이 없었다.
- 이번 세션에서는 `.xcresult`나 로그 파일을 저장소나 영구 위치에 보관하지 않았다(터미널 출력만 확인).

### 실기기 확인 항목 (자동 테스트로 대체 불가)

이번 세션은 실기기를 사용하지 않아 아래 항목을 관찰하지 못했다. 모두 "미확인"으로 남긴다.

| 항목 | 결과 |
| --- | --- |
| 복사 → 키보드 재등장 시 기록 반영 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| 복사 → 텍스트 필드 전환 시 기록 반영 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| 복사 → 클립보드 버튼 탭 시 기록 반영 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| iOS 16 붙여넣기 권한 배너 표시, "다른 앱에서 붙여넣기" 허용 후 사라짐 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| 한글 조합 중 붙여넣기 후 다음 자모가 새 글자로 시작 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| 붙여넣기가 undo 1단위 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| 편집 모드 체크마크와 모든 행 들여쓰기 | 확인 (시스템 다중 선택 컨트롤, 원형 체크 형태) |
| 편집 모드에서 스와이프 삭제가 막힘 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| 평소 모드 trailing swipe 삭제 | 확인 (diffable 전환 1d83c8e6 빌드에서 삭제와 행 애니메이션 정상) |
| 길게 누르기 상세 뷰 스크롤·붙여넣기·닫기 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| Full Access OFF에서 안내 상태 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| 자동완성 OFF에서 클립보드 버튼 미표시 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| 한 손 모드·가로 모드에서 패널 폭·높이 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| 클립보드 버튼 아이콘이 패널 열림/닫힘에 따라 바뀜 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| 비밀번호 관리자에서 복사한 항목(org.nspasteboard.ConcealedType)이 기록되지 않음 | iOS '암호' 앱은 public.utf8-plain-text만 넣어 기록됨(실기기 로그 확인, 구분 불가). Bitwarden도 ConcealedType을 넣지 않아 기록됨(2026-09-09, 실기기). 제외는 ConcealedType을 표기하는 관리자에만 적용 |
| leading swipe로 고정/해제, 고정 행 pin 아이콘, 고정 항목이 맨 위 고정 순 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| 고정 20개가 차면 미고정 행에 leading swipe 없음 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| 상세 뷰 고정/해제 버튼 후 목록 갱신 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| 앱 설정 '클립보드 기록 관리' 화면: 목록·스와이프·편집 모드가 키보드 패널과 같음 | 확인 (2026-09-09, 실기기, 77df2e5f 빌드: 편집→선택→n개 삭제, 원문 하프 시트) |
| 앱에서 직접 추가한 항목이 고정으로 맨 위에 오고 키보드 패널에 바로 반영 | 확인 (2026-09-08, 실기기, 커밋 5c5c9f99~f840d2ab 빌드) |
| 다른 앱에서 복사 → SY키보드 앱을 열면 관리 화면에 기록 반영(권한 배너 포함) | 확인 (2026-09-09, 실기기, 77df2e5f 빌드, 붙여넣기 배너 표시) |
| 영어 기기에서 패널 문자열(Full Access 안내 등)이 영문으로 표시 | 77df2e5f 빌드에서 세 키보드 모두 한국어로만 표시됨(실기기). 원인: Core가 정적 라이브러리라 Core 카탈로그가 extension 번들에 안 들어감. Common·앱 카탈로그로 옮긴 d9d531fa 빌드에서 세 키보드 모두 영문 표시 확인(2026-09-09, 실기기) |
| iOS 16 앱 관리 화면 편집 모드에서 하단 바(전체 선택·n개 삭제) 표시 | 77df2e5f 빌드에서 iOS 16 실기기는 하단 바가 안 뜸(iOS 27은 정상). bottomBar 항목을 항상 두고 `.toolbar(_:for:)`로 표시만 토글한 54f1bc7a 빌드에서 iOS 16 표시 확인(2026-09-09, 실기기) |
| 앱 관리 화면 편집 모드 "n개 고정"/"n개 고정 해제"(대상 없음·한도 초과 시 비활성) | 확인 (2026-09-09, 실기기, bb88cc50 빌드) |
| 키보드 패널 trailing swipe가 `trash.fill` 아이콘으로 표시 | 확인 (2026-09-09, 실기기, bb88cc50 빌드) |
| 패널 문자열을 `SYKeyboardAssets` 카탈로그로 옮긴 뒤 영어 기기에서 세 키보드 패널·전체 접근 허용 안내 오버레이가 영문 표시 | 확인 (2026-09-09, 실기기, bb88cc50 빌드. appex 안 `SYKeyboardAssets_SYKeyboardAssets.bundle/en.lproj/Localizable.strings`에 18개 포함) |
| 전체 접근 허용 안내 오버레이가 Base로 옮긴 뒤에도 세 키보드에서 뜨고, 닫기·시스템 설정 이동이 동작 | 확인 (2026-09-09, 실기기, bb88cc50 빌드) |
| 앱 미리보기 키보드에 전체 접근 허용 안내가 뜨지 않음 | 확인 (2026-09-09, 실기기, bb88cc50 빌드) |
| Xcode 빌드 후 Assets 카탈로그(`manual`)가 `git status`에 나타나지 않음 | 확인 (2026-09-09, Xcode 빌드) |
| iOS 16 앱 관리 화면 비편집 모드에서 하단 바가 숨겨짐(`.toolbar(.hidden, for: .bottomBar)`, 빈 바가 남지 않음) | 확인 (2026-09-09, iOS 16 실기기 스크린샷) |
| 키보드 상세 뷰·앱 원문 시트에서 항목 전체가 URL이면 본문이 파란 밑줄 링크로 보이고 탭하면 브라우저가 열림. URL이 아니면 일반 텍스트 | 확인 (2026-09-10, 실기기) |
| 앱 원문 시트 왼쪽 상단 공유 버튼으로 공유 시트가 뜸 | 확인 (2026-09-10, 실기기) |
| 앱 `List`에서 고정 항목 스와이프 삭제 시 확인 시트가 뜨는 동안 행이 접혔다 돌아옴 | 재현됨 (2026-09-09, iOS 16·27 실기기). destructive role의 선행 애니메이션. `UITableView` 전환(6095f645 시점)은 iOS 27에서 지워지는 행이 카드 위로 올라가는 문제가 있어 되돌리고 `List` 유지. 확인 시트를 행에 붙인 뒤에는 행이 접히며 시트가 닫히는 것까지 확인돼(2026-09-10, iOS 27 녹화) 스와이프 삭제 버튼을 role 없이 `.tint(.red)`로 변경 |
| 앱에서 고정 항목을 스와이프 삭제하면 확인 시트가 행이 접히지 않은 채 유지되고, 취소·삭제 모두 정상 동작 | 확인 (2026-09-10, iOS 27 실기기) |
| 앱 원문 시트의 고정/해제 버튼이 즉시 시트와 목록에 반영되고, 복사하면 시트 뒤 목록에서 항목이 맨 위로 올라감(고정 항목은 그대로). 편집 모드 편집기에 흰 사각형 배경이 없음 | 확인 (2026-09-10, 실기기) |
| 키보드 패널 편집 모드의 "완료"만 semibold("n개 삭제"는 regular로 되돌림) | 확인 (2026-09-10, 실기기) |
| 키보드 패널에서 행을 스와이프 삭제해도 편집 모드로 바뀌지 않음 | 확인 (2026-09-10, 실기기) |
| 키보드에서 행 탭·상세 뷰 붙여넣기로 쓴 미고정 항목이 다음에 패널을 열면 맨 위(고정 아래)에 옴. 고정 항목은 자리 유지 | 확인 (2026-09-10, 실기기) |
| 앱에서 고정 항목이 포함된 삭제(스와이프·편집 모드)는 알림으로 확인 후 삭제되고, 취소하면 유지 | 확인 (2026-09-10, 실기기, action sheet) |
| 키보드 패널에서 고정 항목이 포함된 삭제(스와이프·편집 모드)는 패널 안 확인 뷰가 뜨고, 삭제 시 지워지며 취소·패널 닫기 시 유지 | 확인 (2026-09-10, 실기기) |
| 키보드 고정 행 스와이프 삭제 → 확인 뷰 → 취소 시 행이 제자리에 남음(completion false) | 확인 (2026-09-10, 실기기) |
| 키보드 상세 뷰에서 URL 항목의 빈 여백 탭은 브라우저를 열지 않고 글자 영역 탭만 엶 | 확인 (2026-09-10, 실기기) |
| 키보드에서 스와이프를 연 채 패널을 닫고 다시 열면 스와이프가 닫혀 있고, 스와이프 연 채 "선택"을 눌러도 헤더와 테이블이 함께 편집 모드 | 확인 (2026-09-10, 실기기) |
| 앱 삭제 확인 시트가 닫히는 동안 제목이 "0개"로 바뀌지 않음, 자동완성 설정 화면의 토글 조작 시 관리 화면 저장소 읽기가 일어나지 않음(LazyView) | 확인 (2026-09-10, 실기기) |
| 앱 원문 시트 "편집"으로 내용을 고쳐 저장하면 같은 자리에 반영되고, 빈 값·중복·원문과 같으면 저장 비활성 | 확인 (2026-09-10, 실기기). 이후 중복 저장은 기존 항목을 맨 위로 합치도록 변경 |
| 앱 편집/완료 전환 시 버튼 위치가 고정되고("+" 오른쪽, "완료" semibold), 선택이 있을 때 삭제 아이콘이 destructive role만으로 빨간색 | 확인 (2026-09-09, 실기기): role만으로는 빨간색이 되지 않음. 사용자 결정으로 tint 없이 그대로 둠 |
| 앱 편집 모드에서 선택이 있으면 제목이 "n개 선택", 하단 바가 `checklist.checked`/`checklist.unchecked`·`pin`/`pin.slash`·`trash` 아이콘으로 표시 | 확인 (2026-09-10, 실기기) |
| 키보드 편집 모드에서 "선택 해제" ↔ "전체 선택" 전환 시 글자가 잘리지 않음 | 확인 (2026-09-10, 실기기). iOS 26+에서 "전체 선택 해제"가 잘리던 문제를 폭 고정 대신 같은 글자 수의 "선택 해제"로 해결 |
| 고정·미고정이 섞인 삭제의 확인 문구가 "항목 n개를 삭제할까요?" + 고정 개수 설명(키보드·앱) | 확인 (2026-09-10, 실기기) |
| 앱 원문 편집에서 다른 항목과 같은 내용으로 저장하면 편집 항목이 사라지고 기존 항목이 맨 위로 옴, 시트는 그 항목을 보여줌 | 확인 (2026-09-10, 실기기). 이후 규칙 변경: 어느 쪽이든 고정이었으면 고정 맨 위로 |
| 편집 중복 병합에서 고정→미고정 텍스트는 고정 맨 위로, 미고정→고정 텍스트는 그 고정 항목이 맨 위로. `+`로 이미 고정된 텍스트를 추가하면 그 항목이 고정 맨 위로 | 확인 (2026-09-10, 실기기) |
| 앱 삭제 확인 시트가 스와이프한 행(스와이프 삭제)과 하단 바 삭제 버튼(편집 모드)에서 뜸(iOS 26+), iOS 16은 하단 시트 | 확인 (2026-09-10, iOS 27 실기기) |
| 앱 목록 행을 탭해 시트를 연 뒤 눌린 표시가 남지 않음 | 확인 (2026-09-10, 실기기, 탭 제스처) |
| 앱에서 지운 최근 항목이 키보드로 돌아가면 되살아남 | 재현됨 (2026-09-10, iOS 27 녹화). 임시 로그로 `UIPasteboard.changeCount`가 프로세스마다 다름을 확인(앱 313, 키보드 299. 키보드는 다른 앱의 복사는 바로 보지만 SY키보드 앱 안의 복사는 뒤늦게 증가로 봄). 프로세스별 카운트 + 공유 텍스트 해시·기록 시각 비교로 고치는 시도(로컬 브랜치 `wip/#54-clipboard-sync-attempt`)는 되살아남이 간헐적으로 남고 iOS 16 배너·Universal Clipboard 재동기화까지 없애지 못해 되돌림. 알려진 제한으로 둔다 |
