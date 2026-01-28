//
//  EnglishKeyboardViewController.swift
//  EnglishKeyboard
//
//  Created by 서동환 on 9/8/25.
//

import UIKit
import OSLog

import EnglishKeyboardCore

import FirebaseCore
import FirebaseCrashlytics

/// 영어 키보드 입력/UI 컨트롤러
final class EnglishKeyboardViewController: EnglishKeyboardCoreViewController {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
    // MARK: - UI Components
    
    /// 전체 접근 허용 안내 오버레이
    private lazy var requestFullAccessOverlayView = RequestFullAccessOverlayView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFirebase()
        
        if needToShowFullAccessGuide {
            setupRequestFullAccessOverlayView()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        let msg = "Memory Warning Received in \(Bundle.main.bundleIdentifier ?? "Unknown Bundle")"
        logger.fault("\(msg)")
        
        // 메모리 경고 발생 시 Crashlytics에 로그 남기기
        Crashlytics.crashlytics().log(msg)
        Crashlytics.crashlytics().setCustomValue(true, forKey: "did_receive_memory_warning")
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
            let urlString = "sykeyboard://"
            guard let url = URL(string: urlString) else {
                assertionFailure("올바르지 않은 URL 형식입니다.")
                
                let error = KeyboardError.invalidSettingsURL(url: urlString)
                Crashlytics.crashlytics().record(error: error)
                return
            }
            self?.openURL(url)
        }
        requestFullAccessOverlayView.goToSettingsButton.addAction(redirectToSettingsAction, for: .touchUpInside)
    }
}

// MARK: - Private Methods

private extension EnglishKeyboardViewController {
    func setupFirebase() {
        // Firebase 로딩
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // IDFV를 사용하여 Crashlytics User ID 설정
        let idfv = UIDevice.current.identifierForVendor?.uuidString
        Crashlytics.crashlytics().setUserID(idfv)
    }
    
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
