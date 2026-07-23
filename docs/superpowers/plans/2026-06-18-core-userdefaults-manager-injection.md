# Core UserDefaults Manager Injection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `SYKeyboardCore.UserDefaultsManager`도 `AppUserDefaultsManager`처럼 테스트용 `UserDefaults`를 주입할 수 있게 만든다.

**Architecture:** `UserDefaultsManager`의 `storage`를 init에서 주입받도록 바꾸고, property wrapper 내부의 고정 App Group storage를 제거한다. Wrapper 기반 프로퍼티는 backing wrapper를 `init(storage:)`에서 초기화해 모든 getter/setter가 같은 injected storage를 보게 한다.

**Tech Stack:** Swift 5, Swift property wrapper, Swift Testing, Xcode `xcodebuild test`

---

### Task 1: 주입 저장소가 wrapper 기반 프로퍼티에 쓰이는지 실패 테스트 추가

**Files:**
- Create: `SYKeyboardTests/Storage/UserDefaultsManagerInjectionTests.swift`
- Modify: 없음
- Test: `SYKeyboardTests/Storage/UserDefaultsManagerInjectionTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
//
//  UserDefaultsManagerInjectionTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/18/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("UserDefaultsManager storage injection")
struct UserDefaultsManagerInjectionTests {

    @Test("wrapper 기반 Bool 프로퍼티가 주입된 storage를 사용한다")
    func testWrapperBackedBoolUsesInjectedStorage() {
        let storage = makeStorage(name: "bool")
        let manager = UserDefaultsManager(storage: storage)

        #expect(manager.isSoundFeedbackEnabled == DefaultValues.isSoundFeedbackEnabled)

        manager.isSoundFeedbackEnabled = false

        #expect(storage.object(forKey: UserDefaultsKeys.isSoundFeedbackEnabled) as? Bool == false)

        storage.set(true, forKey: UserDefaultsKeys.isSoundFeedbackEnabled)

        #expect(manager.isSoundFeedbackEnabled == true)
    }

    @Test("RawRepresentable wrapper 프로퍼티가 주입된 storage를 사용한다")
    func testRawRepresentableWrapperUsesInjectedStorage() {
        let storage = makeStorage(name: "raw")
        let manager = UserDefaultsManager(storage: storage)

        #expect(manager.lastOneHandedMode == DefaultValues.lastOneHandedMode)

        manager.lastOneHandedMode = .left

        #expect(storage.object(forKey: UserDefaultsKeys.lastOneHandedMode) as? Int == OneHandedMode.left.rawValue)

        storage.set(OneHandedMode.right.rawValue, forKey: UserDefaultsKeys.lastOneHandedMode)

        #expect(manager.lastOneHandedMode == .right)
    }

    @Test("직접 storage를 읽는 프로퍼티도 주입된 storage를 사용한다")
    func testDirectStoragePropertyUsesInjectedStorage() {
        let storage = makeStorage(name: "direct")
        let manager = UserDefaultsManager(storage: storage)

        #expect(manager.selectedLongPressAction == DefaultValues.selectedLongPressAction)

        manager.selectedLongPressAction = .numberInput

        #expect(storage.object(forKey: UserDefaultsKeys.selectedLongPressAction) as? Int == LongPressAction.numberInput.rawValue)

        storage.set(LongPressAction.disabled.rawValue, forKey: UserDefaultsKeys.selectedLongPressAction)

        #expect(manager.selectedLongPressAction == .disabled)
    }

    private func makeStorage(name: String) -> UserDefaults {
        let suiteName = "UserDefaultsManagerInjectionTests.\(name).\(UUID().uuidString)"
        let storage = UserDefaults(suiteName: suiteName)!
        storage.removePersistentDomain(forName: suiteName)
        return storage
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/UserDefaultsManagerInjectionTests
```

Expected: FAIL at compile time with `argument passed to call that takes no arguments` for `UserDefaultsManager(storage:)`.

### Task 2: Wrapper가 storage를 init으로 받게 변경

