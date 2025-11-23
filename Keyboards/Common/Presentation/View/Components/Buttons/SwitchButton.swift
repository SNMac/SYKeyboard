//
//  SwitchButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit
import Then

/// 키보드 전환 버튼
final class SwitchButton: SecondaryButton {
    
    // MARK: - Properties
    
    private let keyboard: SYKeyboardType
    private let title: String
    
    // MARK: - UI Components
    
    private lazy var oneHandedLabel = UILabel().then {
        $0.attributedText = createOneHandedAttributedText(needToEmphasize: false)
        $0.font = .systemFont(ofSize: 9)
        $0.isHidden = !UserDefaultsManager.shared.isOneHandedKeyboardEnabled
    }
    
    private lazy var keyboardSelectLabel = UILabel().then {
        $0.attributedText = createKeyboardSelectAttributedText(needToEmphasize: false)
        $0.font = .systemFont(ofSize: 9)
        $0.isHidden = !UserDefaultsManager.shared.isNumericKeypadEnabled
    }
    
    // MARK: - Initializer
    
    override init(keyboard: SYKeyboardType) {
        self.keyboard = keyboard
        switch keyboard {
        case .hangeul, .english:
            self.title = "!#1"
        case .symbol, .numeric:
            guard let primaryLanguage = Bundle.primaryLanguage else { fatalError("Info.plist에서 PrimaryLanguage 값을 찾을 수 없습니다.") }
            if primaryLanguage == "ko-KR" {
                self.title = "한글"
            } else if primaryLanguage == "en-US" {
                self.title = "ABC"
            } else {
                assertionFailure("구현이 필요한 키보드입니다.")
                self.title = "한글"
            }
        case .tenKey:
            assertionFailure("도달할 수 없는 case입니다.")
            self.title = ""
        }
        super.init(keyboard: keyboard)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.backgroundView.bounds.width < 40 {
            let attributes = AttributeContainer([.font: UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)])
            self.configuration?.attributedTitle = AttributedString(title, attributes: attributes)
        } else if self.backgroundView.bounds.width < 44 {
            let attributes = AttributeContainer([.font: UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)])
            self.configuration?.attributedTitle = AttributedString(title, attributes: attributes)
        } else {
            let attributes = AttributeContainer([.font: UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .regular)])
            self.configuration?.attributedTitle = AttributedString(title, attributes: attributes)
        }
    }
    
    // MARK: - Override Methods
    
    override func playFeedback() {
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playModifierSound()
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
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        oneHandedLabel.isHidden = !UserDefaultsManager.shared.isOneHandedKeyboardEnabled
        keyboardSelectLabel.isHidden = !UserDefaultsManager.shared.isNumericKeypadEnabled
        
        let attributes = AttributeContainer([.font: UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .regular)])
        self.configuration?.attributedTitle = AttributedString(title, attributes: attributes)
    }
    
    func setHierarchy() {
        self.addSubviews(oneHandedLabel, keyboardSelectLabel)
    }
    
    func setConstraints() {
        switch keyboard {
        case .english, .symbol:
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
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "keyboard")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        
        let fullString: NSMutableAttributedString?
        switch keyboard {
        case .hangeul, .numeric:
            fullString = NSMutableAttributedString(attachment: attachment)
            fullString?.append(NSAttributedString(attachment: arrowtriangleUp))
        case .english, .symbol:
            fullString = NSMutableAttributedString(attachment: arrowtriangleUp)
            fullString?.append(NSAttributedString(attachment: attachment))
        default:
            fullString = nil
        }
        return fullString
    }
    
    func createKeyboardSelectAttributedText(needToEmphasize: Bool) -> NSAttributedString? {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 9, weight: needToEmphasize ? .bold : .regular)
        let font = UIFont.systemFont(ofSize: 9, weight: needToEmphasize ? .bold : .regular)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        
        let text: String
        let arrowtriangle = NSTextAttachment()
        let fullString: NSMutableAttributedString?
        
        switch keyboard {
        case .hangeul:
            text = "123"
            arrowtriangle.image = UIImage(systemName: needToEmphasize ? "arrowtriangle.left.fill" : "arrowtriangle.left")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            
            let textAttributedString = NSAttributedString(string: text, attributes: attributes)
            fullString = NSMutableAttributedString(attachment: arrowtriangle)
            fullString?.append(textAttributedString)
        case .english, .symbol:
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
