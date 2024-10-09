//
//  SpeedSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/5/24.
//

import SwiftUI

struct SpeedAndCursorSettingsView: View {
    @AppStorage("longPressSpeed", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var longPressSpeed = 0.5
    @AppStorage("repeatTimerSpeed", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var repeatTimerSpeed = 0.05
    @AppStorage("cursorActiveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorActiveWidth = 20.0
    @AppStorage("cursorMoveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorMoveWidth = 5.0
    
    var longPressSpeedSetting: some View {
        HStack {
            Text("길게 누르기")
                .frame(width: 84, alignment: .leading)
            Spacer()
            Text("\(longPressSpeed * 10, specifier: "%.1f")")
                .frame(width: 26)
            Slider(value: $longPressSpeed, in: 0.1...0.9, step: 0.05) { _ in
                hideKeyboard()
            }
            
            Button {
                longPressSpeed = GlobalValues.defaultLongPressSpeed
                hideKeyboard()
            } label: {
                Text("리셋")
            }.frame(width: 30)
        }
    }
    
    var repeatTimerSpeedSetting: some View {
        HStack {
            Text("반복 입력")
                .frame(width: 84, alignment: .leading)
            Spacer()
            Text("\(repeatTimerSpeed * 100, specifier: "%.1f")")
                .frame(width: 26)
            Slider(value: $repeatTimerSpeed, in: 0.01...0.09, step: 0.005) { _ in
                hideKeyboard()
            }
            
            Button {
                repeatTimerSpeed = GlobalValues.defaultRepeatTimerSpeed
                hideKeyboard()
            } label: {
                Text("리셋")
            }.frame(width: 30)
        }
    }
    
    var cursorActiveWidthSetting: some View {
        HStack {
            Text("커서 이동 활성화 거리")
                .frame(width: 84, alignment: .leading)
            Spacer()
            Text("\(repeatTimerSpeed * 100, specifier: "%.1f")")
                .frame(width: 26)
            Slider(value: $repeatTimerSpeed, in: 0.01...0.09, step: 0.005) { _ in
                hideKeyboard()
            }
            
            Button {
                repeatTimerSpeed = GlobalValues.defaultRepeatTimerSpeed
                hideKeyboard()
            } label: {
                Text("리셋")
            }.frame(width: 30)
        }
    }
    
    var cursorMoveWidthSetting: some View {
        HStack {
            Text("커서 이동 간격")
                .frame(width: 84, alignment: .leading)
            Spacer()
            Text("\(repeatTimerSpeed * 100, specifier: "%.1f")")
                .frame(width: 26)
            Slider(value: $repeatTimerSpeed, in: 0.01...0.09, step: 0.005) { _ in
                hideKeyboard()
            }
            
            Button {
                repeatTimerSpeed = GlobalValues.defaultRepeatTimerSpeed
                hideKeyboard()
            } label: {
                Text("리셋")
            }.frame(width: 30)
        }
    }
    
    var body: some View {
        NavigationStack {
            KeyboardTestView()
            List {
                Section {
                    longPressSpeedSetting
                    repeatTimerSpeedSetting
                    dragActiveWidthSetting
                    cursorMoveWidthSetting
                }
            }
            .navigationTitle("속도 설정")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SpeedAndCursorSettingsView()
}
