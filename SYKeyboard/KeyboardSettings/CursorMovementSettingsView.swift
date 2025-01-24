//
//  CursorMovementSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/24/25.
//

import SwiftUI

struct CursorMovementSettingsView: View {
    @AppStorage("cursorActiveDistance", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var cursorActiveDistance = GlobalValues.defaultCursorActiveDistance
    @AppStorage("cursorMoveInterval", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var cursorMoveInterval = GlobalValues.defaultCursorMoveInterval
    
    private var cursorActiveDistanceSetting: some View {
        HStack {
            Text("\(cursorActiveDistance, specifier: "%.1f")")
                .frame(width: 40)
                .monospacedDigit()
            Slider(value: $cursorActiveDistance, in: 40.0...60.0, step: 1.0) { _ in
                hideKeyboard()
            }
            Button {
                cursorActiveDistance = GlobalValues.defaultCursorActiveDistance
                hideKeyboard()
            } label: {
                Text("리셋")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
    
    private var cursorMoveIntervalSetting: some View {
        HStack {
            Text("\(cursorMoveInterval, specifier: "%.1f")")
                .frame(width: 40)
                .monospacedDigit()
            Slider(value: $cursorMoveInterval, in: 1.0...9.0, step: 0.5) { _ in
                hideKeyboard()
            }
            Button {
                cursorMoveInterval = GlobalValues.defaultCursorMoveInterval
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
                    cursorActiveDistanceSetting
                } header: {
                    Text("활성화 드래그 거리")
                }
                
                Section {
                    cursorMoveIntervalSetting
                } header: {
                    Text("이동 드래그 간격")
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
