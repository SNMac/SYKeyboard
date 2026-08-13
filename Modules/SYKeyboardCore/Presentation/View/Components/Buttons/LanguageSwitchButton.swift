//
//  LanguageSwitchButton.swift
//  SYKeyboardCore
//
//  Created by Codex on 8/13/26.
//

import UIKit

import SYKeyboardAssets

/// 통합 키보드의 한영 전환 버튼
public final class LanguageSwitchButton: SecondaryButton {

    // MARK: - Properties

    public private(set) var attributedTitleForCurrentMode = NSAttributedString(string: "한/영")
    public private(set) var activeTitleRange = NSRange(location: 0, length: 2)
    public private(set) var mutedTitleRange = NSRange(location: 2, length: 1)

    // MARK: - Initializer

    public convenience init(mode: HangeulEnglishLanguageMode) {
        self.init(
            mode: mode,
            keyboard: mode == .hangeul ? .dubeolsik : .qwerty
        )
    }

    init(mode: HangeulEnglishLanguageMode, keyboard: SYKeyboardType) {
        super.init(keyboard: keyboard)

        primaryKeyListLabel.font = .systemFont(ofSize: FontSize.stringKeyMedium)
        primaryKeyListLabel.adjustsFontSizeToFitWidth = true
        primaryKeyListLabel.minimumScaleFactor = 0.5
        updateLanguageMode(mode)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override Methods

    public override func playFeedback() {
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playModifierSound()
    }

    // MARK: - Public Methods

    public func updateLanguageMode(_ mode: HangeulEnglishLanguageMode) {
        switch mode {
        case .hangeul:
            activeTitleRange = NSRange(location: 0, length: 2)
            mutedTitleRange = NSRange(location: 2, length: 1)
        case .english:
            activeTitleRange = NSRange(location: 1, length: 2)
            mutedTitleRange = NSRange(location: 0, length: 1)
        }

        let title = NSMutableAttributedString(string: "한/영")
        title.addAttribute(.foregroundColor, value: UIColor.label, range: activeTitleRange)
        title.addAttribute(
            .foregroundColor,
            value: UIColor.languageSwitchMutedLabel,
            range: mutedTitleRange
        )
        attributedTitleForCurrentMode = title
        primaryKeyListLabel.attributedText = title
    }
}
