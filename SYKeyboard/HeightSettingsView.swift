//
//  HeightSettingsView.swift.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/3/24.
//

import SwiftUI

struct HeightSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("keyboardHeight", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var keyboardHeight = 240.0
    @AppStorage("tempKeyboardHeight", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var tempKeyboardHeight = 240.0
    
    let vPadding: CGFloat = 4
    let interItemVPadding: CGFloat = 2
    let hPadding: CGFloat = 4
    let interItemHPadding: CGFloat = 3
    
    private var heightSettings: some View {
        VStack {
            Text("\(Int(tempKeyboardHeight) - 140)")
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
                    tempKeyboardHeight = keyboardHeight
                    dismiss()
                } label: {
                    Text("취소")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    tempKeyboardHeight = DefaultValues().defaultKeyboardHeight
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
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
    
    private var previewSYKeyboard: some View {
        VStack(spacing: 0) {
            // MARK: - ㄱ, ㄴ, ㅏㅓ, 􀆛
            HStack(spacing: 0) {
                PreviewSYKeyboardButton(text: "ㄱ", primary: true)
                    .padding(EdgeInsets(top: vPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                
                PreviewSYKeyboardButton(text: "ㄴ", primary: true)
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                
                PreviewSYKeyboardButton(text: "ㅏㅓ", primary: true)
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                
                PreviewSYKeyboardButton(systemName: "delete.left", primary: false)
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
            }
            
            // MARK: - ㄹ, ㅁ, ㅗㅜ, 􁁺
            HStack(spacing: 0) {
                PreviewSYKeyboardButton(text: "ㄹ", primary: true)
                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                
                PreviewSYKeyboardButton(text: "ㅁ", primary: true)
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                
                PreviewSYKeyboardButton(text: "ㅗㅜ", primary: true)
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                
                PreviewSYKeyboardButton(systemName: "space", primary: false)
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
            }
            
            // MARK: - ㅅ, ㅇ, ㅣ, 􁂆
            HStack(spacing: 0) {
                PreviewSYKeyboardButton(text: "ㅅ", primary: true)
                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                
                PreviewSYKeyboardButton(text: "ㅇ", primary: true)
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                
                PreviewSYKeyboardButton(text: "ㅣ", primary: true)
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                
                PreviewSYKeyboardButton(systemName: "return.left", primary: false)
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
            }
            
            // MARK: - 획, ㅡ, 쌍, (123, 􀆪)
            HStack(spacing: 0) {
                PreviewSYKeyboardButton(text: "획", primary: true)
                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                
                PreviewSYKeyboardButton(text: "ㅡ", primary: true)
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                
                PreviewSYKeyboardButton(text: "쌍", primary: true)
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                
                PreviewSYKeyboardButton(text: "123", primary: false)
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
            }
        }
            .frame(height: tempKeyboardHeight)
            .background(Color("KeyboardBackground"))
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 40, trailing: 0))
    }
    
    var body: some View {
        NavigationStack {
            heightSettings
            previewSYKeyboard
        }
    }
}

#Preview {
    HeightSettingsView()
}
