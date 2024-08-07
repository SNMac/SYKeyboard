//
//  KeyboardView.swift
//  Naratgeul
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI
import Combine


protocol SYKeyboardDelegate: AnyObject {
    func getBufferSize() -> Int
    func hangulKeypadTap(letter: String)
    func hoegKeypadTap()
    func ssangKeypadTap()
    func removeKeypadTap()
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
    @State var timer: AnyCancellable?
    @State var lastLongPressKey: String = ""
    
    weak var delegate: SYKeyboardDelegate?
    
    let keyboardHeight: CGFloat
    
    var needsInputModeSwitchKey: Bool = false
    var nextKeyboardAction: Selector? = nil
    
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                SYKeyboardButton(
                    text: "ㄱ", primary: true,
                    action: {
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㄱ")
                    },
                    onLongPress: {
                        
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                    },
                    onLongPressFinished: {
                        
                    })
                
                SYKeyboardButton(
                    text: "ㄴ", primary: true,
                    action: {
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㄴ")
                    },
                    onLongPress: {
                        
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                    },
                    onLongPressFinished: {
                        
                    })
                
                SYKeyboardButton(
                    text: "ㅏㅓ", primary: true,
                    action: {
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㅏ")
                    },
                    onLongPress: {
                        
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                    },
                    onLongPressFinished: {
                        
                    })
                
                SYKeyboardButton(
                    systemName: "delete.left", primary: false,
                    action: {
                        Feedback.shared.playDeleteSound()
                        Feedback.shared.playHaptics()
                        delegate?.removeKeypadTap()
                    },
                    onLongPress: {
                        timer = Timer.publish(every: 0.1, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playDeleteSound()
                                Feedback.shared.playHaptics()
                                delegate?.removeKeypadTap()
                            }
                    },
                    onLongPressFinished: {
                        timer?.cancel()
                    })
            }.padding(.horizontal, 2)
            
            HStack(spacing: 5) {
                SYKeyboardButton(
                    text: "ㄹ", primary: true,
                    action: {
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㄹ")
                    },
                    onLongPress: {
                        
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                    },
                    onLongPressFinished: {
                        
                    })
                
                SYKeyboardButton(
                    text: "ㅁ", primary: true,
                    action: {
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㅁ")
                    },
                    onLongPress: {
                        
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                    },
                    onLongPressFinished: {
                        
                    })
                
                SYKeyboardButton(
                    text: "ㅗㅜ", primary: true,
                    action: {
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㅗ")
                    },
                    onLongPress: {
                        
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                    },
                    onLongPressFinished: {
                        
                    })
                
                SYKeyboardButton(
                    systemName: "space", primary: false,
                    action: {
                        Feedback.shared.playModifierSound()
                        Feedback.shared.playHaptics()
                        delegate?.spaceKeypadTap()
                    })
            }.padding(.horizontal, 2)
            
            HStack(spacing: 5) {
                SYKeyboardButton(
                    text: "ㅅ", primary: true,
                    action: {
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㅅ")
                    },
                    onLongPress: {
                        
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                    },
                    onLongPressFinished: {
                        
                    })
                
                SYKeyboardButton(
                    text: "ㅇ", primary: true,
                    action: {
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㅇ")
                    },
                    onLongPress: {
                        
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                    },
                    onLongPressFinished: {
                        
                    })
                
                SYKeyboardButton(
                    text: "ㅣ", primary: true,
                    action: {
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㅣ")
                    },
                    onLongPress: {
                        
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                    },
                    onLongPressFinished: {
                        
                    })
                
                SYKeyboardButton(
                    systemName: "return.left", primary: false,
                    action: {
                        Feedback.shared.playModifierSound()
                        Feedback.shared.playHaptics()
                        delegate?.enterKeypadTap()
                    })
            }.padding(.horizontal, 2)
            
            HStack(spacing: 5) {
                SYKeyboardButton(
                    text: "획", primary: true,
                    action: {
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                        delegate?.hoegKeypadTap()
                    },
                    onLongPress: {
                        
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                    },
                    onLongPressFinished: {
                        
                    })
                
                SYKeyboardButton(
                    text: "ㅡ", primary: true,
                    action: {
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㅡ")
                    },
                    onLongPress: {
                        
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                    },
                    onLongPressFinished: {
                        
                    })
                
                SYKeyboardButton(
                    text: "쌍", primary: true,
                    action: {
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                        delegate?.ssangKeypadTap()
                    },
                    onLongPress: {
                        
                        Feedback.shared.playTypeSound()
                        Feedback.shared.playHaptics()
                    },
                    onLongPressFinished: {
                        
                    })
                
                if needsInputModeSwitchKey && nextKeyboardAction != nil {
                    HStack(spacing: 5) {
                        SYKeyboardButton(
                            systemName: "textformat.123", primary: false,
                            action: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptics()
                                delegate?.numKeypadTap()
                            })
                        
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
                    SYKeyboardButton(
                        systemName: "textformat.123", primary: false,
                        action: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptics()
                            delegate?.numKeypadTap()
                        })
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
