//
//  NumericView.swift
//  Keyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

import SnapKit

final class NumericView: UIView {
    
    // MARK: - Properties
    
    private let numericKeyList = [
        [ ["1"], ["2"], ["3"] ],
        [ ["4"], ["5"], ["6"] ],
        [ ["7"], ["8"], ["9"] ],
        [ ["-"], [","], ["0"], ["."], ["/"] ]
    ]
    
    // MARK: - UI Components
    
    private let spacer = KeyboardSpacer()
    
    private let frameStackView = KeyboardFrameStackView()
    
    private let firstRowStackView = KeyboardRowStackView()
    private let secondRowStackView = KeyboardRowStackView()
    private let thirdRowStackView = KeyboardRowStackView()
    private let fourthRowLeftStackView = KeyboardRowStackView()
    private let fourthRowStackView = KeyboardRowStackView()
    private let fourthRowRightStackView = KeyboardRowStackView()
    
    private lazy var firstRowKeyButtonList = numericKeyList[0].map { KeyButton(layout: .numeric, keys: $0) }
    private lazy var secondRowKeyButtonList = numericKeyList[1].map { KeyButton(layout: .numeric, keys: $0) }
    private lazy var thirdRowKeyButtonList = numericKeyList[2].map { KeyButton(layout: .numeric, keys: $0) }
    private lazy var fourthRowKeyButtonList = numericKeyList[3].map { KeyButton(layout: .numeric, keys: $0) }
    
    private let deleteButton = DeleteButton(layout: .numeric)
    private let spaceButton = SpaceButton(layout: .numeric)
    private let returnButton = ReturnButton(layout: .numeric)
    private let switchButton = SwitchButton(layout: .numeric)
    
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
