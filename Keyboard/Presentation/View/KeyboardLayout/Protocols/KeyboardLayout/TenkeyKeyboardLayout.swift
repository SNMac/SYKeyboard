//
//  TenkeyKeyboardLayout.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/6/25.
//

import UIKit

/// 텐키 키보드 레이아웃 프로토콜
protocol TenkeyKeyboardLayout: BaseKeyboardLayout {
    /// 현재 텐키 키보드 레이아웃 모드
    var currentTenkeyKeyboardMode: TenkeyKeyboardMode { get set }
    /// 키보드 네번째 행 좌측 여백
    var bottomLeftButtonSpacer: KeyboardSpacer { get }
    /// `.` 보조 키 버튼
    var periodButton: SecondaryKeyButton { get }
    /// 텐키 키보드 레이아웃 모드 변경이 이루어졌을 때 호출되는 메서드
    /// - Parameters:
    ///   - oldMode: 이전 텐키 키보드 레이아웃 모드
    func updateLayoutForCurrentTenkeyKeyboardMode(oldMode: TenkeyKeyboardMode)
    /// `UIKeyboardType`이 `.numberPad` 일 때의 레이아웃 설정
    func updateLayoutToNumberPad()
    /// `UIKeyboardType`이 `.decimalPad` 일 때의 레이아웃 설정
    func updateLayoutToDecimalPad()
}

extension TenkeyKeyboardLayout {
    func updateLayoutForCurrentTenkeyKeyboardMode(oldMode: TenkeyKeyboardMode) {
        guard oldMode != currentTenkeyKeyboardMode else { return }
        switch currentTenkeyKeyboardMode {
        case .numberPad:
            updateLayoutToNumberPad()
        case .decimalPad:
            updateLayoutToDecimalPad()
        }
    }
    
    func updateLayoutToNumberPad() {
        bottomLeftButtonSpacer.isHidden = false
        periodButton.isHidden = true
    }
    
    func updateLayoutToDecimalPad() {
        bottomLeftButtonSpacer.isHidden = true
        periodButton.isHidden = false
    }
}
