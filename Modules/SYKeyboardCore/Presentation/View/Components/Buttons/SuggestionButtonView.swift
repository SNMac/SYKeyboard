//
//  SuggestionButtonView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/11/26.
//

import UIKit

import SYKeyboardAssets

final class SuggestionButtonView: UIView {
    
    // MARK: - Properties
    
    private let cornerRadius: CGFloat
    
    /// 현재 표시 중인 후보 문자열
    var text: String? {
        return suggestionLabel.text
    }

    var hasText: Bool {
        return !(text?.isEmpty ?? true)
    }

    var isHighlighted: Bool = false {
        didSet {
            updateAppearance()
        }
    }

    // MARK: - UI Components
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.clipsToBounds = true
        view.layer.cornerRadius = cornerRadius
        
        return view
    }()

    private let suggestionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: FontSize.stringKeyMedium)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.lineBreakMode = .byTruncatingMiddle
        label.isUserInteractionEnabled = false
        
        return label
    }()
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        if #available(iOS 26, *) {
            let height = KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing - KeyboardLayoutFigure.keyboardFrameSpacing
            self.cornerRadius = height / 2
        } else {
            self.cornerRadius = 4.6
        }
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal Methods
    
    /// - Parameters:
    ///   - title: 표시할 후보 문자열
    ///   - isRemovable: 길게 눌러 학습에서 삭제할 수 있는 후보면 `true`. 약한 단서로 medium 굵기를 쓴다
    func update(to title: String, isRemovable: Bool = false) {
        suggestionLabel.text = title
        suggestionLabel.font = .systemFont(ofSize: FontSize.stringKeyMedium, weight: isRemovable ? .medium : .regular)
        updateAppearance()
    }
}

// MARK: - UI Methods

private extension SuggestionButtonView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.tintColor = .clear
        self.backgroundColor = .systemBackground.withAlphaComponent(0.001)  // 터치 영역 확보용
    }
    
    func setHierarchy() {
        self.insertSubview(backgroundView, at: 0)
        self.addSubview(suggestionLabel)
    }
    
    func setConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        suggestionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            suggestionLabel.topAnchor.constraint(equalTo: self.topAnchor),
            suggestionLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4),
            suggestionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4),
            suggestionLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    func updateAppearance() {
        backgroundView.backgroundColor = isHighlighted ? .suggestionButtonPressed : .clear

        if #available(iOS 26.0, *) {
            suggestionLabel.textColor = isHighlighted ? .label : .suggestionButtonLabel
        } else {
            suggestionLabel.textColor = .label
        }
    }
}
