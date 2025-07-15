//
//  SymbolView.swift
//  Keyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

import SnapKit

/// 기호 자판 `UIView`
final class SymbolView: UIView {
    
    // MARK: - Properties
    
    /// 기호 자판 키 배열
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
    
    /// 키보드 전체 프레임 `KeyboardFrameStackView`
    private let frameStackView = KeyboardFrameStackView()
    
    /// 키보드 첫번째 행 `KeyboardRowStackView`
    private let firstRowStackView = KeyboardRowStackView()
    /// 키보드 두번째 행 `KeyboardRowStackView`
    private let secondRowStackView = KeyboardRowStackView()
    /// 키보드 세번째 행 `KeyboardRowStackView`
    private let thirdRowStackView = KeyboardRowStackView()
    /// 키보드 네번째 행 `KeyboardRowStackView`
    private let fourthRowStackView = KeyboardRowStackView()
    
    /// 키보드 첫번째 행 `KeyButton` 배열
    private lazy var firstRowkeyButtonList = symbolKeyList[0][0].map { KeyButton(layout: .symbol, keys: $0) }
    /// 키보드 두번째 행 `KeyButton` 배열
    private lazy var secondRowkeyButtonList = symbolKeyList[0][1].map { KeyButton(layout: .symbol, keys: $0) }
    /// 키보드 세번째 행 `KeyButton` 배열
    private lazy var thirdRowkeyButtonList = symbolKeyList[0][2].map { KeyButton(layout: .symbol, keys: $0) }
    
    /// 기호 전환 버튼 `SymbolShiftButton`
    private let symbolShiftButton = SymbolShiftButton(layout: .symbol)
    /// 삭제 버튼 `DeleteButton`
    private let deleteButton = DeleteButton(layout: .symbol)
    /// 자판 전환 버튼 `SwitchButton`
    private let switchButton = SwitchButton(layout: .symbol)
    /// 스페이스 버튼 `SpaceButton`
    private let spaceButton = SpaceButton(layout: .symbol)
    /// 리턴 버튼 `ReturnButton`
    private let returnButton = ReturnButton(layout: .symbol)
    /// iPhone SE용 키보드 전환 버튼
    private lazy var nextKeyboardButton: NextKeyboardButton? = nil
    
    // MARK: - Initializer
    
    init(nextKeyboardAction: Selector?) {
        super.init(frame: .zero)
        
        if let nextKeyboardAction { setNextKeyboardButtonTarget(action: nextKeyboardAction) }
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

// MARK: - Action Methods

private extension SymbolView {
    func setNextKeyboardButtonTarget(action: Selector) {
        nextKeyboardButton = NextKeyboardButton(layout: .symbol)
        nextKeyboardButton?.addTarget(nil, action: action, for: .allTouchEvents)
    }
}