**Files:**
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift`
- Test: `SYKeyboardTests/Storage/UserDefaultsManagerInjectionTests.swift`

- [ ] **Step 1: Update `UserDefaultsWrapper`**

Replace the current fixed-storage wrapper with:

```swift
@propertyWrapper
public struct UserDefaultsWrapper<T: Codable> {

    // MARK: Properties

    /// 데이터를 저장할 `UserDefaults`
    private let storage: UserDefaults

    /// 값을 저장할 키값
    private let key: String
    /// 기본값
    private let defaultValue: T

    public var wrappedValue: T {
        get { storage.object(forKey: key) as? T ?? defaultValue }
        set { storage.set(newValue, forKey: key) }
    }

    // MARK: Initializer

    init(
        storage: UserDefaults = UserDefaultsManager.defaultStorage,
        key: String,
        defaultValue: T
    ) {
        self.storage = storage
        self.key = key
        self.defaultValue = defaultValue
    }
}
```

- [ ] **Step 2: Update `UserDefaultsRawRepresentableWrapper`**

Replace the current fixed-storage wrapper with:

```swift
@propertyWrapper
public struct UserDefaultsRawRepresentableWrapper<T: RawRepresentable> {

    // MARK: Properties

    /// 데이터를 저장할 `UserDefaults`
    private let storage: UserDefaults
    /// 값을 저장할 키값
    private let key: String
    /// 기본값
    private let defaultValue: T

    public var wrappedValue: T {
        get {
            guard let rawValue = storage.object(forKey: key) as? T.RawValue,
                  let value = T(rawValue: rawValue) else {
                return defaultValue
            }
            return value
        }
        set {
            storage.set(newValue.rawValue, forKey: key)
        }
    }

    // MARK: Initializer

    init(
        storage: UserDefaults = UserDefaultsManager.defaultStorage,
        key: String,
        defaultValue: T
    ) {
        self.storage = storage
        self.key = key
        self.defaultValue = defaultValue
    }
}
```

- [ ] **Step 3: Run test and keep expected failure**

Run the same focused test command.

Expected: still FAIL because `UserDefaultsManager(storage:)` and backing wrapper initialization are not implemented yet.

### Task 3: `UserDefaultsManager`에 주입 가능한 init 추가

**Files:**
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift`
- Test: `SYKeyboardTests/Storage/UserDefaultsManagerInjectionTests.swift`

- [ ] **Step 1: Replace storage and singleton initializer section**

Replace:

```swift
/// 데이터를 저장할 `UserDefaults`
public let storage: UserDefaults = UserDefaults(suiteName: DefaultValues.groupBundleID)!

// MARK: Singleton Initializer

public static let shared = UserDefaultsManager()
private init() {}
```

with:

