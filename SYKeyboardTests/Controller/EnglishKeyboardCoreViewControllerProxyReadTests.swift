//
//  EnglishKeyboardCoreViewControllerProxyReadTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import EnglishKeyboardCore
@testable import SYKeyboardCore

/// 하위 VC가 `super.textWillChange` 뒤에서 읽는 값과 반복 입력 틱에서 읽는 값을 한 범위에서 한 번만 읽는지 확인한다
@Suite("EnglishKeyboardCoreViewController 텍스트 프록시 읽기", .sharedUserDefaults)
@MainActor
struct EnglishKeyboardCoreViewControllerProxyReadTests {

    @Test("textWillChange는 shift 자동 대문자 판정까지 같은 프록시 값을 한 번만 읽음")
    func testTextWillChangeReadsShiftContextOnce() {
        let controller = TestEnglishProxyReadViewController()
        controller.loadViewIfNeeded()
        controller.proxy.resetReadCounts()

        controller.textWillChange(nil)

        #expect(controller.proxy.readCount(of: "autocapitalizationType") == 1)
        #expect(controller.proxy.readCount(of: "documentContextBeforeInput") == 1)
    }

    @Test("반복 입력 도중 textWillChange로 버퍼가 비워진 틱은 쓰기 전 앞 문맥을 한 번만 읽음")
    func testRepeatInsertTickAfterTextWillChangeReadsContextOnceBeforeWrite() {
        let controller = TestEnglishProxyReadViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.addSubview(controller.view)
        let button = PrimaryKeyButton(
            keyboard: .qwerty,
            button: .keyButton(primary: ["a"], secondary: nil)
        )
        // 길게 누르기가 인식되면 첫 글자가 바로 입력돼 버퍼가 찬다. 크래시는 그 뒤 문서 상태가 리셋된 틱에서 났다
        controller.repeatTextInteractionWillPerform(button: button)
        controller.textWillChange(nil)
        let writeCountBeforeTick = controller.proxy.writes.count
        controller.proxy.resetReadCounts()

        controller.performRepeatTextInteraction(for: button)

        #expect(controller.proxy.writes.dropFirst(writeCountBeforeTick) == ["insertText(a)"])
        // 쓰기 뒤 undo 기록·컨트롤 갱신의 읽기는 새 문맥이 필요하므로 쓰기 전 읽기만 센다
        #expect(controller.proxy.readCountsAtWrites.first?["documentContextBeforeInput"] == 1)

        controller.repeatTextInteractionDidPerform(button: button)
        window.removeFromSuperview()
    }
}

// MARK: - Test Helpers

@MainActor
private final class TestEnglishProxyReadViewController: EnglishKeyboardCoreViewController {
    let proxy = CountingTextDocumentProxy()

    override var textDocumentProxy: any UITextDocumentProxy {
        proxy
    }
}
