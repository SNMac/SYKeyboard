//
//  KeyboardInputViewController.swift
//  Keyboard
//
//  Created by 서동환 on 7/29/24.
//

import UIKit
import SwiftUI
import SnapKit

/// 키보드 `UIInputViewController`
final class KeyboardInputViewController: UIInputViewController {
    
    // MARK: - UI Components
    
    private let spacer = KeyboardSpacer()
    
    private lazy var hangeulView = HangeulView()
//    private lazy var symbolView = HangeulView()
//    private lazy var numericView = HangeulView()
//    private lazy var tenKeyView = HangeulView()
    
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
        self.view.addSubviews(spacer,
                              hangeulView)
    }
    
    func setConstraints() {
        spacer.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(2)
        }
        
        hangeulView.snp.makeConstraints {
            $0.top.equalTo(spacer.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(240).priority(.high)
        }
    }
}
