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

    /// 현재 표시 중인 언어 모드
    public private(set) var languageMode: HangeulEnglishLanguageMode = .hangeul

    private let hangeulLabel = UILabel()
    private let englishLabel = UILabel()
    private let dividerLayer = CAShapeLayer()

    /// 기본 글자 크기
    private let maximumLabelFontSize: CGFloat = 14.0
    /// 구분선과 글자 사이 간격. 버튼 크기와 무관하게 고정한다
    private let dividerLabelSpacing: CGFloat = 3.0
    /// 글자가 버튼 밖으로 밀려나지 않게 하는 최소 여백
    private let minimumEdgeInset: CGFloat = 3.0
    /// 구분선 가로 반길이의 버튼 너비 대비 상한
    private static let dividerWidthRatio: CGFloat = 0.22
    /// 구분선 세로 반길이의 버튼 높이 대비 상한
    private static let dividerHeightRatio: CGFloat = 0.20
    /// 45° 하한이 걸리는 낮은 키에서 쓰는 세로 예산 배수.
    /// 세로 예산(`dividerHeightRatio`)만으로 자르면 획이 세로 모드보다 짧아져 뭉툭해 보인다
    private static let dividerClampedHeightBoost: CGFloat = 1.5
    /// 버튼 너비 대비 글자 크기 비율
    static let labelFontSizeToWidthRatio: CGFloat = 0.38
    /// 글자 크기 대비 구분선 두께 비율. 기본 글자 크기에서 1.5가 되도록 맞춘다
    static let dividerLineWidthToFontSizeRatio: CGFloat = 1.5 / 14.0

    /// 현재 적용된 글자 크기
    private var appliedLabelFontSize: CGFloat = 0
    /// 글자 프레임 안에서 실제 글자가 그려지는 영역까지의 여백
    private var hangeulInkInsets: UIEdgeInsets = .zero
    private var englishInkInsets: UIEdgeInsets = .zero

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
        englishLabel.text = "A"
        dividerLayer.fillColor = UIColor.clear.cgColor
        dividerLayer.lineCap = .round
        backgroundView.layer.addSublayer(dividerLayer)
        [hangeulLabel, englishLabel].forEach(addSubview)
        applyLabelFont(size: maximumLabelFontSize)
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

        let keyBounds = backgroundView.bounds
        updateLabelFontIfNeeded(forKeyWidth: keyBounds.width)

        dividerLayer.frame = keyBounds
        dividerLayer.strokeColor = UIColor.label.cgColor
        dividerLayer.lineWidth = Self.dividerLineWidth(forFontSize: appliedLabelFontSize)

        let halfExtents = Self.dividerHalfExtents(forKeySize: keyBounds.size)
        let halfWidth = halfExtents.width
        let halfHeight = halfExtents.height

        let path = UIBezierPath()
        path.move(to: CGPoint(x: keyBounds.midX - halfWidth, y: keyBounds.midY + halfHeight))
        path.addLine(to: CGPoint(x: keyBounds.midX + halfWidth, y: keyBounds.midY - halfHeight))
        dividerLayer.path = path.cgPath

        layoutLabels(halfWidth: halfWidth, halfHeight: halfHeight)
    }

    // MARK: - Public Methods

    public func updateLanguageMode(_ mode: HangeulEnglishLanguageMode) {
        languageMode = mode
        hangeulLabel.textColor = mode == .hangeul ? .label : .languageSwitchMutedLabel
        englishLabel.textColor = mode == .english ? .label : .languageSwitchMutedLabel
    }
}

// MARK: - Internal Methods

extension LanguageSwitchButton {
    /// 버튼 너비에 맞는 글자 크기.
    ///
    /// 기본 크기를 상한으로 두고, 버튼이 좁아지면 너비에 비례해 줄입니다.
    /// 구분선 길이도 너비 비례라 함께 줄어들어 글자와 구분선이 겹치지 않습니다.
    static func labelFontSize(forKeyWidth width: CGFloat, maximum: CGFloat) -> CGFloat {
        guard width > 0 else { return maximum }

        return min(maximum, width * labelFontSizeToWidthRatio)
    }

    /// 글자 크기에 맞는 구분선 두께.
    /// 글자와 함께 줄어들어야 마크 전체의 비례가 유지됩니다.
    static func dividerLineWidth(forFontSize fontSize: CGFloat) -> CGFloat {
        return fontSize * dividerLineWidthToFontSizeRatio
    }

    /// 구분선 반길이.
    ///
    /// 세로 모드처럼 키가 높으면 두 비율을 그대로 쓴다.
    /// 가로 모드처럼 키가 낮아 사선이 45°보다 누울 때만 두 반길이를 같게 맞추고,
    /// 이때는 세로 예산을 `dividerClampedHeightBoost`배까지 써서 획이 짧아지지 않게 한다
    static func dividerHalfExtents(forKeySize size: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return .zero }

        let halfWidth = size.width * dividerWidthRatio
        let halfHeight = size.height * dividerHeightRatio
        guard halfWidth >= halfHeight else {
            return CGSize(width: halfWidth, height: halfHeight)
        }

        let clamped = min(halfWidth, halfHeight * dividerClampedHeightBoost)
        return CGSize(width: clamped, height: clamped)
    }
}

// MARK: - UI Methods

private extension LanguageSwitchButton {
    /// 버튼 너비에 맞춰 글자 크기를 정한다.
    /// 한 손 키보드처럼 버튼이 좁아지면 글자가 구분선과 겹치므로 함께 줄인다
    func updateLabelFontIfNeeded(forKeyWidth width: CGFloat) {
        applyLabelFont(size: Self.labelFontSize(forKeyWidth: width, maximum: maximumLabelFontSize))
    }

    func applyLabelFont(size: CGFloat) {
        guard size > 0, abs(size - appliedLabelFontSize) > 0.01 else { return }

        appliedLabelFontSize = size
        let font = UIFont.systemFont(ofSize: size)
        [hangeulLabel, englishLabel].forEach { $0.font = font }
        hangeulInkInsets = Self.inkInsets(of: hangeulLabel)
        englishInkInsets = Self.inkInsets(of: englishLabel)
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
