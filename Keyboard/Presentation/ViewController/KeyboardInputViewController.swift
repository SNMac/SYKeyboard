//
//  KeyboardInputViewController.swift
//  Keyboard
//
//  Created by 서동환 on 7/29/24.
//

import UIKit

import SnapKit
import Then

/// 키보드 컨트롤러
final class KeyboardInputViewController: UIInputViewController {
    
    // MARK: - UI Components
    
    /// 한글 자판
    private lazy var hangeulView = HangeulView(nextKeyboardAction: self.needsInputModeSwitchKey ?
                                               #selector(self.handleInputModeList(from:with:)) : nil).then { $0.isHidden = true }
    /// 기호 자판
    private lazy var symbolView = SymbolView(nextKeyboardAction: self.needsInputModeSwitchKey ?
                                             #selector(self.handleInputModeList(from:with:)) : nil).then { $0.isHidden = false }
    /// 숫자 자판
    private lazy var numericView = NumericView(nextKeyboardAction: self.needsInputModeSwitchKey ?
                                               #selector(self.handleInputModeList(from:with:)) : nil).then { $0.isHidden = true }
    /// 텐키 자판
    private lazy var tenKeyView = TenKeyView().then { $0.isHidden = true }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let inputView = self.inputView else { return }
        setupUI(inputView: inputView)
    }
}
    
// MARK: - UI Methods

private extension KeyboardInputViewController {
    func setupUI(inputView: UIInputView) {
        setStyles()
        setViewHierarchy(inputView: inputView)
        setConstraints(inputView: inputView)
    }
    
    func setStyles() {
        
    }
    
    func setViewHierarchy(inputView: UIInputView) {
        inputView.addSubviews(hangeulView,
                              symbolView,
                              numericView,
                              tenKeyView)
    }
    
    func setConstraints(inputView: UIInputView) {
        hangeulView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(240).priority(.high)
        }
        
        symbolView.snp.makeConstraints {
            $0.edges.equalTo(hangeulView)
        }
        
        numericView.snp.makeConstraints {
            $0.edges.equalTo(hangeulView)
        }
        
        tenKeyView.snp.makeConstraints {
            $0.edges.equalTo(hangeulView)
        }
    }
}
