//
//  BaseKeyboardViewControllerRootViewTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 11/27/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

/// 화면에 나타나기 전에 호스트와 연결이 끊긴 키보드 VC는, 루트 뷰에 하위 뷰나 interaction이 붙어 있으면 UIKit이 해제하지 않는다(#216).
/// 이 누수는 호스트 연결이 있어야 생겨 단위 테스트로 재현할 수 없으므로, 누수를 피하는 계약만 고정한다.
/// 힌지 interaction은 iOS 27.1 이상에서만 설치되므로 interaction 단언은 그 버전 시뮬레이터에서만 실패할 수 있다
@MainActor
@Suite("첫 표시 전 키보드 VC 루트 뷰를 비워 두는 계약", .sharedUserDefaults)
struct BaseKeyboardViewControllerRootViewTests {

    @Test("나타나기 전에는 문맥 변경 콜백을 받아도 루트 뷰에 하위 뷰도 interaction도 붙지 않음")
    func test첫표시전_루트뷰비어있음() {
        let controller = RootViewTestViewController()
        controller.loadViewIfNeeded()
        // 호스트는 키보드가 나타나기 전에도 문맥 변경 콜백을 보낸다
        controller.textWillChange(nil)
        controller.textDidChange(nil)

        #expect(controller.view.subviews.isEmpty)
        #expect(controller.view.interactions.isEmpty)
    }
}

private final class RootViewTestViewController: BaseKeyboardViewController {
    let primaryView = TestPrimaryKeyboardView(keyboard: .dubeolsik)
    let proxy = CountingTextDocumentProxy()

    override var primaryKeyboardView: PrimaryKeyboardRepresentable {
        primaryView
    }

    override var textDocumentProxy: any UITextDocumentProxy {
        proxy
    }

    init() {
        super.init(language: "ko-KR")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateKeyboardType() {}
}
