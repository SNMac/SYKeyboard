//
//  KeyboardView.swift
//  Naratgeul
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI

struct HangulButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .font(.system(size: 24))
            .foregroundStyle(.white)
            .background(.gray)
            .clipShape(.rect(cornerRadius: 6))
    }
}

struct FunctionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .font(.system(size: 18))
            .foregroundStyle(.white)
            .background(.black.opacity(0.55))
            .clipShape(.rect(cornerRadius: 6))
    }
}

struct NextKeyboardButtonOverlay: UIViewRepresentable {
    let action: Selector

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton()
        button.addTarget(nil, action: action, for: .allTouchEvents)
        return button
    }
    func updateUIView(_ button: UIButton, context: Context) {}
}


struct NaratgeulKeyboardView: View {
    
    var insertText: (String) -> Void
    var deleteText: () -> Void
    
    let KeyboardDataList = KeyboardData.list
    let keyboardHeight: CGFloat
    let layout: [GridItem] = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ]
    
    var needsInputModeSwitchKey: Bool = false
    var nextKeyboardAction: Selector? = nil
    
    var backgroundColor: Color = .clear
    
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                Button {
                    insertText("ㄱ")
                } label: {
                    Text("ㄱ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    insertText("ㄴ")
                } label: {
                    Text("ㄴ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    insertText("")
                } label: {
                    Text("ㅏㅓ")
                }.buttonStyle(HangulButtonStyle())
                
                Button{
                    deleteText()
                } label: {
                    Image(systemName: "delete.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24)
                }.buttonStyle(FunctionButtonStyle())
            }.padding(.horizontal, 2)
            
            HStack(spacing: 5) {
                Button {
                    insertText("ㄹ")
                } label: {
                    Text("ㄹ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    insertText("ㅁ")
                } label: {
                    Text("ㅁ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    insertText("")
                } label: {
                    Text("ㅗㅜ")
                }.buttonStyle(HangulButtonStyle())
                
                Button{
                    insertText(" ")
                } label: {
                    Image(systemName: "space")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24)
                }.buttonStyle(FunctionButtonStyle())
            }.padding(.horizontal, 2)
            
            HStack(spacing: 5) {
                Button {
                    insertText("ㅅ")
                } label: {
                    Text("ㅅ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    insertText("ㅇ")
                } label: {
                    Text("ㅇ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    insertText("ㅣ")
                } label: {
                    Text("ㅣ")
                }.buttonStyle(HangulButtonStyle())
                
                Button{
                    insertText("\n")
                } label: {
                    Image(systemName: "return.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18)
                }.buttonStyle(FunctionButtonStyle())
            }.padding(.horizontal, 2)
            
            HStack(spacing: 5) {
                Button {
                    insertText("")
                } label: {
                    Text("획")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    insertText("ㅡ")
                } label: {
                    Text("ㅡ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    insertText("")
                } label: {
                    Text("쌍")
                }.buttonStyle(HangulButtonStyle())
                
                if needsInputModeSwitchKey && nextKeyboardAction != nil {
                    HStack {
                        Button {
                            
                        } label: {
                            Image(systemName: "textformat.123")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18)
                        }.buttonStyle(FunctionButtonStyle())
                        
                        Button {
                            
                        } label: {
                            Image(systemName: "globe")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18)
                                .overlay(NextKeyboardButtonOverlay(action: nextKeyboardAction!))
                        }.buttonStyle(FunctionButtonStyle())
                    }
                } else {
                    Button {
                        
                    } label: {
                        Image(systemName: "textformat.123")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                    }.buttonStyle(FunctionButtonStyle())
                }
            }.padding(.horizontal, 2)
        }
        .frame(height: keyboardHeight)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
    }
}


#Preview {
    NaratgeulKeyboardView(insertText: { _ in }, deleteText: {}, keyboardHeight: 260, needsInputModeSwitchKey: true)
}
