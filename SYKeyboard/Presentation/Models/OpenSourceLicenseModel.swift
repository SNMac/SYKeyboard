//
//  OpenSourceLicenseModel.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/1/26.
//

import Foundation

/// 앱 번들의 `opensource_license.json` 구조
struct OpenSourceLicenseData: Decodable {

    /// 고지 대상 라이브러리
    struct Library: Decodable, Identifiable {
        var id: String { name }

        let name: String
        let url: String
        /// 저장소의 LICENSE 부록 또는 소스 헤더에서 확인한 저작권 표기
        let copyright: String
        /// 이 라이브러리에 적용되는 라이선스 유형 이름
        let licenses: [String]

        var linkURL: URL? { URL(string: url) }
    }

    /// 라이선스 유형별 전문
    struct License: Decodable, Identifiable {
        var id: String { name }

        let name: String
        let text: String
    }

    let libraries: [Library]
    let licenses: [License]
    /// 오픈소스가 아닌 바이너리 SDK의 이용 약관 안내
    let binarySDKNotice: String
}
