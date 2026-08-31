//
//  OpenSourceLicenseTextLoaderTests.swift
//  SYKeyboardTests
//
//  Created by 서동환 on 9/1/26.
//

import Foundation
import Testing

@testable import SYKeyboard

@Suite("오픈소스 라이선스 전문 로딩 검증")
struct OpenSourceLicenseTextLoaderTests {

    /// `LICENSES.txt`가 앱 타깃에 편입되지 않으면 빌드는 통과하고 런타임에만 빈 화면이 된다.
    /// production과 같은 `Bundle.main` 조회 경로를 그대로 호출해 그 경우를 잡는다.
    @Test("LICENSES.txt가 앱 번들에 포함되어 production 조회 경로로 읽힌다")
    func testLoadsLicenseTextFromAppBundle() throws {
        let text = try OpenSourceLicenseTextLoader.loadText()

        #expect(text.contains("Apache License"))
        #expect(text.contains("BSD 3-Clause License"))
        #expect(text.contains("zlib License"))
        #expect(text.contains("Meta Platforms License"))
    }
}
