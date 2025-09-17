//
//  HangeulKeyboardLayout.swift
//  HangeulKeyboard
//
//  Created by 서동환 on 9/6/25.
//

import UIKit

/// 한글 키보드 레이아웃 프로토콜
protocol HangeulKeyboardLayout: PrimaryKeyboard, TextInteractionButtonGestureHandler, SwitchButtonGestureHandler {
    /// 현재 한글 키보드 모드
    var currentHangeulKeyboardMode: HangeulKeyboardMode { get set }
    /// Shift 상태
    var isShifted: Bool? { get set }
    /// 이전 Shift 상태
    var wasShifted: Bool? { get set }
    /// 대문자 전환 버튼
    var shiftButton: ShiftButton? { get }
    /// 리턴 버튼 수평 스택
    var returnButtonHStackView: KeyboardRowHStackView { get }
    /// `@` 보조 키 버튼
    var secondaryAtButton: SecondaryKeyButton { get }
    /// `#` 보조 키 버튼
    var secondarySharpButton: SecondaryKeyButton { get }
    /// 한글 키보드 레이아웃 모드 변경이 이루어졌을 때 호출되는 메서드
    /// - Parameters:
    ///   - oldMode: 이전 한글 키보드 레이아웃 모드
    func updateLayoutForCurrentHangeulMode(oldMode: HangeulKeyboardMode)
    /// `UIKeyboardType`이 `.default` 일 때의 레이아웃 설정
    func updateLayoutToDefault()
    /// `UIKeyboardType`이 `.twitter` 일 때의 레이아웃 설정
    func updateLayoutToTwitter()
    /// `ShiftButton`의 Shift 상태 초기화
    func initShiftButton()
    /// `ShiftButton`의 Shift 상태 변경
    func updateShiftButton(isShifted: Bool)
}

// MARK: - Protocol Properties & Methods

extension HangeulKeyboardLayout {
    var keyboard: SYKeyboardType { .hangeul }
    var isShifted: Bool? {
        get { nil } set {}
    }
    var wasShifted: Bool? {
        get { nil } set {}
    }
    var shiftButton: ShiftButton? { nil }
    
    func updateLayoutForCurrentHangeulMode(oldMode: HangeulKeyboardMode) {
        guard oldMode != currentHangeulKeyboardMode else { return }
        switch currentHangeulKeyboardMode {
        case .default:
            updateLayoutToDefault()
        case .twitter:
            updateLayoutToTwitter()
        }
    }
    
    func updateLayoutToDefault() {
        returnButton.isHidden = false
        secondaryAtButton.isHidden = true
        secondarySharpButton.isHidden = true
        
        initShiftButton()
    }
    
    func updateLayoutToTwitter() {
        returnButton.isHidden = true
        secondaryAtButton.isHidden = false
        secondarySharpButton.isHidden = false
        
        initShiftButton()
    }
    
    func initShiftButton() {
        isShifted = false
        wasShifted = false
    }
    
    func updateShiftButton(isShifted: Bool) {
        self.isShifted = isShifted
        wasShifted = false
    }
}
