//
//  HangeulEnglishKeyboardCoreViewControllerProxyReadTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/9/26.
//

import Testing
import UIKit

@testable import HangeulEnglishKeyboardCore
@testable import SYKeyboardCore

/// 한영 통합 VC가 `super.textWillChange` 뒤에서 읽는 값도 같은 콜백 범위에서 한 번만 읽는지 확인한다
@Suite("HangeulEnglishKeyboardCoreViewController 텍스트 프록시 읽기", .sharedUserDefaults)
@MainActor
struct HangeulEnglishKeyboardCoreViewControllerProxyReadTests {

    @Test("영어 모드 textWillChange는 shift 자동 대문자 판정까지 같은 프록시 값을 한 번만 읽음")
    func testTextWillChangeReadsShiftContextOnceInEnglishMode() {
        withLastLanguageMode(.english) {
            let controller = TestHangeulEnglishProxyReadViewController()
            controller.loadViewIfNeeded()
            controller.proxy.resetReadCounts()

            controller.textWillChange(nil)

            #expect(controller.proxy.readCount(of: "autocapitalizationType") == 1)
            #expect(controller.proxy.readCount(of: "documentContextBeforeInput") == 1)
        }
    }

    @Test("한/A 전환과 textWillChange를 거친 VC는 참조를 놓으면 해제됨")
    func testControllerIsReleased() {
        weak var weakController: TestHangeulEnglishProxyReadViewController?
        withLastLanguageMode(.hangeul) {
            autoreleasepool {
                let controller = TestHangeulEnglishProxyReadViewController()
                let window = UIWindow(frame: UIScreen.main.bounds)
                window.addSubview(controller.view)

                // 한/A 전환은 UIAction 클로저를 지나며 마지막 언어를 저장한다(withLastLanguageMode가 되돌림)
                controller.primaryKeyboardView.languageSwitchButton?.sendActions(for: .touchUpInside)
                controller.textWillChange(nil)
                controller.view.removeFromSuperview()
                weakController = controller
            }
            // 창에 올렸던 VC는 UIKit이 예약한 main queue 작업이 끝난 뒤 해제되므로 런루프를 한 번 돌린다
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        }

        #expect(weakController == nil)
    }
}

// MARK: - Test Helpers

@MainActor
private final class TestHangeulEnglishProxyReadViewController: HangeulEnglishKeyboardCoreViewController {
    let proxy = CountingTextDocumentProxy()

    override var textDocumentProxy: any UITextDocumentProxy {
        proxy
    }
}

/// VC `init()`이 읽는 마지막 언어를 바꾸고, body가 끝나면 원래 저장값으로 되돌린다.
/// 한/A 전환이 `persist: true`로 다시 저장하므로 테스트 본문 전체를 감싼다
@MainActor
private func withLastLanguageMode(_ mode: HangeulEnglishLanguageMode, _ body: () -> Void) {
    let storage = UserDefaultsManager.shared.storage
    let key = UserDefaultsKeys.lastHangeulEnglishLanguageMode
    let original = storage.object(forKey: key)
    defer {
        if let original {
            storage.set(original, forKey: key)
        } else {
            storage.removeObject(forKey: key)
        }
    }

    UserDefaultsManager.shared.lastHangeulEnglishLanguageMode = mode
    body()
}
