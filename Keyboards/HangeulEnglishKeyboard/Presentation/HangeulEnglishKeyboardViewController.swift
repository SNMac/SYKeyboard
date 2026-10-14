//
//  HangeulEnglishKeyboardViewController.swift
//  HangeulEnglishKeyboard
//
//  Created by 서동환 on 6/28/26.
//

import UIKit
import OSLog

import HangeulEnglishKeyboardCore
import SYKeyboardCore

import FirebaseCore
import FirebaseCrashlytics

/// 한영 통합 키보드 입력/UI 컨트롤러
final class HangeulEnglishKeyboardViewController: HangeulEnglishKeyboardCoreViewController {

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

        let message = "Memory Warning Received in \(Bundle.main.bundleIdentifier ?? "Unknown Bundle")"
        logger.fault("\(message)")
        Crashlytics.crashlytics().log(message)
        Crashlytics.crashlytics().setCustomValue(true, forKey: "did_receive_memory_warning")
    }

    // MARK: - Override Methods

    /// 시작 언어 판정 근거를 기록한다.
    /// 입력한 텍스트는 남기지 않고 필드 특성만 남긴다
    override func languageModeDecisionDidResolve(
        requiresLatinInput: Bool,
        resolved: HangeulEnglishLanguageMode
    ) {
        let language = textDocument.documentInputMode?.primaryLanguage ?? "nil"
        let keyboardType = textDocument.keyboardType?.rawValue ?? -1
        let contentType = textDocument.textContentType?.rawValue ?? "nil"
        let message = "languageMode documentPrimaryLanguage=\(language)"
        + " keyboardType=\(keyboardType) textContentType=\(contentType)"
        + " requiresLatinInput=\(requiresLatinInput) resolved=\(resolved)"

        logger.info("\(message)")
        Crashlytics.crashlytics().setCustomValue(language, forKey: "document_primary_language")
        Crashlytics.crashlytics().log(message)
    }
}

// MARK: - Private Methods

private extension HangeulEnglishKeyboardViewController {
    func setupFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        Crashlytics.crashlytics().setUserID(
            UIDevice.current.identifierForVendor?.uuidString
        )

        // 진단 기록 연결. 입력한 텍스트는 전달되지 않는다(`KeyboardDiagnostics` 참고)
        KeyboardDiagnostics.record = { message in
            Crashlytics.crashlytics().log(message)
        }
    }
}
