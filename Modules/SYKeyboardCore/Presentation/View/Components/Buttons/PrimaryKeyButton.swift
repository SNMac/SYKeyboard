//
//  PrimaryKeyButton.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 주 키 버튼
final public class PrimaryKeyButton: PrimaryButton, TextInteractable {
    
    // MARK: - Properties
    
    /// 버튼 정렬 관리용
    enum KeyAlignment {
        case center  // 일반 키
        case left  // 영어 키보드의 'l' 키처럼 왼쪽에 붙는 키
        case right  // 영어 키보드의 'a' 키처럼 오른쪽에 붙는 키
    }
    
    private var keyAlignment: KeyAlignment = .center
    
    /// 나랏글 획/쌍 키의 점 기호 표기(`ㆍ` U+318D, `ᆢ` U+11A2)
    ///
    /// 나랏글 전용 매핑이다. 다른 레이아웃에 `"획"`, `"쌍"` 키가 생기면 keyboard 타입으로 게이트해야 한다.
    private static let naratgeulDotLabels: [String: String] = ["획": "\u{318D}", "쌍": "\u{11A2}"]
    
    public private(set) var type: TextInteractableType {
        didSet {
            if type.primaryKeyList.isEmpty {
                self.isHidden = true
            } else {
                updatePrimaryKeyListLabel()
                self.isHidden = false
            }
            
            updateSecondaryKeyListLabel()
        }
    }
    
    // MARK: - UI Components
    
    let secondaryKeyLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: FontSize.stringKeySmall, weight: .regular)
        label.textColor = .secondaryLabel
        label.isHidden = !(UserDefaultsManager.shared.selectedLongPressAction == .numberInput)
        
        return label
    }()
    
    // MARK: - Initializer
    
    public init(keyboard: SYKeyboardType, button: TextInteractableType) {
        self.type = button
        super.init(keyboard: keyboard)
        
        setupUI()
        updatePrimaryKeyListLabel()
        updateSecondaryKeyListLabel()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    public override func playFeedback() {
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playKeyTypingSound()
    }
    
    // MARK: - Internal Methods
    
    func update(buttonType: TextInteractableType) {
        self.type = buttonType
    }
    
    /// 입력 식별자를 화면에 표시할 문자로 변환합니다.
    ///
    /// 입력 식별자(`NaratgeulProcessor`가 비교하는 `"획"`, `"쌍"`)는 그대로 두고 표기만 바꾼다.
    static func displayLabel(for primaryKey: String) -> String {
        guard let dotLabel = naratgeulDotLabels[primaryKey],
              UserDefaultsManager.shared.isNaratgeulDotLabelEnabled else { return primaryKey }
        return dotLabel
    }
}

// MARK: - UI Methods

private extension PrimaryKeyButton {
    func setupUI() {
        setHierarchy()
        setConstraints()
    }
    
    func setHierarchy() {
        self.addSubview(secondaryKeyLabel)
    }
    
    func setConstraints() {
        let offsetX = insetDx + 2
        let offsetY = insetDy + 2
        
        secondaryKeyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secondaryKeyLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: offsetY),
            secondaryKeyLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -offsetX)
        ])
    }
}

// MARK: - Update Methods

private extension PrimaryKeyButton {
    func updatePrimaryKeyListLabel() {
        if type.primaryKeyList.count == 1 {
            // 함수 참조는 비격리 클로저로 전달돼 @MainActor 경고가 난다. 클로저로 감싸 격리를 유지한다
            guard let primaryKey = type.primaryKeyList.first.map({ Self.displayLabel(for: $0) }) else { return }
            primaryKeyListLabel.text = primaryKey
            
            if primaryKey.count == 1 {
                if Character(primaryKey).isLowercase {
                    primaryKeyListLabel.font = .systemFont(ofSize: FontSize.charKeyLarge)
                } else {
                    primaryKeyListLabel.font = .systemFont(ofSize: FontSize.charKeyMedium)
                }
            } else {
                primaryKeyListLabel.font = .systemFont(ofSize: FontSize.stringKeyMedium)
            }
        } else {
            primaryKeyListLabel.text = type.primaryKeyList.map { Self.displayLabel(for: $0) }.joined(separator: "")
            primaryKeyListLabel.font = .systemFont(ofSize: FontSize.charKeyMedium)
        }
    }
    
    /// 코너 라벨은 주 키 표기가 아닌 입력 식별자와 비교한다.
    /// 표기 설정으로 라벨이 바뀌어도(`획` -> `ㆍ`) 중복 노출되지 않도록 하기 위함.
    func updateSecondaryKeyListLabel() {
        guard let secondaryKey = type.secondaryKey else { return }
        if type.primaryKeyList.joined(separator: "") == secondaryKey {
            secondaryKeyLabel.text = ""
        } else {
            secondaryKeyLabel.text = secondaryKey
        }
    }
}
