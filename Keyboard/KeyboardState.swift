//
//  KeyboardState.swift
//  Keyboard
//
//  Created by 서동환 on 8/14/24.
//

import SwiftUI

enum InputType {
    case hangeul
    case symbol
    case number
}

enum OneHandMode: Int {
    case left
    case center
    case right
}

enum KeyboardType {
    case `default`
    case numbersAndPunctuation
    case URL
    case numberPad
    case emailAddress
    case twitter
    case webSearch
    case asciiCapableNumberPad
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
    @Published var currentInputType: InputType = .hangeul
    @Published var activeInputTypeSelectOverlay: Bool = false
    @Published var selectedInputType: InputType?
    
    @Published var currentOneHandMode: OneHandMode = .center
    @Published var activeOneHandModeSelectOverlay: Bool = false
    @Published var selectedOneHandMode: OneHandMode?
    
    @Published var currentKeyboardType: KeyboardType = .default
    @Published var returnButtonType: ReturnButtonType = .default

    @Published var nowSymbolPage: Int = 0
    @Published var totalSymbolPage: Int = 0
    
    @Published var isHoegSsangAvailable: Bool = false
    
    var nowPressedButton: KeyboardButton?
    
    weak var delegate: KeyboardDelegate?
    var keyboardHeight: CGFloat
    var oneHandWidth: CGFloat
    var longPressTime: Double
    var repeatTimerCycle: Double
    var needsInputModeSwitchKey: Bool
    var nextKeyboardAction: Selector
    
    var inputTypeButtonPosition = [CGRect](repeating: .zero, count: 2)
    var oneHandButtonPosition = [CGRect](repeating: .zero, count: 3)
    
    init(
        delegate: KeyboardDelegate,
        keyboardHeight: CGFloat,
        oneHandWidth: CGFloat,
        longPressTime: Double,
        repeatTimerCycle: Double,
        needsInputModeSwitchKey: Bool,
        nextKeyboardAction: Selector
    ) {
        self.delegate = delegate
        self.keyboardHeight = keyboardHeight
        self.oneHandWidth = oneHandWidth
        self.longPressTime = longPressTime
        self.repeatTimerCycle = repeatTimerCycle
        self.needsInputModeSwitchKey = needsInputModeSwitchKey
        self.nextKeyboardAction = nextKeyboardAction
    }
}
