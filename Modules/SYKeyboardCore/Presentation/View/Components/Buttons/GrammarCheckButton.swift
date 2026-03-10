//
//  GrammarCheckButton.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/11/26.
//

import UIKit

import SYKeyboardAssets

final class GrammarCheckButton: UIButton {
    
    // MARK: - Properties
    
    private let cornerRadius: CGFloat
    
    weak var leadingDivider: UIView?
    
    // MARK: - UI Components
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.clipsToBounds = true
        view.layer.cornerRadius = cornerRadius
        
        return view
    }()
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        if #available(iOS 26, *) {
            self.cornerRadius = KeyboardLayoutFigure.suggestionBarHeight / 2
        } else {
            self.cornerRadius = 4.6
        }
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension GrammarCheckButton {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.tintColor = .label
        self.backgroundColor = .systemBackground.withAlphaComponent(0.001)  // 터치 영역 확보용
        self.isHidden = !UserDefaultsManager.shared.isGrammarCheckButtonEnabled
        
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "text.badge.checkmark")?.withConfiguration(imageConfig)
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        self.configuration = config
        
        self.configurationUpdateHandler = { [weak self] button in
            switch button.state {
            case .highlighted:
                self?.backgroundView.backgroundColor = .suggestionButtonPressed
                self?.leadingDivider?.backgroundColor = .clear
            default:
                self?.backgroundView.backgroundColor = .clear
                self?.leadingDivider?.backgroundColor = .suggestionDividerColor
            }
        }
    }
    
    func setHierarchy() {
        self.insertSubview(backgroundView, at: 0)
    }
    
    func setConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}
