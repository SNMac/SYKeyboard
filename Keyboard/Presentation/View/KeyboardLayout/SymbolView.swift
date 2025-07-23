//
//  SymbolView.swift
//  Keyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

import SnapKit
import Then

/// 기호 키보드
final class SymbolView: UIView {
    
    // MARK: - Properties
    
    /// 기호 키보드 키 배열
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
    
    /// 키보드 레이아웃 프레임
    private let layoutVStackView = KeyboardLayoutVStackView()
    
    /// 키보드 첫번째 행
    private let firstRowHStackView = KeyboardRowHStackView()
    /// 키보드 두번째 행
    private let secondRowHStackView = KeyboardRowHStackView()
    /// 키보드 세번째 행
    private let thirdRowHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 행
    private let fourthRowHStackView = KeyboardRowHStackView().then {
        $0.distribution = .fill
    }
    /// 키보드 네번째 좌측 `SecondaryButton` 행
    private let fourthRowLeftSecondaryButtonHStackView = KeyboardRowHStackView()
    
    /// 키보드 첫번째 행
    private lazy var firstRowkeyButtonList = symbolKeyList[0][0].map { KeyButton(layout: .symbol, keys: $0) }
    /// 키보드 두번째 행
    private lazy var secondRowkeyButtonList = symbolKeyList[0][1].map { KeyButton(layout: .symbol, keys: $0) }
    /// 키보드 세번째 행
    private lazy var thirdRowkeyButtonList = symbolKeyList[0][2].map { KeyButton(layout: .symbol, keys: $0) }
    
    /// 기호 전환 버튼
    private let symbolShiftButton = SymbolShiftButton(layout: .symbol)
    /// 삭제 버튼
    private let deleteButton = DeleteButton(layout: .symbol)
    /// 키보드 전환 버튼
    private(set) var switchButton = SwitchButton(layout: .symbol)
    /// 스페이스 버튼
    private let spaceButton = SpaceButton(layout: .symbol)
    /// 리턴 버튼
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
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
    }
    
    func setHierarchy() {
        self.addSubview(layoutVStackView)
        
        layoutVStackView.addArrangedSubviews(firstRowHStackView,
                                           secondRowHStackView,
                                           thirdRowHStackView,
                                           fourthRowHStackView)
        
        firstRowkeyButtonList.forEach { firstRowHStackView.addArrangedSubview($0) }
        
        secondRowkeyButtonList.forEach { secondRowHStackView.addArrangedSubview($0) }
        
        thirdRowHStackView.addArrangedSubview(symbolShiftButton)
        thirdRowkeyButtonList.forEach { thirdRowHStackView.addArrangedSubview($0) }
        thirdRowHStackView.addArrangedSubview(deleteButton)
        
        fourthRowHStackView.addArrangedSubviews(fourthRowLeftSecondaryButtonHStackView, spaceButton, returnButton)
        fourthRowLeftSecondaryButtonHStackView.addArrangedSubview(switchButton)
        // iPhone SE일 때 키보드 전환 버튼 추가
        if let nextKeyboardButton {
            fourthRowLeftSecondaryButtonHStackView.addArrangedSubview(nextKeyboardButton)
        }
    }
    
    func setConstraints() {
        layoutVStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        fourthRowLeftSecondaryButtonHStackView.snp.makeConstraints {
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
