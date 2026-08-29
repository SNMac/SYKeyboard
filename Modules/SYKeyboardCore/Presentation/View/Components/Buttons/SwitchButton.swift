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
    private let keyboardSelectDirection: PanDirection
    public private(set) var titleForCurrentKeyboard: String

    /// 보조 라벨이 기본 크기 그대로 들어가는 최소 키 폭.
    /// 한 손 키보드처럼 이보다 좁아지면 글자가 키 밖으로 나가므로 너비에 비례해 줄인다
    private static let subLabelFullSizeKeyWidth: CGFloat = 25.0

    /// 보조 라벨이 기본 크기 그대로 들어가는 최소 키 높이.
    /// 기본 `keyboardHeight`(240)에서 세로 모드 행 높이는 60pt, 가로 모드는 36pt로 낮아
    /// 모서리 힌트가 가운데 라벨과 겹치므로 높이에도 비례해 줄인다.
    /// 세로 모드 최소 키 높이(쿼티 40pt)를 기준값으로 잡아 세로 크기는 그대로 둔다.
    /// `keyboardHeight` 슬라이더 최소값(190)에서는 세로 쿼티 키 높이가 39.5pt로
    /// 살짝 낮아져 힌트 글자 크기가 8.0이 아닌 7.9가 되는 의도된 0.1pt 오차가 있다
    private static let subLabelFullSizeKeyHeight: CGFloat = 40.0

    /// 현재 보조 라벨에 적용된 글자 크기
    private var appliedSubLabelFontSize: CGFloat = FontSize.stringKeySmall
    /// 보조 라벨 강조 상태. 너비가 바뀌어 다시 만들 때도 유지해야 한다
    private var isOneHandedEmphasized = false
    private var isKeyboardSelectEmphasized = false
    
    // MARK: - UI Components
    
    private lazy var oneHandedLabel: UILabel = {
        let label = UILabel()
        label.attributedText = createOneHandedAttributedText(needToEmphasize: false)
        label.font = .systemFont(ofSize: FontSize.stringKeySmall)
        label.isHidden = !UserDefaultsManager.shared.isOneHandedKeyboardEnabled
        
        return label
    }()
    
    private lazy var keyboardSelectLabel: UILabel = {
        let label = UILabel()
        label.attributedText = createKeyboardSelectAttributedText(needToEmphasize: false)
        label.font = .systemFont(ofSize: FontSize.stringKeySmall)
        label.isHidden = !UserDefaultsManager.shared.isNumericKeypadEnabled
        
        return label
    }()
    
    // MARK: - Initializer
    
    public init(keyboard: SYKeyboardType, usesBottomSpaceLayout: Bool = false) {
        self.keyboard = keyboard
        self.keyboardSelectDirection = KeyboardSelectDirectionPolicy.targetDirection(
            for: keyboard,
            usesBottomSpaceLayout: usesBottomSpaceLayout
        )
        switch keyboard {
        case .naratgeul, .cheonjiin, .dubeolsik, .qwerty:
            self.titleForCurrentKeyboard = "!#1"
        case .symbol, .numeric:
            let primaryLanguage: String
            if Bundle.primaryLanguage != nil {
                primaryLanguage = Bundle.primaryLanguage!
            } else {
                logger.critical("Info.plist에서 PrimaryLanguage 값을 찾을 수 없습니다.")
                primaryLanguage = Self.previewPrimaryLanguage
            }
            
            if primaryLanguage == "ko-KR" {
                self.titleForCurrentKeyboard = "한글"
            } else if primaryLanguage == "en-US" {
                self.titleForCurrentKeyboard = "ABC"
            } else if primaryLanguage == "mul" {
                self.titleForCurrentKeyboard = "한글"
            } else {
                assertionFailure("구현이 필요한 키보드입니다.")
                self.titleForCurrentKeyboard = "한글"
            }
        case .tenKey:
            assertionFailure("도달할 수 없는 case입니다.")
            self.titleForCurrentKeyboard = ""
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
        
        primaryKeyListLabel.text = titleForCurrentKeyboard
        if backgroundView.bounds.width < 38 {
            primaryKeyListLabel.font = .monospacedDigitSystemFont(ofSize: FontSize.stringKeyMedium - 4, weight: .regular)
        } else if backgroundView.bounds.width < 44 {
            primaryKeyListLabel.font = .monospacedDigitSystemFont(ofSize: FontSize.stringKeyMedium - 2, weight: .regular)
        } else {
            primaryKeyListLabel.font = .monospacedDigitSystemFont(ofSize: FontSize.stringKeyMedium, weight: .regular)
        }

        let subLabelFontSize = Self.subLabelFontSize(forKeyWidth: backgroundView.bounds.width,
                                                    keyHeight: backgroundView.bounds.height)
        guard abs(subLabelFontSize - appliedSubLabelFontSize) > 0.01 else { return }

        appliedSubLabelFontSize = subLabelFontSize
        configureOneHandedComponent(needToEmphasize: isOneHandedEmphasized)
        configureKeyboardSelectComponent(needToEmphasize: isKeyboardSelectEmphasized)
    }
    
    // MARK: - Override Methods
    
    public override func playFeedback() {
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playModifierSound()
    }
    
    // MARK: - Internal Methods
    
    func configureOneHandedComponent(needToEmphasize: Bool) {
        isOneHandedEmphasized = needToEmphasize
        oneHandedLabel.attributedText = createOneHandedAttributedText(needToEmphasize: needToEmphasize)
    }
    
    func configureKeyboardSelectComponent(needToEmphasize: Bool) {
        isKeyboardSelectEmphasized = needToEmphasize
        keyboardSelectLabel.attributedText = createKeyboardSelectAttributedText(needToEmphasize: needToEmphasize)
    }

    /// 키 크기에 맞는 보조 라벨 글자 크기.
    /// 기본 크기를 상한으로 두고, 키가 좁거나 낮아지면 좁은 쪽 기준으로 줄인다
    static func subLabelFontSize(forKeyWidth width: CGFloat, keyHeight height: CGFloat) -> CGFloat {
        guard width > 0, height > 0 else { return FontSize.stringKeySmall }

        return min(FontSize.stringKeySmall,
                   FontSize.stringKeySmall * width / subLabelFullSizeKeyWidth,
                   FontSize.stringKeySmall * height / subLabelFullSizeKeyHeight)
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
        primaryKeyListLabel.text = titleForCurrentKeyboard
        primaryKeyListLabel.font = .monospacedDigitSystemFont(ofSize: FontSize.stringKeyMedium, weight: .regular)
        // 사다리식 최소 크기로도 넘치는 좁은 키에서 글자가 키 밖으로 나가지 않게 한다
        primaryKeyListLabel.adjustsFontSizeToFitWidth = true
        primaryKeyListLabel.minimumScaleFactor = 0.5
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
        
        // 목표 라벨이 오른쪽에 있으면 힌트도 오른쪽 아래 모서리에 붙는다
        switch keyboardSelectDirection {
        case .right:
            constraints.append(oneHandedLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: offsetX))
            constraints.append(keyboardSelectLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -offsetX))

        default:
            constraints.append(oneHandedLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -offsetX))
            constraints.append(keyboardSelectLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: offsetX))
        }
        
        NSLayoutConstraint.activate(constraints)
    }
}

