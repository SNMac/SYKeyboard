//
//  RequestFullAccessOverlayView.swift
//  Keyboard
//
//  Created by 서동환 on 1/13/25.
//

import UIKit
import SnapKit

class RequestFullAccessOverlayView: UIView {
    // MARK: - UI Components
    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        
        return visualEffectView
    }()
    
    private let vibrancyEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: .fill)
        let visualEffectView = UIVisualEffectView(effect: vibrancyEffect)
        
        return visualEffectView
    }()
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        let localStr = String(localized: "‼️ 전체 접근 허용 ON 필요 ‼️")
        label.text = localStr
        label.font = .systemFont(ofSize: 18, weight: .bold)
        
        return label
    }()
    
    private let descriptionLabel1: UILabel = {
        let label = UILabel()
        let localStr = String(localized: "전체 접근 허용이 OFF 되어 있는 경우 일부 기능이 작동하지 않을 수 있습니다.")
        label.text = localStr
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        
        return label
    }()
    
    private let descriptionLabel2: UILabel = {
        let label = UILabel()
        let localStr = String(localized: "활성화 방법: 키보드 ➡️ 전체 접근 허용 ON")
        label.text = localStr
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        
        return label
    }()
    
    let goToSettingsButton: UIButton = {
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.image = UIImage(systemName: "gear")
        let localStr = String(localized: "시스템 설정 이동")
        buttonConfig.title = localStr
        buttonConfig.imagePadding = 5
        let button = UIButton(configuration: buttonConfig)
        
        return button
    }()

    // MARK: - initializers
    init() {
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods
private extension RequestFullAccessOverlayView {
    func setupUI() {
        setViewHierarchy()
        setConstraints()
    }
    
    func setViewHierarchy() {
        addSubview(blurEffectView)
        blurEffectView.contentView.addSubview(vibrancyEffectView)
        addSubview(warningLabel)
        addSubview(descriptionLabel1)
        addSubview(descriptionLabel2)
        addSubview(goToSettingsButton)
    }
    
    func setConstraints() {
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        vibrancyEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        warningLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(20)
        }
        descriptionLabel1.snp.makeConstraints { make in
            make.top.equalTo(warningLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
        }
        descriptionLabel2.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalTo(goToSettingsButton.snp.top).offset(-10)
        }
        goToSettingsButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(20)
        }
    }
}
