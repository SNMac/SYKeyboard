//
//  WordSuggestionButtonLikeView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/11/26.
//

import UIKit

import SYKeyboardAssets

final class WordSuggestionButtonLikeView: UIView {
    
    // MARK: - Properties
    
    private let cornerRadius: CGFloat
    
    var hasText: Bool {
        return !(suggestionLabel.text?.isEmpty ?? true)
    }
    
    var isSuggestionHighlighted: Bool = false {
        didSet {
            if isSuggestionHighlighted {
                backgroundView.backgroundColor = .suggestionButtonPressed
                leadingDivider?.backgroundColor = .clear
                trailingDivider?.backgroundColor = .clear
            } else {
                backgroundView.backgroundColor = .clear
                leadingDivider?.backgroundColor = .suggestionDividerColor
                trailingDivider?.backgroundColor = .suggestionDividerColor
            }
        }
    }
    
    weak var leadingDivider: UIView?
    weak var trailingDivider: UIView?
    
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
            self.cornerRadius = KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing / 2
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
    
    func update(to title: String) {
        suggestionLabel.text = title
    }
}

// MARK: - UI Methods

private extension WordSuggestionButtonLikeView {
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
}
