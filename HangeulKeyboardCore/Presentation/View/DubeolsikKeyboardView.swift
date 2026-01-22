//
//  DubeolsikKeyboardView.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 1/23/26.
//

import UIKit

import SYKeyboardCore

final class DubeolsikKeyboardView: StandardKeyboardView, HangeulKeyboardLayoutProvider {
    
    // MARK: - Properties
    
    override var keyboard: SYKeyboardType { .dubeolsik }
    
    /// 두벌식 키보드 키 배열
    override var primaryKeyList: [[[[String]]]] {
        [
            [
                [ ["ㅂ"], ["ㅈ"], ["ㄷ"], ["ㄱ"], ["ㅅ"], ["ㅛ"], ["ㅕ"], ["ㅑ"], ["ㅐ"], ["ㅔ"] ],
                [ ["ㅁ"], ["ㄴ"], ["ㅇ"], ["ㄹ"], ["ㅎ"], ["ㅗ"], ["ㅓ"], ["ㅏ"], ["ㅣ"] ],
                [ ["ㅋ"], ["ㅌ"], ["ㅊ"], ["ㅍ"], ["ㅠ"], ["ㅜ"], ["ㅡ"] ]
            ],
            [
                [ ["ㅃ"], ["ㅉ"], ["ㄸ"], ["ㄲ"], ["ㅆ"], ["ㅛ"], ["ㅕ"], ["ㅑ"], ["ㅒ"], ["ㅖ"] ],
                [ ["ㅁ"], ["ㄴ"], ["ㅇ"], ["ㄹ"], ["ㅎ"], ["ㅗ"], ["ㅓ"], ["ㅏ"], ["ㅣ"] ],
                [ ["ㅋ"], ["ㅌ"], ["ㅊ"], ["ㅍ"], ["ㅠ"], ["ㅜ"], ["ㅡ"] ]
            ]
        ]
    }
    
    override var secondaryKeyList: [[[[String]]]] {
        [
            [
                [ ["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"] ],
                [ [], [], [], [], [], [], [], [], [] ],
                [ [], [], [], [], [], [], [] ]
            ],
            [
                [ ["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"] ],
                [ [], [], [], [], [], [], [], [], [] ],
                [ [], [], [], [], [], [], [] ]
            ]
        ]
    }
    
    final var currentHangeulKeyboardMode: HangeulKeyboardMode = .default {
        didSet(oldMode) { updateLayoutForCurrentHangeulMode(oldMode: oldMode) }
    }
    
    init() {
        super.init(frame: .zero)
        updateLayoutToDefault()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Private Methods

private extension DubeolsikKeyboardView {
    /// periodButton에 걸려있는 기존 Width 제약 조건을 찾아 제거합니다.
    func removePeriodButtonWidthConstraints() {
        guard let superview = periodButton.superview else { return }
        
        let constraintsToRemove = superview.constraints.filter { constraint in
            guard let firstItem = constraint.firstItem as? UIView else { return false }
            return firstItem == periodButton && constraint.firstAttribute == .width
        }
        
        NSLayoutConstraint.deactivate(constraintsToRemove)
    }
    
    /// 기존 제약 조건을 제거하고 새로운 너비(Multiplier) 제약 조건을 설정합니다.
    func remakePeriodButtonWidthConstraint(multiplier: CGFloat) {
        removePeriodButtonWidthConstraints()
        
        guard let superview = periodButton.superview else { return }
        let newConstraint = periodButton.widthAnchor.constraint(equalTo: superview.widthAnchor, multiplier: multiplier)
        newConstraint.isActive = true
    }
}

// MARK: - HangeulKeyboardLayoutProvider Methods

extension DubeolsikKeyboardView {
    func updateLayoutToDefault() {
        spaceButton.isHidden = false
        atButton.isHidden = true
        periodButton.isHidden = true
        slashButton.isHidden = true
        dotComButton.isHidden = true
        
        returnButton.isHidden = false
        secondaryAtButton.isHidden = true
        secondarySharpButton.isHidden = true
        
        initShiftButton()
    }
    
    func updateLayoutToURL() {
        spaceButton.isHidden = true
        atButton.isHidden = true
        periodButton.isHidden = false
        slashButton.isHidden = false
        dotComButton.isHidden = false

        removePeriodButtonWidthConstraints()

        returnButton.isHidden = false
        secondaryAtButton.isHidden = true
        secondarySharpButton.isHidden = true

        initShiftButton()
    }
    
    func updateLayoutToEmailAddress() {
        spaceButton.isHidden = false
        atButton.isHidden = false
        periodButton.isHidden = false
        slashButton.isHidden = true
        dotComButton.isHidden = true

        remakePeriodButtonWidthConstraint(multiplier: 0.25)

        returnButton.isHidden = false
        secondaryAtButton.isHidden = true
        secondarySharpButton.isHidden = true

        initShiftButton()
    }
    
    func updateLayoutToWebSearch() {
        spaceButton.isHidden = false
        atButton.isHidden = true
        periodButton.isHidden = false
        slashButton.isHidden = true
        dotComButton.isHidden = true

        remakePeriodButtonWidthConstraint(multiplier: 0.20)

        returnButton.isHidden = false
        secondaryAtButton.isHidden = true
        secondarySharpButton.isHidden = true

        initShiftButton()
    }
}
