//
//  KeyboardSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/17/25.
//

import SwiftUI

struct KeyboardSettingsView: View {

    // MARK: - Properties

    @Environment(\.scenePhase) private var scenePhase

    @State private var isKeyboardExtensionEnabled: Bool = false

    // MARK: - Content

    var body: some View {
        List {
            Section {
                InitialSettingsView()
            } header: {
                Text("키보드 추가 및 권한 설정")
            } footer: {
                Text("키보드 ➡️ 'SY키보드' 및 '전체 접근 허용' 활성화")
                    .font(.caption)
            }
            .alignmentGuide(.listRowSeparatorLeading) { dimensions in
                dimensions[.leading]
            }

            HangeulKeyboardSelectView()

            if isKeyboardExtensionEnabled {
                Section {
                    FeedbackSettingsView()
                } header: {
                    Text("피드백 설정")
                }

                Section {
                    PredictiveTextSettingsView()
                } header: {
                    Text("자동완성 텍스트 설정")
                }

                Section {
                    InputSettingsView()
                } header: {
                    Text("입력 설정")
                }

                Section {
                    AppearanceSettingsView()
                } header: {
                    Text("외형 설정")
                }
            } else {
                Section {
                    Text("‼️ SY키보드 추가 필요 ‼️")
                } footer: {
                    Text("SY키보드를 설정에서 추가하시면 세부 설정이 가능합니다.")
                }
            }

            Section {
                InfoView()
            } header: {
                Text("정보")
            }
            .alignmentGuide(.listRowSeparatorLeading) { dimensions in
                dimensions[.leading]
            }
        }
        .ignoresSafeArea(.keyboard, edges: .all)
        .scrollDismissesKeyboard(.immediately)
        .onAppear {
            isKeyboardExtensionEnabled = KeyboardExtensionAvailability.isEnabled()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active, .inactive:
                isKeyboardExtensionEnabled = KeyboardExtensionAvailability.isEnabled()
            default:
                break
            }
        }
    }
}

// MARK: - Preview

#Preview {
    KeyboardSettingsView()
}
