//
//  NaratgeulState.swift
//  Naratgeul
//
//  Created by 서동환 on 8/14/24.
//

import Foundation
import SwiftUI

enum OneHandType: Int {
    case left
    case center
    case right
}

enum InputType {
    case hangeul
    case symbol
    case number
}

enum KeyboardType {
    case _default
    case numbersAndPunctuation
    case URL
    case numberPad
    case emailAddress
    case twitter
    case webSearch
    case asciiCapableNumberPad
}

enum ReturnButtonType: String {
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

final class NaratgeulState: ObservableObject {
    @Published var currentInputType: InputType = .hangeul
    @Published var isSelectingInputType: Bool = false
    @Published var selectedInputType: InputType?
    @Published var currentOneHandType: OneHandType = .center
    @Published var isSelectingOneHandType: Bool = false
    @Published var selectedOneHandType: OneHandType = .center
    @Published var currentKeyboardType: KeyboardType = ._default
    @Published var returnButtonType: ReturnButtonType = ._default
    @Published var isHoegSsangAvailable: Bool = false
    @Published var nowSymbolPage: Int = 0
    @Published var totalSymbolPage: Int = 0
    
    var nowPressedButton: SYKeyboardButton?
    var swift6_nowPressedButton: Swift6_NaratgeulButton?
    
    weak var delegate: NaratgeulDelegate?
    var keyboardHeight: CGFloat
    var longPressTime: Double
    var repeatTimerCycle: Double
    var needsInputModeSwitchKey: Bool
    var nextKeyboardAction: Selector
    
    var inputTypeButtonMinXPosition = [CGFloat](repeating: 0.0, count: 3)
    var inputTypeButtonMaxXPosition = [CGFloat](repeating: 0.0, count: 3)
    var oneHandButtonMinXPosition = [CGFloat](repeating: 0.0, count: 3)
    var oneHandButtonMaxXPosition = [CGFloat](repeating: 0.0, count: 3)
    var oneHandButtonMinYPosition = [CGFloat](repeating: 0.0, count: 3)
    var oneHandButtonMaxYPosition = [CGFloat](repeating: 0.0, count: 3)
    
    init(
        delegate: NaratgeulDelegate,
        keyboardHeight: CGFloat,
        longPressTime: Double,
        repeatTimerCycle: Double,
        needsInputModeSwitchKey: Bool,
        nextKeyboardAction: Selector
    ) {
        self.delegate = delegate
        self.keyboardHeight = keyboardHeight
        self.longPressTime = longPressTime
        self.repeatTimerCycle = repeatTimerCycle
        self.needsInputModeSwitchKey = needsInputModeSwitchKey
        self.nextKeyboardAction = nextKeyboardAction
    }
}
