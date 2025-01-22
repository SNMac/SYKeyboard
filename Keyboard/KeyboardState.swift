//
//  KeyboardState.swift
//  Keyboard
//
//  Created by 서동환 on 8/14/24.
//

import SwiftUI

enum Keyboard {
    case hangeul
    case symbol
    case numeric
}

enum OneHandedKeyboard: Int {
    case left
    case center
    case right
}

enum ReturnButtonType: String {
    case `default` = "return.left"
    case go = "이동"
    case join = "연결"
    case next = "다음"
    case route = "경로"
    case send = "전송"
    case `continue` = "계속"
    case search = "검색"
    case done = "완료"
    case emergencyCall = "긴급통화"
}

final class KeyboardState: ObservableObject {
    @Published var currentKeyboard: Keyboard = .hangeul
    @Published var activeKeyboardSelectOverlay: Bool = false
    @Published var selectedKeyboard: Keyboard?
    
    @Published var currentOneHandedKeyboard: OneHandedKeyboard = .center
    @Published var activeOneHandedKeyboardSelectOverlay: Bool = false
    @Published var selectedOneHandedKeyboard: OneHandedKeyboard?
    
    @Published var currentUIKeyboardType: UIKeyboardType = .default
    @Published var returnButtonType: ReturnButtonType = .default

    @Published var nowSymbolPage: Int = 0
    @Published var totalSymbolPage: Int = 0
    
    @Published var isHoegSsangAvailable: Bool = false
    
    var nowPressedButton: KeyboardButton?
    
    weak var delegate: KeyboardDelegate?
    var keyboardHeight: CGFloat
    var oneHandedKeyboardWidth: CGFloat
    var longPressTime: Double
    var repeatTimerCycle: Double
    var needsInputModeSwitchKey: Bool
    var nextKeyboardAction: Selector
    
    var keyboardSelectButtonPosition = [CGRect](repeating: .zero, count: 2)
    var oneHandedKeyboardSelectButtonPosition = [CGRect](repeating: .zero, count: 3)
    
    init(
        delegate: KeyboardDelegate,
        keyboardHeight: CGFloat,
        oneHandedKeyboardWidth: CGFloat,
        longPressTime: Double,
        repeatTimerCycle: Double,
        needsInputModeSwitchKey: Bool,
        nextKeyboardAction: Selector
    ) {
        self.delegate = delegate
        self.keyboardHeight = keyboardHeight
        self.oneHandedKeyboardWidth = oneHandedKeyboardWidth
        self.longPressTime = longPressTime
        self.repeatTimerCycle = repeatTimerCycle
        self.needsInputModeSwitchKey = needsInputModeSwitchKey
        self.nextKeyboardAction = nextKeyboardAction
    }
}
