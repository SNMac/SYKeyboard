//
//  HangeulKeyboardViewController.swift
//  HangeulKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import UIKit

/// 한글 키보드 입력/UI 컨트롤러
final class HangeulKeyboardViewController: BaseKeyboardViewController {
    
    // MARK: - UI Components
    
    /// 나랏글 키보드
    private lazy var naratgeulKeyboardView: HangeulKeyboardLayout = NaratgeulKeyboardView()
    /// 천지인 키보드
    private lazy var cheonjiinKeyboardView: HangeulKeyboardLayout = CheonjiinKeyboardView()
    /// 사용자가 선택한 한글 키보드
    private lazy var hangeulKeyboardView: HangeulKeyboardLayout = naratgeulKeyboardView  // TODO: 사용자가 선택한 한글 키보드를 저장
    override var primaryKeyboardView: PrimaryKeyboard { hangeulKeyboardView }
    
    // MARK: - Override Methods
    
    override func updateKeyboardType(oldKeyboardType: UIKeyboardType?) {
        guard textDocumentProxy.keyboardType != oldKeyboardType else { return }
        switch textDocumentProxy.keyboardType {
        case .default, nil:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .hangeul
        case .asciiCapable:
            // 지원 안함
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .hangeul
        case .numbersAndPunctuation:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .symbol
        case .URL:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .URL
            currentKeyboard = .hangeul
        case .numberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .phonePad, .namePhonePad:
            // 항상 iOS 시스템 키보드 표시됨
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .emailAddress:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .emailAddress
            currentKeyboard = .hangeul
        case .decimalPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .decimalPad
            currentKeyboard = .tenKey
        case .twitter:
            hangeulKeyboardView.currentHangeulKeyboardMode = .twitter
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .hangeul
        case .webSearch:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .webSearch
            currentKeyboard = .hangeul
        case .asciiCapableNumberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        @unknown default:
            assertionFailure("구현이 필요한 case 입니다.")
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .hangeul
        }
    }
}
