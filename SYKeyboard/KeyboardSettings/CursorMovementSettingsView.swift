//
//  CursorMovementSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/24/25.
//

import SwiftUI

struct CursorMovementSettingsView: View {
    @AppStorage("cursorActiveWidth", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var cursorActiveWidth = GlobalValues.defaultCursorActiveWidth
    @AppStorage("cursorMoveWidth", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var cursorMoveWidth = GlobalValues.defaultCursorMoveWidth
    
    private var cursorActiveWidthSetting: some View {
        HStack {
            Text("\(cursorActiveWidth, specifier: "%.1f")")
                .frame(width: 40)
                .monospacedDigit()
            Slider(value: $cursorActiveWidth, in: 40.0...60.0, step: 1.0) { _ in
                hideKeyboard()
            }
            Button {
                cursorActiveWidth = GlobalValues.defaultCursorActiveWidth
                hideKeyboard()
            } label: {
                Text("리셋")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
    
    private var cursorMoveWidthSetting: some View {
        HStack {
            Text("\(cursorMoveWidth, specifier: "%.1f")")
                .frame(width: 40)
                .monospacedDigit()
            Slider(value: $cursorMoveWidth, in: 1.0...9.0, step: 0.5) { _ in
                hideKeyboard()
            }
            Button {
                cursorMoveWidth = GlobalValues.defaultCursorMoveWidth
                hideKeyboard()
            } label: {
                Text("리셋")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
    
    var body: some View {
        NavigationStack {
            KeyboardTestView()
            List {
                Section {
                    cursorActiveWidthSetting
                } header: {
                    Text("활성화 거리")
                }
                
                Section {
                    cursorMoveWidthSetting
                } header: {
                    Text("이동 간격")
                }
            }
            .navigationTitle("커서 이동")
            .navigationBarTitleDisplayMode(.inline)
            .requestReviewViewModifier()
        }
    }
}

#Preview {
    CursorMovementSettingsView()
}
