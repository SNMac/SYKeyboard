//
//  EnglishKeyboardInputAdapter.swift
//  EnglishKeyboardCore
//
//  Created by Codex on 8/13/26.
//

import UIKit

import SYKeyboardCore

/// 영어 Shift/CapsLock과 키보드 view 상태를 재사용 가능한 형태로 제공합니다.
public final class EnglishKeyboardInputAdapter {

    // MARK: - Properties

    private var isUppercaseInput = false

    private lazy var englishKeyboardView: EnglishKeyboardLayoutProvider = EnglishKeyboardView(
        getIsShiftedLetterInput: { [weak self] in self?.isUppercaseInput ?? false },
        setIsShiftedLetterInput: { [weak self] in self?.isUppercaseInput = $0 }
    )

    public var primaryKeyboardView: PrimaryKeyboardRepresentable {
        return englishKeyboardView
    }

    public var isShifted: Bool {
        return englishKeyboardView.isShifted
    }

    public var isCapsLocked: Bool {
        return englishKeyboardView.isCapsLocked
    }

    // MARK: - Initializer

    public init(showsLanguageSwitchButton: Bool = false) {
        _ = showsLanguageSwitchButton
    }

    // MARK: - Public Methods

    public func recordInsertedText(_ text: String) {
        if text.count == 1, Character(text).isUppercase {
            isUppercaseInput = true
        }
    }

    public func updateShiftAfterInput(isShiftButtonPressed: Bool) {
        guard !isShiftButtonPressed else { return }

        if isUppercaseInput {
            englishKeyboardView.updateShiftButton(to: false)
        }
        isUppercaseInput = false
    }

    public func updateAutocapitalization(
        type: UITextAutocapitalizationType,
        documentContextBeforeInput: String?,
        isEnabled: Bool,
        isShiftButtonPressed: Bool
    ) {
        guard !isShiftButtonPressed else { return }

        var shouldShift = false
        if isEnabled {
            switch type {
            case .allCharacters:
                shouldShift = true
            case .sentences:
                shouldShift = documentContextBeforeInput?.hasOnlyWhitespaceAfterLastDot() ?? true
            case .words:
                shouldShift = documentContextBeforeInput?.endsWithWhitespace() ?? true
            default:
                break
            }
        }

        englishKeyboardView.updateShiftButton(to: shouldShift)
        isUppercaseInput = false
    }

    public func updateLayout(for keyboardType: UIKeyboardType?) {
        switch keyboardType {
        case .default, nil, .asciiCapable, .numbersAndPunctuation:
            englishKeyboardView.currentEnglishKeyboardMode = .default
        case .URL:
            englishKeyboardView.currentEnglishKeyboardMode = .URL
        case .emailAddress:
            englishKeyboardView.currentEnglishKeyboardMode = .emailAddress
        case .twitter:
            englishKeyboardView.currentEnglishKeyboardMode = .twitter
        case .webSearch:
            englishKeyboardView.currentEnglishKeyboardMode = .webSearch
        case .numberPad, .phonePad, .namePhonePad, .decimalPad, .asciiCapableNumberPad:
            break
        @unknown default:
            assertionFailure("구현이 필요한 case 입니다.")
            englishKeyboardView.currentEnglishKeyboardMode = .default
        }
    }

    public func finishForLanguageChange() {
        englishKeyboardView.initShiftButton()
        isUppercaseInput = false
    }
}
