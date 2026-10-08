# 텍스트 프록시 중복 읽기 정리 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `textWillChange`/`textDidChange` 한 번에 같은 `textDocumentProxy` 값을 한 번만 읽고, 프록시에 쓴 뒤에는 다시 읽게 한다.

**Architecture:** 프록시 읽기·쓰기를 모으는 `CachingTextDocumentProxy`를 SYKeyboardCore에 추가한다. `withReadCaching(_:)` 범위 안에서는 값마다 처음 한 번만 읽고, 쓰기 메서드가 캐시를 비운다. Base와 하위 VC의 `textDocumentProxy.xxx`를 모두 `textDocument.xxx`로 바꾸고, 콜백 본문을 범위로 감싼다.

**Tech Stack:** Swift 5, UIKit(`UIInputViewController`, `UITextDocumentProxy`), Swift Testing, Xcode 26+

**Spec:** `docs/superpowers/specs/2026-10-08-text-proxy-read-cache-design.md`

## Global Constraints

- 기본 검증 대상: `iPhone 13 mini / iOS 18.6` 시뮬레이터. iOS 16.0 런타임은 쓰지 않는다.
- 콜백 순서, 호출 횟수, 버튼 이벤트 타이밍은 바꾸지 않는다. 바뀌는 것은 프록시 읽기 횟수뿐이다.
- `updateKeyboardType()` 등 `open` 메서드 시그니처를 바꾸지 않는다.
- production 클래스에 `ForTesting` 메서드를 추가하지 않는다. 테스트는 production 진입점을 부르고 정확한 값을 단언한다.
- `Modules/`에 새 파일을 추가하면 `SYKeyboard.xcodeproj/project.pbxproj`의 `SYKeyboard`·`SYKeyboardCore` 두 타깃 `membershipExceptions`에 알파벳 순서로 등록한다.
- 커밋 메시지: `refactor: #181 - <결과 중심 한국어 subject>` 또는 `docs: #181 - ...`, `test: #181 - ...`. 끝에 `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. push하지 않는다.
- 각 step은 실제 작업과 검증이 끝난 직후에만 체크하고, 결과(테스트 개수, 빌드 결과, 확인하지 못한 항목)를 이 문서에 적는다. task 끝의 커밋에 이 문서의 체크 갱신을 함께 넣는다.
- `xcodebuild`는 foreground로 `timeout 600000`을 주고 로그는 scratchpad 파일로 받는다. 오래 걸리는 실행은 시작 전에 사용자에게 알린다.
- extension scheme 빌드 뒤 `git status --short`에 `.xcscheme`이 보이면 `RemotePath`만 바뀐 경우 `git checkout -- <파일>`로 되돌린다.
- 테스트가 준비 단계에서 타임아웃하면(`XCTHTestOperationCoordinatorErrorDomain Code=14`) 코드 실패로 기록하지 않는다. CLAUDE.md "환경 오류와 코드 실패 구분"대로 시뮬레이터 화면부터 확인한다.

## Review Focus

1. 필드 이동으로 `keyboardType`이 바뀐 `textDidChange`: 캐시가 있어도 trait 변경 훅(`inputTraitsDidChange`)이 새 값으로 정확히 한 번 불리고 `oldKeyboardType`이 새 값이 되어야 한다. → Task 2 Step 1의 `testKeyboardTypeChangeCallsTraitHookOnceWithNewValue`.
2. 콜백 사이 캐시 누수: `textWillChange`에서 읽은 값이 `textDidChange`에 남으면 전송 감지·리턴 버튼·후보가 지난 문맥을 본다. → Task 2 Step 1의 `testTextDidChangeRereadsValuesReadInTextWillChange`.
3. 범위 안 쓰기 뒤 읽기: 보류된 삭제가 이어진 뒤 리턴 버튼·후보는 삭제가 반영된 문맥을 봐야 한다. → Task 1 `testWriteInsideScopeRereadsValue`, Task 5 삭제 이어 가기 시뮬레이터 확인.
4. 하위 VC의 `super` 뒤 읽기(영문·한영 shift 자동 대문자): 감싸지 않으면 캐시 밖에서 다시 읽는다. → Task 3 `testTextWillChangeReadsShiftContextOnce`, Task 5 커서 이동 확인.
5. 전송 감지용 `documentIdentifier`(KVC): 래퍼를 거쳐도 같은 UUID를 돌려줘야 전송 기록이 유지된다. → Task 1 `testDocumentIdentifierReadsThroughKVCOnceInsideScope`, Task 5 전송 기록 확인.

---

## File Structure

| 파일 | 작업 | 책임 |
|---|---|---|
| `Modules/SYKeyboardCore/Presentation/ViewController/Bases/Utils/CachingTextDocumentProxy.swift` | Create | 프록시 읽기·쓰기 창구, 범위 캐시 |
| `SYKeyboard.xcodeproj/project.pbxproj` | Modify | 새 파일 타깃 등록 |
| `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` | Modify | `textDocument` 추가, 프록시 접근 치환, 콜백 범위 |
| `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardCoreViewController.swift` | Modify | 접근 치환, `textWillChange` 범위 |
| `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift` | Modify | 접근 치환 |
| `Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift` | Modify | 접근 치환, `textWillChange` 범위 |
| `SYKeyboardTests/Utils/CountingTextDocumentProxy.swift` | Create | 필드별 읽기 횟수·쓰기 기록 가짜 프록시 |
| `SYKeyboardTests/Utils/CachingTextDocumentProxyTests.swift` | Create | 타입 단위 테스트 |
| `SYKeyboardTests/Controller/BaseKeyboardViewControllerProxyReadTests.swift` | Modify | 공통 가짜 프록시로 교체, 콜백 테스트 추가 |
| `SYKeyboardTests/Controller/EnglishKeyboardCoreViewControllerProxyReadTests.swift` | Create | 영문 `textWillChange` 테스트 |
| `CLAUDE.md` | Modify | 프록시 접근 규칙 |

`SYKeyboardTests/`는 폴더 동기화 그룹이라 테스트 파일은 pbxproj 등록이 필요 없다.

---

### Task 1: `CachingTextDocumentProxy`와 공통 가짜 프록시

**Files:**
- Create: `SYKeyboardTests/Utils/CountingTextDocumentProxy.swift`
- Create: `SYKeyboardTests/Utils/CachingTextDocumentProxyTests.swift`
- Create: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/Utils/CachingTextDocumentProxy.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj` (`Bases/BaseKeyboardViewController.swift,` 줄 2곳 바로 아래)
- Modify: `SYKeyboardTests/Controller/BaseKeyboardViewControllerProxyReadTests.swift`

