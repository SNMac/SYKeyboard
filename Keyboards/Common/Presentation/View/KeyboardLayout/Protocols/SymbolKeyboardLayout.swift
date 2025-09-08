//
//  SymbolKeyboardLayout.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/6/25.
//

import UIKit

import SnapKit

/// 기호 키보드 레이아웃 프로토콜
protocol SymbolKeyboardLayout: DefaultKeyboardLayout, TextInteractionButtonGestureHandler, SwitchButtonGestureHandler {
    /// 현재 기호 키보드 레이아웃 모드
    var currentSymbolKeyboardMode: SymbolKeyboardMode { get set }
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
}

extension SymbolKeyboardLayout {
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
    }
    
    func updateLayoutToURL() {
        spaceButton.isHidden = true
        atButton.isHidden = true
        periodButton.isHidden = false
        slashButton.isHidden = false
        dotComButton.isHidden = false
        
        periodButton.snp.updateConstraints {
            $0.width.equalToSuperview().dividedBy(3)
        }
    }
    
    func updateLayoutToEmailAddress() {
        spaceButton.isHidden = false
        atButton.isHidden = false
        periodButton.isHidden = false
        slashButton.isHidden = true
        dotComButton.isHidden = true
        
        periodButton.snp.updateConstraints {
            $0.width.equalToSuperview().dividedBy(4)
        }
    }
    
    func updateLayoutToWebSearch() {
        spaceButton.isHidden = false
        atButton.isHidden = true
        periodButton.isHidden = false
        slashButton.isHidden = true
        dotComButton.isHidden = true
        
        periodButton.snp.updateConstraints {
            $0.width.equalToSuperview().dividedBy(5)
        }
    }
}
