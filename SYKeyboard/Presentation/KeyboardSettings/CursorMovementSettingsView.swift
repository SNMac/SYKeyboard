//
//  CursorMovementSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/24/25.
//

import SwiftUI

import SYKeyboardCore

import FirebaseAnalytics

struct CursorMovementSettingsView: View {
    
    // MARK: - Properties
    
    @AppStorage(UserDefaultsKeys.cursorActiveDistance, store: UserDefaultsManager.shared.storage)
    private var cursorActiveDistance = DefaultValues.cursorActiveDistance
    
    @AppStorage(UserDefaultsKeys.cursorMoveInterval, store: UserDefaultsManager.shared.storage)
    private var cursorMoveInterval = DefaultValues.cursorMoveInterval
    
    // MARK: - Contents
    
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
        }.onDisappear {
            Analytics.logEvent("cursor_active_distance", parameters: [
                "view": "CursorMovementSettingsView",
                "distance": cursorActiveDistance,
            ])
            
            Analytics.logEvent("cursor_move_interval", parameters: [
                "view": "CursorMovementSettingsView",
                "interval": cursorMoveInterval
            ])
        }
    }
}

// MARK: - UI Components

private extension CursorMovementSettingsView {
    var cursorActiveDistanceSetting: some View {
        HStack {
            Text("\(cursorActiveDistance, specifier: "%.1f")")
                .monospacedDigit()
                .frame(width: 40)
            Slider(value: $cursorActiveDistance, in: 40.0...60.0, step: 1.0) { _ in
                hideKeyboard()
            }
            Button {
                cursorActiveDistance = DefaultValues.cursorActiveDistance
                hideKeyboard()
            } label: {
                Text("리셋")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
    
    var cursorMoveIntervalSetting: some View {
        HStack {
            Text("\(cursorMoveInterval, specifier: "%.1f")")
                .monospacedDigit()
                .frame(width: 40)
            Slider(value: $cursorMoveInterval, in: 1.0...9.0, step: 0.5) { _ in
                hideKeyboard()
            }
            Button {
                cursorMoveInterval = DefaultValues.cursorMoveInterval
                hideKeyboard()
            } label: {
                Text("리셋")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
}

// MARK: - Preview

#Preview {
    CursorMovementSettingsView()
}
