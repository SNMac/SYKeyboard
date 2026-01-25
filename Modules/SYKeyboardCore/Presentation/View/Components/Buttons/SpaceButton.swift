//
//  SpaceButton.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

/// 스페이스 버튼
final public class SpaceButton: PrimaryButton, TextInteractable {
    
    // MARK: - Properties
    
    public let type: TextInteractableType

    private let imageConfig = UIImage.SymbolConfiguration(pointSize: FontSize.imageSize, weight: .medium, scale: .large)
    
    // MARK: - Initializer
    
    public override init(keyboard: SYKeyboardType) {
        self.type = .spaceButton
        super.init(keyboard: keyboard)
        
        setupUI()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    public override func playFeedback() {
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playModifierSound()
    }
    
    // MARK: - Internal Methods
    
    /// 버튼의 시스템 이미지를 업데이트합니다.
    func updateImage(systemName: String) {
        primaryKeyListImageView.image = UIImage(systemName: systemName)?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
    }
}

// MARK: - UI Methods

private extension SpaceButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        primaryKeyListImageView.image = UIImage(systemName: "space")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
    }
}
