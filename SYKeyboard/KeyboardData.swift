//
//  KeyLayoutInfo.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/30/24.
//

import Foundation

struct KeyboardData: Identifiable, Hashable {
    var id: UUID = UUID()
    var buttonText: String
    var buttonImage: String?
    var keyTexts: [String]
    var isFunctionKey: Bool = false
    var isDeleteKey: Bool = false
    var isNumKey: Bool = false
    var isLangKey: Bool = false
}

extension KeyboardData {
    static let list: [KeyboardData] = [
        KeyboardData(buttonText: "ㄱ", keyTexts: ["ㄱ"]),
        KeyboardData(buttonText: "ㄴ", keyTexts: ["ㄴ"]),
        KeyboardData(buttonText: "ㅏㅓ", keyTexts: ["ㅏ", "ㅓ"]),
        KeyboardData(buttonText: "", buttonImage: "delete.left", keyTexts: [""], isFunctionKey: true, isDeleteKey: false),
        KeyboardData(buttonText: "ㄹ", keyTexts: ["ㄹ"]),
        KeyboardData(buttonText: "ㅁ", keyTexts: ["ㅁ"]),
        KeyboardData(buttonText: "ㅗㅜ", keyTexts: ["ㅗ", "ㅜ"]),
        KeyboardData(buttonText: "", buttonImage: "space", keyTexts: [" "], isFunctionKey: true),
        KeyboardData(buttonText: "ㅅ", keyTexts: ["ㅅ"]),
        KeyboardData(buttonText: "ㅇ", keyTexts: ["ㅇ"]),
        KeyboardData(buttonText: "ㅣ", keyTexts: ["ㅣ"]),
        KeyboardData(buttonText: "", buttonImage: "return.left", keyTexts: ["\n"], isFunctionKey: true),
        KeyboardData(buttonText: "획", keyTexts: [""]),
        KeyboardData(buttonText: "ㅡ", keyTexts: ["ㅡ"]),
        KeyboardData(buttonText: "쌍", keyTexts: [""]),
        KeyboardData(buttonText: "", buttonImage: "textformat.123", keyTexts: [""], isFunctionKey: true),
        KeyboardData(buttonText: "", buttonImage: "globe", keyTexts: [""], isFunctionKey: true),
    ]
}
