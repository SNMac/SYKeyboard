//
//  RequestFullAccessOverlayView.swift
//  Naratgeul
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
        label.text = "‼️ 전체 접근 허용 활성화 필요 ‼️"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "전체 접근 허용이 비활성화되어 있는 경우 일부 기능이 작동하지 않을 수 있습니다."
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        
        return label
    }()
    
    let goToSettingsButton: UIButton = {
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.image = UIImage(systemName: "gear")
        buttonConfig.title = "시스템 설정 이동"
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
        addSubview(descriptionLabel)
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
            make.top.equalToSuperview().offset(40)
        }
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(warningLabel.snp.bottom).offset(30)
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
        }
        goToSettingsButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-30)
        }
    }
}
