//
//  KeyboardFigure.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/2/25.
//

import CoreFoundation

/// 키보드 레이아웃 수치
public enum KeyboardLayoutFigure {
    /// 버튼 코너값
    static let buttonCornerRadius: CGFloat = {
        if #available(iOS 26, *) {
            return 8.5
        } else {
            return 4.6
        }
    }()
    /// 키보드 가로모드 높이
    public static let landscapeKeyboardHeight: CGFloat = 188.0
    /// 키보드 프레임 내부 간격
    public static let keyboardFrameSpacing: CGFloat = 4.0
    /// 키보드 자동완성 툴바 높이 (여백 포함)
    public static let suggestionBarHeightWithTopSpacing: CGFloat = 44.0
    /// 키보드 자동완성 버튼 구분선 높이
    static let suggestionButtonDividerHeight: CGFloat = 24.0
    /// Undo/Redo 버튼 너비
    static let undoRedoButtonWidth: CGFloat = 44.0
    /// Shift 버튼과 삭제 버튼 곱하기 계수
    static let shiftAndDeleteButtonWidthMultiplier: CGFloat = 1.35
    /// 리턴 버튼 영역이 차지하는 열 너비 비율
    static let returnButtonWidthMultiplier: CGFloat = 0.25
    /// 기호 키보드 세번째 열 버튼 곱하기 계수
    static let symbolThirdRowButtonWidthMultiplier: CGFloat = 1.4
    /// 키보드 레이아웃 선택 오버레이 너비
    static let keyboardSelectOverlayWidth: CGFloat = 180.0
    /// 한 손 키보드 선택 오버레이 너비
    static let oneHandedModeSelectOverlayWidth: CGFloat = 240.0
    /// 선택 오버레이 높이
    static let selectOverlayHeight: CGFloat = 60.0
    /// 선택 오버레이 코너값
    static let selectOverlayCornerRadius: CGFloat = {
        if #available(iOS 26, *) {
            return 8.5
        } else {
            return 4.6
        }
    }()
    // 기타 오버레이 코너값
    static let otherOverlayCornerRadius: CGFloat = {
        if #available(iOS 26, *) {
            return 12.0
        } else {
            return 0.0
        }
    }()
}

/// 키보드 버튼  `font`, `image` 크기
enum FontSize {
    static let charKeyMedium: CGFloat = 20.0
    static let charKeyLarge: CGFloat = 22.0
    static let stringKeyMedium: CGFloat = 16.0
    static let stringKeySmall: CGFloat = 8.0
    static let imageLarge: CGFloat = 32.0
    static let imageMedium: CGFloat = 14.0
    static let overlayLarge: CGFloat = 26.0
    static let overlayMedium: CGFloat = 20.0
}
