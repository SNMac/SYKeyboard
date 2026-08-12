//
//  KeyboardLanguageModePolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 8/13/26.
//

import Foundation

public enum KeyboardLanguageModePolicy {
    public static func initialMode(
        documentPrimaryLanguage: String?,
        lastMode: HangeulEnglishLanguageMode?
    ) -> HangeulEnglishLanguageMode {
        let language = documentPrimaryLanguage?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if language == "ko" || language?.hasPrefix("ko-") == true {
            return .hangeul
        }

        if language == "en" || language?.hasPrefix("en-") == true {
            return .english
        }

        return lastMode ?? .hangeul
    }
}
