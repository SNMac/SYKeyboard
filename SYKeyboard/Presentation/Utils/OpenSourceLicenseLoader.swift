//
//  OpenSourceLicenseLoader.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/1/26.
//

import Foundation

/// 앱 번들에 포함된 오픈소스 라이선스 고지 데이터를 읽는 로더
///
/// 번들 편입 실패는 빌드로 드러나지 않고 런타임에 빈 화면으로만 나타나므로,
/// UI에 의존하지 않는 타입으로 분리해 테스트에서 같은 조회 경로를 호출한다.
enum OpenSourceLicenseLoader {

    // MARK: - Properties

    /// 라이선스 고지 데이터 파일 이름
    static let resourceName = "opensource_license"
    /// 라이선스 고지 데이터 파일 확장자
    static let resourceExtension = "json"

    // MARK: - LoadError

    enum LoadError: Error {
        /// 번들에서 파일을 찾지 못함
        case resourceNotFound
        /// 파일을 읽거나 디코딩하지 못함
        case decodingFailed(Error)
    }

    // MARK: - Methods

    /// 번들에서 라이선스 고지 데이터를 읽어 반환합니다.
    static func load(from bundle: Bundle = .main) throws -> OpenSourceLicenseData {
        guard let url = bundle.url(forResource: resourceName, withExtension: resourceExtension) else {
            throw LoadError.resourceNotFound
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(OpenSourceLicenseData.self, from: data)
        } catch {
            throw LoadError.decodingFailed(error)
        }
    }
}
