//
//  RequestFullAccessOverlayView.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 11/24/25.
//

import UIKit

/// 전체 접근 허용 안내 오버레이
final class RequestFullAccessOverlayView: UIView {
    
    // MARK: - UI Components
    
    private let blurEffectView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView()
        visualEffectView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        return visualEffectView
    }()
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "전체 접근 허용 활성화 필요")
        label.font = .systemFont(ofSize: 15, weight: .bold)
        
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "전체 접근 허용이 비활성화 되어있는 경우 일부 기능이 작동하지 않을 수 있습니다.")
        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 0
        
        return label
    }()
    
    private let guideLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "활성화 방법: 설정 ➡️ 일반 ➡️ 키보드 ➡️ 키보드 ➡️ SY키보드 ➡️ '전체 접근 허용' 활성화")
        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 0
        
        return label
    }()
    
    private let buttonHStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 16
        
        return stackView
    }()
    
    let closeButton: UIButton = {
        let button = UIButton()
        var buttonConfig = UIButton.Configuration.gray()
        buttonConfig.attributedTitle = AttributedString(String(localized: "닫기"), attributes: .init([.font: UIFont.systemFont(ofSize: 15)]))
        
        button.configuration = buttonConfig
        button.layer.cornerRadius = 4.6
        
        return button
    }()
    
    let goToSettingsButton: UIButton = {
        let button = UIButton()
        var buttonConfig = UIButton.Configuration.filled()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        buttonConfig.image = UIImage(systemName: "gear")?.withConfiguration(imageConfig)
        buttonConfig.attributedTitle = AttributedString(String(localized: "시스템 설정 이동"), attributes: .init([.font: UIFont.systemFont(ofSize: 15)]))
        buttonConfig.imagePadding = 4
        
        button.configuration = buttonConfig
        button.layer.cornerRadius = 4.6
        
        return button
    }()
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension RequestFullAccessOverlayView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        if #available(iOS 26, *) {
            self.clipsToBounds = true
            self.layer.cornerRadius = 12
            
            closeButton.layer.cornerRadius = 8.5
            goToSettingsButton.isHidden = true
        }
    }
    
    func setHierarchy() {
        [blurEffectView,
         warningLabel,
         descriptionLabel,
         guideLabel,
         buttonHStackView].forEach { self.addSubview($0) }
        
        [closeButton, goToSettingsButton].forEach { buttonHStackView.addArrangedSubview($0) }
    }
    
    func setConstraints() {
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: self.topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            warningLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            warningLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 16)
        ])
        
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16)
        ])
        
        guideLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            guideLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            guideLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            guideLabel.bottomAnchor.constraint(equalTo: buttonHStackView.topAnchor, constant: -8)
        ])
        
        buttonHStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonHStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            buttonHStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            buttonHStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16),
            buttonHStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}