// MARK: - Update Methods

public extension SwitchButton {
    func updatePrimaryLanguageMode(_ mode: HangeulEnglishLanguageMode) {
        guard keyboard == .symbol || keyboard == .numeric else { return }

        titleForCurrentKeyboard = mode == .hangeul ? "한글" : "ABC"
        primaryKeyListLabel.text = titleForCurrentKeyboard
        setNeedsLayout()
    }
}

// MARK: - Private Methods

private extension SwitchButton {
    func createOneHandedAttributedText(needToEmphasize: Bool) -> NSAttributedString? {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: appliedSubLabelFontSize, weight: needToEmphasize ? .bold : .regular)
        
        let arrowtriangleUp = NSTextAttachment()
        arrowtriangleUp.image = UIImage(systemName: needToEmphasize ? "arrowtriangle.up.fill" : "arrowtriangle.up")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "keyboard")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        
        let fullString: NSMutableAttributedString?
        switch keyboard {
        case .naratgeul, .cheonjiin, .dubeolsik, .qwerty, .symbol, .numeric:
            switch keyboardSelectDirection {
            case .right:
                fullString = NSMutableAttributedString(attachment: arrowtriangleUp)
                fullString?.append(NSAttributedString(attachment: attachment))
            default:
                fullString = NSMutableAttributedString(attachment: attachment)
                fullString?.append(NSAttributedString(attachment: arrowtriangleUp))
            }
        default:
            fullString = nil
        }
        return fullString
    }
    
    func createKeyboardSelectAttributedText(needToEmphasize: Bool) -> NSAttributedString? {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: appliedSubLabelFontSize, weight: needToEmphasize ? .bold : .regular)
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: appliedSubLabelFontSize, weight: needToEmphasize ? .bold : .regular),
                                                         .foregroundColor: UIColor.label]
        
        let text: String
        switch keyboard {
        case .naratgeul, .cheonjiin, .dubeolsik, .qwerty, .symbol:
            text = "123"
        case .numeric:
            text = "!#1"
        default:
            return nil
        }

        let arrowtriangle = NSTextAttachment()
        let textAttributedString = NSAttributedString(string: text, attributes: attributes)
        let fullString: NSMutableAttributedString

        switch keyboardSelectDirection {
        case .right:
            arrowtriangle.image = UIImage(systemName: needToEmphasize ? "arrowtriangle.right.fill" : "arrowtriangle.right")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            fullString = NSMutableAttributedString(attributedString: textAttributedString)
            fullString.append(NSAttributedString(attachment: arrowtriangle))
        default:
            arrowtriangle.image = UIImage(systemName: needToEmphasize ? "arrowtriangle.left.fill" : "arrowtriangle.left")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            fullString = NSMutableAttributedString(attachment: arrowtriangle)
            fullString.append(textAttributedString)
        }

        return fullString
    }
}
