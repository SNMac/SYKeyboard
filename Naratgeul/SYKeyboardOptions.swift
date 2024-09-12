//
//  SYKeyboardOptions.swift
//  Naratgeul
//
//  Created by 서동환 on 8/14/24.
//

import Foundation
import SwiftUI

enum KeyboardType {
  case hangul
  case symbol
}

enum returnButtonType: String {
    case _default = "return.left"
    case go = "이동"
    case join = "연결"
    case next = "다음"
    case route = "경로"
    case send = "전송"
    case _continue = "계속"
    case search = "검색"
    case done = "완료"
}

final class SYKeyboardOptions: ObservableObject {
    @Published var current: KeyboardType = .hangul
    @Published var returnButtonLabel: returnButtonType = ._default
    var colorScheme: ColorScheme
    var curPressedButton: SYKeyboardButton?
    weak var delegate: SYKeyboardDelegate?
    var keyboardHeight: CGFloat
    var longPressTime: Double
    var repeatTimerCycle: Double
    var needsInputModeSwitchKey: Bool
    var nextKeyboardAction: Selector
    var isHoegSsangAvailable: Bool = false
    
    init(
        delegate: SYKeyboardDelegate,
        keyboardHeight: CGFloat,
        longPressTime: Double,
        repeatTimerCycle: Double,
        colorScheme: ColorScheme,
        needsInputModeSwitchKey: Bool,
        nextKeyboardAction: Selector
    ) {
        self.delegate = delegate
        self.keyboardHeight = keyboardHeight
        self.longPressTime = longPressTime
        self.repeatTimerCycle = repeatTimerCycle
        self.colorScheme = colorScheme
        self.needsInputModeSwitchKey = needsInputModeSwitchKey
        self.nextKeyboardAction = nextKeyboardAction
    }
}
