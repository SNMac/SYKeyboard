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
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "[" : "1")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "[" : "1")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "]" : "2", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "]" : "2")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "]" : "2")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "{" : "3", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "{" : "3")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "{" : "3")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "}" : "4", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "}" : "4")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "}" : "4")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "#" : "5", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "#" : "5")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "#" : "5")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "%" : "6", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "%" : "6")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "%" : "6")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "^" : "7", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "^" : "7")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "^" : "7")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "*" : "8", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "*" : "8")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "*" : "8")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "+" : "9", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "+" : "9")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "+" : "9")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "=" : "0", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "=" : "0")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "=" : "0")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
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
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "_" : "-")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "_" : "-")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "\\" : "/", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "\\" : "/")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "\\" : "/")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "|" : ":", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "|" : ":")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "|" : ":")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "~" : ";", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "~" : ";")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "~" : ";")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "<" : "(", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "<" : "(")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "<" : "(")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? ">" : ")", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? ">" : ")")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? ">" : ")")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "$" : "₩", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "$" : "₩")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "$" : "₩")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "£" : "&", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "£" : "&")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "£" : "&")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "¥" : "@", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "¥" : "@")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "¥" : "@")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: isShiftTapped ? "•" : "\"", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "•" : "\"")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: isShiftTapped ? "•" : "\"")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                }.padding(.horizontal, 4)
                
                // MARK: - #+=/123, ., ,, ?, !, `
                HStack(spacing: 6) {
                    SYKeyboardButton(
                        text: isShiftTapped ? "123" : "#+=", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptics()
                            isShiftTapped.toggle()
                        })
                    
                    SYKeyboardButton(
                        text: ".", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: ".")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: ".")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: ",", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: ",")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: ",")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: "?", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: "?")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "?")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: "!", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: "!")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "!")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        text: "`", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.otherKeypadTap(letter: "`")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptics()
                            options.delegate?.otherKeypadTap(letter: "`")
                            timer = Timer.publish(every: 0.05, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptics()
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    
                    SYKeyboardButton(
                        systemName: "delete.left", primary: false,
                        onPress: {
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
                
                // MARK: - (한글, 􀆪), 􁁺, 􁂆
                HStack(spacing: 6) {
                    if options.needsInputModeSwitchKey {
                        HStack(spacing: 6) {
                            SYKeyboardButton(
                                text: "한글", primary: false,
                                onPress: {
                                    Feedback.shared.playModifierSound()
                                    Feedback.shared.playHaptics()
                                    options.current = .hangul
                                })
                            
                            NextKeyboardButton(
                                systemName: "globe",
                                action: options.nextKeyboardAction,
                                primary: false)
                        }
                    } else {
                        SYKeyboardButton(
                            text: "한글", primary: false,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptics()
                                options.current = .hangul
                            })
                    }
                    
                    SYKeyboardButton(
                        systemName: "space", primary: true,
                        onPress: {
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
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        }).frame(width: geometry.size.width / 2)
                    
                    SYKeyboardButton(
                        systemName: "return.left", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptics()
                        },
                        onRelease: {
                            options.delegate?.enterKeypadTap()
                        },
                        onLongPressFinished: {
                            options.delegate?.enterKeypadTap()
                        }
                    )
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
