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

    private let hangeulLabel = UILabel()
    private let englishLabel = UILabel()
    private let dividerLayer = CAShapeLayer()

    // MARK: - Initializer

    public convenience init(mode: HangeulEnglishLanguageMode) {
        self.init(
            mode: mode,
            keyboard: mode == .hangeul ? .dubeolsik : .qwerty
        )
    }

    init(mode: HangeulEnglishLanguageMode, keyboard: SYKeyboardType) {
        super.init(keyboard: keyboard)

        primaryKeyListLabel.isHidden = true
        hangeulLabel.text = "한"
        englishLabel.text = "영"
        accessibilityLabel = "한영 전환"
        dividerLayer.fillColor = UIColor.clear.cgColor
        dividerLayer.lineCap = .round
        dividerLayer.lineWidth = 1.5
        backgroundView.layer.addSublayer(dividerLayer)
        [hangeulLabel, englishLabel].forEach(addSubview)
        setupLabels()
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

    public override func layoutSubviews() {
        super.layoutSubviews()

        dividerLayer.frame = backgroundView.bounds
        dividerLayer.strokeColor = UIColor.label.cgColor
        let bounds = backgroundView.bounds
        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.midX - 4, y: bounds.midY + 7))
        path.addLine(to: CGPoint(x: bounds.midX + 4, y: bounds.midY - 7))
        dividerLayer.path = path.cgPath
    }

    // MARK: - Public Methods

    public func updateLanguageMode(_ mode: HangeulEnglishLanguageMode) {
        hangeulLabel.textColor = mode == .hangeul ? .label : .languageSwitchMutedLabel
        englishLabel.textColor = mode == .english ? .label : .languageSwitchMutedLabel
        accessibilityValue = mode == .hangeul ? "한글" : "영어"
    }
}

// MARK: - UI Methods

private extension LanguageSwitchButton {
    func setupLabels() {
        [hangeulLabel, englishLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.font = .systemFont(ofSize: FontSize.stringKeyMedium)
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = 0.5
        }

        NSLayoutConstraint.activate([
            hangeulLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            hangeulLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            hangeulLabel.trailingAnchor.constraint(lessThanOrEqualTo: englishLabel.leadingAnchor),
            englishLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
            englishLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor)
        ])
    }
}
