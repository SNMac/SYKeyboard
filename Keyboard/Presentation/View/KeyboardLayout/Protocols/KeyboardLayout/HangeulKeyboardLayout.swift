//
//  HangeulKeyboardLayout.swift
//  Keyboard
//
//  Created by 서동환 on 9/6/25.
//

/// 한글 키보드 레이아웃 프로토콜
protocol HangeulKeyboardLayout: DefaultKeyboardLayout, TextInteractionButtonGestureHandler, SwitchButtonGestureHandler {
    /// 현재 한글 키보드 레이아웃 모드
    var currentHangeulKeyboardMode: HangeulKeyboardMode { get set }
    /// 리턴 버튼 수평 스택
    var returnButtonHStackView: KeyboardRowHStackView { get }
    /// `@` 기능 버튼
    var secondaryAtButton: SecondaryKeyButton { get }
    /// `#` 기능 버튼
    var secondarySharpButton: SecondaryKeyButton { get }
    /// `UIKeyboardType`이 `.default` 일 때의 레이아웃 설정
    func updateLayoutToDefault()
    /// `UIKeyboardType`이 `.twitter` 일 때의 레이아웃 설정
    func updateLayoutToTwitter()
}

extension HangeulKeyboardLayout {
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
    }
    
    func updateLayoutToTwitter() {
        returnButton.isHidden = true
        secondaryAtButton.isHidden = false
        secondarySharpButton.isHidden = false
    }
}
