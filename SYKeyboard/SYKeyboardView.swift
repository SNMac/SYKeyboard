//
//  KeyboardView.swift
//  Naratgeul
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI

protocol SYKeyboardDelegate: AnyObject {
    func hangulKeypadTap(letter: String)
    func hoegKeypadTap()
    func ssangKeypadTap()
    func deleteKeypadTap()
    func enterKeypadTap()
    func spaceKeypadTap()
    func numKeypadTap()
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
    
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                Button {
                    delegate?.hangulKeypadTap(letter: "ㄱ")
                } label: {
                    Text("ㄱ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.hangulKeypadTap(letter: "ㄴ")
                } label: {
                    Text("ㄴ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.hangulKeypadTap(letter: "ㅏ")
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
                    delegate?.hangulKeypadTap(letter: "ㄹ")
                } label: {
                    Text("ㄹ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.hangulKeypadTap(letter: "ㅁ")
                } label: {
                    Text("ㅁ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.hangulKeypadTap(letter: "ㅗ")
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
                    delegate?.hangulKeypadTap(letter: "ㅅ")
                } label: {
                    Text("ㅅ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.hangulKeypadTap(letter: "ㅇ")
                } label: {
                    Text("ㅇ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.hangulKeypadTap(letter: "ㅣ")
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
                    delegate?.hoegKeypadTap()
                } label: {
                    Text("획")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.hangulKeypadTap(letter: "ㅡ")
                } label: {
                    Text("ㅡ")
                }.buttonStyle(HangulButtonStyle())
                
                Button {
                    delegate?.ssangKeypadTap()
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
                        delegate?.numKeypadTap()
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
