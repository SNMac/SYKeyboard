//
//  UserDefaultsManager+Extension.swift
//  EnglishKeyboardCore
//
//  Created by 서동환 on 12/4/25.
//

import Foundation

import SYKeyboardCore

extension UserDefaultsManager {
    /// 자동 대문자
    public var isAutoCapitalizationEnabled: Bool {
        get { storage.bool(forKey: UserDefaultsKeys.isAutoCapitalizationEnabled) }
        set { storage.set(newValue, forKey: UserDefaultsKeys.isAutoCapitalizationEnabled) }
    }
}
