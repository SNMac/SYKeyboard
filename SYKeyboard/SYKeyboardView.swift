//
//  KeyboardView.swift
//  Naratgeul
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI

protocol SYKeyboardDelegate: AnyObject {
    func hangulKeypadTap(char: String)
    func deleteKeypadTap()
    func enterKeypadTap()
    func spaceKeypadTap()
}

struct HangulButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .font(.system(size: 24))
            .foregroundStyle(Color(uiColor: UIColor.label))
            .background(Color("PrimaryKeyboardButton"))
            .clipShape(.rect(cornerRadius: 5))
    }
}

struct FunctionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(Color(uiColor: UIColor.label))
            .background(Color("SecondaryKeyboardButton"))
            .clipShape(.rect(cornerRadius: 5))
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


struct SYKeyboardView: View {

    weak var delegate: SYKeyboardDelegate?
    
    let keyboardHeight: CGFloat
    
    var needsInputModeSwitchKey: Bool = false
    var nextKeyboardAction: Selector? = nil
    
    var backgroundColor: Color = .clear
    

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                Button {
                    delegate?.hangulKeypadTap(char: "ㄱ")
                } label: {
                    Text("ㄱ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.hangulKeypadTap(char: "ㄴ")
                } label: {
                    Text("ㄴ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.hangulKeypadTap(char: "ㅏ")  // TODO:
                } label: {
                    Text("ㅏㅓ")
                }.buttonStyle(HangulButtonStyle())
                
                Button{
                    delegate?.deleteKeypadTap()
                } label: {
                    Image(systemName: "delete.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24)
                }.buttonStyle(FunctionButtonStyle())
            }.padding(.horizontal, 2)
            
            HStack(spacing: 5) {
                Button {
                    delegate?.hangulKeypadTap(char: "ㄹ")
                } label: {
                    Text("ㄹ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.hangulKeypadTap(char: "ㅁ")
                } label: {
                    Text("ㅁ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.hangulKeypadTap(char: "ㅗ")  // TODO:
                } label: {
                    Text("ㅗㅜ")
                }.buttonStyle(HangulButtonStyle())
                
                Button{
                    delegate?.spaceKeypadTap()
                } label: {
                    Image(systemName: "space")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26)
                }.buttonStyle(FunctionButtonStyle())
            }.padding(.horizontal, 2)
            
            HStack(spacing: 5) {
                Button {
                    delegate?.hangulKeypadTap(char: "ㅅ")
                } label: {
                    Text("ㅅ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.hangulKeypadTap(char: "ㅇ")
                } label: {
                    Text("ㅇ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.hangulKeypadTap(char: "ㅣ")
                } label: {
                    Text("ㅣ")
                }.buttonStyle(HangulButtonStyle())
                
                Button{
                    delegate?.enterKeypadTap()
                } label: {
                    Image(systemName: "return.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                }.buttonStyle(FunctionButtonStyle())
            }.padding(.horizontal, 2)
            
            HStack(spacing: 5) {
                Button {
                    delegate?.hangulKeypadTap(char: ".")  // TODO:
                } label: {
                    Text("획")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.hangulKeypadTap(char: "ㅡ")  // TODO:
                } label: {
                    Text("ㅡ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.hangulKeypadTap(char: "ㄲ")  // TODO:
                } label: {
                    Text("쌍")
                }.buttonStyle(HangulButtonStyle())
                
                if needsInputModeSwitchKey && nextKeyboardAction != nil {
                    HStack(spacing: 5) {
                        Button {
                            
                        } label: {
                            Image(systemName: "textformat.123")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24)
                        }.buttonStyle(FunctionButtonStyle())
                        
                        Button {
                            
                        } label: {
                            Image(systemName: "globe")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22)
                                .overlay(NextKeyboardButtonOverlay(action: nextKeyboardAction!))
                        }.buttonStyle(FunctionButtonStyle())
                    }
                } else {
                    Button {
                        
                    } label: {
                        Image(systemName: "textformat.123")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32)
                    }.buttonStyle(FunctionButtonStyle())
                }
            }.padding(.horizontal, 2)
        }
        .frame(height: keyboardHeight)
        .padding(.vertical, 2)
        .background(Color("KeyboardBackground"))
    }
}


#Preview {
    SYKeyboardView(keyboardHeight: 260, needsInputModeSwitchKey: true)
}
