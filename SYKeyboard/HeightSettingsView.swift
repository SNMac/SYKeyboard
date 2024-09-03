//
//  HeightSettingsView.swift.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/3/24.
//

import SwiftUI

struct HeightSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("keyboardHeight", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var keyboardHeight = 240
    @AppStorage("tempKeyboardHeight", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var tempKeyboardHeight = 240.0
    
    private var previewSYKeyboard: some View {
        VStack(spacing: 5) {
            // MARK: - ㄱ, ㄴ, ㅏㅓ, 􀆛
            HStack(spacing: 6) {
                PreviewSYKeyboardButton(text: "ㄱ", primary: true)
                
                PreviewSYKeyboardButton(text: "ㄴ", primary: true)
                
                PreviewSYKeyboardButton(text: "ㅏㅓ", primary: true)
                
                PreviewSYKeyboardButton(systemName: "delete.left", primary: false)
            }.padding(.horizontal, 4)
            
            // MARK: - ㄹ, ㅁ, ㅗㅜ, 􁁺
            HStack(spacing: 6) {
                PreviewSYKeyboardButton(text: "ㄹ", primary: true)
                
                PreviewSYKeyboardButton(text: "ㅁ", primary: true)
                
                PreviewSYKeyboardButton(text: "ㅗㅜ", primary: true)
                
                PreviewSYKeyboardButton(systemName: "space", primary: false)
            }.padding(.horizontal, 4)
            
            // MARK: - ㅅ, ㅇ, ㅣ, 􁂆
            HStack(spacing: 6) {
                PreviewSYKeyboardButton(text: "ㅅ", primary: true)
                
                PreviewSYKeyboardButton(text: "ㅇ", primary: true)
                
                PreviewSYKeyboardButton(text: "ㅣ", primary: true)
                
                PreviewSYKeyboardButton(systemName: "return.left", primary: false)
            }.padding(.horizontal, 4)
            
            // MARK: - 획, ㅡ, 쌍, (123, 􀆪)
            HStack(spacing: 6) {
                PreviewSYKeyboardButton(text: "획", primary: true)
                
                PreviewSYKeyboardButton(text: "ㅡ", primary: true)
                
                PreviewSYKeyboardButton(text: "쌍", primary: true)
                
                PreviewSYKeyboardButton(text: "123", primary: false)
            }.padding(.horizontal, 4)
        }.padding(.vertical, 4)
            .frame(height: tempKeyboardHeight)
            .background(Color("KeyboardBackground"))
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 40, trailing: 0))
    }
    
    private var insideNavigation: some View {
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
                    dismiss()
                } label: {
                    Text("취소")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    tempKeyboardHeight = Double(GlobalData().defaultHeight)
                } label: {
                    Text("리셋")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    keyboardHeight = Int(tempKeyboardHeight)
                    dismiss()
                } label: {
                    Text("저장")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                insideNavigation
                previewSYKeyboard
            }
        } else {
            NavigationView {
                insideNavigation
                previewSYKeyboard
            }
        }
    }
}

#Preview {
    HeightSettingsView()
}
