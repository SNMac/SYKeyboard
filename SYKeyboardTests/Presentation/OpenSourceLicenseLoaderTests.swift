//
//  OpenSourceLicenseLoaderTests.swift
//  SYKeyboardTests
//
//  Created by 서동환 on 9/1/26.
//

import Foundation
import Testing

@testable import SYKeyboard

@Suite("오픈소스 라이선스 고지 데이터 로딩 검증")
struct OpenSourceLicenseLoaderTests {

    /// `opensource_license.json`이 앱 타깃에 편입되지 않으면 빌드는 통과하고
    /// 런타임에만 빈 화면이 된다. production과 같은 `Bundle.main` 조회 경로를
    /// 그대로 호출해 그 경우를 잡는다.
    @Test("opensource_license.json이 앱 번들에 포함되어 production 조회 경로로 읽힌다")
    func testLoadsLicenseDataFromAppBundle() throws {
        let data = try OpenSourceLicenseLoader.load()

        #expect(data.libraries.isEmpty == false)
        #expect(data.licenses.isEmpty == false)
        #expect(data.binarySDKNotice.isEmpty == false)
    }

    /// 라이브러리 항목에 이슈 #52가 요구한 네 가지가 모두 채워져 있는지 확인한다.
    @Test("모든 라이브러리에 이름·저작권·라이선스 유형·링크가 있다")
    func testEveryLibraryHasRequiredFields() throws {
        let data = try OpenSourceLicenseLoader.load()
        let licenseNames = Set(data.licenses.map(\.name))

        for library in data.libraries {
            #expect(library.name.isEmpty == false)
            #expect(library.copyright.isEmpty == false)
            #expect(library.licenses.isEmpty == false, "\(library.name)에 라이선스 유형이 없습니다.")
            #expect(library.linkURL != nil, "\(library.name)의 url이 올바르지 않습니다.")

            // 표기한 라이선스 유형은 전문이 실린 유형이어야 한다.
            for name in library.licenses {
                #expect(licenseNames.contains(name), "\(library.name)의 \(name) 전문이 없습니다.")
            }
        }
    }

    /// 전문 길이에 하한을 두면 짧은 라이선스가 추가될 때 정상 데이터가 실패한다.
    /// 실제로 막으려는 것은 빈 문자열이나 공백뿐인 항목이다.
    @Test("라이선스 전문이 비어 있지 않다")
    func testEveryLicenseHasText() throws {
        let data = try OpenSourceLicenseLoader.load()

        for license in data.licenses {
            let trimmed = license.text.trimmingCharacters(in: .whitespacesAndNewlines)
            #expect(trimmed.isEmpty == false, "\(license.name) 전문이 비어 있습니다.")
        }
    }
}
