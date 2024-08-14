//
//  SYKeyboardSymbolView.swift
//  Naratgeul
//
//  Created by 서동환 on 8/14/24.
//

import SwiftUI
import Combine

struct SYKeyboardSymbolView: View {
    @EnvironmentObject var options: SYKeyboardOptions
    @State var timer: AnyCancellable?
    @State var isShiftTapped: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // MARK: - 1, 2, 3, 4, 5, 6, 7, 8, 9, 0 / [, ], {, }, #, %, ^, *, +, =
                HStack(spacing: 6) {
                    SYKeyboardButton(
                        text: isShiftTapped ? "[" : "1", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "1")
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
                        text: isShiftTapped ? "]" : "2", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "2")
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
                        text: isShiftTapped ? "{" : "3", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "3")
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
                        text: isShiftTapped ? "}" : "4", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "4")
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
                        text: isShiftTapped ? "#" : "5", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "5")
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
                        text: isShiftTapped ? "%" : "6", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "6")
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
                        text: isShiftTapped ? "^" : "7", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "7")
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
                        text: isShiftTapped ? "*" : "8", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "8")
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
                        text: isShiftTapped ? "+" : "9", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "9")
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
                        text: isShiftTapped ? "=" : "0", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "0")
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
                }.padding(.horizontal, 4)
                
                // MARK: - -, /, :, ;, (, ), ₩, &, @, " / _, \, |, ~, <, >, $, £, ¥, •
                HStack(spacing: 6) {
                    SYKeyboardButton(
                        text: isShiftTapped ? "_" : "-", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "-")
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
                        text: isShiftTapped ? "\\" : "/", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "/")
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
                        text: isShiftTapped ? "|" : ":", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: ":")
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
                        text: isShiftTapped ? "~" : ";", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: ";")
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
                        text: isShiftTapped ? "<" : "(", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "(")
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
                        text: isShiftTapped ? ">" : ")", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: ")")
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
                        text: isShiftTapped ? "$" : "₩", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "₩")
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
                        text: isShiftTapped ? "£" : "&", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "&")
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
                        text: isShiftTapped ? "¥" : "@", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "@")
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
                        text: isShiftTapped ? "•" : "\"", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "\"")
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
                }.padding(.horizontal, 4)
                
                // MARK: - ., ,, ?, !, `
                HStack(spacing: 6) {
                    SYKeyboardButton(
                        text: isShiftTapped ? "123" : "#+=", primary: false,
                        action: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptics()
                            isShiftTapped.toggle()
                        })
                    
                    SYKeyboardButton(
                        text: ".", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: ".")
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
                        text: ",", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: ",")
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
                        text: "?", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "?")
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
                        text: "!", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "!")
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
                        text: "`", primary: true,
                        action: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "`")
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
                
                // MARK: - 한글, 􁁺, 􁂆
                HStack(spacing: 6) {
                    SYKeyboardButton(
                        text: "한글", primary: false,
                        action: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptics()
                            options.current = .hangul
                        })
                    
                    SYKeyboardButton(
                        systemName: "space", primary: true,
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
                        }).frame(width: geometry.size.width / 2)
                    
                    SYKeyboardButton(
                        systemName: "return.left", primary: false,
                        action: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.enterKeypadTap()
                        })
                }.padding(.horizontal, 4)
            }.padding(.vertical, 4)
        }
        .frame(height: options.keyboardHeight)
        .background(Color("KeyboardBackground"))
    }
}

#Preview {
    SYKeyboardSymbolView()
}
