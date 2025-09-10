//
//  NumericKeyboardLayout.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/6/25.
//

/// 숫자 키보드 레이아웃 프로토콜
protocol NumericKeyboardLayout: DefaultKeyboardLayout, TextInteractionButtonGestureHandler, SwitchButtonGestureHandler {}