**Interfaces:**
- Produces:
  - `@MainActor public final class CachingTextDocumentProxy`
    - `init(proxy: @escaping () -> any UITextDocumentProxy)` (internal)
    - `public func withReadCaching(_ body: () -> Void)`
    - 읽기: `documentContextBeforeInput: String?`, `documentContextAfterInput: String?`, `selectedText: String?`, `documentIdentifier: UUID?`, `documentInputMode: UITextInputMode?`, `hasText: Bool`, `keyboardType: UIKeyboardType?`, `textContentType: UITextContentType?`, `returnKeyType: UIReturnKeyType?`, `enablesReturnKeyAutomatically: Bool?`, `autocorrectionType: UITextAutocorrectionType?`, `autocapitalizationType: UITextAutocapitalizationType?`, `smartQuotesType: UITextSmartQuotesType?`, `smartDashesType: UITextSmartDashesType?`, `smartInsertDeleteType: UITextSmartInsertDeleteType?`, `@available(iOS 18.0, *) mathExpressionCompletionType: UITextMathExpressionCompletionType?`
    - 쓰기: `insertText(_ text: String)`, `deleteBackward()`, `adjustTextPosition(byCharacterOffset offset: Int)`
  - 테스트 `final class CountingTextDocumentProxy: NSObject, UITextDocumentProxy`
    - 값: `beforeInput: String?`(기본 `"안녕"`), `afterInput: String?`, `selected: String?`, `identifier: UUID`, `inputMode: UITextInputMode?`, `stubbedHasText: Bool`(기본 `true`), trait 프로퍼티는 `UITextDocumentProxy` 이름 그대로 get/set
    - 기록: `readCounts: [String: Int]`(키 = 프로퍼티 이름), `writes: [String]`
    - `readCount(of:) -> Int`, `contextReadCount: Int`(앞·뒤 문맥 + 선택 텍스트 합), `resetReadCounts()`

- [ ] **Step 1: 공통 가짜 프록시 작성**

`SYKeyboardTests/Utils/CountingTextDocumentProxy.swift`:

```swift
//
//  CountingTextDocumentProxy.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import UIKit

/// 필드별 읽기 횟수와 쓰기 기록을 남기는 가짜 텍스트 프록시
///
/// 쓰기는 실제 프록시처럼 앞 문맥에 반영한다
final class CountingTextDocumentProxy: NSObject, UITextDocumentProxy {

    // MARK: - Records

    /// 프로퍼티 이름별 읽기 횟수
    private(set) var readCounts: [String: Int] = [:]
    /// 쓰기 호출 기록. 예: `"insertText(가)"`, `"deleteBackward"`, `"adjustTextPosition(-1)"`
    private(set) var writes: [String] = []

    // MARK: - Stubbed Values

    var beforeInput: String? = "안녕"
    var afterInput: String?
    var selected: String?
    var identifier = UUID()
    var inputMode: UITextInputMode?
    var stubbedHasText = true

    private var storedKeyboardType: UIKeyboardType = .default
    private var storedTextContentType: UITextContentType?
    private var storedReturnKeyType: UIReturnKeyType = .default
    private var storedEnablesReturnKeyAutomatically = false
    private var storedAutocorrectionType: UITextAutocorrectionType = .default
    private var storedAutocapitalizationType: UITextAutocapitalizationType = .sentences
    private var storedSmartQuotesType: UITextSmartQuotesType = .default
    private var storedSmartDashesType: UITextSmartDashesType = .default
    private var storedSmartInsertDeleteType: UITextSmartInsertDeleteType = .default
    /// iOS 18 타입은 저장 프로퍼티에 availability를 붙일 수 없어 raw 값으로 둔다
    private var storedMathExpressionCompletionTypeRawValue = 0

    // MARK: - UITextDocumentProxy

    var documentContextBeforeInput: String? { read(beforeInput) }
    var documentContextAfterInput: String? { read(afterInput) }
    var selectedText: String? { read(selected) }
    var documentIdentifier: UUID { read(identifier) }
    var documentInputMode: UITextInputMode? { read(inputMode) }
    var hasText: Bool { read(stubbedHasText) }

    // UITextInputTraits는 get/set 요구사항이라 접근자로 읽기를 센다
    var keyboardType: UIKeyboardType {
        get { read(storedKeyboardType) }
        set { storedKeyboardType = newValue }
    }
    var textContentType: UITextContentType? {
        get { read(storedTextContentType) }
        set { storedTextContentType = newValue }
    }
    var returnKeyType: UIReturnKeyType {
        get { read(storedReturnKeyType) }
        set { storedReturnKeyType = newValue }
    }
    var enablesReturnKeyAutomatically: Bool {
        get { read(storedEnablesReturnKeyAutomatically) }
        set { storedEnablesReturnKeyAutomatically = newValue }
    }
    var autocorrectionType: UITextAutocorrectionType {
        get { read(storedAutocorrectionType) }
        set { storedAutocorrectionType = newValue }
    }
    var autocapitalizationType: UITextAutocapitalizationType {
        get { read(storedAutocapitalizationType) }
        set { storedAutocapitalizationType = newValue }
    }
    var smartQuotesType: UITextSmartQuotesType {
        get { read(storedSmartQuotesType) }
        set { storedSmartQuotesType = newValue }
    }
    var smartDashesType: UITextSmartDashesType {
        get { read(storedSmartDashesType) }
        set { storedSmartDashesType = newValue }
    }
    var smartInsertDeleteType: UITextSmartInsertDeleteType {
        get { read(storedSmartInsertDeleteType) }
        set { storedSmartInsertDeleteType = newValue }
    }
    @available(iOS 18.0, *)
    var mathExpressionCompletionType: UITextMathExpressionCompletionType {
        get { read(UITextMathExpressionCompletionType(rawValue: storedMathExpressionCompletionTypeRawValue) ?? .default) }
        set { storedMathExpressionCompletionTypeRawValue = newValue.rawValue }
    }

    func insertText(_ text: String) {
        writes.append("insertText(\(text))")
        beforeInput = (beforeInput ?? "") + text
    }

    func deleteBackward() {
        writes.append("deleteBackward")
        beforeInput = beforeInput.map { String($0.dropLast()) }
    }

    func adjustTextPosition(byCharacterOffset offset: Int) {
        writes.append("adjustTextPosition(\(offset))")
    }

    func setMarkedText(_ markedText: String, selectedRange: NSRange) {}
    func unmarkText() {}

    // MARK: - Helpers

    func readCount(of key: String) -> Int {
        readCounts[key, default: 0]
    }

    /// 앞·뒤 문맥과 선택 텍스트 읽기 합계
    var contextReadCount: Int {
        readCount(of: "documentContextBeforeInput")
            + readCount(of: "documentContextAfterInput")
            + readCount(of: "selectedText")
    }

    func resetReadCounts() {
        readCounts.removeAll()
    }

    private func read<T>(_ value: T, key: String = #function) -> T {
        readCounts[key, default: 0] += 1
        return value
    }
}
```

