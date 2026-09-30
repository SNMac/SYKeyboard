//
//  KeyboardLanguageModePolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 8/13/26.
//

import UIKit

public enum KeyboardLanguageModePolicy {

    /// 라틴 문자 입력을 요구하는 것이 확실한 `UITextContentType`
    private static let latinTextContentTypes: Set<UITextContentType> = [
        .emailAddress,
        .URL,
        .username,
        .password,
        .newPassword,
        .oneTimeCode,
        .creditCardNumber
    ]

    /// 텍스트 필드가 라틴 문자 입력을 요구하는지 판단합니다.
    ///
    /// 텍스트 필드가 기대하는 언어를 알려주는 공개 API는 없습니다.
    /// 입력 trait로 확실하게 알 수 있는 것은 "이 필드는 ASCII를 원한다" 뿐이므로,
    /// 한글 여부는 추측하지 않고 라틴 입력이 필요한 경우만 가려냅니다.
    ///
    /// 숫자 전용 키보드 타입은 글자를 입력하지 않으므로 대상에서 제외합니다.
    /// `webSearch`, `twitter`, `namePhonePad`는 한글 입력이 자연스러운 경우가 있어 제외합니다.
    public static func requiresLatinInput(
        keyboardType: UIKeyboardType?,
        textContentType: UITextContentType?
    ) -> Bool {
        switch keyboardType {
        case .asciiCapable, .asciiCapableNumberPad, .emailAddress, .URL:
            return true
        default:
            break
        }

        guard let textContentType else { return false }
        return latinTextContentTypes.contains(textContentType)
    }

    /// 새 텍스트 필드에서 시작할 언어를 결정합니다.
    ///
    /// - Parameters:
    ///   - requiresLatinInput: 필드가 라틴 문자 입력을 요구하는지 여부
    ///   - lastMode: 마지막으로 사용한 언어. 저장값이 없으면 `nil`
    ///   - preferredLanguages: OS 언어 설정(`Locale.preferredLanguages`)
    public static func initialMode(
        requiresLatinInput: Bool,
        lastMode: HangeulEnglishLanguageMode?,
        preferredLanguages: [String]
    ) -> HangeulEnglishLanguageMode {
        if requiresLatinInput { return .english }
        if let lastMode { return lastMode }

        return mode(forPreferredLanguages: preferredLanguages)
    }

    /// OS 언어 설정에서 시작 언어를 고릅니다.
    ///
    /// 앞선 언어부터 확인해 한국어면 한글, 영어면 영어로 시작합니다.
    /// 목록에 한국어도 영어도 없으면 한글로 시작합니다.
    public static func mode(forPreferredLanguages languages: [String]) -> HangeulEnglishLanguageMode {
        for language in languages {
            switch language.split(separator: "-").first?.lowercased() {
            case "ko":
                return .hangeul
            case "en":
                return .english
            default:
                continue
            }
        }

        return .hangeul
    }

    /// 언어 전환 후 문자 키보드로 돌아갈지 판단합니다.
    /// - Parameters:
    ///   - isManualSwitch: 사용자가 한영 전환 버튼을 직접 누른 경우 `true`
    ///   - currentKeyboard: 전환 시점에 표시 중인 키보드
    ///
    /// 사용자가 직접 누른 전환은 항상 문자 키보드로 돌아가고,
    /// 텍스트 컨텍스트 변경으로 인한 자동 전환은 현재 숫자·기호 화면을 유지합니다.
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
