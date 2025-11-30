//
//  EnglishKeyboardViewController.swift
//  EnglishKeyboard
//
//  Created by 서동환 on 9/8/25.
//

import UIKit
import EnglishKeyboardCore

import FirebaseCore

/// 영어 키보드 입력/UI 컨트롤러
final class EnglishKeyboardViewController: EnglishKeyboardCoreViewController {
    
    // MARK: - UI Components
    
    /// 전체 접근 허용 안내 오버레이
    private lazy var requestFullAccessOverlayView = RequestFullAccessOverlayView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if needToShowFullAccessGuide { setupRequestFullAccessOverlayView() }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
}

// MARK: - UI Methods

private extension EnglishKeyboardViewController {
    func setupRequestFullAccessOverlayView() {
        self.view.addSubview(requestFullAccessOverlayView)
        
        requestFullAccessOverlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            requestFullAccessOverlayView.topAnchor.constraint(equalTo: self.view.topAnchor),
            requestFullAccessOverlayView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            requestFullAccessOverlayView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            requestFullAccessOverlayView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        let closeOverlayAction = UIAction { [weak self] _ in
            self?.keyboardSettingsManager.isRequestFullAccessOverlayClosed = true
            self?.requestFullAccessOverlayView.isHidden = true
        }
        requestFullAccessOverlayView.closeButton.addAction(closeOverlayAction, for: .touchUpInside)
        
        let redirectToSettingsAction = UIAction { [weak self] _ in
            guard let url = URL(string: "sykeyboard://") else {
                assertionFailure("올바르지 않은 URL 형식입니다.")
                return
            }
            self?.openURL(url)
        }
        requestFullAccessOverlayView.goToSettingsButton.addAction(redirectToSettingsAction, for: .touchUpInside)
    }
}

// MARK: - Private Methods

private extension EnglishKeyboardViewController {
    func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url)
                return
            }
            responder = responder?.next
        }
    }
}
