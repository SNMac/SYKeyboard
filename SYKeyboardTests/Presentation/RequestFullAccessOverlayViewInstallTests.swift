//
//  RequestFullAccessOverlayViewInstallTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("전체 접근 안내 오버레이 설치")
@MainActor
struct RequestFullAccessOverlayViewInstallTests {

    @Test("설치하면 컨테이너 네 변에 붙고 보임")
    func testInstallAddsOverlayFillingContainer() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let overlay = RequestFullAccessOverlayView()

        overlay.install(in: container, onClose: {}, onOpenSettings: { _ in })
        container.layoutIfNeeded()

        #expect(overlay.superview === container)
        #expect(overlay.isHidden == false)
        #expect(overlay.frame == container.bounds)
    }

    @Test("닫기 버튼은 onClose를 부른 뒤 오버레이를 숨김")
    func testCloseButtonCallsOnCloseThenHides() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let overlay = RequestFullAccessOverlayView()
        var closeCount = 0
        var wasHiddenWhenClosed: Bool?

        overlay.install(
            in: container,
            onClose: {
                closeCount += 1
                wasHiddenWhenClosed = overlay.isHidden
            },
            onOpenSettings: { _ in }
        )
        overlay.closeButton.sendActions(for: .touchUpInside)

        #expect(closeCount == 1)
        #expect(wasHiddenWhenClosed == false)
        #expect(overlay.isHidden)
    }

    @Test("설정 이동 버튼은 앱 URL scheme으로 onOpenSettings를 부름")
    func testSettingsButtonPassesAppURL() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let overlay = RequestFullAccessOverlayView()
        var openedURLs: [URL] = []

        overlay.install(in: container, onClose: {}, onOpenSettings: { openedURLs.append($0) })
        overlay.goToSettingsButton.sendActions(for: .touchUpInside)

        #expect(openedURLs == [URL(string: "sykeyboard://")!])
        #expect(overlay.isHidden == false)
    }
}
