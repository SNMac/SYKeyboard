//
//  Bundle+Extension.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/9/25.
//

import Foundation

extension Bundle {
    /// Info.plist에서 "PrimaryLanguage" 값을 가져오는 연산 프로퍼티
    static var primaryLanguage: String? {
        guard let nsExtensionDict = main.object(forInfoDictionaryKey: "NSExtension") as? [String: Any],
              let attributesDict = nsExtensionDict["NSExtensionAttributes"] as? [String: Any] else { return nil }
        return attributesDict["PrimaryLanguage"] as? String
    }
}
