//
//  KeyboardSelectOverlayView.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/24/25.
//

import UIKit

import SnapKit
import Then

/// 키보드 레이아웃 선택 UI
final class KeyboardSelectOverlayView: UIStackView {
    
    // MARK: - Properties
    
    private let keyboard: SYKeyboardType
    private var isEmphasizingTarget: Bool?
    
    // MARK: - UI Components
    
    /// Material 블러 효과
    private let blurEffect = UIBlurEffect(style: .systemMaterial)
    /// Material 효과를 배경에 적용시키기 위한 뷰
    private lazy var blurView = UIVisualEffectView(effect: blurEffect)
    
    /// 숫자 키보드를 나타내는 라벨
    private(set) lazy var numericLabel = UILabel().then {
        $0.text = "123"
        $0.font = .systemFont(ofSize: 20, weight: .regular)
        $0.textAlignment = .center
        
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    /// 기호 키보드를 나타내는 라벨
    private(set) lazy var symbolLabel = UILabel().then {
        $0.text = "!#1"
        $0.font = .systemFont(ofSize: 20, weight: .regular)
        $0.textAlignment = .center
        
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    /// 키보드 선택 취소 이미지
    private let xmarkImageView = UIImageView().then {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        $0.image = UIImage(systemName: "xmark.square")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        $0.contentMode = .center
    }
    /// 키보드 선택 취소 이미지 컨테이너
    private(set) var xmarkImageContainerView = UIView().then {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    
    // MARK: - Initializer
    
    init(keyboard: SYKeyboardType) {
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
            case .hangeul, .english, .symbol:
                numericLabel.textColor = .white
                numericLabel.backgroundColor = .tintColor
            case .numeric:
                symbolLabel.textColor = .white
                symbolLabel.backgroundColor = .tintColor
            default:
                fatalError("구현되지 않은 case입니다.")
            }
            xmarkImageView.image = xmarkImageView.image?.withTintColor(.label, renderingMode: .alwaysOriginal)
            xmarkImageContainerView.backgroundColor = .clear
        } else {
            switch keyboard {
            case .hangeul, .english, .symbol:
                numericLabel.textColor = .label
                numericLabel.backgroundColor = .clear
            case .numeric:
                symbolLabel.textColor = .label
                symbolLabel.backgroundColor = .clear
            default:
                fatalError("구현되지 않은 case입니다.")
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
        case .hangeul:
            self.addArrangedSubviews(numericLabel, xmarkImageContainerView)
            xmarkImageView.snp.makeConstraints {
                $0.height.equalTo(numericLabel)
            }
        case .english, .symbol:
            self.addArrangedSubviews(xmarkImageContainerView, numericLabel)
        case .numeric:
            self.addArrangedSubviews(symbolLabel, xmarkImageContainerView)
        default:
            fatalError("구현되지 않은 case입니다.")
        }
    }
    
    func setConstraints() {
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        xmarkImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
