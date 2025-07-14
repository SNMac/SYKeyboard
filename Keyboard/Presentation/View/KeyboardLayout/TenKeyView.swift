//
//  TenKeyView.swift
//  Keyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

import SnapKit

final class TenKeyView: UIView {
    
    // MARK: - Properties
    
    private let tenKeyList = [
        [ ["1"], ["2"], ["3"] ],
        [ ["4"], ["5"], ["6"] ],
        [ ["7"], ["8"], ["9"] ],
        [ ["0"] ]
    ]
    
    // MARK: - UI Components
    
    /// 상단 여백 `KeyboardSpacer`
    private let spacer = KeyboardSpacer()
    /// 키보드 프레임 `KeyboardFrameStackView`
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
    private lazy var firstRowKeyButtonList = tenKeyList[0].map { KeyButton(layout: .tenKey, keys: $0) }
    /// 키보드 두번째 행 `KeyButton` 배열
    private lazy var secondRowKeyButtonList = tenKeyList[1].map { KeyButton(layout: .tenKey, keys: $0) }
    /// 키보드 세번째 행 `KeyButton` 배열
    private lazy var thirdRowKeyButtonList = tenKeyList[2].map { KeyButton(layout: .tenKey, keys: $0) }
    /// 키보드 네번째 행 `KeyButton` 배열
    private lazy var fourthRowKeyButtonList = tenKeyList[3].map { KeyButton(layout: .tenKey, keys: $0) }
    
    /// 키보드 네번째 행 좌측 여백 `KeyboardSpacer`
    private let buttonSpacer = KeyboardSpacer()
    /// 삭제 버튼 `DeleteButton`
    private let deleteButton = DeleteButton(layout: .hangeul)
    
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

private extension TenKeyView {
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
        
        secondRowKeyButtonList.forEach { secondRowStackView.addArrangedSubview($0) }
        
        thirdRowKeyButtonList.forEach { thirdRowStackView.addArrangedSubview($0) }
        
        fourthRowStackView.addArrangedSubview(buttonSpacer)
        fourthRowKeyButtonList.forEach { fourthRowStackView.addArrangedSubview($0) }
        fourthRowStackView.addArrangedSubview(deleteButton)
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
    }
}
