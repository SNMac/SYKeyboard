//
//  HangeulKeyboardLayoutProvider.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 9/6/25.
//

import UIKit

import SYKeyboardCore

/// 한글 키보드 레이아웃 프로토콜
protocol HangeulKeyboardLayoutProvider: PrimaryKeyboardRepresentable {
    /// 현재 한글 키보드 모드
    var currentHangeulKeyboardMode: HangeulKeyboardMode { get set }
    /// Shift 상태
    var isShifted: Bool { get set }
    /// 이전 Shift 상태
    var wasShifted: Bool { get set }
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
    /// `UIKeyboardType`이 `.URL` 일 때의 레이아웃 설정
    func updateLayoutToURL()
    /// `UIKeyboardType`이 `.emailAddress` 일 때의 레이아웃 설정
    func updateLayoutToEmailAddress()
    /// `UIKeyboardType`이 `.twitter` 일 때의 레이아웃 설정
    func updateLayoutToTwitter()
    /// `UIKeyboardType`이 `.webSearch` 일 때의 레이아웃 설정
    func updateLayoutToWebSearch()
    /// `ShiftButton`의 Shift 상태 초기화
    func initShiftButton()
    /// `ShiftButton`의 Shift 상태 변경
    func updateShiftButton(to isShifted: Bool)
}

// MARK: - Protocol Properties & Methods

extension HangeulKeyboardLayoutProvider {
    var shiftButton: ShiftButton? { nil }
    
    func updateLayoutForCurrentHangeulMode(oldMode: HangeulKeyboardMode) {
        guard oldMode != currentHangeulKeyboardMode else { return }
        switch currentHangeulKeyboardMode {
        case .default:
            updateLayoutToDefault()
        case .URL:
            updateLayoutToURL()
        case .emailAddress:
            updateLayoutToEmailAddress()
        case .twitter:
            updateLayoutToTwitter()
        case .webSearch:
            updateLayoutToWebSearch()
        }
    }
    
    func updateLayoutToDefault() {
        spaceButton.isHidden = false
        
        returnButton.isHidden = false
        secondaryAtButton.isHidden = true
        secondarySharpButton.isHidden = true
        
        initShiftButton()
    }
    
    func updateLayoutToURL() {
        updateLayoutToDefault()
    }
    
    func updateLayoutToEmailAddress() {
        spaceButton.isHidden = false
        
        returnButton.isHidden = false
        secondaryAtButton.isHidden = true
        secondarySharpButton.isHidden = true
        
        initShiftButton()
    }
    
    func updateLayoutToTwitter() {
        spaceButton.isHidden = false
        
        returnButton.isHidden = true
        secondaryAtButton.isHidden = false
        secondarySharpButton.isHidden = false
        
        initShiftButton()
    }
    
    func updateLayoutToWebSearch() {
        spaceButton.isHidden = false
        
        returnButton.isHidden = false
        secondaryAtButton.isHidden = true
        secondarySharpButton.isHidden = true
        
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
