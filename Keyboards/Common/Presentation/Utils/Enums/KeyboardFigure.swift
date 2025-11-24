//
//  KeyboardFigure.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/2/25.
//

import CoreFoundation

/// 키보드 레이아웃 수치
enum KeyboardLayoutFigure {
    /// 키보드 가로모드 높이
    static let landscapeKeyboardHeight: CGFloat = 188.0
    /// Shift 버튼과 삭제 버튼 나누기 계수
    static let shiftAndDeleteButtonDivider: CGFloat = 6.65
    /// 키보드 레이아웃 선택 오버레이 너비 곱하기 계수
    static let keyboardSelectOverlayWidthMultiplier: CGFloat = 0.42
    /// 한 손 키보드 선택 오버레이 너비 곱하기 계수
    static let oneHandedModeSelectOverlayWidthMultiplier: CGFloat = 0.55
    /// `DeleteButton`, `ShiftButton` 수평 여백
    static let buttonHorizontalInset: CGFloat = 6
}

/// 키보드 버튼  `font`, `image` 크기
enum FontSize {
    static let defaultKeySize: CGFloat = 22.0
    static let lowercaseKeySize: CGFloat = 24.0
    static let stringKeySize: CGFloat = 18.0
    static let imageSize: CGFloat = 16.0
}