- [ ] **Step 2: 기존 프록시 읽기 테스트를 공통 가짜 프록시로 교체**

`SYKeyboardTests/Controller/BaseKeyboardViewControllerProxyReadTests.swift`에서:
- 파일 끝의 `/// 문맥·선택 텍스트 읽기 횟수를 세는 프록시`부터 `private final class ReadCountingTextDocumentProxy { ... }` 끝까지 삭제한다.
- `let proxy = ReadCountingTextDocumentProxy()` → `let proxy = CountingTextDocumentProxy()`
- `controller.proxy.readCount = 0` 3곳 → `controller.proxy.resetReadCounts()`
- `#expect(controller.proxy.readCount == 0)` 3곳 → `#expect(controller.proxy.contextReadCount == 0)`

- [ ] **Step 3: 타입 단위 테스트 작성**

`SYKeyboardTests/Utils/CachingTextDocumentProxyTests.swift`:

```swift
//
//  CachingTextDocumentProxyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("CachingTextDocumentProxy 콜백 범위 읽기 캐시")
@MainActor
struct CachingTextDocumentProxyTests {

    @Test("범위 밖에서는 읽을 때마다 프록시를 읽음")
    func testReadsProxyEveryTimeOutsideScope() {
        let proxy = CountingTextDocumentProxy()
        let textDocument = CachingTextDocumentProxy { proxy }

        _ = textDocument.documentContextBeforeInput
        _ = textDocument.documentContextBeforeInput

        #expect(proxy.readCount(of: "documentContextBeforeInput") == 2)
    }

    @Test("범위 안에서는 같은 값을 한 번만 읽음")
    func testReadsProxyOnceInsideScope() {
        let proxy = CountingTextDocumentProxy()
        proxy.keyboardType = .emailAddress
        let textDocument = CachingTextDocumentProxy { proxy }

        textDocument.withReadCaching {
            #expect(textDocument.documentContextBeforeInput == "안녕")
            #expect(textDocument.documentContextBeforeInput == "안녕")
            #expect(textDocument.keyboardType == .emailAddress)
            #expect(textDocument.keyboardType == .emailAddress)
        }

        #expect(proxy.readCount(of: "documentContextBeforeInput") == 1)
        #expect(proxy.readCount(of: "keyboardType") == 1)
    }

    @Test("범위 안에서 읽은 nil도 다시 읽지 않음")
    func testCachesNilInsideScope() {
        let proxy = CountingTextDocumentProxy()
        proxy.afterInput = nil
        let textDocument = CachingTextDocumentProxy { proxy }

        textDocument.withReadCaching {
            #expect(textDocument.documentContextAfterInput == nil)
            #expect(textDocument.documentContextAfterInput == nil)
        }

        #expect(proxy.readCount(of: "documentContextAfterInput") == 1)
    }

    @Test("범위 안에서 쓰면 다음 읽기는 쓰기가 반영된 값을 다시 읽음")
    func testWriteInsideScopeRereadsValue() {
        let proxy = CountingTextDocumentProxy()
        let textDocument = CachingTextDocumentProxy { proxy }

        textDocument.withReadCaching {
            #expect(textDocument.documentContextBeforeInput == "안녕")
            textDocument.deleteBackward()
            #expect(textDocument.documentContextBeforeInput == "안")
            #expect(textDocument.documentContextBeforeInput == "안")
        }

        #expect(proxy.readCount(of: "documentContextBeforeInput") == 2)
    }

    @Test("쓰기는 순서와 인자 그대로 프록시에 전달됨")
    func testForwardsWritesInOrder() {
        let proxy = CountingTextDocumentProxy()
        let textDocument = CachingTextDocumentProxy { proxy }

        textDocument.insertText("가")
        textDocument.deleteBackward()
        textDocument.adjustTextPosition(byCharacterOffset: -1)

        #expect(proxy.writes == ["insertText(가)", "deleteBackward", "adjustTextPosition(-1)"])
    }

    @Test("안쪽 범위가 끝나도 바깥 범위 캐시는 남고, 바깥 범위가 끝나면 버림")
    func testNestedScopeKeepsOuterCacheUntilOutermostEnds() {
        let proxy = CountingTextDocumentProxy()
        let textDocument = CachingTextDocumentProxy { proxy }

        textDocument.withReadCaching {
            _ = textDocument.documentContextBeforeInput
            textDocument.withReadCaching {
                _ = textDocument.documentContextBeforeInput
            }
            _ = textDocument.documentContextBeforeInput
        }
        #expect(proxy.readCount(of: "documentContextBeforeInput") == 1)

        proxy.beforeInput = "바뀐 문맥"
        #expect(textDocument.documentContextBeforeInput == "바뀐 문맥")
        #expect(proxy.readCount(of: "documentContextBeforeInput") == 2)
    }

    @Test("문서 식별자는 KVC로 읽고 범위 안에서 한 번만 읽음")
    func testDocumentIdentifierReadsThroughKVCOnceInsideScope() {
        let proxy = CountingTextDocumentProxy()
        let identifier = UUID()
        proxy.identifier = identifier
        let textDocument = CachingTextDocumentProxy { proxy }

        textDocument.withReadCaching {
            #expect(textDocument.documentIdentifier == identifier)
            #expect(textDocument.documentIdentifier == identifier)
        }

        #expect(proxy.readCount(of: "documentIdentifier") == 1)
    }
}
```

- [ ] **Step 4: 테스트가 컴파일 실패하는지 확인**

