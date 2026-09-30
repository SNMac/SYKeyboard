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
    @Environment(\.openURL) private var openURL

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

    private func libraryRow(_ library: OpenSourceLicenseData.Library) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(library.name)
            Text(library.copyright)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(library.licenses.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(.secondary)

            // List 행에 기본 스타일 컨트롤이 하나만 있으면 행 전체가 탭 영역이 된다.
            // borderless 스타일은 탭 영역을 라벨로 한정하면서 눌린 효과도 준다.
            if let linkURL = library.linkURL {
                Button {
                    openURL(linkURL)
                } label: {
                    Text(library.url)
                        .font(.caption)
                        // Button은 라벨을 가운데 정렬한다. 큰 글자 크기에서 URL이
                        // 감싸지면 마지막 줄만 가운데로 떠 위 세 줄과 어긋난다.
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.borderless)
                .accessibilityAddTraits(.isLink)
            } else {
                Text(library.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
