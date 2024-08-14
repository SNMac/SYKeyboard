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
                        onClick: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㄱ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.hangulKeypadTap(letter: "ㄱ")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastLetter()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: "ㄴ", primary: true,
                        onClick: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㄴ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.hangulKeypadTap(letter: "ㄴ")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastLetter()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: "ㅏㅓ", primary: true,
                        onClick: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㅏ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.hangulKeypadTap(letter: "ㅏ")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastLetter()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        systemName: "delete.left", primary: false,
                        onClick: {
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
                        onClick: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㄹ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.hangulKeypadTap(letter: "ㄹ")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastLetter()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: "ㅁ", primary: true,
                        onClick: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㅁ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.hangulKeypadTap(letter: "ㅁ")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastLetter()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: "ㅗㅜ", primary: true,
                        onClick: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㅗ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.hangulKeypadTap(letter: "ㅗ")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastLetter()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        systemName: "space", primary: false,
                        onClick: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.spaceKeypadTap()
                        },
                        onLongPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.spaceKeypadTap()
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playModifierSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastLetter()
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
                        onClick: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㅅ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.hangulKeypadTap(letter: "ㅅ")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastLetter()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: "ㅇ", primary: true,
                        onClick: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㅇ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.hangulKeypadTap(letter: "ㅇ")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastLetter()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: "ㅣ", primary: true,
                        onClick: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㅣ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.hangulKeypadTap(letter: "ㅣ")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastLetter()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        systemName: "return.left", primary: false,
                        onClick: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.enterKeypadTap()
                        },
                        onLongPressFinished: {
                            options.delegate?.enterKeypadTap()
                        })
                }.padding(.horizontal, 4)
                
                // MARK: - 획, ㅡ, 쌍, (123, 􀆪)
                HStack(spacing: 6) {
                    SYKeyboardButton(
                        text: "획", primary: true,
                        onClick: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.hoegKeypadTap()
                        },
                        onLongPress: {
                            // TODO: 쉼표(,) 입력
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.hoegKeypadTap()
                            if options.isHoegSsangAvailable {
                                timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                    .autoconnect()
                                    .sink { _ in
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptics()
                                        options.delegate?.inputLastLetter()
                                    }
                            } else {
                                options.delegate?.hoegKeypadLongPress()
                            }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: "ㅡ", primary: true,
                        onClick: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㅡ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.hangulKeypadTap(letter: "ㅡ")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastLetter()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: "쌍", primary: true,
                        onClick: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.ssangKeypadTap()
                        },
                        onLongPress: {
                            // TODO: 온점(.) 입력
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.ssangKeypadTap()
                            if options.isHoegSsangAvailable {
                                timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                    .autoconnect()
                                    .sink { _ in
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptics()
                                        options.delegate?.inputLastLetter()
                                    }
                            } else {
                                options.delegate?.ssangKeypadLongPress()
                            }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    if options.needsInputModeSwitchKey {
                        HStack(spacing: 6) {
                            SYKeyboardButton(
                                text: "123", primary: false,
                                onClick: {
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
                            onClick: {
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
