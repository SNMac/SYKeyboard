//
//  SwitchButton.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/13/25.
//

import UIKit
import OSLog

/// 키보드 전환 버튼
final public class SwitchButton: SecondaryButton {
    
    // MARK: - Properties
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "SwitchButton"
    )
    
    public static var previewPrimaryLanguage: String = "ko-KR"
    
    private let keyboard: SYKeyboardType
    private let title: String
    
    // MARK: - UI Components
    
    private lazy var oneHandedLabel: UILabel = {
        let label = UILabel()
        label.attributedText = createOneHandedAttributedText(needToEmphasize: false)
        label.font = .systemFont(ofSize: 9)
        label.isHidden = !UserDefaultsManager.shared.isOneHandedKeyboardEnabled
        
        return label
    }()
    
    private lazy var keyboardSelectLabel: UILabel = {
        let label = UILabel()
        label.attributedText = createKeyboardSelectAttributedText(needToEmphasize: false)
        label.font = .systemFont(ofSize: 9)
        label.isHidden = !UserDefaultsManager.shared.isNumericKeypadEnabled
        
        return label
    }()
    
    // MARK: - Initializer
    
    public override init(keyboard: SYKeyboardType) {
        self.keyboard = keyboard
        switch keyboard {
        case .naratgeul, .cheonjiin, .dubeolsik, .qwerty:
            self.title = "!#1"
        case .symbol, .numeric:
            let primaryLanguage: String
            if Bundle.primaryLanguage != nil {
                primaryLanguage = Bundle.primaryLanguage!
            } else {
                logger.critical("Info.plist에서 PrimaryLanguage 값을 찾을 수 없습니다.")
                primaryLanguage = Self.previewPrimaryLanguage
            }
            
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
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        primaryKeyListLabel.text = title
        if backgroundView.bounds.width < 38 {
            primaryKeyListLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        } else if backgroundView.bounds.width < 44 {
            primaryKeyListLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .regular)
        } else {
            primaryKeyListLabel.font = .monospacedDigitSystemFont(ofSize: 18, weight: .regular)
        }
    }
    
    // MARK: - Override Methods
    
    public override func playFeedback() {
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
        primaryKeyListLabel.text = title
        primaryKeyListLabel.font = .monospacedDigitSystemFont(ofSize: 18, weight: .regular)
    }
    
    func setHierarchy() {
        [oneHandedLabel, keyboardSelectLabel].forEach { self.addSubview($0) }
    }
    
    func setConstraints() {
        let offsetX = insetDx + 1
        let offsetY = insetDy + 1
        
        oneHandedLabel.translatesAutoresizingMaskIntoConstraints = false
        keyboardSelectLabel.translatesAutoresizingMaskIntoConstraints = false
        var constraints: [NSLayoutConstraint] = [
            oneHandedLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: offsetY),
            keyboardSelectLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -offsetY)
        ]
        
        switch keyboard {
        case .dubeolsik, .qwerty, .symbol:
            constraints.append(oneHandedLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: offsetX))
            constraints.append(keyboardSelectLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -offsetX))
            
        default:
            constraints.append(oneHandedLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -offsetX))
            constraints.append(keyboardSelectLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: offsetX))
        }
        
        NSLayoutConstraint.activate(constraints)
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
        case .naratgeul, .cheonjiin, .numeric:
            fullString = NSMutableAttributedString(attachment: attachment)
            fullString?.append(NSAttributedString(attachment: arrowtriangleUp))
        case .dubeolsik, .qwerty, .symbol:
            fullString = NSMutableAttributedString(attachment: arrowtriangleUp)
            fullString?.append(NSAttributedString(attachment: attachment))
        default:
            fullString = nil
        }
        return fullString
    }
    
    func createKeyboardSelectAttributedText(needToEmphasize: Bool) -> NSAttributedString? {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 9, weight: needToEmphasize ? .bold : .regular)
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 9, weight: needToEmphasize ? .bold : .regular),
                                                         .foregroundColor: UIColor.label]
        
        let text: String
        let arrowtriangle = NSTextAttachment()
        let fullString: NSMutableAttributedString?
        
        switch keyboard {
        case .naratgeul, .cheonjiin:
            text = "123"
            arrowtriangle.image = UIImage(systemName: needToEmphasize ? "arrowtriangle.left.fill" : "arrowtriangle.left")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            
            let textAttributedString = NSAttributedString(string: text, attributes: attributes)
            fullString = NSMutableAttributedString(attachment: arrowtriangle)
            fullString?.append(textAttributedString)
        case .dubeolsik, .qwerty, .symbol:
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
