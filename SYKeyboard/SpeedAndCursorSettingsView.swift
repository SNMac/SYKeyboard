//
//  SpeedAndCursorSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/5/24.
//

import SwiftUI

struct SpeedAndCursorSettingsView: View {
    @AppStorage("longPressSpeed", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var longPressSpeed = 0.5
    @AppStorage("repeatTimerSpeed", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var repeatTimerSpeed = 0.05
    @AppStorage("cursorActiveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorActiveWidth = 30.0
    @AppStorage("cursorMoveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorMoveWidth = 5.0
    
    var longPressSpeedSetting: some View {
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
            .frame(width: 30)
        }
    }
    
    var repeatTimerSpeedSetting: some View {
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
            .frame(width: 30)
        }
    }
    
    var cursorActiveWidthSetting: some View {
        HStack {
            Text("활성화 거리")
                .frame(alignment: .leading)
            Spacer()
            Text("\(cursorActiveWidth, specifier: "%.1f")")
            Slider(value: $cursorActiveWidth, in: 10.0...50.0, step: 2.0) { _ in
                hideKeyboard()
            }.frame(width: 140)
            
            Button {
                cursorActiveWidth = GlobalValues.defaultCursorActiveWidth
                hideKeyboard()
            } label: {
                Text("리셋")
            }
            .buttonStyle(BorderlessButtonStyle())
            .frame(width: 30)
        }
    }
    
    var cursorMoveWidthSetting: some View {
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
            .frame(width: 30)
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
                    Text("입력 속도")
                }
                
                Section {
                    cursorActiveWidthSetting
                    cursorMoveWidthSetting
                } header: {
                    Text("커서 이동")
                }
            }
            .navigationTitle("속도/커서 설정")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SpeedAndCursorSettingsView()
}
