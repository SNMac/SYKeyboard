//
//  SwitchButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit
import Then

/// 자판 전환 버튼
final class SwitchButton: SecondaryButton {
    
    // MARK: - Properties
    
    private let layout: KeyboardLayout
    private let title: String
    
    // MARK: - UI Components
    
    private lazy var oneHandedLabel = UILabel().then {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 9, weight: .regular)
        
        let arrowtriangleUp = NSTextAttachment()
        arrowtriangleUp.image = UIImage(systemName: "arrowtriangle.up")?.withConfiguration(imageConfig)
        let keyboard = NSTextAttachment()
        keyboard.image = UIImage(systemName: "keyboard")?.withConfiguration(imageConfig)
        
        let fullString: NSMutableAttributedString?
        switch layout {
        case .hangeul:
            fullString = NSMutableAttributedString(attachment: keyboard)
            fullString?.append(NSMutableAttributedString(attachment: arrowtriangleUp))
        case .symbol:
            fullString = NSMutableAttributedString(attachment: arrowtriangleUp)
            fullString?.append(NSMutableAttributedString(attachment: keyboard))
        case .numeric:
            fullString = NSMutableAttributedString(attachment: keyboard)
            fullString?.append(NSMutableAttributedString(attachment: arrowtriangleUp))
        default:
            fullString = nil
        }
        
        $0.attributedText = fullString
        $0.font = .systemFont(ofSize: 9)
    }
    
    private lazy var swipeModeLabel = UILabel().then {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 9, weight: .regular)
        
        let text: String
        let arrowtriangle = NSTextAttachment()
        let fullString: NSMutableAttributedString?
        switch layout {
        case .hangeul:
            text = "123"
            arrowtriangle.image = UIImage(systemName: "arrowtriangle.left")?.withConfiguration(imageConfig)
            fullString = NSMutableAttributedString(attachment: arrowtriangle)
            fullString?.append(NSMutableAttributedString(string: text))
        case .symbol:
            text = "123"
            arrowtriangle.image = UIImage(systemName: "arrowtriangle.right")?.withConfiguration(imageConfig)
            fullString = NSMutableAttributedString(string: text)
            fullString?.append(NSMutableAttributedString(attachment: arrowtriangle))
        case .numeric:
            text = "!#1"
            arrowtriangle.image = UIImage(systemName: "arrowtriangle.left")?.withConfiguration(imageConfig)
            fullString = NSMutableAttributedString(attachment: arrowtriangle)
            fullString?.append(NSMutableAttributedString(string: text))
        default:
            text = ""
            fullString = nil
        }
        
        $0.attributedText = fullString
        $0.font = .systemFont(ofSize: 9)
    }
    
    // MARK: - Initializer
    
    override init(layout: KeyboardLayout) {
        self.layout = layout
        switch layout {
        case .hangeul:
            self.title = "!#1"
        case .symbol:
            self.title = "한글"
        case .numeric:
            self.title = "한글"
        default:
            self.title = ""
        }
        super.init(layout: layout)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.isHighlighted = true
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        self.isHighlighted = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.isHighlighted = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.isHighlighted = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.backgroundView.bounds.width < 44 {
            let attributes = AttributeContainer([.font: UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular), .foregroundColor: UIColor.label])
            self.configuration?.attributedTitle = AttributedString(title, attributes: attributes)
        }
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
        let attributes = AttributeContainer([.font: UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .regular), .foregroundColor: UIColor.label])
        self.configuration?.attributedTitle = AttributedString(title, attributes: attributes)
    }
    
    func setViewHierarchy() {
        self.addSubviews(oneHandedLabel, swipeModeLabel)
    }
    
    func setConstraints() {
        switch layout {
        case .symbol:
            oneHandedLabel.snp.makeConstraints {
                $0.top.equalToSuperview().inset(super.insetDy + 1)
                $0.leading.equalToSuperview().inset(super.insetDx + 1)
            }
            
            swipeModeLabel.snp.makeConstraints {
                $0.trailing.equalToSuperview().inset(super.insetDx + 1)
                $0.bottom.equalToSuperview().inset(super.insetDy + 1)
            }
        default:
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
}
