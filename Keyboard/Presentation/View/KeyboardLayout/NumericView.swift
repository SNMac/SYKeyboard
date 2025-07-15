//
//  NumericView.swift
//  Keyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

import SnapKit

/// 숫자 자판 `UIView`
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
    
    /// 상단 여백 `KeyboardSpacer`
    private let spacer = KeyboardSpacer()
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
    /// 키보드 네번째 좌측 행 `KeyboardRowStackView`
    private let fourthRowLeftStackView = KeyboardRowStackView()
    /// 키보드 네번째 우측 행 `KeyboardRowStackView`
    private let fourthRowRightStackView = KeyboardRowStackView()
    
    /// 키보드 첫번째 행 `KeyButton` 배열
    private lazy var firstRowKeyButtonList = numericKeyList[0].map { KeyButton(layout: .numeric, keys: $0) }
    /// 키보드 두번째 행 `KeyButton` 배열
    private lazy var secondRowKeyButtonList = numericKeyList[1].map { KeyButton(layout: .numeric, keys: $0) }
    /// 키보드 세번째 행 `KeyButton` 배열
    private lazy var thirdRowKeyButtonList = numericKeyList[2].map { KeyButton(layout: .numeric, keys: $0) }
    /// 키보드 네번째 행 `KeyButton` 배열
    private lazy var fourthRowKeyButtonList = numericKeyList[3].map { KeyButton(layout: .numeric, keys: $0) }
    
    /// 삭제 버튼 `DeleteButton`
    private let deleteButton = DeleteButton(layout: .numeric)
    /// 스페이스 버튼 `SpaceButton`
    private let spaceButton = SpaceButton(layout: .numeric)
    /// 리턴 버튼 `ReturnButton`
    private let returnButton = ReturnButton(layout: .numeric)
    /// 자판 전환 버튼 `SwitchButton`
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
        self.addSubviews(spacer,
                         frameStackView)
        
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
        
        fourthRowStackView.addArrangedSubviews(fourthRowLeftStackView, fourthRowKeyButtonList[2], fourthRowRightStackView, switchButton)
        fourthRowLeftStackView.addArrangedSubviews(fourthRowKeyButtonList[0], fourthRowKeyButtonList[1])
        fourthRowRightStackView.addArrangedSubviews(fourthRowKeyButtonList[3], fourthRowKeyButtonList[4])
    }
    
    func setConstraints() {
        spacer.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(2)
        }
        
        frameStackView.snp.makeConstraints {
            $0.top.equalTo(spacer.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
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
        
        fourthRowLeftStackView.arrangedSubviews.forEach { subview in
            subview.snp.makeConstraints {
                $0.width.equalToSuperview().dividedBy(fourthRowLeftStackView.arrangedSubviews.count)
            }
        }
        
        fourthRowRightStackView.arrangedSubviews.forEach { subview in
            subview.snp.makeConstraints {
                $0.width.equalToSuperview().dividedBy(fourthRowRightStackView.arrangedSubviews.count)
            }
        }
    }
}

// MARK: - Action Methods

private extension NumericView {
    func setNextKeyboardButtonTarget(action: Selector) {
        nextKeyboardButton = NextKeyboardButton(layout: .numeric)
        nextKeyboardButton?.addTarget(nil, action: action, for: .allTouchEvents)
    }
}
