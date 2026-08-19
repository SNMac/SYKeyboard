//
//  LanguageSwitchButton.swift
//  SYKeyboardCore
//
//  Created by Codex on 8/13/26.
//

import CoreText
import UIKit

import SYKeyboardAssets

/// 통합 키보드의 한영 전환 버튼
public final class LanguageSwitchButton: SecondaryButton {

    // MARK: - Properties

    private let hangeulLabel = UILabel()
    private let englishLabel = UILabel()
    private let dividerLayer = CAShapeLayer()

    /// 글자 크기
    private let labelFontSize: CGFloat = 14.0
    /// 구분선과 글자 사이 간격. 버튼 크기와 무관하게 고정한다
    private let dividerLabelSpacing: CGFloat = 3.0
    /// 글자가 버튼 밖으로 밀려나지 않게 하는 최소 여백
    private let minimumEdgeInset: CGFloat = 3.0
    /// 구분선 가로 반길이의 버튼 너비 대비 비율
    private let dividerWidthRatio: CGFloat = 0.22
    /// 구분선 세로 반길이의 버튼 높이 대비 비율
    private let dividerHeightRatio: CGFloat = 0.20

    /// 글자 프레임 안에서 실제 글자가 그려지는 영역까지의 여백
    private lazy var hangeulInkInsets = Self.inkInsets(of: hangeulLabel)
    private lazy var englishInkInsets = Self.inkInsets(of: englishLabel)

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

        let keyBounds = backgroundView.bounds
        let halfWidth = keyBounds.width * dividerWidthRatio
        let halfHeight = keyBounds.height * dividerHeightRatio

        let path = UIBezierPath()
        path.move(to: CGPoint(x: keyBounds.midX - halfWidth, y: keyBounds.midY + halfHeight))
        path.addLine(to: CGPoint(x: keyBounds.midX + halfWidth, y: keyBounds.midY - halfHeight))
        dividerLayer.path = path.cgPath

        layoutLabels(halfWidth: halfWidth, halfHeight: halfHeight)
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
            $0.font = .systemFont(ofSize: labelFontSize)
        }
    }

    /// 구분선을 기준으로 두 글자를 배치한다.
    /// 글자는 구분선에서 `dividerLabelSpacing`만큼 수직으로 떨어지고,
    /// 남는 공간이 그대로 버튼 여백이 된다.
    func layoutLabels(halfWidth: CGFloat, halfHeight: CGFloat) {
        let length = hypot(halfWidth, halfHeight)
        guard length > 0 else { return }

        // 구분선에 수직이며 왼쪽 위를 향하는 단위 벡터. `한`이 놓이는 방향이다
        let normalX = -halfHeight / length
        let normalY = -halfWidth / length

        // `backgroundView`는 버튼 안쪽에 들어가 있으므로 버튼 좌표계로 계산한다
        let keyFrame = backgroundView.frame
        let safeArea = keyFrame.insetBy(dx: minimumEdgeInset, dy: minimumEdgeInset)

        let hangeulSize = hangeulLabel.intrinsicContentSize
        let hangeulShift = dividerLabelSpacing
        + abs((hangeulSize.width / 2 - hangeulInkInsets.right) * normalX
              + (hangeulSize.height / 2 - hangeulInkInsets.bottom) * normalY)
        hangeulLabel.frame = clampedFrame(
            size: hangeulSize,
            center: CGPoint(x: keyFrame.midX + normalX * hangeulShift,
                            y: keyFrame.midY + normalY * hangeulShift),
            inkInsets: hangeulInkInsets,
            in: safeArea
        )

        let englishSize = englishLabel.intrinsicContentSize
        let englishShift = dividerLabelSpacing
        + abs((englishSize.width / 2 - englishInkInsets.left) * normalX
              + (englishSize.height / 2 - englishInkInsets.top) * normalY)
        englishLabel.frame = clampedFrame(
            size: englishSize,
            center: CGPoint(x: keyFrame.midX - normalX * englishShift,
                            y: keyFrame.midY - normalY * englishShift),
            inkInsets: englishInkInsets,
            in: safeArea
        )
    }

    /// 글자가 `safeArea` 밖으로 나가지 않도록 위치를 보정한 프레임
    func clampedFrame(
        size: CGSize,
        center: CGPoint,
        inkInsets: UIEdgeInsets,
        in safeArea: CGRect
    ) -> CGRect {
        var frame = CGRect(
            origin: CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2),
            size: size
        )
        let ink = frame.inset(by: inkInsets)

        frame.origin.x += max(0, safeArea.minX - ink.minX) - max(0, ink.maxX - safeArea.maxX)
        frame.origin.y += max(0, safeArea.minY - ink.minY) - max(0, ink.maxY - safeArea.maxY)

        return frame
    }

    /// 글자 프레임과 실제 글자가 그려지는 영역 사이의 여백.
    /// `UILabel` 프레임에는 글꼴의 위아래 여백이 포함되어 있어 그대로 쓰면 간격이 어긋난다
    static func inkInsets(of label: UILabel) -> UIEdgeInsets {
        guard let font = label.font,
              let text = label.text,
              !text.isEmpty else { return .zero }

        let attributedText = NSAttributedString(string: text, attributes: [.font: font])
        let line = CTLineCreateWithAttributedString(attributedText)
        let ink = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        let size = label.intrinsicContentSize

        return UIEdgeInsets(
            top: font.ascender - ink.maxY,
            left: ink.minX,
            bottom: size.height - (font.ascender - ink.minY),
            right: size.width - ink.maxX
        )
    }
}
