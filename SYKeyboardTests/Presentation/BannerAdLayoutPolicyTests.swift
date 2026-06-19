//
//  BannerAdLayoutPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/19/26.
//

import Foundation
import Testing

@testable import SYKeyboard

@Suite("배너 광고 레이아웃 정책 검증")
struct BannerAdLayoutPolicyTests {

    @Test("광고를 받기 전에는 하단 safe area 높이를 확보하지 않음")
    func testCollapsedHeightBeforeAdReceived() {
        #expect(BannerAdLayoutPolicy.containerHeight(adHeight: 50, isAdReceived: false) == 0)
    }

    @Test("광고를 받은 뒤에만 광고 높이만큼 safe area를 확보")
    func testUsesAdHeightAfterAdReceived() {
        #expect(BannerAdLayoutPolicy.containerHeight(adHeight: 50, isAdReceived: true) == 50)
    }
}
