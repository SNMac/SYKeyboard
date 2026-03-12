//
//  SymbolKeyboardLayoutProvider.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/6/25.
//

import UIKit

/// 기호 키보드 레이아웃 프로토콜
public protocol SymbolKeyboardLayoutProvider: NormalKeyboardLayoutProvider {
    /// Shift 상태
    var isShifted: Bool { get set }
    /// 이전 Shift 상태
    var wasShifted: Bool { get set }
    /// 키보드 네번째 좌측 `SecondaryButton` 행
    var fourthRowLeftSecondaryButtonHStackView: KeyboardRowHStackView { get }
    /// 기호 전환 버튼
    var shiftButton: ShiftButton { get }
    /// `ShiftButton`의 Shift 상태 초기화
    func initShiftButton()
    /// `ShiftButton`의 Shift 상태 변경
    func updateShiftButton(to isShifted: Bool)
}

// MARK: - Protocol Properties & Methods

extension SymbolKeyboardLayoutProvider {
    var keyboard: SYKeyboardType { .symbol }
    
    func initShiftButton() {
        isShifted = false
        wasShifted = false
    }
    
    func updateShiftButton(to isShifted: Bool) {
        self.isShifted = isShifted
        wasShifted = false
    }
}
