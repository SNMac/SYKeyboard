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
    
    // MARK: - Initializer
    
    override init(
        getIsShiftedLetterInput: @escaping () -> Bool,
        setIsShiftedLetterInput: @escaping (Bool) -> ()
    ) {
        super.init(
            getIsShiftedLetterInput: getIsShiftedLetterInput,
            setIsShiftedLetterInput: setIsShiftedLetterInput
        )
        updateLayoutToDefault()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

        updatePeriodButtonWidthConstraint(multiplier: nil)

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

        updatePeriodButtonWidthConstraint(multiplier: 0.25)

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

        updatePeriodButtonWidthConstraint(multiplier: 0.20)

        returnButton.isHidden = false
        secondaryAtButton.isHidden = true
        secondarySharpButton.isHidden = true

        initShiftButton()
    }
}
