//
//  EnglishKeyboardView.swift
//  EnglishKeyboard
//
//  Created by 서동환 on 9/8/25.
//

import UIKit

import SnapKit
import Then

/// 영어 키보드
final class EnglishKeyboardView: QwertyKeyboard, EnglishKeyboardLayout {
    
    // MARK: - Properties
    
    override var keyboard: SYKeyboardType { .english }
    override var keyList: [[[[String]]]] { currentEnglishKeyboardMode.keyList }
    
    var currentEnglishKeyboardMode: EnglishKeyboardMode = .default {
        didSet(oldMode) { updateLayoutForCurrentEnglishMode(oldMode: oldMode) }
    }
    
    var isCapsLocked: Bool = false {
        didSet {
            shiftButton.updateCapsLockState(to: isCapsLocked)
            updateKeyButtonList()
        }
    }
    var willCapsLock: Bool = false
    
    private let getIsUppercaseInput: () -> Bool
    private let resetIsUppercaseInput: () -> Void

    // MARK: - Initializer
    
    init(getIsUppercaseInput: @escaping () -> Bool,
         resetIsUppercaseInput: @escaping () -> Void) {
        self.getIsUppercaseInput = getIsUppercaseInput
        self.resetIsUppercaseInput = resetIsUppercaseInput
        super.init(frame: .zero)
        
        updateLayoutToDefault()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    override func setShiftButtonAction() {
        let enableShift = UIAction { [weak self] _ in
            guard let self else { return }
            if isCapsLocked {
                willCapsLock = false
                isCapsLocked = false
            } else {
                willCapsLock = true
            }
            wasShifted = isShifted
            isShifted = true
        }
        shiftButton.addAction(enableShift, for: .touchDown)
        
        let toggleCapsLock = UIAction { [weak self] action in
            guard let self else { return }
            if willCapsLock {
                isCapsLocked = true
            }
        }
        shiftButton.addAction(toggleCapsLock, for: .touchDownRepeat)
        
        let disableShift = UIAction { [weak self] _ in
            guard let self else { return }
            if (!isCapsLocked && wasShifted) || getIsUppercaseInput() {
                isShifted = false
                resetIsUppercaseInput()
            }
        }
        shiftButton.addAction(disableShift, for: .touchUpInside)
    }
}
