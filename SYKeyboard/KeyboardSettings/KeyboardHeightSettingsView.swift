//
//  HeightSettingsView.swift.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/3/24.
//

import SwiftUI

struct KeyboardHeightSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var state: PreviewKeyboardState
    @AppStorage("keyboardHeight", store: UserDefaults(suiteName: UserDefaultsManager.groupBundleID)) private var keyboardHeight = UserDefaultsManager.defaultKeyboardHeight
    @AppStorage("oneHandedKeyboardWidth", store: UserDefaults(suiteName: UserDefaultsManager.groupBundleID)) private var oneHandedKeyboardWidth = UserDefaultsManager.defaultOneHandedKeyboardWidth
    @State private var tempKeyboardHeight: Double = UserDefaultsManager.defaultKeyboardHeight
    
    private var keyboardHeightSettings: some View {
        VStack {
            Text("\(Int(tempKeyboardHeight) - (Int(UserDefaultsManager.defaultKeyboardHeight) - 100))")
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
            Slider(value: $tempKeyboardHeight, in: 190...290, step: 1)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
            Spacer()
        }
        .navigationTitle("키보드 높이")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("취소")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    tempKeyboardHeight = UserDefaultsManager.defaultKeyboardHeight
                } label: {
                    Text("리셋")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    keyboardHeight = tempKeyboardHeight
                    dismiss()
                } label: {
                    Text("저장")
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            keyboardHeightSettings
            
            PreviewHangeulView(keyboardHeight: $tempKeyboardHeight, oneHandedKeyboardWidth: $oneHandedKeyboardWidth)
        }
        .onAppear {
            tempKeyboardHeight = keyboardHeight
            state.currentOneHandedKeyboard = .center
        }
        .requestReviewViewModifier()
    }
}

#Preview {
    KeyboardHeightSettingsView()
        .environmentObject(PreviewKeyboardState())
}
