//
//  SwitchButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit
import Then

final class SwitchButton: SecondaryButton {
    
    // MARK: - UI Components
    
    private let oneHandedLabel = UILabel().then {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 9, weight: .regular)
        
        let arrowtriangleUp = NSTextAttachment()
        arrowtriangleUp.image = UIImage(systemName: "arrowtriangle.up")?.withConfiguration(imageConfig)
        let keyboard = NSTextAttachment()
        keyboard.image = UIImage(systemName: "keyboard")?.withConfiguration(imageConfig)
        
        let fullString = NSMutableAttributedString(attachment: arrowtriangleUp)
        fullString.append(NSMutableAttributedString(attachment: keyboard))
        $0.attributedText = fullString
        $0.font = .systemFont(ofSize: 9)
    }
    
    private let swipeModeLabel = UILabel().then {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 9, weight: .regular)
        
        let arrowtriangleLeft = NSTextAttachment()
        arrowtriangleLeft.image = UIImage(systemName: "arrowtriangle.left")?.withConfiguration(imageConfig)
        
        let fullString = NSMutableAttributedString(attachment: arrowtriangleLeft)
        fullString.append(NSMutableAttributedString(string: "123"))
        $0.attributedText = fullString
        $0.font = .systemFont(ofSize: 9)
    }
    
    // MARK: - Initializer
    
    override init(layout: KeyboardLayout) {
        super.init(layout: layout)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    func configure() {
        
    }
}

// MARK: - UI Methods

private extension SwitchButton {
    func setupUI() {
        setStyles()
        setViewHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        guard var buttonConfig = self.configuration else { return }
        let attributes = AttributeContainer([.font: UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .regular), .foregroundColor: UIColor.label])
        buttonConfig.attributedTitle = AttributedString("!#1", attributes: attributes)
        self.configuration = buttonConfig
    }
    
    func setViewHierarchy() {
        self.addSubviews(oneHandedLabel, swipeModeLabel)
    }
    
    func setConstraints() {
        oneHandedLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(super.insetDy + 1)
            $0.trailing.equalToSuperview().inset(super.insetDx + 1)
        }
        
        swipeModeLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(super.insetDx + 1)
            $0.bottom.equalToSuperview().inset(super.insetDy + 1)
        }
    }
}
