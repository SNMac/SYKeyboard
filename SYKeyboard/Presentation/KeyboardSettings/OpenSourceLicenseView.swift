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

    @Environment(\.dismiss) private var dismiss

    @State private var licenseData: OpenSourceLicenseData?

    // MARK: - Content

    var body: some View {
        NavigationStack {
            List {
                if let licenseData {
                    librarySection(licenseData.libraries)
                    licenseSection(licenseData.licenses)
                    binarySDKSection(licenseData.binarySDKNotice)
                } else {
                    Text("라이선스 정보를 불러오지 못했습니다.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("오픈소스 라이선스")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        .task {
            licenseData = Self.loadLicenseData()
        }
    }

    // MARK: - Sections

    private func librarySection(_ libraries: [OpenSourceLicenseData.Library]) -> some View {
        Section {
            ForEach(libraries) { library in
                libraryRow(library)
            }
        } header: {
            Text("사용 중인 오픈소스")
        }
    }

    @ViewBuilder
    private func libraryRow(_ library: OpenSourceLicenseData.Library) -> some View {
        let content = VStack(alignment: .leading, spacing: 3) {
            Text(library.name)
            Text(library.copyright)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(library.licenses.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(library.url)
                .font(.caption)
                .foregroundStyle(.tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if let linkURL = library.linkURL {
            Link(destination: linkURL) { content }
                .foregroundStyle(.primary)
        } else {
            content
        }
    }

    private func licenseSection(_ licenses: [OpenSourceLicenseData.License]) -> some View {
        Section {
            ForEach(licenses) { license in
                NavigationLink(license.name) {
                    OpenSourceLicenseTextView(name: license.name, text: license.text)
                }
            }
        } header: {
            Text("라이선스 전문")
        }
    }

    private func binarySDKSection(_ notice: String) -> some View {
        Section {
            Text(notice)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("바이너리 SDK 이용 약관")
        }
    }

    // MARK: - Methods

    private static func loadLicenseData() -> OpenSourceLicenseData? {
        do {
            return try OpenSourceLicenseLoader.load()
        } catch OpenSourceLicenseLoader.LoadError.resourceNotFound {
            assertionFailure("opensource_license.json이 앱 번들에 존재하지 않습니다.")
            logger.error("opensource_license.json을 앱 번들에서 찾을 수 없습니다.")
            return nil
        } catch {
            assertionFailure("opensource_license.json을 디코딩하지 못했습니다.")
            logger.error("opensource_license.json 디코딩 실패: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - OpenSourceLicenseTextView

/// 라이선스 전문 표시 화면
private struct OpenSourceLicenseTextView: View {

    let name: String
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .font(.callout)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    OpenSourceLicenseView()
}
