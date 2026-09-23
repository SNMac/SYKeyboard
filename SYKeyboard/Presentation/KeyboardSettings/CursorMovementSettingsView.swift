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
    
    /// 리셋할 때마다 바꿔 `Slider`를 새로 만든다. iOS 27 `Slider`는 놓은 직후 값이 바깥에서 바뀌면
    /// 마지막 드래그 값을 다시 커밋하므로, 이전 슬라이더를 버려 그 커밋을 끊는다
    @State private var cursorActiveDistanceResetCount = 0
    @State private var cursorMoveIntervalResetCount = 0
    
    // MARK: - Content
    
    var body: some View {
        VStack {
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
            .requestReviewOnDetailSettingsReturn()
        }.onDisappear {
            Analytics.setUserProperty(String(format: "%.1f", cursorActiveDistance),
                                      forName: "pref_cursor_atv_distance")
            Analytics.logEvent("cursor_active_distance", parameters: [
                "view": "CursorMovementSettingsView",
                "value": cursorActiveDistance,
            ])
            
            Analytics.setUserProperty(String(format: "%.1f", cursorMoveInterval),
                                      forName: "pref_cursor_mv_interval")
            Analytics.logEvent("cursor_move_interval", parameters: [
                "view": "CursorMovementSettingsView",
                "value": cursorMoveInterval
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
            Slider(value: $cursorActiveDistance, in: 10.0...50.0, step: 1.0) { _ in
                hideKeyboard()
            }
            .id(cursorActiveDistanceResetCount)
            Button {
                cursorActiveDistance = DefaultValues.cursorActiveDistance
                cursorActiveDistanceResetCount += 1
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
            .id(cursorMoveIntervalResetCount)
            Button {
                cursorMoveInterval = DefaultValues.cursorMoveInterval
                cursorMoveIntervalResetCount += 1
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
    NavigationStack {
        CursorMovementSettingsView()
    }
}
