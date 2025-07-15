//
//  KeyboardInputViewController.swift
//  Keyboard
//
//  Created by 서동환 on 7/29/24.
//

import UIKit

import SnapKit
import Then

/// 키보드 `UIInputViewController`
final class KeyboardInputViewController: UIInputViewController {
    
    // MARK: - UI Components
    
    private lazy var hangeulView = HangeulView(nextKeyboardAction: self.needsInputModeSwitchKey ?
                                               #selector(self.handleInputModeList(from:with:)) : nil).then { $0.isHidden = false }
    private lazy var symbolView = SymbolView(nextKeyboardAction: self.needsInputModeSwitchKey ?
                                             #selector(self.handleInputModeList(from:with:)) : nil).then { $0.isHidden = true }
    private lazy var numericView = NumericView(nextKeyboardAction: self.needsInputModeSwitchKey ?
                                               #selector(self.handleInputModeList(from:with:)) : nil).then { $0.isHidden = true }
    private lazy var tenKeyView = TenKeyView().then { $0.isHidden = true }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}
    
// MARK: - UI Methods

private extension KeyboardInputViewController {
    func setupUI() {
        setStyles()
        setViewHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        
    }
    
    func setViewHierarchy() {
        self.view.addSubviews(hangeulView,
                              symbolView,
                              numericView,
                              tenKeyView)
    }
    
    func setConstraints() {
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
