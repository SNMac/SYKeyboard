//
//  OneHandedModeSelectOverlayView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/24/25.
//

import UIKit

/// 한 손 키보드 선택 UI
final public class OneHandedModeSelectOverlayView: UIStackView {
    
    // MARK: - Properties
    
    private var lastEmphasizeMode: OneHandedMode?
    
    // MARK: - UI Components
    
    /// Material 블러 효과
    private let blurEffect = UIBlurEffect(style: .systemMaterial)
    /// Material 효과를 배경에 적용시키기 위한 뷰
    private lazy var blurView = UIVisualEffectView(effect: blurEffect)
    
    /// 왼손 모드 이미지
    private let leftKeyboardImageView: UIImageView = {
        let imageView = UIImageView()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        imageView.image = UIImage(systemName: "keyboard.onehanded.left")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        imageView.contentMode = .center
        
        return imageView
    }()
    /// 왼손 모드 이미지 컨테이너
    let leftKeyboardImageContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        
        return view
    }()
    /// 기본 모드 이미지
    private let normalKeyboardImageView: UIImageView = {
        let imageView = UIImageView()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        imageView.image = UIImage(systemName: "keyboard")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        imageView.contentMode = .center
        
        return imageView
    }()
    /// 기본 모드 이미지 컨테이너
    private let normalKeyboardImageContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        
        return view
    }()
    /// 오른손 모드 이미지
    private let rightKeyboardImageView: UIImageView = {
        let imageView = UIImageView()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        imageView.image = UIImage(systemName: "keyboard.onehanded.right")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        imageView.contentMode = .center
        
        return imageView
    }()
    /// 오른손 모드 이미지 컨테이너
    let rightKeyboardImageContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        
        return view
    }()
    
    // MARK: - Initializer
    
    public override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Internal Methods
    
    func configure(emphasizeOf mode: OneHandedMode) {
        if let lastEmphasizeMode {
            if lastEmphasizeMode != mode {
                FeedbackManager.shared.playHaptic(isForcing: true)
            }
        } else {
            FeedbackManager.shared.playHaptic(isForcing: true)
        }
        
        switch mode {
        case .left:
            leftKeyboardImageView.image = leftKeyboardImageView.image?.withTintColor(.white, renderingMode: .alwaysOriginal)
            leftKeyboardImageContainerView.backgroundColor = .tintColor
            normalKeyboardImageView.image = normalKeyboardImageView.image?.withTintColor(.label, renderingMode: .alwaysOriginal)
            normalKeyboardImageContainerView.backgroundColor = .clear
            rightKeyboardImageView.image = rightKeyboardImageView.image?.withTintColor(.label, renderingMode: .alwaysOriginal)
            rightKeyboardImageContainerView.backgroundColor = .clear
        case .center:
            leftKeyboardImageView.image = leftKeyboardImageView.image?.withTintColor(.label, renderingMode: .alwaysOriginal)
            leftKeyboardImageContainerView.backgroundColor = .clear
            normalKeyboardImageView.image = normalKeyboardImageView.image?.withTintColor(.white, renderingMode: .alwaysOriginal)
            normalKeyboardImageContainerView.backgroundColor = .tintColor
            rightKeyboardImageView.image = rightKeyboardImageView.image?.withTintColor(.label, renderingMode: .alwaysOriginal)
            rightKeyboardImageContainerView.backgroundColor = .clear
        case .right:
            leftKeyboardImageView.image = leftKeyboardImageView.image?.withTintColor(.label, renderingMode: .alwaysOriginal)
            leftKeyboardImageContainerView.backgroundColor = .clear
            normalKeyboardImageView.image = normalKeyboardImageView.image?.withTintColor(.label, renderingMode: .alwaysOriginal)
            normalKeyboardImageContainerView.backgroundColor = .clear
            rightKeyboardImageView.image = rightKeyboardImageView.image?.withTintColor(.white, renderingMode: .alwaysOriginal)
            rightKeyboardImageContainerView.backgroundColor = .tintColor
        }
        
        self.lastEmphasizeMode = mode
    }
    
    func resetLastEmphasizeMode() {
        self.lastEmphasizeMode = nil
    }
}

// MARK: - UI Methods

private extension OneHandedModeSelectOverlayView {
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
        
        leftKeyboardImageContainerView.addSubview(leftKeyboardImageView)
        normalKeyboardImageContainerView.addSubview(normalKeyboardImageView)
        rightKeyboardImageContainerView.addSubview(rightKeyboardImageView)
        
        [leftKeyboardImageContainerView,
         normalKeyboardImageContainerView,
         rightKeyboardImageContainerView].forEach { self.addArrangedSubview($0) }
    }
    
    func setConstraints() {
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: self.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        leftKeyboardImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leftKeyboardImageView.topAnchor.constraint(equalTo: leftKeyboardImageContainerView.topAnchor),
            leftKeyboardImageView.leadingAnchor.constraint(equalTo: leftKeyboardImageContainerView.leadingAnchor),
            leftKeyboardImageView.trailingAnchor.constraint(equalTo: leftKeyboardImageContainerView.trailingAnchor),
            leftKeyboardImageView.bottomAnchor.constraint(equalTo: leftKeyboardImageContainerView.bottomAnchor)
        ])
        
        normalKeyboardImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            normalKeyboardImageView.topAnchor.constraint(equalTo: normalKeyboardImageContainerView.topAnchor),
            normalKeyboardImageView.leadingAnchor.constraint(equalTo: normalKeyboardImageContainerView.leadingAnchor),
            normalKeyboardImageView.trailingAnchor.constraint(equalTo: normalKeyboardImageContainerView.trailingAnchor),
            normalKeyboardImageView.bottomAnchor.constraint(equalTo: normalKeyboardImageContainerView.bottomAnchor)
        ])
        
        rightKeyboardImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rightKeyboardImageView.topAnchor.constraint(equalTo: rightKeyboardImageContainerView.topAnchor),
            rightKeyboardImageView.leadingAnchor.constraint(equalTo: rightKeyboardImageContainerView.leadingAnchor),
            rightKeyboardImageView.trailingAnchor.constraint(equalTo: rightKeyboardImageContainerView.trailingAnchor),
            rightKeyboardImageView.bottomAnchor.constraint(equalTo: rightKeyboardImageContainerView.bottomAnchor)
        ])
    }
}
