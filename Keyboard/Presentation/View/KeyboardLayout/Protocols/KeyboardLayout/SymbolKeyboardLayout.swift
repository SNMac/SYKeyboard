//
//  SymbolKeyboardLayout.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/6/25.
//


/// 기호 키보드 레이아웃 프로토콜
protocol SymbolKeyboardLayout: DefaultKeyboardLayout, TextInteractionButtonGestureHandler, SwitchButtonGestureHandler {
    /// 현재 기호 키보드 레이아웃 모드
    var currentSymbolKeyboardMode: SymbolKeyboardMode { get set }
    /// 기호 전환 버튼
    var symbolShiftButton: SymbolShiftButton { get }
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
    func updateLayoutToDefault() {
        guard currentSymbolKeyboardMode != .default else { return }
        currentSymbolKeyboardMode = .default
        
        spaceButton.isHidden = false
        atButton.isHidden = true
        periodButton.isHidden = true
        slashButton.isHidden = true
        dotComButton.isHidden = true
        
        spaceButton.snp.removeConstraints()
    }
    
    func updateLayoutToURL() {
        guard currentSymbolKeyboardMode != .URL else { return }
        currentSymbolKeyboardMode = .URL
        
        spaceButton.isHidden = true
        atButton.isHidden = true
        periodButton.isHidden = false
        slashButton.isHidden = false
        dotComButton.isHidden = false
        
        periodButton.snp.remakeConstraints {
            $0.width.equalToSuperview().dividedBy(3)
        }
    }
    
    func updateLayoutToEmailAddress() {
        guard currentSymbolKeyboardMode != .emailAddress else { return }
        currentSymbolKeyboardMode = .emailAddress
        
        spaceButton.isHidden = false
        atButton.isHidden = false
        periodButton.isHidden = false
        slashButton.isHidden = true
        dotComButton.isHidden = true
        
        periodButton.snp.remakeConstraints {
            $0.width.equalToSuperview().dividedBy(4)
        }
    }
    
    func updateLayoutToWebSearch() {
        guard currentSymbolKeyboardMode != .webSearch else { return }
        currentSymbolKeyboardMode = .webSearch
        
        spaceButton.isHidden = false
        atButton.isHidden = true
        periodButton.isHidden = false
        slashButton.isHidden = true
        dotComButton.isHidden = true
        
        periodButton.snp.remakeConstraints {
            $0.width.equalToSuperview().dividedBy(5)
        }
    }
}
