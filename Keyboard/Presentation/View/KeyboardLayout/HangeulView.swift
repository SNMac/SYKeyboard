//
//  HangeulView.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit
import Then

final class HangeulView: UIView {
    
    // MARK: - Properties
    
    private let naratgeulKeyList = [["ㄱ"], ["ㄴ"], ["ㅏ", "ㅓ"],
                                    ["ㄹ"], ["ㅁ"], ["ㅗ", "ㅜ"],
                                    ["ㅅ"], ["ㅇ"], ["ㅣ"],
                                    ["획"], ["ㅡ"], ["쌍"]]
    
    // MARK: - UI Components
    
    private let frameStackView = KeyboardFrameStackView()
    
    private let firstRowStackView = KeyboardRowStackView()
    private let secondRowStackView = KeyboardRowStackView()
    private let thirdRowStackView = KeyboardRowStackView()
    private let fourthRowStackView = KeyboardRowStackView()
    
    private lazy var keyButtonList = naratgeulKeyList.map { KeyButton(layout: .hangeul, keys: $0) }
    private let deleteButton = DeleteButton(layout: .hangeul)
    private let spaceButton = SpaceButton(layout: .hangeul)
    private let returnButton = ReturnButton(layout: .hangeul)
    private let switchButton = SwitchButton(layout: .hangeul)
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    func configure() {
        
    }
}

// MARK: - UI Methods

private extension HangeulView {
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
        firstRowStackView.addArrangedSubviews(keyButtonList[0], keyButtonList[1], keyButtonList[2], deleteButton)
        secondRowStackView.addArrangedSubviews(keyButtonList[3], keyButtonList[4], keyButtonList[5], spaceButton)
        thirdRowStackView.addArrangedSubviews(keyButtonList[6], keyButtonList[7], keyButtonList[8], returnButton)
        fourthRowStackView.addArrangedSubviews(keyButtonList[9], keyButtonList[10], keyButtonList[11], switchButton)
    }
    
    func setConstraints() {
        frameStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
