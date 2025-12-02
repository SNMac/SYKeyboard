//
//  SymbolKeyboardLayoutProvider.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/6/25.
//

import UIKit

/// 기호 키보드 레이아웃 프로토콜
public protocol SymbolKeyboardLayoutProvider: NormalKeyboardLayoutProvider, TextInteractionGestureHandling, SwitchGestureHandling {
    /// 현재 기호 키보드 모드
    var currentSymbolKeyboardMode: SymbolKeyboardMode { get set }
    /// Shift 상태
    var isShifted: Bool { get set }
    /// 이전 Shift 상태
    var wasShifted: Bool { get set }
    /// 키보드 네번째 좌측 `SecondaryButton` 행
    var fourthRowLeftSecondaryButtonHStackView: KeyboardRowHStackView { get }
    /// 기호 전환 버튼
    var shiftButton: ShiftButton { get }
    /// 스페이스 버튼 수평 스택
    var spaceButtonHStackView: KeyboardRowHStackView { get }
    /// `@` 키 버튼
    var atButton: PrimaryKeyButton { get }
    /// `.` 키 버튼
    var periodButton: PrimaryKeyButton { get }
    /// `/` 키 버튼
    var slashButton: PrimaryKeyButton { get }
    /// `.com` 키 버튼
    var dotComButton: PrimaryKeyButton { get }
    /// 기호 키보드 레이아웃 모드 변경이 이루어졌을 때 호출되는 메서드
    /// - Parameters:
    ///   - oldMode: 이전 기호 키보드 레이아웃 모드
    func updateLayoutForCurrentSymbolKeyboardMode(oldMode: SymbolKeyboardMode)
    /// `UIKeyboardType`이 `.default` 일 때의 레이아웃 설정
    func updateLayoutToDefault()
    /// `UIKeyboardType`이 `.URL` 일 때의 레이아웃 설정
    func updateLayoutToURL()
    /// `UIKeyboardType`이 `.emailAddress` 일 때의 레이아웃 설정
    func updateLayoutToEmailAddress()
    /// `UIKeyboardType`이 `.webSearch` 일 때의 레이아웃 설정
    func updateLayoutToWebSearch()
    /// `ShiftButton`의 Shift 상태 초기화
    func initShiftButton()
    /// `ShiftButton`의 Shift 상태 변경
    func updateShiftButton(isShifted: Bool)
}

// MARK: - Protocol Properties & Methods

extension SymbolKeyboardLayoutProvider {
    var keyboard: SYKeyboardType { .symbol }
    
    func updateLayoutForCurrentSymbolKeyboardMode(oldMode: SymbolKeyboardMode) {
        guard oldMode != currentSymbolKeyboardMode else { return }
        switch currentSymbolKeyboardMode {
        case .default:
            updateLayoutToDefault()
        case .URL:
            updateLayoutToURL()
        case .emailAddress:
            updateLayoutToEmailAddress()
        case .webSearch:
            updateLayoutToWebSearch()
        }
    }
    
    func updateLayoutToDefault() {
        spaceButton.isHidden = false
        atButton.isHidden = true
        periodButton.isHidden = true
        slashButton.isHidden = true
        dotComButton.isHidden = true
        
        initShiftButton()
    }
    
    func updateLayoutToURL() {
        spaceButton.isHidden = true
        atButton.isHidden = true
        periodButton.isHidden = false
        slashButton.isHidden = false
        dotComButton.isHidden = false
        
        removePeriodButtonWidthConstraints()
        
        initShiftButton()
    }
    
    func updateLayoutToEmailAddress() {
        spaceButton.isHidden = false
        atButton.isHidden = false
        periodButton.isHidden = false
        slashButton.isHidden = true
        dotComButton.isHidden = true
        
        remakePeriodButtonWidthConstraint(multiplier: 0.25)
        
        initShiftButton()
    }
    
    func updateLayoutToWebSearch() {
        spaceButton.isHidden = false
        atButton.isHidden = true
        periodButton.isHidden = false
        slashButton.isHidden = true
        dotComButton.isHidden = true
        
        remakePeriodButtonWidthConstraint(multiplier: 0.20)
        
        initShiftButton()
    }
    
    func initShiftButton() {
        self.isShifted = false
        wasShifted = false
    }
    
    func updateShiftButton(isShifted: Bool) {
        self.isShifted = isShifted
        wasShifted = false
    }
}

// MARK: - Helper Methods

private extension SymbolKeyboardLayoutProvider {
    /// periodButton에 걸려있는 기존 Width 제약 조건을 찾아 제거합니다.
    func removePeriodButtonWidthConstraints() {
        guard let superview = periodButton.superview else { return }
        let constraintsToRemove = superview.constraints.filter { constraint in
            guard let firstItem = constraint.firstItem as? UIView else { return false }
            return firstItem == periodButton && constraint.firstAttribute == .width
        }
        
        NSLayoutConstraint.deactivate(constraintsToRemove)
    }
    /// 기존 제약 조건을 제거하고 새로운 너비(Multiplier) 제약 조건을 설정합니다.
    func remakePeriodButtonWidthConstraint(multiplier: CGFloat) {
        removePeriodButtonWidthConstraints()
        
        guard let superview = periodButton.superview else { return }
        
        let newConstraint = periodButton.widthAnchor.constraint(equalTo: superview.widthAnchor, multiplier: multiplier)
        newConstraint.isActive = true
    }
}
