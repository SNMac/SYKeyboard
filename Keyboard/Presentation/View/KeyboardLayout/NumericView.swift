//
//  NumericView.swift
//  Keyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

import SnapKit

/// 숫자 자판
final class NumericView: UIView {
    
    // MARK: - Properties
    
    /// 숫자 자판 키 배열
    private let numericKeyList = [
        [ ["1"], ["2"], ["3"] ],
        [ ["4"], ["5"], ["6"] ],
        [ ["7"], ["8"], ["9"] ],
        [ ["-"], [","], ["0"], ["."], ["/"] ]
    ]
    
    // MARK: - UI Components
    
    /// 상단 여백
    private let topSpacer = KeyboardSpacer()
    /// 키보드 전체 프레임
    private let frameStackView = KeyboardFrameStackView()
    /// 하단 여백
    private let bottomSpacer = KeyboardSpacer()
    
    /// 키보드 첫번째 행
    private let firstRowStackView = KeyboardRowStackView()
    /// 키보드 두번째 행
    private let secondRowStackView = KeyboardRowStackView()
    /// 키보드 세번째 행
    private let thirdRowStackView = KeyboardRowStackView()
    /// 키보드 네번째 행
    private let fourthRowStackView = KeyboardRowStackView()
    /// 키보드 네번째 `KeyButton` 좌측 행
    private let fourthRowPrimaryLeftStackView = KeyboardRowStackView()
    /// 키보드 네번째 `KeyButton` 우측 행
    private let fourthRowPrimaryRightStackView = KeyboardRowStackView()
    /// 키보드 네번째 우측 `SecondaryButton` 행
    private let fourthRowSecondaryRightStackView = KeyboardRowStackView()
    
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
    /// 자판 전환 버튼
    private let switchButton = SwitchButton(layout: .numeric)
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
        setViewHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
    }
    
    func setViewHierarchy() {
        self.addSubviews(topSpacer,
                         frameStackView,
                         bottomSpacer)
        
        frameStackView.addArrangedSubviews(firstRowStackView,
                                           secondRowStackView,
                                           thirdRowStackView,
                                           fourthRowStackView)
        
        firstRowKeyButtonList.forEach { firstRowStackView.addArrangedSubview($0) }
        firstRowStackView.addArrangedSubview(deleteButton)
        
        secondRowKeyButtonList.forEach { secondRowStackView.addArrangedSubview($0) }
        secondRowStackView.addArrangedSubview(spaceButton)
        
        thirdRowKeyButtonList.forEach { thirdRowStackView.addArrangedSubview($0) }
        thirdRowStackView.addArrangedSubview(returnButton)
        
        fourthRowStackView.addArrangedSubviews(fourthRowPrimaryLeftStackView, fourthRowKeyButtonList[2], fourthRowPrimaryRightStackView, fourthRowSecondaryRightStackView)
        fourthRowPrimaryLeftStackView.addArrangedSubviews(fourthRowKeyButtonList[0], fourthRowKeyButtonList[1])
        fourthRowPrimaryRightStackView.addArrangedSubviews(fourthRowKeyButtonList[3], fourthRowKeyButtonList[4])
        fourthRowSecondaryRightStackView.addArrangedSubview(switchButton)
        // iPhone SE일 때 키보드 전환 버튼 추가
        if let nextKeyboardButton {
            fourthRowSecondaryRightStackView.addArrangedSubview(nextKeyboardButton)
        }
    }
    
    func setConstraints() {
        topSpacer.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(2)
        }
        
        frameStackView.snp.makeConstraints {
            $0.top.equalTo(topSpacer.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomSpacer.snp.top)
        }
        
        bottomSpacer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(2)
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
        
        fourthRowStackView.arrangedSubviews.forEach { subview in
            subview.snp.makeConstraints {
                $0.width.equalToSuperview().dividedBy(fourthRowStackView.arrangedSubviews.count)
            }
        }
        
        fourthRowPrimaryLeftStackView.arrangedSubviews.forEach { subview in
            subview.snp.makeConstraints {
                $0.width.equalToSuperview().dividedBy(fourthRowPrimaryLeftStackView.arrangedSubviews.count)
            }
        }
        
        fourthRowPrimaryRightStackView.arrangedSubviews.forEach { subview in
            subview.snp.makeConstraints {
                $0.width.equalToSuperview().dividedBy(fourthRowPrimaryRightStackView.arrangedSubviews.count)
            }
        }
        
        fourthRowSecondaryRightStackView.arrangedSubviews.forEach { subview in
            subview.snp.makeConstraints {
                $0.width.equalToSuperview().dividedBy(fourthRowSecondaryRightStackView.arrangedSubviews.count)
            }
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
