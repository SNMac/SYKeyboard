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

final class SYKeyboardOptions: ObservableObject {
    @Published var current: KeyboardType = .hangul
    var curPressedButton: SYKeyboardButton?
    weak var delegate: SYKeyboardDelegate?
    var keyboardHeight: CGFloat
    var longPressTime: Double
    var repeatTimerCycle: Double
    var colorScheme: ColorScheme
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
