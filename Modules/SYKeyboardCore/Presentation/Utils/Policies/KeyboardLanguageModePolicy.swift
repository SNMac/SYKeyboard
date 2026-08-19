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

    /// 언어 전환 후 문자 키보드로 돌아갈지 판단한다.
    /// - Parameters:
    ///   - isManualSwitch: 사용자가 한영 전환 버튼을 직접 누른 경우 `true`
    ///   - currentKeyboard: 전환 시점에 표시 중인 키보드
    /// 사용자가 직접 누른 전환은 항상 문자 키보드로 돌아가고,
    /// 텍스트 컨텍스트 변경으로 인한 자동 전환은 현재 숫자·기호 화면을 유지한다.
    public static func shouldReturnToPrimaryKeyboard(
        isManualSwitch: Bool,
        currentKeyboard: SYKeyboardType
    ) -> Bool {
        if isManualSwitch { return true }

        switch currentKeyboard {
        case .symbol, .numeric, .tenKey:
            return false
        case .naratgeul, .cheonjiin, .dubeolsik, .qwerty:
            return true
        }
    }
}
