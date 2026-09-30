//
//  HangeulKeyboardViewController.swift
//  HangeulKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import UIKit
import OSLog

import HangeulKeyboardCore
import SYKeyboardCore

import FirebaseCore
import FirebaseCrashlytics

/// 한글 키보드 입력/UI 컨트롤러
final class HangeulKeyboardViewController: HangeulKeyboardCoreViewController {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
    // MARK: - Initializer
    
    override init() {
        super.init()
        
        // loadView와 viewDidLoad에서 발생하는 크래시도 기록되도록 가장 먼저 설정한다
        setupFirebase()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        let msg = "Memory Warning Received in \(Bundle.main.bundleIdentifier ?? "Unknown Bundle")"
        logger.fault("\(msg)")
        
        // 메모리 경고 발생 시 Crashlytics에 로그 남기기
        Crashlytics.crashlytics().log(msg)
        Crashlytics.crashlytics().setCustomValue(true, forKey: "did_receive_memory_warning")
    }
}

// MARK: - Private Methods

private extension HangeulKeyboardViewController {
    func setupFirebase() {
        // Firebase 로딩
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // IDFV를 사용하여 Crashlytics User ID 설정
        let idfv = UIDevice.current.identifierForVendor?.uuidString
        Crashlytics.crashlytics().setUserID(idfv)
        
        // 진단 기록 연결. 입력한 텍스트는 전달되지 않는다(`KeyboardDiagnostics` 참고)
        KeyboardDiagnostics.record = { message in
            Crashlytics.crashlytics().log(message)
        }
    }
}