Run:
```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/CachingTextDocumentProxyTests \
  > "$SCRATCH/task1-red.log" 2>&1; tail -20 "$SCRATCH/task1-red.log"
```
(`$SCRATCH`는 세션 scratchpad 경로.) Expected: `cannot find 'CachingTextDocumentProxy' in scope`로 실패.

- [ ] **Step 5: 타입 구현**

`Modules/SYKeyboardCore/Presentation/ViewController/Bases/Utils/CachingTextDocumentProxy.swift`:

```swift
//
//  CachingTextDocumentProxy.swift
//  SYKeyboardCore
//
//  Created by Claude on 10/8/26.
//

import UIKit

/// 텍스트 프록시 읽기·쓰기 창구. 콜백 한 번 동안 같은 값을 다시 읽지 않게 한다
///
/// UIKit이 XPC 스레드에서 문서 상태를 교체하는 순간 메인 스레드가 프록시를 읽으면 크래시한다.
/// `withReadCaching(_:)` 안에서는 값마다 처음 한 번만 프록시를 읽고, 쓰기 메서드가 저장한 값을 모두 버려
/// 쓰기 뒤에는 새 값을 읽는다. 범위 밖에서는 프록시를 그대로 읽고 쓴다.
///
/// > 쓰기가 캐시를 비우도록 프록시 읽기·쓰기는 이 타입으로만 한다
@MainActor
public final class CachingTextDocumentProxy {

    // MARK: - Properties

    private let proxy: () -> any UITextDocumentProxy
    /// 중첩된 `withReadCaching(_:)` 깊이. 0이면 캐시를 쓰지 않는다
    private var cachingDepth = 0
    /// 프로퍼티 이름별로 읽은 값. `nil`도 읽은 값으로 저장한다
    private var cachedValues: [String: Any] = [:]

    // MARK: - Initializer

    init(proxy: @escaping () -> any UITextDocumentProxy) {
        self.proxy = proxy
    }

    // MARK: - Caching Scope

    /// `body`가 도는 동안 읽은 값을 저장해 다시 읽지 않습니다.
    ///
    /// 중첩할 수 있고, 가장 바깥 범위가 끝날 때 저장한 값을 버립니다
    public func withReadCaching(_ body: () -> Void) {
        cachingDepth += 1
        defer {
            cachingDepth -= 1
            if cachingDepth == 0 { cachedValues.removeAll() }
        }
        body()
    }

    // MARK: - Document

    public var documentContextBeforeInput: String? { cached { $0.documentContextBeforeInput } }
    public var documentContextAfterInput: String? { cached { $0.documentContextAfterInput } }
    public var selectedText: String? { cached { $0.selectedText } }
    public var documentInputMode: UITextInputMode? { cached { $0.documentInputMode } }
    public var hasText: Bool { cached { $0.hasText } }

    /// 헤더는 nonnull이지만 키보드가 처음 뜰 때나 입력창이 바뀌는 순간 nil이 온다.
    /// Swift 프로퍼티로 읽으면 `UUID` 브리징에서 크래시하므로 KVC로 읽는다
    public var documentIdentifier: UUID? {
        cached { ($0 as AnyObject).value(forKey: "documentIdentifier") as? UUID }
    }

    // MARK: - Input Traits

    public var keyboardType: UIKeyboardType? { cached { $0.keyboardType } }
    public var textContentType: UITextContentType? { cached { $0.textContentType ?? nil } }
    public var returnKeyType: UIReturnKeyType? { cached { $0.returnKeyType } }
    public var enablesReturnKeyAutomatically: Bool? { cached { $0.enablesReturnKeyAutomatically } }
    public var autocorrectionType: UITextAutocorrectionType? { cached { $0.autocorrectionType } }
    public var autocapitalizationType: UITextAutocapitalizationType? { cached { $0.autocapitalizationType } }
    public var smartQuotesType: UITextSmartQuotesType? { cached { $0.smartQuotesType } }
    public var smartDashesType: UITextSmartDashesType? { cached { $0.smartDashesType } }
    public var smartInsertDeleteType: UITextSmartInsertDeleteType? { cached { $0.smartInsertDeleteType } }

    @available(iOS 18.0, *)
    public var mathExpressionCompletionType: UITextMathExpressionCompletionType? {
        cached { $0.mathExpressionCompletionType }
    }

    // MARK: - Writes

    public func insertText(_ text: String) {
        cachedValues.removeAll()
        proxy().insertText(text)
    }

    public func deleteBackward() {
        cachedValues.removeAll()
        proxy().deleteBackward()
    }

    public func adjustTextPosition(byCharacterOffset offset: Int) {
        cachedValues.removeAll()
        proxy().adjustTextPosition(byCharacterOffset: offset)
    }
}

// MARK: - Private Methods

private extension CachingTextDocumentProxy {
    func cached<T>(_ key: String = #function, _ read: (any UITextDocumentProxy) -> T) -> T {
        guard cachingDepth > 0 else { return read(proxy()) }
        if let stored = cachedValues[key], let value = stored as? T { return value }

        let value = read(proxy())
        cachedValues[key] = value
        return value
    }
}
```

`$0.textContentType ?? nil`은 선택 요구사항 + IUO로 이중 옵셔널이 되는 경우를 한 겹으로 편다. 컴파일러가 프로퍼티 타입을 다르게 추론해 오류가 나면 반환 타입은 그대로 두고 클로저 본문만 맞춘다.

- [ ] **Step 6: pbxproj 등록**

`SYKeyboard.xcodeproj/project.pbxproj`에서 아래 줄(2곳: `SYKeyboard` 타깃, `SYKeyboardCore` 타깃 예외 목록)을 Edit `replace_all`로 바꾼다.

```
				SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift,
```
→
```
				SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift,
				SYKeyboardCore/Presentation/ViewController/Bases/Utils/CachingTextDocumentProxy.swift,
```

`Bases/Utils/` 폴더는 새로 만든다. Base VC만 쓰는 보조 타입을 Base 옆에 둔다(하위 VC는 타입이 아니라 `textDocument` 인스턴스만 쓴다).

확인: `grep -c "CachingTextDocumentProxy.swift" SYKeyboard.xcodeproj/project.pbxproj` → `2`.

- [ ] **Step 7: 테스트 통과 확인**

Run:
```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/CachingTextDocumentProxyTests \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerProxyReadTests \
  > "$SCRATCH/task1-green.log" 2>&1; grep -E "Test run with|passed|failed" "$SCRATCH/task1-green.log" | tail -5
```
Expected: 10 tests passed (새 7 + 기존 3).

