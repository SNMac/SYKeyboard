//
//  EnglishKeyboardView.swift
//  EnglishKeyboardCore
//
//  Created by 서동환 on 9/8/25.
//

import UIKit

import SYKeyboardCore

/// 영어 키보드
final class EnglishKeyboardView: StandardKeyboardView, EnglishKeyboardLayoutProvider {
    
    // MARK: - Properties
    
    override var keyboard: SYKeyboardType { .qwerty }
    override var primaryKeyList: [[[[String]]]] { currentEnglishKeyboardMode.primaryKeyList }
    override var secondaryKeyList: [[[[String]]]] { currentEnglishKeyboardMode.secondaryKeyList }
    
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
            if (!isCapsLocked && wasShifted) || getIsShiftedLetterInput() {
                isShifted = false
                setIsShiftedLetterInput(false)
            }
        }
        shiftButton.addAction(disableShift, for: .touchUpInside)
    }
}
