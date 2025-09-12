//
//  TenkeyKeyboardView.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

import SnapKit
import Then

/// 텐키 키보드
final class TenkeyKeyboardView: UIView, TenkeyKeyboardLayout {
    
    // MARK: - Properties
    
    private(set) lazy var totalTextInteractionButtonList: [TextInteractionButton] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList + fourthRowKeyButtonList
    + [periodButton, deleteButton]
    
    var currentTenkeyKeyboardMode: TenkeyKeyboardMode = .numberPad {
        didSet(oldMode) { updateLayoutForCurrentTenkeyKeyboardMode(oldMode: oldMode) }
    }
    
    /// 텐키 키보드 키 배열
    private let tenKeyList = [
        [ ["1"], ["2"], ["3"] ],
        [ ["4"], ["5"], ["6"] ],
        [ ["7"], ["8"], ["9"] ],
        [ ["0"] ]
    ]
    
    // MARK: - UI Components
    
    /// 상단 여백
    private let topSpacer = KeyboardSpacer()
    /// 키보드 레이아웃 수직 스택
    private let layoutVStackView = KeyboardLayoutVStackView()
    /// 하단 여백
    private let bottomSpacer = KeyboardSpacer()
    
    /// 키보드 첫번째 행
    private let firstRowHStackView = KeyboardRowHStackView()
    /// 키보드 두번째 행
    private let secondRowHStackView = KeyboardRowHStackView()
    /// 키보드 세번째 행
    private let thirdRowHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 행
    private let fourthRowHStackView = KeyboardRowHStackView()
    
    /// 키보드 첫번째 행 `PrimaryButton` 배열
    private lazy var firstRowKeyButtonList = tenKeyList[0].map { PrimaryKeyButton(keyboard: .tenKey, button: .keyButton(keys: $0)) }
    /// 키보드 두번째 행 `PrimaryButton` 배열
    private lazy var secondRowKeyButtonList = tenKeyList[1].map { PrimaryKeyButton(keyboard: .tenKey, button: .keyButton(keys: $0)) }
    /// 키보드 세번째 행 `PrimaryButton` 배열
    private lazy var thirdRowKeyButtonList = tenKeyList[2].map { PrimaryKeyButton(keyboard: .tenKey, button: .keyButton(keys: $0)) }
    /// 키보드 네번째 행 `PrimaryButton` 배열
    private lazy var fourthRowKeyButtonList = tenKeyList[3].map { PrimaryKeyButton(keyboard: .tenKey, button: .keyButton(keys: $0)) }
    
    private(set) var bottomLeftButtonSpacer = KeyboardSpacer()
    private(set) var periodButton = SecondaryKeyButton(keyboard: .tenKey, button: .keyButton(keys: ["."]))
    private(set) var deleteButton = DeleteButton(keyboard: .tenKey)
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        updateLayoutToNumberPad()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension TenkeyKeyboardView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
    }
    
    func setHierarchy() {
        self.addSubviews(topSpacer,
                         layoutVStackView,
                         bottomSpacer)
        
        layoutVStackView.addArrangedSubviews(firstRowHStackView,
                                             secondRowHStackView,
                                             thirdRowHStackView,
                                             fourthRowHStackView)
        
        firstRowKeyButtonList.forEach { firstRowHStackView.addArrangedSubview($0) }
        
        secondRowKeyButtonList.forEach { secondRowHStackView.addArrangedSubview($0) }
        
        thirdRowKeyButtonList.forEach { thirdRowHStackView.addArrangedSubview($0) }
        
        fourthRowHStackView.addArrangedSubviews(bottomLeftButtonSpacer, periodButton)
        fourthRowKeyButtonList.forEach { fourthRowHStackView.addArrangedSubview($0) }
        fourthRowHStackView.addArrangedSubview(deleteButton)
    }
    
    func setConstraints() {
        topSpacer.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(2)
        }
        
        layoutVStackView.snp.makeConstraints {
            $0.top.equalTo(topSpacer.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomSpacer.snp.top)
        }
        
        bottomSpacer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(2)
        }
    }
}