```swift
/// 데이터를 저장할 `UserDefaults`
public let storage: UserDefaults

// MARK: Singleton Initializer

public static let shared = UserDefaultsManager()

init(storage: UserDefaults = UserDefaultsManager.defaultStorage) {
    self.storage = storage

    _isSoundFeedbackEnabled = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.isSoundFeedbackEnabled,
        defaultValue: DefaultValues.isSoundFeedbackEnabled
    )
    _isHapticFeedbackEnabled = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.isHapticFeedbackEnabled,
        defaultValue: DefaultValues.isHapticFeedbackEnabled
    )
    _isTextReplacementEnabled = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.isTextReplacementEnabled,
        defaultValue: DefaultValues.isTextReplacementEnabled
    )
    _isPredictiveTextEnabled = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.isPredictiveTextEnabled,
        defaultValue: DefaultValues.isPredictiveTextEnabled
    )
    _isUndoRedoEnabled = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.isUndoRedoEnabled,
        defaultValue: DefaultValues.isUndoRedoEnabled
    )
    _isDragToMoveCursorEnabled = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.isDragToMoveCursorEnabled,
        defaultValue: DefaultValues.isDragToMoveCursorEnabled
    )
    _isPeriodShortcutEnabled = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.isPeriodShortcutEnabled,
        defaultValue: DefaultValues.isPeriodShortcutEnabled
    )
    _isAutoChangeToPrimaryEnabled = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.isAutoChangeToPrimaryEnabled,
        defaultValue: DefaultValues.isAutoChangeToPrimaryEnabled
    )
    _longPressDuration = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.longPressDuration,
        defaultValue: DefaultValues.longPressDuration
    )
    _repeatRate = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.repeatRate,
        defaultValue: DefaultValues.repeatRate
    )
    _cursorActiveDistance = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.cursorActiveDistance,
        defaultValue: DefaultValues.cursorActiveDistance
    )
    _cursorMoveInterval = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.cursorMoveInterval,
        defaultValue: DefaultValues.cursorMoveInterval
    )
    _keyboardHeight = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.keyboardHeight,
        defaultValue: DefaultValues.keyboardHeight
    )
    _isNumericKeypadEnabled = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.isNumericKeypadEnabled,
        defaultValue: DefaultValues.isNumericKeypadEnabled
    )
    _isOneHandedKeyboardEnabled = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.isOneHandedKeyboardEnabled,
        defaultValue: DefaultValues.isOneHandedKeyboardEnabled
    )
    _oneHandedKeyboardWidth = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.oneHandedKeyboardWidth,
        defaultValue: DefaultValues.oneHandedKeyboardWidth
    )
    _needsInputModeSwitchKey = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.needsInputModeSwitchKey,
        defaultValue: DefaultValues.needsInputModeSwitchKey
    )
    _lastOneHandedMode = UserDefaultsRawRepresentableWrapper(
        storage: storage,
        key: UserDefaultsKeys.lastOneHandedMode,
        defaultValue: DefaultValues.lastOneHandedMode
    )
    _isRequestFullAccessOverlayClosed = UserDefaultsWrapper(
        storage: storage,
        key: UserDefaultsKeys.isRequestFullAccessOverlayClosed,
        defaultValue: DefaultValues.isRequestFullAccessOverlayClosed
    )
}
```

- [ ] **Step 2: Add default storage helper**

Add at the end of the file:

```swift
extension UserDefaultsManager {
    static let defaultStorage: UserDefaults = {
        guard let userDefaults = UserDefaults(suiteName: DefaultValues.groupBundleID) else {
            fatalError("UserDefaults를 suiteName으로 불러오는 데 실패했습니다.")
        }
        return userDefaults
    }()
}
```

- [ ] **Step 3: Run focused test to verify it passes**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/UserDefaultsManagerInjectionTests
```

Expected: `TEST SUCCEEDED`.

### Task 4: 기존 UserDefaults 계약 테스트와 키보드 빌드 검증

**Files:**
- Modify: 없음
- Test: `SYKeyboardTests/Storage/UserDefaultsContractTests.swift`, `SYKeyboardTests/Storage/UserDefaultsManagerInjectionTests.swift`

- [ ] **Step 1: Run storage-focused tests**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/UserDefaultsContractTests \
  -only-testing:SYKeyboardTests/UserDefaultsManagerInjectionTests
```

Expected: `TEST SUCCEEDED`.

- [ ] **Step 2: Run full app test**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: `TEST SUCCEEDED`.

- [ ] **Step 3: Build keyboard extensions**

Run:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'

xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: both commands end with `BUILD SUCCEEDED`.

- [ ] **Step 4: Commit**

```sh
git add Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift SYKeyboardTests/Storage/UserDefaultsManagerInjectionTests.swift
git commit -m "refactor: UserDefaultsManager 저장소 주입 지원"
```

### Self-Review

- Spec coverage: Core manager와 wrapper 모두 주입 storage를 사용하도록 하는 작업이 Task 1-3에 포함됐다. 기존 shared App Group storage 유지와 테스트/빌드 검증은 Task 4에 포함됐다.
- Placeholder scan: 계획에 `TBD`, `TODO`, `implement later`, `appropriate` 같은 미정 표현은 없다.
- Type consistency: 테스트의 `UserDefaultsManager(storage:)`, `OneHandedMode`, `LongPressAction`, `UserDefaultsKeys`, `DefaultValues` 이름은 현재 코드와 일치한다.
