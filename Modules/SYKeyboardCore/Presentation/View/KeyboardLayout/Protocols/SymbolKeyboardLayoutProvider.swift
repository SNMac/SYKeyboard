//
//  SymbolKeyboardLayoutProvider.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/6/25.
//

import UIKit

/// 기호 키보드 레이아웃 프로토콜
public protocol SymbolKeyboardLayoutProvider: NormalKeyboardLayoutProvider {
    /// 한영 전환 버튼
    var languageSwitchButton: LanguageSwitchButton? { get }
    /// 현재 기호 키보드 모드
    var currentSymbolKeyboardMode: SymbolKeyboardMode { get set }
    /// Shift 상태
    var isShifted: Bool { get set }
    /// 이전 Shift 상태
    var wasShifted: Bool { get set }
    /// 키보드 네번째 좌측 `SecondaryButton` 행
    var fourthRowLeftSecondaryButtonHStackView: KeyboardRowHStackView { get }
    /// 스페이스 버튼 수평 스택
    var spaceButtonHStackView: KeyboardRowHStackView { get }
    /// 기호 전환 버튼
    var shiftButton: ShiftButton { get }
    /// `@` 키 버튼
    var atButton: PrimaryKeyButton { get }
    /// `.` 키 버튼
    var periodButton: PrimaryKeyButton { get }
    /// `/` 키 버튼
    var slashButton: PrimaryKeyButton { get }
    /// `.com` 키 버튼
    var dotComButton: PrimaryKeyButton { get }
    /// 현재 기호 키보드 모드에 맞게 레이아웃 변경
    func updateLayoutForCurrentSymbolKeyboardMode(oldMode: SymbolKeyboardMode)
    /// 기본 기호 키보드 레이아웃 설정
    func updateLayoutToDefault()
    /// URL 기호 키보드 레이아웃 설정
    func updateLayoutToURL()
    /// 이메일 기호 키보드 레이아웃 설정
    func updateLayoutToEmailAddress()
    /// 웹 검색 기호 키보드 레이아웃 설정
    func updateLayoutToWebSearch()
    /// `ShiftButton`의 Shift 상태 초기화
    func initShiftButton()
    /// `ShiftButton`의 Shift 상태 변경
    func updateShiftButton(to isShifted: Bool)
    /// `periodButton` 너비 제약 조건 업데이트
    func updatePeriodButtonWidthConstraint(multiplier: CGFloat?)
}

// MARK: - Protocol Properties & Methods

public extension SymbolKeyboardLayoutProvider {
    var languageSwitchButton: LanguageSwitchButton? { nil }

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
        
        updatePeriodButtonWidthConstraint(multiplier: nil)
        
        initShiftButton()
    }
    
    func updateLayoutToEmailAddress() {
        spaceButton.isHidden = false
        atButton.isHidden = false
        periodButton.isHidden = false
        slashButton.isHidden = true
        dotComButton.isHidden = true
        
        updatePeriodButtonWidthConstraint(multiplier: 0.25)
        
        initShiftButton()
    }
    
    func updateLayoutToWebSearch() {
        spaceButton.isHidden = false
        atButton.isHidden = true
        periodButton.isHidden = false
        slashButton.isHidden = true
        dotComButton.isHidden = true
        
        updatePeriodButtonWidthConstraint(multiplier: 0.20)
        
        initShiftButton()
    }
    
    func initShiftButton() {
        isShifted = false
        wasShifted = false
    }
    
    func updateShiftButton(to isShifted: Bool) {
        self.isShifted = isShifted
        wasShifted = false
    }
}
