//
//  SYKeyboardHangulView.swift
//  Naratgeul
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI
import Combine

struct SYKeyboardHangulView: View {
    @EnvironmentObject var options: SYKeyboardOptions
    @State var timer: AnyCancellable?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 5) {
                // MARK: - ㄱ, ㄴ, ㅏㅓ, 􀆛
                HStack(spacing: 6) {
                    SYKeyboardButton(
                        text: "ㄱ", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.hangulKeypadTap(letter: "ㄱ")
                        },
                        onLongPress: {
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputlastLetter()
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
                            options.delegate?.hangulKeypadTap(letter: "ㄴ")
                        },
                        onLongPress: {
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputlastLetter()
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
                            options.delegate?.hangulKeypadTap(letter: "ㅏ")
                        },
                        onLongPress: {
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputlastLetter()
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
                            options.delegate?.removeKeypadTap()
                        },
                        onLongPress: {
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playDeleteSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.removeKeypadTap()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                }.padding(.horizontal, 4)
                
                // MARK: - ㄹ, ㅁ, ㅗㅜ, 􁁺
                HStack(spacing: 6) {
                    SYKeyboardButton(
                        text: "ㄹ", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.hangulKeypadTap(letter: "ㄹ")
                        },
                        onLongPress: {
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputlastLetter()
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
                            options.delegate?.hangulKeypadTap(letter: "ㅁ")
                        },
                        onLongPress: {
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputlastLetter()
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
                            options.delegate?.hangulKeypadTap(letter: "ㅗ")
                        },
                        onLongPress: {
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputlastLetter()
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
                            options.delegate?.spaceKeypadTap()
                        },
                        onLongPress: {
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playModifierSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.spaceKeypadTap()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                }.padding(.horizontal, 4)
                
                // MARK: - ㅅ, ㅇ, ㅣ, 􁂆
                HStack(spacing: 6) {
                    SYKeyboardButton(
                        text: "ㅅ", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.hangulKeypadTap(letter: "ㅅ")
                        },
                        onLongPress: {
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputlastLetter()
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
                            options.delegate?.hangulKeypadTap(letter: "ㅇ")
                        },
                        onLongPress: {
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputlastLetter()
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
                            options.delegate?.hangulKeypadTap(letter: "ㅣ")
                        },
                        onLongPress: {
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputlastLetter()
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
                            options.delegate?.enterKeypadTap()
                        })
                }.padding(.horizontal, 4)
                
                // MARK: - 획, ㅡ, 쌍, 􀅱
                HStack(spacing: 6) {
                    SYKeyboardButton(
                        text: "획", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.hoegKeypadTap()
                        },
                        onLongPress: {
                            // TODO: 쉼표(,) 입력
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputlastLetter()
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
                            options.delegate?.hangulKeypadTap(letter: "ㅡ")
                        },
                        onLongPress: {
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputlastLetter()
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
                            options.delegate?.ssangKeypadTap()
                        },
                        onLongPress: {
                            // TODO: 온점(.) 입력
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputlastLetter()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    if options.needsInputModeSwitchKey {
                        HStack(spacing: 5) {
                            SYKeyboardButton(
                                text: "123", primary: false,
                                action: {
                                    Feedback.shared.playModifierSound()
                                    Feedback.shared.playHaptics()
                                    options.current = .symbol
                                })
                            
                            NextKeyboardButton(
                                systemName: "globe",
                                action: options.nextKeyboardAction,
                                primary: false)
                        }
                    } else {
                        SYKeyboardButton(
                            text: "123", primary: false,
                            action: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptics()
                                options.current = .symbol
                            })
                    }
                }.padding(.horizontal, 4)
            }.padding(.vertical, 4)
        }
        .frame(height: options.keyboardHeight)
        .background(Color("KeyboardBackground"))
    }
}


#Preview {
    SYKeyboardHangulView()
}
