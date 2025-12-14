//
//  EnglishKeyboardViewController.swift
//  EnglishKeyboard
//
//  Created by 서동환 on 9/8/25.
//

import UIKit

import EnglishKeyboardCore

import FirebaseCore
import FirebaseCrashlytics

/// 영어 키보드 입력/UI 컨트롤러
final class EnglishKeyboardViewController: EnglishKeyboardCoreViewController {
    
    // MARK: - UI Components
    
    /// 전체 접근 허용 안내 오버레이
    private lazy var requestFullAccessOverlayView = RequestFullAccessOverlayView()
    
    // MARK: - Initializer
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        
        // Firebase 로딩
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // IDFV를 사용하여 Crashlytics User ID 설정
        let idfv = UIDevice.current.identifierForVendor?.uuidString
        Crashlytics.crashlytics().setUserID(idfv)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if needToShowFullAccessGuide {
            setupRequestFullAccessOverlayView()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // 메모리 경고 발생 시 Crashlytics에 로그 남기기
        let msg = "Memory Warning Received in \(Bundle.main.bundleIdentifier!)"
        Crashlytics.crashlytics().log(msg)
        
        let error = NSError(domain: Bundle.main.bundleIdentifier!, code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
        Crashlytics.crashlytics().record(error: error)
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
