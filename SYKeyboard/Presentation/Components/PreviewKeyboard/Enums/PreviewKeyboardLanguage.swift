//
//  PreviewKeyboardLanguage.swift
//  SYKeyboard
//
//  Created by 서동환 on 11/30/25.
//

enum PreviewKeyboardLanguage: Int, CaseIterable {
    case hangeul
    case english
    
    var displayStr: String {
        switch self {
        case .hangeul:
            String(localized: "한글 키보드")
        case .english:
            String(localized: "영어 키보드")
        }
    }
}
