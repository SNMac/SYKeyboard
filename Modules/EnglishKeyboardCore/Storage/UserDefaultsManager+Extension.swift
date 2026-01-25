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
        get {
            return self.storage.object(forKey: UserDefaultsKeys.isAutoCapitalizationEnabled) as? Bool ?? DefaultValues.isAutoCapitalizationEnabled
        }
        set {
            self.storage.set(newValue, forKey: UserDefaultsKeys.isAutoCapitalizationEnabled)
        }
    }
}
