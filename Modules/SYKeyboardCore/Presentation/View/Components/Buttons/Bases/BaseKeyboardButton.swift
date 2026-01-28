//
//  BaseKeyboardButton.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 키보드 버튼 베이스
public class BaseKeyboardButton: UIButton {
    
    // MARK: - Properties
    
    /// 버튼 정렬 관리용
    enum KeyAlignment {
        case center  // 일반 키
        case left  // 영어 키보드의 'l' 키처럼 왼쪽에 붙는 키
        case right  // 영어 키보드의 'a' 키처럼 오른쪽에 붙는 키
    }
    
    private var keyAlignment: KeyAlignment = .center
    
    final let insetDx: CGFloat
    final let insetDy: CGFloat
    final let cornerRadius: CGFloat
    
    final var isPressed: Bool = false {
        didSet {
            setNeedsUpdateConfiguration()
        }
    }
    
    final public var isGesturing: Bool = false {
        didSet {
            setNeedsUpdateConfiguration()
        }
    }
    
    /// 코드로 `sendActions`가 호출되었는지 확인하는 플래그
    private(set) var isProgrammaticCall: Bool = false
    
    public override func sendActions(for controlEvents: UIControl.Event) {
        isProgrammaticCall = true
        
        super.sendActions(for: controlEvents)
        
        isProgrammaticCall = false
    }
    
    var visualConstraints: [NSLayoutConstraint] = []
    
    // MARK: - UI Components
    
    /// 배경 UI
    final lazy var backgroundView = ButtonBackgroundView(cornerRadius: self.cornerRadius)
    /// 그림자 UI
    final lazy var shadowView = ButtonShadowView(cornerRadius: self.cornerRadius)
    /// iOS 26 `UIButton.Configuration.attributedTitle` 애니메이션 해결용
    final let primaryKeyListLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.textAlignment = .center
        
        return label
    }()
    /// iOS 26 `UIButton.Configuration.image` 애니메이션 해결용
    final let primaryKeyListImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.backgroundColor = .clear
        
        return imageView
    }()
    
    // MARK: - Initializer
    
    init(keyboard: SYKeyboardType) {
        switch keyboard {
        case .naratgeul, .cheonjiin, .numeric, .tenKey:
            self.insetDx = 3
            self.insetDy = 2
        case .dubeolsik, .qwerty, .symbol:
            self.insetDx = 3
            self.insetDy = 4
        }
        if #available(iOS 26, *) {
            self.cornerRadius = 8.5
        } else {
            self.cornerRadius = 4.6
        }
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Internal Methods
    
    /// 키의 시각적 정렬을 업데이트합니다.
    /// - Parameters:
    ///   - keyAlignment: 정렬 방향 (`.left`, `.right`, `.center`)
    ///   - referenceView: 시각적 너비의 기준이 될 뷰 (예: `'s'` 키)
    ///   - multiplier: 너비 배율 (`keyAlignment == .center`일 시 무시됨)
    func updateKeyAlignment(_ keyAlignment: KeyAlignment, referenceView: UIView?, multiplier: CGFloat) {
        self.keyAlignment = keyAlignment
        
        remakeConstraintsForVisuals(referenceView: referenceView, multiplier: multiplier)
    }
    
    // MARK: - Overridable Methods
    
    /// 햅틱 피드백, 사운드 피드백을 재생하는 메서드
    public func playFeedback() { assertionFailure("메서드가 오버라이딩 되지 않았습니다.") }
}

// MARK: - UI Methods

private extension BaseKeyboardButton {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.tintColor = .clear
        self.backgroundColor = .systemBackground.withAlphaComponent(0.001)  // 터치 영역 확보용
        
        if #available(iOS 26, *) {
            shadowView.isHidden = true
        } else {
            shadowView.isHidden = false
        }
        
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.contentInsets = .zero
        buttonConfig.titleAlignment = .center
        buttonConfig.automaticallyUpdateForSelection = false
        self.configuration = buttonConfig
    }
    
    func setHierarchy() {
        self.insertSubview(shadowView, at: 0)
        self.insertSubview(backgroundView, at: 1)
        
        [primaryKeyListLabel, primaryKeyListImageView].forEach { self.addSubview($0) }
    }
    
    func setConstraints() {
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            shadowView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            shadowView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            shadowView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])
        
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        let top = backgroundView.topAnchor.constraint(equalTo: self.topAnchor, constant: insetDy)
        let leading = backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: insetDx)
        let trailing = backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -insetDx)
        let bottom = backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insetDy)
        visualConstraints = [top, leading, trailing, bottom]
        NSLayoutConstraint.activate(visualConstraints)
        
        primaryKeyListLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            primaryKeyListLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            primaryKeyListLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            primaryKeyListLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            primaryKeyListLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])
        
        primaryKeyListImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            primaryKeyListImageView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            primaryKeyListImageView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            primaryKeyListImageView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            primaryKeyListImageView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])
    }
}

// MARK: - Update Methods

private extension BaseKeyboardButton {
    func remakeConstraintsForVisuals(referenceView: UIView?, multiplier: CGFloat) {
        NSLayoutConstraint.deactivate(visualConstraints)
        visualConstraints.removeAll()
        
        let top = shadowView.topAnchor.constraint(equalTo: self.topAnchor, constant: insetDy)
        let bottom = shadowView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insetDy)
        visualConstraints.append(contentsOf: [top, bottom])
        
        switch keyAlignment {
        case .left:
            guard let referenceView else { break }
            let leading = shadowView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: insetDx)
            let width = shadowView.widthAnchor.constraint(equalTo: referenceView.widthAnchor,
                                                          multiplier: multiplier,
                                                          constant: -(insetDx * 2))
            visualConstraints.append(contentsOf: [leading, width])
            
        case .right:
            guard let referenceView else { break }
            let trailing = shadowView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -insetDx)
            let width = shadowView.widthAnchor.constraint(equalTo: referenceView.widthAnchor,
                                                          multiplier: multiplier,
                                                          constant: -(insetDx * 2))
            visualConstraints.append(contentsOf: [trailing, width])
            
        case .center:
            let leading = shadowView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: insetDx)
            let trailing = shadowView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -insetDx)
            visualConstraints.append(contentsOf: [leading, trailing])
        }
        
        NSLayoutConstraint.activate(visualConstraints)
    }
}
