//
//  KeyboardFigure.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/2/25.
//

import CoreFoundation

/// 키보드 레이아웃 수치
public enum KeyboardLayoutFigure {
    /// 키보드 가로모드 높이
    public static let landscapeKeyboardHeight: CGFloat = 188.0
    /// Shift 버튼과 삭제 버튼 곱하기 계수
    public static let shiftAndDeleteButtonWidthMultiplier: CGFloat = 1.35
    /// 기호 키보드 세번째 열 버튼 곱하기 계수
    public static let symbolThirdRowButtonWidthMultiplier: CGFloat = 1.4
    /// 키보드 레이아웃 선택 오버레이 너비 곱하기 계수
    public static let keyboardSelectOverlayWidthMultiplier: CGFloat = 0.42
    /// 한 손 키보드 선택 오버레이 너비 곱하기 계수
    public static let oneHandedModeSelectOverlayWidthMultiplier: CGFloat = 0.55
}

/// 키보드 버튼  `font`, `image` 크기
enum FontSize {
    static let defaultKeySize: CGFloat = 22.0
    static let lowercaseKeySize: CGFloat = 24.0
    static let stringKeySize: CGFloat = 18.0
    static let imageSize: CGFloat = 16.0
}
