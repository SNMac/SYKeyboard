//
//  NumericView.swift
//  Keyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

import SnapKit

/// 숫자 키보드
final class NumericView: UIView {
    
    // MARK: - Properties
    
    /// 숫자 키보드 키 배열
    private let numericKeyList = [
        [ ["1"], ["2"], ["3"] ],
        [ ["4"], ["5"], ["6"] ],
        [ ["7"], ["8"], ["9"] ],
        [ ["-"], [","], ["0"], ["."], ["/"] ]
    ]
    
    // MARK: - UI Components
    
    /// 상단 여백
    private let topSpacer = KeyboardSpacer()
    /// 키보드 레이아웃 프레임
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
    /// 키보드 네번째 좌측 `PrimaryButton` 행
    private let fourthRowLeftPrimaryButtonHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 우측 `PrimaryButton` 행
    private let fourthRowRightPrimaryButtonHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 우측 `SecondaryButton` 행
    private let fourthRowRightSecondaryButtonHStackView = KeyboardRowHStackView()
    
    /// 키보드 첫번째 행 `KeyButton` 배열
    private lazy var firstRowKeyButtonList = numericKeyList[0].map { KeyButton(layout: .numeric, keys: $0) }
    /// 키보드 두번째 행 `KeyButton` 배열
    private lazy var secondRowKeyButtonList = numericKeyList[1].map { KeyButton(layout: .numeric, keys: $0) }
    /// 키보드 세번째 행 `KeyButton` 배열
    private lazy var thirdRowKeyButtonList = numericKeyList[2].map { KeyButton(layout: .numeric, keys: $0) }
    /// 키보드 네번째 행 `KeyButton` 배열
    private lazy var fourthRowKeyButtonList = numericKeyList[3].map { KeyButton(layout: .numeric, keys: $0) }
    
    /// 삭제 버튼
    private let deleteButton = DeleteButton(layout: .numeric)
    /// 스페이스 버튼
    private let spaceButton = SpaceButton(layout: .numeric)
    /// 리턴 버튼
    private let returnButton = ReturnButton(layout: .numeric)
    /// 키보드 전환 버튼
    private(set) var switchButton = SwitchButton(layout: .numeric)
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

private extension NumericView {
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
        firstRowHStackView.addArrangedSubview(deleteButton)
        
        secondRowKeyButtonList.forEach { secondRowHStackView.addArrangedSubview($0) }
        secondRowHStackView.addArrangedSubview(spaceButton)
        
        thirdRowKeyButtonList.forEach { thirdRowHStackView.addArrangedSubview($0) }
        thirdRowHStackView.addArrangedSubview(returnButton)
        
        fourthRowHStackView.addArrangedSubviews(fourthRowLeftPrimaryButtonHStackView, fourthRowKeyButtonList[2], fourthRowRightPrimaryButtonHStackView, fourthRowRightSecondaryButtonHStackView)
        fourthRowLeftPrimaryButtonHStackView.addArrangedSubviews(fourthRowKeyButtonList[0], fourthRowKeyButtonList[1])
        fourthRowRightPrimaryButtonHStackView.addArrangedSubviews(fourthRowKeyButtonList[3], fourthRowKeyButtonList[4])
        fourthRowRightSecondaryButtonHStackView.addArrangedSubview(switchButton)
        // iPhone SE일 때 키보드 전환 버튼 추가
        if let nextKeyboardButton {
            fourthRowRightSecondaryButtonHStackView.addArrangedSubview(nextKeyboardButton)
        }
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

// MARK: - Action Methods

private extension NumericView {
    func setNextKeyboardButtonTarget(action: Selector) {
        switchButton.configuration?.attributedTitle?.font = .system(size: 16)
        nextKeyboardButton = NextKeyboardButton(layout: .numeric)
        nextKeyboardButton?.addTarget(nil, action: action, for: .allTouchEvents)
    }
}