- [ ] **Step 8: 계획 문서 체크와 결과 기록 후 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/ViewController/Bases/Utils/CachingTextDocumentProxy.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  SYKeyboardTests/Utils/CountingTextDocumentProxy.swift \
  SYKeyboardTests/Utils/CachingTextDocumentProxyTests.swift \
  SYKeyboardTests/Controller/BaseKeyboardViewControllerProxyReadTests.swift \
  docs/superpowers/plans/2026-10-08-text-proxy-read-cache.md
git commit -m "refactor: #181 - 콜백 범위 동안 프록시 값을 한 번만 읽는 CachingTextDocumentProxy 추가" \
  -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Base VC를 `textDocument`로 전환하고 콜백을 범위로 감싸기

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` (프로퍼티 L49-51 부근, `textWillChange` L393-416, `textDidChange` L418-458, `currentDocumentIdentifier` L2197-2201, 그 밖의 `textDocumentProxy.` 전체)
- Test: `SYKeyboardTests/Controller/BaseKeyboardViewControllerProxyReadTests.swift`

**Interfaces:**
- Consumes: Task 1의 `CachingTextDocumentProxy`, `CountingTextDocumentProxy`
- Produces: `BaseKeyboardViewController.textDocument: CachingTextDocumentProxy` (`final public private(set) lazy var`). Task 3이 하위 VC에서 쓴다.

- [ ] **Step 1: 콜백 테스트 작성**

`BaseKeyboardViewControllerProxyReadTests` struct 안 마지막 테스트 뒤에 추가:

```swift
    @Test("textDidChange 한 번에 같은 프록시 값을 두 번 읽지 않음")
    func testTextDidChangeReadsEachProxyValueAtMostOnce() {
        let controller = TestProxyReadViewController()
        controller.loadViewIfNeeded()
        controller.proxy.resetReadCounts()

        controller.textDidChange(nil)

        let readCounts = controller.proxy.readCounts
        #expect(readCounts.values.allSatisfy { $0 <= 1 }, "\(readCounts)")
        #expect(controller.proxy.readCount(of: "documentContextBeforeInput") == 1)
        #expect(controller.proxy.readCount(of: "keyboardType") == 1)
        #expect(controller.proxy.readCount(of: "returnKeyType") == 1)
    }

    @Test("textWillChange 한 번에 같은 프록시 값을 두 번 읽지 않음")
    func testTextWillChangeReadsEachProxyValueAtMostOnce() {
        let controller = TestProxyReadViewController()
        controller.loadViewIfNeeded()
        controller.proxy.resetReadCounts()

        controller.textWillChange(nil)

        let readCounts = controller.proxy.readCounts
        #expect(readCounts.values.allSatisfy { $0 <= 1 }, "\(readCounts)")
        #expect(controller.proxy.readCount(of: "documentContextBeforeInput") == 1)
        #expect(controller.proxy.readCount(of: "returnKeyType") == 1)
    }

    @Test("textWillChange에서 읽은 값을 textDidChange가 다시 읽음")
    func testTextDidChangeRereadsValuesReadInTextWillChange() {
        let controller = TestProxyReadViewController()
        controller.loadViewIfNeeded()
        controller.textWillChange(nil)
        controller.proxy.resetReadCounts()
        controller.proxy.beforeInput = "바뀐 문맥"

        controller.textDidChange(nil)

        #expect(controller.proxy.readCount(of: "documentContextBeforeInput") == 1)
    }

    @Test("keyboardType이 바뀐 textDidChange는 새 값으로 trait 변경 훅을 한 번 부름")
    func testKeyboardTypeChangeCallsTraitHookOnceWithNewValue() {
        let controller = TestProxyReadViewController()
        controller.loadViewIfNeeded()
        controller.textDidChange(nil)
        controller.proxy.keyboardType = .emailAddress

        controller.textDidChange(nil)

        #expect(controller.keyboardTypesAtTraitChange == [.emailAddress])
        #expect(controller.oldKeyboardType == .emailAddress)
    }
```

`TestProxyReadViewController`에 추가(`override func updateKeyboardType() {}` 아래):

```swift
    private(set) var keyboardTypesAtTraitChange: [UIKeyboardType?] = []

    override func inputTraitsDidChange() {
        keyboardTypesAtTraitChange.append(textDocumentProxy.keyboardType)
    }
```

(Step 4에서 이 줄도 `textDocument.keyboardType`으로 바꾼다. 지금은 `textDocument`가 없어 컴파일되지 않으므로 RED 단계에서는 `textDocumentProxy`로 둔다.)

- [ ] **Step 2: 테스트 실패 확인**

Run:
```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerProxyReadTests \
  > "$SCRATCH/task2-red.log" 2>&1; grep -E "✘|failed|passed" "$SCRATCH/task2-red.log" | tail -15
```
Expected: `testTextDidChangeReadsEachProxyValueAtMostOnce`, `testTextWillChangeReadsEachProxyValueAtMostOnce` FAIL(앞 문맥 2회 이상). `testTextDidChangeRereadsValuesReadInTextWillChange`는 지금도 1회 이상 읽으므로 기대값 1과 다르면 FAIL, `testKeyboardTypeChangeCallsTraitHookOnceWithNewValue`는 기존 동작 보존 확인용이라 PASS. 실제 결과를 이 step에 적는다.

- [ ] **Step 3: `textDocument` 프로퍼티 추가**

`final public lazy var oldTextContentType ...` 줄(L51) 바로 아래에 추가:

```swift
    /// 텍스트 프록시 읽기·쓰기 창구. 프록시는 이것으로만 읽고 쓴다
    final public private(set) lazy var textDocument = CachingTextDocumentProxy { [unowned self] in
        self.textDocumentProxy
    }
```

- [ ] **Step 4: 프록시 접근 치환**

주석 줄(`//`, `///`로 시작)은 건드리지 않고 코드의 `textDocumentProxy.`만 바꾼다.

```sh
F=Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
sed -i '' -E '/^[[:space:]]*\/\//!s/textDocumentProxy\./textDocument./g' "$F"
sed -i '' -E 's/keyboardTypesAtTraitChange\.append\(textDocumentProxy\.keyboardType\)/keyboardTypesAtTraitChange.append(textDocument.keyboardType)/' \
  SYKeyboardTests/Controller/BaseKeyboardViewControllerProxyReadTests.swift
```

