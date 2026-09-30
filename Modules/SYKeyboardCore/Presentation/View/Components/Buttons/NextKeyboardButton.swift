//
//  NextKeyboardButton.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/15/25.
//

import UIKit

/// iPhone SE용 키보드 전환 버튼
final public class NextKeyboardButton: SecondaryButton {
    
    // MARK: - Properties
    
    private let keyboard: SYKeyboardType

    /// 지구본 기호와 키 가장자리 사이 최소 여백
    private static let imageEdgeInset: CGFloat = 2.0

    /// 기본 크기 지구본 기호. 축소 비율의 기준이 된다
    private lazy var fullSizeGlobeImage: UIImage? = globeImage(pointSize: FontSize.imageMedium)
    /// 현재 적용된 기호 크기
    private var appliedImagePointSize: CGFloat = FontSize.imageMedium
    
    // MARK: - Initializer
    
    public override init(keyboard: SYKeyboardType) {
        self.keyboard = keyboard
        super.init(keyboard: keyboard)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    /// 한 손 키보드처럼 키가 좁아지면 기호가 키 밖으로 나가므로 너비에 맞춰 줄인다
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let fullSizeGlobeImage, fullSizeGlobeImage.size.width > 0 else { return }
        
        let availableWidth = max(0, backgroundView.bounds.width - Self.imageEdgeInset * 2)
        let pointSize = FontSize.imageMedium * min(1, availableWidth / fullSizeGlobeImage.size.width)
        guard abs(pointSize - appliedImagePointSize) > 0.01 else { return }
        
        appliedImagePointSize = pointSize
        primaryKeyListImageView.image = globeImage(pointSize: pointSize)
    }
    
    public override func playFeedback() {
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playModifierSound()
    }
}

// MARK: - UI Methods

private extension NextKeyboardButton {
    func setupUI() {
        setStyles()
        setActions()
    }
    
    func setStyles() {
        primaryKeyListImageView.image = fullSizeGlobeImage
    }
    
    func globeImage(pointSize: CGFloat) -> UIImage? {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium, scale: .large)
        return UIImage(systemName: "globe")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
    }
    
    func setActions() {
        let setSelected = UIAction { [weak self] _ in self?.isGesturing = true }
        self.addAction(setSelected, for: [.touchDragInside, .touchDragOutside])
        
        let setDeselected = UIAction { [weak self] _ in self?.isGesturing = false }
        self.addAction(setDeselected, for: [.touchUpInside, .touchUpOutside])
    }
}
