//
//  HeightSettingsView.swift.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/3/24.
//

import SwiftUI

struct HeightSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var state: PreviewNaratgeulState
    @AppStorage("keyboardHeight", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var keyboardHeight = GlobalValues.defaultKeyboardHeight
    @AppStorage("isNumberKeyboardTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberKeyboardTypeEnabled = true
    @State var tempKeyboardHeight: Double = GlobalValues.defaultKeyboardHeight
    
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
                    dismiss()
                } label: {
                    Text("취소")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    tempKeyboardHeight = GlobalValues.defaultKeyboardHeight
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
    
    var body: some View {
        NavigationStack {
            heightSettings
            
            ZStack {
                if #available(iOS 18, *) {
                    Swift6_PreviewHangeulView(tempKeyboardHeight: $tempKeyboardHeight)
                } else {
                    PreviewHangeulView(tempKeyboardHeight: $tempKeyboardHeight)
                }
            }
        }.onAppear {
            tempKeyboardHeight = keyboardHeight
        }
    }
}

#Preview {
    HeightSettingsView()
        .environmentObject(PreviewNaratgeulState())
}