`currentDocumentIdentifier()`(KVC 줄은 `textDocumentProxy.` 패턴이 아니라 남는다)를 아래로 바꾼다. KVC 이유 주석은 새 타입으로 옮겼으므로 지운다.

```swift
    /// 지금 입력창의 문서 식별자. 키보드가 처음 뜰 때나 입력창이 바뀌는 순간 nil일 수 있다
    func currentDocumentIdentifier() -> UUID? {
        return textDocument.documentIdentifier
    }
```

확인: `grep -n "textDocumentProxy" "$F"` 결과가 주석 줄과 Step 3의 `self.textDocumentProxy` 한 줄뿐이어야 한다.

- [ ] **Step 5: 콜백 본문을 범위로 감싸기**

`textWillChange`:

```swift
    open override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        logger.debug("textWillChange")
        // 콜백 한 번에 같은 프록시 값을 다시 읽지 않는다. 문서 상태 교체와 겹친 읽기는 크래시한다
        textDocument.withReadCaching {
            let inputIdentifier = textInputIdentifier(for: textInput)
            if let inputIdentifier,
               inputIdentifier != lastNotifiedTextInputIdentifier {
                lastNotifiedTextInputIdentifier = inputIdentifier
                textInputDidChange(textInput)
            }
            synchronizeTextInputTraits()
            synchronizeDeleteInteractionInputIdentifier(textInput)
            undoRedoSession.prepareForTextWillChange(
                inputIdentifier: textInputIdentifier(for: textInput),
                context: currentTextContextSnapshot()
            )
            pendingSentTextSnapshot = makeSentTextSnapshot()
            resetInputBuffer()
            updateKeyboardType()
            updateReturnButtonType()
            updateReturnButtonEnabled()
            updateSuggestionBarHidden()
            closeClipboardPanelIfNeeded()
            synchronizeClipboardHistoryIfNeeded()
        }
    }
```

`textDidChange`:

```swift
    open override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
        logger.debug("textDidChange")
        // 보류된 삭제를 이어 가며 프록시에 쓰면 캐시가 비워져 그 뒤 읽기는 삭제가 반영된 값을 본다
        textDocument.withReadCaching {
            synchronizeTextInputTraits()
            synchronizeDeleteInteractionInputIdentifier(textInput)
            // `textWillChange`에서 떠 둔 스냅샷과 지금 문맥을 비교해 전송으로 비워졌으면 기록한다
            recordSentTextIfNeeded()
            let currentTextContext = currentTextContextSnapshot()
            if KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(
                isPrimaryCursorDragging: isPrimaryCursorDragging,
                pendingRequestContext: pendingCursorDragHapticContext,
                currentContext: currentTextContext
            ) {
                FeedbackManager.shared.playHaptic(isForcing: true)
            }
            pendingCursorDragHapticContext = nil
            let deleteMutationOutcome = deleteMutationLifecycle.completeAfterTextChange(
                currentContext: currentTextContext,
                currentSelectedText: textDocument.selectedText
            )
            processDeleteMutationCallbackOutcome(deleteMutationOutcome)
            resumePendingDeletePanBoundaryIfNeeded()
            invalidateUndoRedoHistoryIfNeededAfterTextChange(textInput)
            updateKeyboardType()
            // iOS는 키보드 확장에 textWillChange/textDidChange의 textInput을 항상 nil로 준다.
            // 그래서 필드 객체 동일성으로는 포커스가 다른 필드로 옮겨졌는지 알 수 없다.
            // keyboardType/textContentType 변화를 대신 신호로 써서 언어 재판정 같은 훅을 부른다
            let inputTraitsDidChange = textDocument.keyboardType != oldKeyboardType
                || textDocument.textContentType != oldTextContentType
            oldKeyboardType = textDocument.keyboardType
            oldTextContentType = textDocument.textContentType
            if inputTraitsDidChange { self.inputTraitsDidChange() }
            updateReturnButtonType()
            updateReturnButtonEnabled()
            updateSuggestionBarHidden()
            if KeyboardSuggestionSelectionPolicy.shouldUpdateSuggestionsOnTextDidChange(
                isPrimaryCursorDragging: isPrimaryCursorDragging
            ) {
                updateSuggestions()
            }
        }
    }
```

본문은 기존과 같고 `textDocumentProxy` → `textDocument`와 들여쓰기만 바뀐다. `git diff -w`로 들여쓰기 외 차이가 위 두 가지뿐인지 확인한다.

- [ ] **Step 6: 테스트 통과 확인**

Step 2와 같은 명령(`task2-green.log`). Expected: 7 tests passed. 이어서 삭제·조합·undo 회귀를 좁게 확인:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerTextInputTests \
  -only-testing:SYKeyboardTests/DeleteMutationLifecycleTests \
  -only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests \
  > "$SCRATCH/task2-regression.log" 2>&1; grep -E "Test run with" "$SCRATCH/task2-regression.log"
```
Expected: 모두 통과. 개수를 이 step에 적는다.

- [ ] **Step 7: 계획 문서 체크와 결과 기록 후 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboardTests/Controller/BaseKeyboardViewControllerProxyReadTests.swift \
  docs/superpowers/plans/2026-10-08-text-proxy-read-cache.md
git commit -m "refactor: #181 - 텍스트 변경 콜백에서 Base VC가 같은 프록시 값을 한 번만 읽도록 변경" \
  -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: 하위 VC 전환과 `super` 뒤 읽기 범위

**Files:**
- Modify: `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardCoreViewController.swift` (`textWillChange` L51-54, `updateKeyboardType` L67~, `updateShiftButton` L150-158)
- Modify: `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift` (`updateKeyboardType` L80~)
- Modify: `Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift` (`inputTraitsDidChange` L126-145, `textWillChange` L147-158, `updateKeyboardType` L175-198, 진단 로그 L492-494, `updateEnglishShiftButton` L604-612)
- Create: `SYKeyboardTests/Controller/EnglishKeyboardCoreViewControllerProxyReadTests.swift`

**Interfaces:**
- Consumes: Task 2의 `textDocument`, Task 1의 `CountingTextDocumentProxy`
- Produces: 없음

- [ ] **Step 1: 영문 VC 테스트 작성**

```swift
//
//  EnglishKeyboardCoreViewControllerProxyReadTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import EnglishKeyboardCore
@testable import SYKeyboardCore

