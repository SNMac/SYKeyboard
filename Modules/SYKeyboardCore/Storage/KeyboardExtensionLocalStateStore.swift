//
//  KeyboardExtensionLocalStateStore.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/18/26.
//

import Foundation

/// Keyboard extension별 local 상태 저장소
final public class KeyboardExtensionLocalStateStore {

    // MARK: - Properties

    private let storage: UserDefaults
    private let key: String

    public var isClosed: Bool {
        get {
            storage.object(forKey: key) as? Bool ?? DefaultValues.isRequestFullAccessOverlayClosed
        }
        set {
            storage.set(newValue, forKey: key)
        }
    }

    // MARK: - Initializer

    public init(
        storage: UserDefaults = .standard,
        key: String = UserDefaultsKeys.isRequestFullAccessOverlayClosed
    ) {
        self.storage = storage
        self.key = key
    }
}
