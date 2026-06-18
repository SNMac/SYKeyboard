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