/// 하위 VC가 `super.textWillChange` 뒤에서 읽는 값도 같은 콜백 범위에서 한 번만 읽는지 확인한다
@Suite("EnglishKeyboardCoreViewController 텍스트 프록시 읽기", .sharedUserDefaults)
@MainActor
struct EnglishKeyboardCoreViewControllerProxyReadTests {

    @Test("textWillChange는 shift 자동 대문자 판정까지 같은 프록시 값을 한 번만 읽음")
    func testTextWillChangeReadsShiftContextOnce() {
        let controller = TestEnglishProxyReadViewController()
        controller.loadViewIfNeeded()
        controller.proxy.resetReadCounts()

        controller.textWillChange(nil)

        #expect(controller.proxy.readCount(of: "autocapitalizationType") == 1)
        #expect(controller.proxy.readCount(of: "documentContextBeforeInput") == 1)
    }
}

// MARK: - Test Helpers

@MainActor
private final class TestEnglishProxyReadViewController: EnglishKeyboardCoreViewController {
    let proxy = CountingTextDocumentProxy()

    override var textDocumentProxy: any UITextDocumentProxy {
        proxy
    }
}
```

- [ ] **Step 2: 테스트 실패 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/EnglishKeyboardCoreViewControllerProxyReadTests \
  > "$SCRATCH/task3-red.log" 2>&1; grep -E "✘|failed|passed|error:" "$SCRATCH/task3-red.log" | tail -10
```
Expected: `documentContextBeforeInput` 2회로 FAIL. 테스트에서 VC를 띄우지 못해(XIB 로드 등) 크래시·실패하면 이 테스트 파일을 지우고, 이 step에 원인과 "Task 5 커서 이동 확인으로 대신함"을 적은 뒤 Step 4로 간다.

- [ ] **Step 3: 하위 VC 3개 치환과 범위 적용**

```sh
for F in Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardCoreViewController.swift \
         Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift \
         Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift; do
  sed -i '' -E '/^[[:space:]]*\/\//!s/textDocumentProxy\./textDocument./g' "$F"
done
```

영문 `textWillChange`:

```swift
    open override func textWillChange(_ textInput: (any UITextInput)?) {
        // shift 자동 대문자 판정도 Base 콜백과 같은 범위에서 읽어 같은 값을 다시 읽지 않는다
        textDocument.withReadCaching {
            super.textWillChange(textInput)
            updateShiftButton()
        }
    }
```

한영 `textWillChange`:

```swift
    override func textWillChange(_ textInput: (any UITextInput)?) {
        // 영어 모드의 shift 자동 대문자 판정도 Base 콜백과 같은 범위에서 읽는다
        textDocument.withReadCaching {
            super.textWillChange(textInput)

            switch modeCoordinator.currentMode {
            case .hangeul:
                hangeulAdapter.clearForExternalTextChange()
                updateHangeulSpaceButton()
                updateHangeulShiftButton()
            case .english:
                updateEnglishShiftButton()
            }
        }
    }
```

한글 `textWillChange`는 `super` 뒤에서 프록시를 읽지 않으므로 바꾸지 않는다. 한영 `inputTraitsDidChange`는 Base `textDidChange` 범위 안에서 불리므로 치환만 한다.

확인:
```sh
grep -rn "textDocumentProxy\." Modules Keyboards | grep -v -E ":[0-9]+:[[:space:]]*//"
```
Expected: 출력 없음.

- [ ] **Step 4: 테스트 통과와 extension 빌드 확인**

Step 2 명령(`task3-green.log`). Expected: 1 test passed(Step 2에서 뺐다면 생략). 한영 VC는 테스트 타깃에서 import할 수 없으므로 빌드로 확인:

```sh
for S in HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build -project SYKeyboard.xcodeproj -scheme "$S" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
    > "$SCRATCH/task3-build-$S.log" 2>&1; echo "$S: $(tail -1 "$SCRATCH/task3-build-$S.log")"
done
git status --short
```
Expected: 세 scheme 모두 `** BUILD SUCCEEDED **`. `.xcscheme`이 `RemotePath`만 바뀌었으면 되돌린다.

- [ ] **Step 5: 계획 문서 체크와 결과 기록 후 커밋**

```sh
git add Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardCoreViewController.swift \
  Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift \
  Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift \
  SYKeyboardTests/Controller/EnglishKeyboardCoreViewControllerProxyReadTests.swift \
  docs/superpowers/plans/2026-10-08-text-proxy-read-cache.md
git commit -m "refactor: #181 - 하위 키보드 VC도 텍스트 프록시를 textDocument로 읽고 쓰도록 변경" \
  -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: 프록시 접근 규칙 문서화와 전체 회귀 확인

**Files:**
- Modify: `CLAUDE.md` (아키텍처 절, `**저장소**` 문단 뒤)

- [ ] **Step 1: CLAUDE.md 규칙 추가**

`CLAUDE.md` `## 아키텍처`의 `**저장소**:` 문단 끝(`extension 프로세스 로컬 상태는 ...에 둔다.`) 다음 빈 줄 뒤에 추가:

```markdown
**텍스트 프록시는 `textDocument`(`CachingTextDocumentProxy`)로만 읽고 쓴다.**
`textWillChange`/`textDidChange`는 `withReadCaching`으로 같은 값을 한 번만 읽고, 쓰기 메서드가 캐시를 비워
쓰기 뒤에는 새 값을 읽는다. `textDocumentProxy.insertText` 등을 직접 부르면 그 쓰기는 캐시를 비우지 않는다.
하위 VC가 `super.textWillChange` 뒤에서 프록시를 읽으면 오버라이드 본문도 `withReadCaching`으로 감싼다.
확인: `grep -rn "textDocumentProxy\." Modules Keyboards | grep -v -E ":[0-9]+:[[:space:]]*//"` 결과가 없어야 한다.
```

`.github/copilot-instructions.md`에는 프록시 관련 규칙이 없어 바꾸지 않는다(작성 시점 확인).

- [ ] **Step 2: 전체 테스트**

