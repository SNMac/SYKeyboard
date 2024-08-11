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
    func flushBuffer()
    func inputlastLetter()
    func hangulKeypadTap(letter: String)
    func hoegKeypadTap()
    func ssangKeypadTap()
    func removeKeypadTap()
    func enterKeypadTap()
    func spaceKeypadTap()
    func otherKeypadTap(letter: String)
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
    
    weak var delegate: SYKeyboardDelegate?
    
    let keyboardHeight: CGFloat
    
    var needsInputModeSwitchKey: Bool = false
    var nextKeyboardAction: Selector? = nil
    
    var body: some View {
        VStack(spacing: 5) {
            // MARK: - ㄱ, ㄴ, ㅏㅓ, 􀆛
            HStack(spacing: 5) {
                SYKeyboardButton(
                    text: "ㄱ", primary: true,
                    action: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptics()
//                        delegate?.hangulKeypadTap(letter: "ㄱ")
                        delegate?.otherKeypadTap(letter: ",")
                    },
                    onLongPress: {
                        timer = Timer.publish(every: 0.05, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptics()
                                delegate?.inputlastLetter()
                            }
                    },
                    onLongPressFinished: {
                        timer?.cancel()
                    })
                
                SYKeyboardButton(
                    text: "ㄴ", primary: true,
                    action: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㄴ")
                    },
                    onLongPress: {
                        timer = Timer.publish(every: 0.05, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptics()
                                delegate?.inputlastLetter()
                            }
                    },
                    onLongPressFinished: {
                        timer?.cancel()
                    })
                
                SYKeyboardButton(
                    text: "ㅏㅓ", primary: true,
                    action: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㅏ")
                    },
                    onLongPress: {
                        timer = Timer.publish(every: 0.05, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptics()
                                delegate?.inputlastLetter()
                            }
                    },
                    onLongPressFinished: {
                        timer?.cancel()
                    })
                
                SYKeyboardButton(
                    systemName: "delete.left", primary: false,
                    action: {
                        Feedback.shared.playDeleteSound()
                        Feedback.shared.playHaptics()
                        delegate?.removeKeypadTap()
                    },
                    onLongPress: {
                        timer = Timer.publish(every: 0.05, on: .main, in: .common)
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
            
            // MARK: - ㄹ, ㅁ, ㅗㅜ, 􁁺
            HStack(spacing: 5) {
                SYKeyboardButton(
                    text: "ㄹ", primary: true,
                    action: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㄹ")
                    },
                    onLongPress: {
                        timer = Timer.publish(every: 0.05, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptics()
                                delegate?.inputlastLetter()
                            }
                    },
                    onLongPressFinished: {
                        timer?.cancel()
                    })
                
                SYKeyboardButton(
                    text: "ㅁ", primary: true,
                    action: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㅁ")
                    },
                    onLongPress: {
                        timer = Timer.publish(every: 0.05, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptics()
                                delegate?.inputlastLetter()
                            }
                    },
                    onLongPressFinished: {
                        timer?.cancel()
                    })
                
                SYKeyboardButton(
                    text: "ㅗㅜ", primary: true,
                    action: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㅗ")
                    },
                    onLongPress: {
                        timer = Timer.publish(every: 0.05, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptics()
                                delegate?.inputlastLetter()
                            }
                    },
                    onLongPressFinished: {
                        timer?.cancel()
                    })
                
                SYKeyboardButton(
                    systemName: "space", primary: false,
                    action: {
                        Feedback.shared.playModifierSound()
                        Feedback.shared.playHaptics()
                        delegate?.spaceKeypadTap()
                    },
                    onLongPress: {
                        timer = Timer.publish(every: 0.05, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptics()
                                delegate?.spaceKeypadTap()
                            }
                    },
                    onLongPressFinished: {
                        timer?.cancel()
                    })
            }.padding(.horizontal, 2)
            
            // MARK: - ㅅ, ㅇ, ㅣ, 􁂆
            HStack(spacing: 5) {
                SYKeyboardButton(
                    text: "ㅅ", primary: true,
                    action: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㅅ")
                    },
                    onLongPress: {
                        timer = Timer.publish(every: 0.05, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptics()
                                delegate?.inputlastLetter()
                            }
                    },
                    onLongPressFinished: {
                        timer?.cancel()
                    })
                
                SYKeyboardButton(
                    text: "ㅇ", primary: true,
                    action: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㅇ")
                    },
                    onLongPress: {
                        timer = Timer.publish(every: 0.05, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptics()
                                delegate?.inputlastLetter()
                            }
                    },
                    onLongPressFinished: {
                        timer?.cancel()
                    })
                
                SYKeyboardButton(
                    text: "ㅣ", primary: true,
                    action: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㅣ")
                    },
                    onLongPress: {
                        timer = Timer.publish(every: 0.05, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptics()
                                delegate?.inputlastLetter()
                            }
                    },
                    onLongPressFinished: {
                        timer?.cancel()
                    })
                
                SYKeyboardButton(
                    systemName: "return.left", primary: false,
                    action: {
                        Feedback.shared.playModifierSound()
                        Feedback.shared.playHaptics()
                        delegate?.enterKeypadTap()
                    })
            }.padding(.horizontal, 2)
            
            // MARK: - 획, ㅡ, 쌍, 􀅱
            HStack(spacing: 5) {
                SYKeyboardButton(
                    text: "획", primary: true,
                    action: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptics()
                        delegate?.hoegKeypadTap()
                    },
                    onLongPress: {
                        // TODO: 쉼표(,) 입력
                        timer = Timer.publish(every: 0.05, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptics()
                                delegate?.inputlastLetter()
                            }
                    },
                    onLongPressFinished: {
                        timer?.cancel()
                    })
                
                SYKeyboardButton(
                    text: "ㅡ", primary: true,
                    action: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptics()
                        delegate?.hangulKeypadTap(letter: "ㅡ")
                    },
                    onLongPress: {
                        timer = Timer.publish(every: 0.05, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptics()
                                delegate?.inputlastLetter()
                            }
                    },
                    onLongPressFinished: {
                        timer?.cancel()
                    })
                
                SYKeyboardButton(
                    text: "쌍", primary: true,
                    action: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptics()
                        delegate?.ssangKeypadTap()
                    },
                    onLongPress: {
                        // TODO: 온점(.) 입력
                        timer = Timer.publish(every: 0.05, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptics()
                                delegate?.inputlastLetter()
                            }
                    },
                    onLongPressFinished: {
                        timer?.cancel()
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
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptics()
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
