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
    case emergencyCall = "긴급통화"
}

final class SYKeyboardOptions: ObservableObject {
    @Published var current: KeyboardType = .hangul
    @Published var returnButtonLabel: returnButtonType = ._default
    @Published var isHoegSsangAvailable: Bool = false
    var colorScheme: ColorScheme
    var curPressedButton: SYKeyboardButton?
    weak var delegate: SYKeyboardDelegate?
    var keyboardHeight: CGFloat
    var longPressTime: Double
    var repeatTimerCycle: Double
    var isHoegSsangToCommaPeriodEnabled: Bool
    var needsInputModeSwitchKey: Bool
    var nextKeyboardAction: Selector
    
    init(
        delegate: SYKeyboardDelegate,
        keyboardHeight: CGFloat,
        longPressTime: Double,
        repeatTimerCycle: Double,
        isHoegSsangToCommaPeriodEnabled: Bool,
        colorScheme: ColorScheme,
        needsInputModeSwitchKey: Bool,
        nextKeyboardAction: Selector
    ) {
        self.delegate = delegate
        self.keyboardHeight = keyboardHeight
        self.longPressTime = longPressTime
        self.repeatTimerCycle = repeatTimerCycle
        self.isHoegSsangToCommaPeriodEnabled = isHoegSsangToCommaPeriodEnabled
        self.colorScheme = colorScheme
        self.needsInputModeSwitchKey = needsInputModeSwitchKey
        self.nextKeyboardAction = nextKeyboardAction
    }
}
