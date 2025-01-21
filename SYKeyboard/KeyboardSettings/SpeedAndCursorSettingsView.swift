//
//  SpeedAndCursorSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/5/24.
//

import SwiftUI

struct SpeedAndCursorSettingsView: View {
    @AppStorage("longPressSpeed", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var longPressSpeed = GlobalValues.defaultLongPressSpeed
    @AppStorage("repeatTimerSpeed", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var repeatTimerSpeed = GlobalValues.defaultRepeatTimerSpeed
    @AppStorage("cursorActiveWidth", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var cursorActiveWidth = GlobalValues.defaultCursorActiveWidth
    @AppStorage("cursorMoveWidth", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var cursorMoveWidth = GlobalValues.defaultCursorMoveWidth
    
    private var longPressSpeedSetting: some View {
        HStack {
            Text("길게 누르기")
                .frame(alignment: .leading)
            Spacer()
            Text("\(longPressSpeed * 10, specifier: "%.1f")")
            Slider(value: $longPressSpeed, in: 0.1...0.9, step: 0.05) { _ in
                hideKeyboard()
            }.frame(width: 140)
            
            Button {
                longPressSpeed = GlobalValues.defaultLongPressSpeed
                hideKeyboard()
            } label: {
                Text("리셋")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
    
    private var repeatTimerSpeedSetting: some View {
        HStack {
            Text("반복 입력")
                .frame(alignment: .leading)
            Spacer()
            Text("\(repeatTimerSpeed * 100, specifier: "%.1f")")
            Slider(value: $repeatTimerSpeed, in: 0.01...0.09, step: 0.005) { _ in
                hideKeyboard()
            }.frame(width: 140)
            
            Button {
                repeatTimerSpeed = GlobalValues.defaultRepeatTimerSpeed
                hideKeyboard()
            } label: {
                Text("리셋")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
    
    private var cursorActiveWidthSetting: some View {
        HStack {
            Text("활성화 거리")
                .frame(alignment: .leading)
            Spacer()
            Text("\(cursorActiveWidth, specifier: "%.1f")")
            Slider(value: $cursorActiveWidth, in: 40.0...60.0, step: 1.0) { _ in
                hideKeyboard()
            }.frame(width: 140)
            
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
            Text("이동 간격")
                .frame(alignment: .leading)
            Spacer()
            Text("\(cursorMoveWidth, specifier: "%.1f")")
            Slider(value: $cursorMoveWidth, in: 1.0...9.0, step: 0.5) { _ in
                hideKeyboard()
            }.frame(width: 140)
            
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
                    longPressSpeedSetting
                    repeatTimerSpeedSetting
                } header: {
                    Text("반복 속도")
                }
                
                Section {
                    cursorActiveWidthSetting
                    cursorMoveWidthSetting
                } header: {
                    Text("커서 이동")
                }
            }
            .navigationTitle("반복/커서 설정")
            .navigationBarTitleDisplayMode(.inline)
            .requestReviewViewModifier()
        }
    }
}

#Preview {
    SpeedAndCursorSettingsView()
}
