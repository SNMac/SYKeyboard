//
//  KeyboardExtensionAvailability.swift
//  SYKeyboard
//
//  Created by Codex on 6/19/26.
//

import Foundation

enum KeyboardExtensionAvailability {

    // MARK: - Properties

    private static let appleKeyboardsKey = "AppleKeyboards"

    // MARK: - Internal Methods

    /// 사용자의 "AppleKeyboards" 설정에 현재 앱의 키보드 확장이 포함되어 있는지 여부를 반환하는 메서드
    static func isEnabled(userDefaults: UserDefaults = .standard,
                          bundleIdentifier: String? = Bundle.main.bundleIdentifier) -> Bool {
        guard let keyboards = userDefaults.array(forKey: appleKeyboardsKey) as? [String] else {
            return false
        }

        let keyboardExtensionBundleIDPrefix = (bundleIdentifier ?? "Unknown Bundle") + "."
        return keyboards.contains { $0.hasPrefix(keyboardExtensionBundleIDPrefix) }
    }
}
