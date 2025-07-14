//
//  SymbolView.swift
//  Keyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

import SnapKit

final class SymbolView: UIView {
    
    // MARK: - Properties
    
    private let symbolKeyList = [
        [
            [ ["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"] ],
            [ ["-"], ["/"], [":"], [";"], ["("], [")"], ["₩"], ["&"], ["@"], ["\""] ],
            [ ["."], [","], ["?"], ["!"], ["'"] ]
        ],
        [
            [ ["["], ["]"], ["{"], ["}"], ["#"], ["%"], ["^"], ["*"], ["+"], ["="] ],
            [ ["_"], ["\\"], ["|"], ["~"], ["<"], [">"], ["$"], ["£"], ["¥"], ["•"] ],
            [ ["."], [","], ["?"], ["!"], ["'"] ]
        ]
    ]
    
    // MARK: - UI Components
    
    private let frameStackView = KeyboardFrameStackView()
    
    private let firstRowStackView = KeyboardRowStackView()
    private let secondRowStackView = KeyboardRowStackView()
    private let thirdRowStackView = KeyboardRowStackView()
    private let fourthRowStackView = KeyboardRowStackView()
    
    private lazy var firstRowkeyButtonList = symbolKeyList[0][0].map { KeyButton(layout: .symbol, keys: $0) }
    private lazy var secondRowkeyButtonList = symbolKeyList[0][1].map { KeyButton(layout: .symbol, keys: $0) }
    private lazy var thirdRowkeyButtonList = symbolKeyList[0][2].map { KeyButton(layout: .symbol, keys: $0) }
    
    private let symbolShiftButton = SymbolShiftButton(layout: .symbol)
    private let deleteButton = DeleteButton(layout: .symbol)
    private let switchButton = SwitchButton(layout: .symbol)
    private let spaceButton = SpaceButton(layout: .symbol)
    private let returnButton = ReturnButton(layout: .symbol)
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension SymbolView {
    func setupUI() {
        setStyles()
        setViewHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
    }
    
    func setViewHierarchy() {
        self.addSubview(frameStackView)
        
        frameStackView.addArrangedSubviews(firstRowStackView,
                                           secondRowStackView,
                                           thirdRowStackView,
                                           fourthRowStackView)
        
        firstRowkeyButtonList.forEach { firstRowStackView.addArrangedSubview($0) }
        
        secondRowkeyButtonList.forEach { secondRowStackView.addArrangedSubview($0) }
        
        thirdRowStackView.addArrangedSubview(symbolShiftButton)
        thirdRowkeyButtonList.forEach { thirdRowStackView.addArrangedSubview($0) }
        thirdRowStackView.addArrangedSubview(deleteButton)
        
        fourthRowStackView.addArrangedSubviews(switchButton, spaceButton, returnButton)
    }
    
    func setConstraints() {
        frameStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        firstRowStackView.arrangedSubviews.forEach { subview in
            subview.snp.makeConstraints {
                $0.width.equalToSuperview().dividedBy(firstRowStackView.arrangedSubviews.count)
            }
        }
        
        secondRowStackView.arrangedSubviews.forEach { subview in
            subview.snp.makeConstraints {
                $0.width.equalToSuperview().dividedBy(secondRowStackView.arrangedSubviews.count)
            }
        }
        
        thirdRowStackView.arrangedSubviews.forEach { subview in
            subview.snp.makeConstraints {
                $0.width.equalToSuperview().dividedBy(thirdRowStackView.arrangedSubviews.count)
            }
        }
        
        switchButton.snp.makeConstraints {
            $0.width.equalToSuperview().dividedBy(4)
        }
        
        spaceButton.snp.makeConstraints {
            $0.width.equalToSuperview().dividedBy(2)
        }
        
        returnButton.snp.makeConstraints {
            $0.width.equalToSuperview().dividedBy(4)
        }
    }
}
