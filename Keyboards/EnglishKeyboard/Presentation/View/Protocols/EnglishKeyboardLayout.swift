//
//  EnglishKeyboardLayout.swift
//  EnglishKeyboard
//
//  Created by 서동환 on 9/8/25.
//

import UIKit

import SnapKit

/// 영어 키보드 레이아웃 프로토콜
protocol EnglishKeyboardLayout: DefaultKeyboardLayout, PrimaryKeyboard, TextInteractionButtonGestureHandler, SwitchButtonGestureHandler {
    /// 현재 영어 키보드 모드
    var currentEnglishKeyboardMode: EnglishKeyboardMode { get set }
    /// Shift 상태
    var isShifted: Bool { get set }
    /// 이전 Shift 상태
    var wasShifted: Bool { get set }
    /// CapsLock 상태
    var isCapsLocked: Bool { get set }
    /// 다음 CapsLock 상태
    var willCapsLock: Bool { get set }
    /// 키보드 네번째 좌측 `SecondaryButton` 행
    var fourthRowLeftSecondaryButtonHStackView: KeyboardRowHStackView { get }
    /// 대문자 전환 버튼
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
    /// 리턴 버튼 수평 스택
    var returnButtonHStackView: KeyboardRowHStackView { get }
    /// `@` 보조 키 버튼
    var secondaryAtButton: SecondaryKeyButton { get }
    /// `#` 보조 키 버튼
    var secondarySharpButton: SecondaryKeyButton { get }
    /// 영어 키보드 레이아웃 모드 변경이 이루어졌을 때 호출되는 메서드
    /// - Parameters:
    ///   - oldMode: 이전 영어 키보드 레이아웃 모드
    func updateLayoutForCurrentEnglishMode(oldMode: EnglishKeyboardMode)
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
    func updateShiftButton(isShifted: Bool)
}

// MARK: - Protocol Properties & Methods

extension EnglishKeyboardLayout {
    var keyboard: SYKeyboardType { .english }
    
    func updateLayoutForCurrentEnglishMode(oldMode: EnglishKeyboardMode) {
        guard oldMode != currentEnglishKeyboardMode else { return }
        switch currentEnglishKeyboardMode {
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
        atButton.isHidden = true
        periodButton.isHidden = true
        slashButton.isHidden = true
        dotComButton.isHidden = true
        
        returnButton.isHidden = false
        secondaryAtButton.isHidden = true
        secondarySharpButton.isHidden = true
        
        initShiftButton()
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
        
        returnButton.isHidden = false
        secondaryAtButton.isHidden = true
        secondarySharpButton.isHidden = true
        
        initShiftButton()
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
        
        returnButton.isHidden = false
        secondaryAtButton.isHidden = true
        secondarySharpButton.isHidden = true
        
        initShiftButton()
    }
    
    func updateLayoutToTwitter() {
        returnButton.isHidden = true
        secondaryAtButton.isHidden = false
        secondarySharpButton.isHidden = false
        
        returnButton.isHidden = false
        secondaryAtButton.isHidden = true
        secondarySharpButton.isHidden = true
        
        initShiftButton()
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
        
        returnButton.isHidden = false
        secondaryAtButton.isHidden = true
        secondarySharpButton.isHidden = true
        
        initShiftButton()
    }
    
    func initShiftButton() {
        isShifted = false
        wasShifted = false
        isCapsLocked = false
        willCapsLock = false
    }
    
    func updateShiftButton(isShifted: Bool) {
        self.isShifted = isShifted
        wasShifted = false
    }
}
