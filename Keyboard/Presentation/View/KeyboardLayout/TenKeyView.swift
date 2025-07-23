//
//  TenKeyView.swift
//  Keyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

import SnapKit

/// 텐키 키보드
final class TenKeyView: UIView {
    
    // MARK: - Properties
    
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
    
    /// 키보드 첫번째 행 `KeyButton` 배열
    private lazy var firstRowKeyButtonList = tenKeyList[0].map { KeyButton(layout: .tenKey, keys: $0) }
    /// 키보드 두번째 행 `KeyButton` 배열
    private lazy var secondRowKeyButtonList = tenKeyList[1].map { KeyButton(layout: .tenKey, keys: $0) }
    /// 키보드 세번째 행 `KeyButton` 배열
    private lazy var thirdRowKeyButtonList = tenKeyList[2].map { KeyButton(layout: .tenKey, keys: $0) }
    /// 키보드 네번째 행 `KeyButton` 배열
    private lazy var fourthRowKeyButtonList = tenKeyList[3].map { KeyButton(layout: .tenKey, keys: $0) }
    
    /// 키보드 네번째 행 좌측 여백
    private let buttonSpacer = KeyboardSpacer()
    /// 삭제 버튼
    private let deleteButton = DeleteButton(layout: .tenKey)
    
    // MARK: - Initializer
    
    init() {
        super.init(frame: .zero)
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
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {}
    
    func setHierarchy() {
        self.addSubviews(topSpacer,
                         frameStackView,
                         bottomSpacer)
        
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
    }
}