사용자에게 전체 테스트를 시작한다고 알린 뒤 실행한다. 붙여넣기 알림 위험을 줄이려 병렬을 끈다.

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  > "$SCRATCH/task4-full.log" 2>&1; grep -E "Test run with|TEST (SUCCEEDED|FAILED)" "$SCRATCH/task4-full.log"
```
Expected: `TEST SUCCEEDED`. 테스트 개수와 `.xcresult` 경로(`grep -m1 "xcresult" "$SCRATCH/task4-full.log"`)를 이 step에 적는다.

- [ ] **Step 3: 계획 문서 체크와 결과 기록 후 커밋**

```sh
git add CLAUDE.md docs/superpowers/plans/2026-10-08-text-proxy-read-cache.md
git commit -m "docs: #181 - 텍스트 프록시 접근 창구 규칙을 CLAUDE.md에 추가" \
  -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: 시뮬레이터 확인 (iPhone 13 mini / iOS 18.6)

**Files:**
- Modify: `docs/superpowers/plans/2026-10-08-text-proxy-read-cache.md` (결과 기록)
- Scratch only: `$SCRATCH/proxy-check/index.html`

시뮬레이터에서 통과한 항목은 PR·이슈에 "시뮬레이터 확인으로 대신함"으로 적는다. idb 주의점은 메모리 `reference-idb-simulator-quirks`를 따른다(우리 키보드 키는 캡처 좌표로 누른다, 포인트 = px × 0.3472, 맨 아래 줄은 y=695~700pt).

- [ ] **Step 1: 준비**

```sh
UDID=$(xcrun simctl list devices booted | grep "iPhone 13 mini" | grep -oE "[0-9A-F-]{36}")
xcrun simctl spawn "$UDID" defaults read -g AppleKeyboards > "$SCRATCH/apple-keyboards-backup.txt"
cat "$SCRATCH/apple-keyboards-backup.txt"
```
앱을 설치한다(`xcodebuild build -scheme SYKeyboard ...` 뒤 `xcrun simctl install "$UDID" <DerivedData>/SYKeyboard.app`, 경로는 빌드 로그의 `Touch`/`CodeSign` 줄에서 확인). 클립보드 기록 설정이 켜져 있으면 붙여넣기 알림이 뜰 수 있으니 확인에 앞서 끈다.

`$SCRATCH/proxy-check/index.html`:

```html
<!doctype html>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>input, textarea { display: block; width: 90%; font-size: 20px; margin: 10px; }</style>
<input id="text" placeholder="일반">
<input id="tel" type="tel" placeholder="전화">
<input id="email" type="email" placeholder="이메일">
<input id="search" type="search" placeholder="검색">
<textarea id="multi" rows="5"></textarea>
```

```sh
cd "$SCRATCH/proxy-check" && python3 -m http.server 8765 --bind 127.0.0.1   # run_in_background
xcrun simctl openurl "$UDID" "http://127.0.0.1:8765/index.html"
```

키보드 전환: `AppleKeyboards` 배열에서 대상 키보드(백업에 나온 우리 키보드 식별자)를 맨 앞에 둔 배열로 `defaults write -g AppleKeyboards -array ...` 후 `xcrun simctl terminate "$UDID" com.apple.mobilesafari` → 페이지 다시 열기.

- [ ] **Step 2: 필드 전환(한글·영문·한영)**

각 키보드로 일반 → 전화 → 이메일 입력창을 차례로 탭하고 매번 `xcrun simctl io "$UDID" screenshot "$SCRATCH/field-<키보드>-<필드>.png"`로 캡처해 확인한다.
- 전화: 숫자 패드(tenkey)로 바뀐다.
- 이메일: 이메일 자판(@ 키)으로 바뀐다. 한영은 한글 모드에서 이메일 입력창으로 가면 영어로 자동 전환된다.
- 다시 일반 입력창: 원래 자판으로 돌아온다.

- [ ] **Step 3: 커서 이동(한글·영문)**

- 한글: 일반 입력창에 `안녕 하세요`를 친 뒤 `안녕` 중간을 탭해 커서를 옮긴다. 후보 바가 커서 앞 단어 기준으로 바뀌는지 캡처로 확인한다.
- 영문: `hello. ` 입력 뒤 shift가 켜지는지(문장 시작 자동 대문자), `hello`의 중간을 탭하면 shift가 꺼지는지 확인한다.

- [ ] **Step 4: 리턴 버튼 자동 활성(한글)**

검색 입력창에서 비어 있을 때 리턴 키가 비활성, 글자를 입력하면 활성이 되는지 확인한다. 웹 검색창이 리턴 키 자동 활성을 켜지 않으면 설정 앱 검색창(`xcrun simctl launch "$UDID" com.apple.Preferences`)으로 다시 본다. 둘 다 안 되면 "확인하지 못함 — 리턴 키 자동 활성 입력창을 찾지 못함, 근거는 `KeyboardPresentationStatePolicyTests`와 Task 2 읽기 횟수 테스트뿐"으로 적는다.

- [ ] **Step 5: 삭제 이어 가기(한글)**

`textarea`에 `첫째 줄`, 리턴, `둘째 줄`을 입력한다. 삭제 키 좌표에서 왼쪽으로 길게 끈다(`idb ui swipe --duration 2.0 <x> <y> <x-150> <y>`). `둘째 줄`을 지운 뒤 줄바꿈을 넘어 `첫째 줄`까지 이어서 지워지는지 캡처로 확인한다.

- [ ] **Step 6: 전송 기록(한글)**

메시지 앱 기본 더미 대화(`+1 (888) 555-1212`)를 연다. 사용자에게 입력창 탭을 요청하고, 키보드로 드문 조합 `ㅌㅊㅋ`를 친 뒤 전송 버튼 클릭을 요청한다. 키보드를 닫아 저장시킨 뒤 확인:

```sh
NGRAM=$(find ~/Library/Developer/CoreSimulator/Devices/$UDID/data/Containers/Shared/AppGroup -name "ngram_ko-KR.plist" | head -1)
plutil -p "$NGRAM" | grep "ㅌㅊㅋ"
```
`ㅌㅊㅋ`가 나오면 통과. 확인 전에 같은 명령으로 기존 기록이 없는지 먼저 본다.

- [ ] **Step 7: 정리와 결과 기록 후 커밋**

`AppleKeyboards`를 백업 배열로 되돌리고, 끈 설정을 원래대로 돌리고, http 서버를 끈다. 항목별 통과·미확인과 캡처 경로를 이 Task에 적는다.

```sh
git add docs/superpowers/plans/2026-10-08-text-proxy-read-cache.md
git commit -m "docs: #181 - 시뮬레이터 확인 결과 기록" \
  -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
