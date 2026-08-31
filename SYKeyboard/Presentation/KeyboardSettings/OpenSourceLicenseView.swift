//
//  OpenSourceLicenseView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/1/26.
//

import SwiftUI
import OSLog

struct OpenSourceLicenseView: View {

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: String(describing: "OpenSourceLicense")
    )

    /// 앱 번들의 `LICENSES.txt` 전문. 원문 줄바꿈을 보존하기 위해 가로 스크롤을 함께 허용한다.
    @State private var licenseText: String = ""

    // MARK: - Content

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            Text(licenseText)
                .font(.system(.caption2, design: .monospaced))
                .textSelection(.enabled)
                .padding()
        }
        .navigationTitle("오픈소스 라이선스")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            licenseText = Self.loadLicenseText()
        }
    }

    // MARK: - Methods

    private static func loadLicenseText() -> String {
        do {
            return try OpenSourceLicenseTextLoader.loadText()
        } catch OpenSourceLicenseTextLoader.LoadError.resourceNotFound {
            assertionFailure("LICENSES.txt가 앱 번들에 존재하지 않습니다.")
            logger.error("LICENSES.txt를 앱 번들에서 찾을 수 없습니다.")
            return String(localized: "라이선스 정보를 불러오지 못했습니다.")
        } catch {
            logger.error("LICENSES.txt를 읽지 못했습니다: \(error.localizedDescription)")
            return String(localized: "라이선스 정보를 불러오지 못했습니다.")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OpenSourceLicenseView()
    }
}
