//
//  OneHandWidthSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 11/17/24.
//

import SwiftUI

struct OneHandWidthSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("keyboardHeight", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var keyboardHeight = GlobalValues.defaultKeyboardHeight
    @AppStorage("oneHandWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var oneHandWidth = GlobalValues.defaultOneHandWidth
    @AppStorage("needsInputModeSwitchKey", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var needsInputModeSwitchKey = true
    @State private var tempOneHandWidth: Double = GlobalValues.defaultOneHandWidth
    
    let fontSize: CGFloat = 36
    
    private var oneHandWidthSettings: some View {
        VStack {
            Text("\(Int(tempOneHandWidth) - (Int(GlobalValues.defaultOneHandWidth) - 100))")
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
            Slider(value: $tempOneHandWidth, in: 300...340, step: 1)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
            Spacer()
            
            HStack {
                Button {
                    
                } label: {
                    Image(systemName: "keyboard.onehanded.left")
                        .font(.system(size: fontSize))
                }.buttonStyle(.bordered)
                
                Button {
                    
                } label: {
                    Image(systemName: "keyboard.onehanded.right")
                        .font(.system(size: fontSize))
                }.buttonStyle(.bordered)
            }
            Spacer()
        }
        .navigationTitle("한손 키보드 너비")
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
                    tempOneHandWidth = GlobalValues.defaultOneHandWidth
                } label: {
                    Text("리셋")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    oneHandWidth = tempOneHandWidth
                    dismiss()
                } label: {
                    Text("저장")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            oneHandWidthSettings
            
            ZStack {
                if #available(iOS 18, *) {
                    iOS18_PreviewHangeulView(keyboardHeight: $keyboardHeight)
                } else {
                    PreviewHangeulView(keyboardHeight: $keyboardHeight)
                }
            }
        }.onAppear {
            tempOneHandWidth = oneHandWidth
        }
        
    }
}

#Preview {
    OneHandWidthSettingsView()
}