//
//  UserDefaultsManager+Extension.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 12/4/25.
//

import Foundation

import SYKeyboardCore

extension UserDefaultsManager {
    /// 선택한 한글 키보드
    public var selectedHangeulKeyboard: HangeulKeyboardType {
        get {
            guard let rawValue = self.storage.object(forKey: UserDefaultsKeys.selectedHangeulKeyboard) as? HangeulKeyboardType.RawValue,
                  let value = HangeulKeyboardType(rawValue: rawValue) else {
                return DefaultValues.selectedHangeulKeyboard
            }
            return value
        }
        set {
            self.storage.set(newValue.rawValue, forKey: UserDefaultsKeys.selectedHangeulKeyboard)
        }
    }
}
