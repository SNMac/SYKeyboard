//
//  SwitchButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit
import Then

/// 키보드 전환 버튼
final class SwitchButton: SecondaryButton {
    
    // MARK: - Properties
    
    private let layout: KeyboardLayout
    private let title: String
    
    // MARK: - UI Components
    
    private lazy var oneHandedLabel = UILabel().then {
        $0.attributedText = createOneHandedAttributedText(needToEmphasize: false)
        $0.font = .systemFont(ofSize: 9)
    }
    
    private lazy var keyboardSelectLabel = UILabel().then {
        $0.attributedText = createKeyboardSelectAttributedText(needToEmphasize: false)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.backgroundView.bounds.width < 44 {
            let attributes = AttributeContainer([.font: UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular), .foregroundColor: UIColor.label])
            self.configuration?.attributedTitle = AttributedString(title, attributes: attributes)
        }
    }
    
    // MARK: - Internal Methods
    
    func configureOneHandedComponent(needToEmphasize: Bool) {
        oneHandedLabel.attributedText = createOneHandedAttributedText(needToEmphasize: needToEmphasize)
    }
    
    func configureKeyboardSelectComponent(needToEmphasize: Bool) {
        keyboardSelectLabel.attributedText = createKeyboardSelectAttributedText(needToEmphasize: needToEmphasize)
    }
}

// MARK: - UI Methods

private extension SwitchButton {
    func setupUI() {
        setStyles()
        setActions()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        oneHandedLabel.isHidden = !UserDefaultsManager.shared.isOneHandedKeyboardEnabled
        keyboardSelectLabel.isHidden = !UserDefaultsManager.shared.isNumericKeypadEnabled
        
        let attributes = AttributeContainer([.font: UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .regular), .foregroundColor: UIColor.label])
        self.configuration?.attributedTitle = AttributedString(title, attributes: attributes)
    }
    
    func setActions() {
        let playFeedback = UIAction { _ in
            FeedbackManager.shared.playModifierSound()
            FeedbackManager.shared.playHaptic()
        }
        self.addAction(playFeedback, for: .touchDown)
    }
    
    func setHierarchy() {
        self.addSubviews(oneHandedLabel, keyboardSelectLabel)
    }
    
    func setConstraints() {
        switch layout {
        case .symbol:
            oneHandedLabel.snp.makeConstraints {
                $0.top.equalToSuperview().inset(self.insetDy + 1)
                $0.leading.equalToSuperview().inset(self.insetDx + 1)
            }
            
            keyboardSelectLabel.snp.makeConstraints {
                $0.trailing.equalToSuperview().inset(self.insetDx + 1)
                $0.bottom.equalToSuperview().inset(self.insetDy + 1)
            }
        default:
            oneHandedLabel.snp.makeConstraints {
                $0.top.equalToSuperview().inset(self.insetDy + 1)
                $0.trailing.equalToSuperview().inset(self.insetDx + 1)
            }
            
            keyboardSelectLabel.snp.makeConstraints {
                $0.leading.equalToSuperview().inset(self.insetDx + 1)
                $0.bottom.equalToSuperview().inset(self.insetDy + 1)
            }
        }
    }
}

// MARK: - Private Methods

private extension SwitchButton {
    func createOneHandedAttributedText(needToEmphasize: Bool) -> NSAttributedString? {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 9, weight: needToEmphasize ? .bold : .regular)
        
        let arrowtriangleUp = NSTextAttachment()
        arrowtriangleUp.image = UIImage(systemName: needToEmphasize ? "arrowtriangle.up.fill" : "arrowtriangle.up")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        let keyboard = NSTextAttachment()
        keyboard.image = UIImage(systemName: "keyboard")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        
        let fullString: NSMutableAttributedString?
        switch layout {
        case .hangeul, .numeric:
            fullString = NSMutableAttributedString(attachment: keyboard)
            fullString?.append(NSAttributedString(attachment: arrowtriangleUp))
        case .symbol:
            fullString = NSMutableAttributedString(attachment: arrowtriangleUp)
            fullString?.append(NSAttributedString(attachment: keyboard))
        default:
            fullString = nil
        }
        return fullString
    }
    
    func createKeyboardSelectAttributedText(needToEmphasize: Bool) -> NSAttributedString? {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 9, weight: needToEmphasize ? .bold : .regular)
        let font = UIFont.systemFont(ofSize: 9, weight: needToEmphasize ? .bold : .regular)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label]
        
        let text: String
        let arrowtriangle = NSTextAttachment()
        let fullString: NSMutableAttributedString?
        
        switch layout {
        case .hangeul:
            text = "123"
            arrowtriangle.image = UIImage(systemName: needToEmphasize ? "arrowtriangle.left.fill" : "arrowtriangle.left")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            
            let textAttributedString = NSAttributedString(string: text, attributes: attributes)
            fullString = NSMutableAttributedString(attachment: arrowtriangle)
            fullString?.append(textAttributedString)
        case .symbol:
            text = "123"
            arrowtriangle.image = UIImage(systemName: needToEmphasize ? "arrowtriangle.right.fill" : "arrowtriangle.right")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            
            let textAttributedString = NSAttributedString(string: text, attributes: attributes)
            fullString = NSMutableAttributedString(attributedString: textAttributedString)
            fullString?.append(NSAttributedString(attachment: arrowtriangle))
        case .numeric:
            text = "!#1"
            arrowtriangle.image = UIImage(systemName: needToEmphasize ? "arrowtriangle.left.fill" : "arrowtriangle.left")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            
            let textAttributedString = NSAttributedString(string: text, attributes: attributes)
            fullString = NSMutableAttributedString(attachment: arrowtriangle)
            fullString?.append(textAttributedString)
        default:
            fullString = nil
        }
        
        return fullString
    }
}
