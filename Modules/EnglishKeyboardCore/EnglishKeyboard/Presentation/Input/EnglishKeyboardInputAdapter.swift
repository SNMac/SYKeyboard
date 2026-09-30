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
    private let showsLanguageSwitchButton: Bool

    private lazy var englishKeyboardView: EnglishKeyboardLayoutProvider = EnglishKeyboardView(
        getIsShiftedLetterInput: { [weak self] in self?.isUppercaseInput ?? false },
        setIsShiftedLetterInput: { [weak self] in self?.isUppercaseInput = $0 },
        showsLanguageSwitchButton: showsLanguageSwitchButton
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
        self.showsLanguageSwitchButton = showsLanguageSwitchButton
    }

    // MARK: - Public Methods

    public func recordInsertedText(_ text: String) {
        if text.count == 1, Character(text).isUppercase {
            isUppercaseInput = true
        }
    }

    /// 자동 대문자 정책에 따라 shift 상태를 정하고 임시 대문자 입력 플래그를 해제합니다.
    ///
    /// 글자 입력 직후 shift 해제도 이 메서드가 함께 처리합니다.
    /// 나눠서 호출하면 같은 결과를 위해 키 라벨 전체 갱신이 두 번 돕니다.
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
