//
//  NumericKeyboardLayoutProvider.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/6/25.
//

/// 숫자 키보드 레이아웃 프로토콜
public protocol NumericKeyboardLayoutProvider: NormalKeyboardLayoutProvider {
    /// 한영 전환 버튼
    var languageSwitchButton: LanguageSwitchButton? { get }
}

public extension NumericKeyboardLayoutProvider {
    var languageSwitchButton: LanguageSwitchButton? { nil }

    var keyboard: SYKeyboardType { .numeric }
}
