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

    /// 글자가 버튼 가장자리에 붙지 않도록 하는 여백
    private let labelInset: CGFloat = 4.0
    /// 두 글자가 나란히 들어가도 축소되지 않는 글자 크기
    private let labelFontSize: CGFloat = 14.0
    /// 구분선 가로 반길이의 버튼 너비 대비 비율
    private let dividerWidthRatio: CGFloat = 0.22
    /// 구분선 세로 반길이의 버튼 높이 대비 비율
    private let dividerHeightRatio: CGFloat = 0.20

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
        let halfWidth = bounds.width * dividerWidthRatio
        let halfHeight = bounds.height * dividerHeightRatio
        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.midX - halfWidth, y: bounds.midY + halfHeight))
        path.addLine(to: CGPoint(x: bounds.midX + halfWidth, y: bounds.midY - halfHeight))
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
            $0.font = .systemFont(ofSize: labelFontSize)
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = 0.5
        }

        NSLayoutConstraint.activate([
            hangeulLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: labelInset),
            hangeulLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: labelInset),
            hangeulLabel.trailingAnchor.constraint(lessThanOrEqualTo: englishLabel.leadingAnchor),
            englishLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -labelInset),
            englishLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -labelInset)
        ])
    }
}
