//
//  KeyboardSelectOverlayView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/24/25.
//

import UIKit

/// 키보드 레이아웃 선택 UI
final public class KeyboardSelectOverlayView: UIStackView {
    
    // MARK: - Properties
    
    private let keyboard: SYKeyboardType
    private var isEmphasizingTarget: Bool?
    
    // MARK: - UI Components
    
    /// Material 블러 효과
    private let blurEffect = UIBlurEffect(style: .systemMaterial)
    /// Material 효과를 배경에 적용시키기 위한 뷰
    private lazy var blurView = UIVisualEffectView(effect: blurEffect)
    
    /// 숫자 키보드를 나타내는 라벨
    private let numericLabel: UILabel = {
        let label = UILabel()
        label.text = "123"
        label.font = .systemFont(ofSize: 20, weight: .regular)
        label.textAlignment = .center
        label.clipsToBounds = true
        label.layer.cornerRadius = 8
        
        return label
    }()
    /// 기호 키보드를 나타내는 라벨
    private let symbolLabel: UILabel = {
        let label = UILabel()
        label.text = "!#1"
        label.font = .systemFont(ofSize: 20, weight: .regular)
        label.textAlignment = .center
        label.clipsToBounds = true
        label.layer.cornerRadius = 8
        
        return label
    }()
    /// 키보드 선택 취소 이미지
    private let xmarkImageView: UIImageView = {
        let imageView = UIImageView()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        imageView.image = UIImage(systemName: "xmark.square")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        imageView.contentMode = .center
        
        return imageView
    }()
    /// 키보드 선택 취소 이미지 컨테이너
    private(set) var xmarkImageContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        
        return view
    }()
    
    // MARK: - Initializer
    
    public init(keyboard: SYKeyboardType) {
        self.keyboard = keyboard
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Internal Methods
    
    func configure(needToEmphasizeTarget: Bool) {
        if let isEmphasizingTarget = self.isEmphasizingTarget {
            if isEmphasizingTarget != needToEmphasizeTarget {
                FeedbackManager.shared.playHaptic(isForcing: true)
            }
        } else {
            FeedbackManager.shared.playHaptic(isForcing: true)
        }
        
        if needToEmphasizeTarget {
            switch keyboard {
            case .naratgeul, .cheonjiin, .dubeolsik, .qwerty, .symbol:
                numericLabel.textColor = .white
                numericLabel.backgroundColor = .tintColor
            case .numeric:
                symbolLabel.textColor = .white
                symbolLabel.backgroundColor = .tintColor
            default:
                assertionFailure("구현되지 않은 case입니다.")
            }
            xmarkImageView.image = xmarkImageView.image?.withTintColor(.label, renderingMode: .alwaysOriginal)
            xmarkImageContainerView.backgroundColor = .clear
        } else {
            switch keyboard {
            case .naratgeul, .cheonjiin, .dubeolsik, .qwerty, .symbol:
                numericLabel.textColor = .label
                numericLabel.backgroundColor = .clear
            case .numeric:
                symbolLabel.textColor = .label
                symbolLabel.backgroundColor = .clear
            default:
                assertionFailure("구현되지 않은 case입니다.")
            }
            xmarkImageView.image = xmarkImageView.image?.withTintColor(.white, renderingMode: .alwaysOriginal)
            xmarkImageContainerView.backgroundColor = .tintColor
        }
        
        self.isEmphasizingTarget = needToEmphasizeTarget
    }
    
    func resetIsEmphasizingTarget() {
        self.isEmphasizingTarget = nil
    }
}

// MARK: - UI Methods

private extension KeyboardSelectOverlayView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.axis = .horizontal
        self.spacing = 8
        self.distribution = .fillEqually
        self.backgroundColor = .clear
        
        self.isLayoutMarginsRelativeArrangement = true
        self.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 8
    }
    
    func setHierarchy() {
        self.addSubview(blurView)
        
        xmarkImageContainerView.addSubview(xmarkImageView)
        
        switch keyboard {
        case .naratgeul, .cheonjiin:
            [numericLabel, xmarkImageContainerView].forEach { self.addArrangedSubview($0) }
        case .dubeolsik, .qwerty, .symbol:
            [xmarkImageContainerView, numericLabel].forEach { self.addArrangedSubview($0) }
        case .numeric:
            [symbolLabel, xmarkImageContainerView].forEach { self.addArrangedSubview($0) }
        default:
            assertionFailure("구현되지 않은 case입니다.")
        }
    }
    
    func setConstraints() {
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: self.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        xmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            xmarkImageView.topAnchor.constraint(equalTo: xmarkImageContainerView.topAnchor),
            xmarkImageView.leadingAnchor.constraint(equalTo: xmarkImageContainerView.leadingAnchor),
            xmarkImageView.trailingAnchor.constraint(equalTo: xmarkImageContainerView.trailingAnchor),
            xmarkImageView.bottomAnchor.constraint(equalTo: xmarkImageContainerView.bottomAnchor)
        ])
    }
}
