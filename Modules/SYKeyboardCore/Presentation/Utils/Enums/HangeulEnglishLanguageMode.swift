//
//  HangeulEnglishLanguageMode.swift
//  SYKeyboardCore
//
//  Created by Codex on 8/13/26.
//

public enum HangeulEnglishLanguageMode: String, Codable, Equatable {
    case hangeul
    case english

    public var languageIdentifier: String {
        switch self {
        case .hangeul:
            return "ko-KR"
        case .english:
            return "en-US"
        }
    }
}
