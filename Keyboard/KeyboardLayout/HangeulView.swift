//
//  HangeulView.swift
//  Keyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI
import Combine

struct HangeulView: View {
    @EnvironmentObject private var state: KeyboardState
    @State private var timer: AnyCancellable?
    
    private let vPadding: CGFloat = 4
    private let interItemVPadding: CGFloat = 2
    private let hPadding: CGFloat = 4
    private let interItemHPadding: CGFloat = 2.5
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - ㄱ, ㄴ, ㅏㅓ, 􀆛
            
            HStack(spacing: 0) {
                KeyboardButton(
                    text: "ㄱ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangeulKeypadTap(letter: "ㄱ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangeulKeypadTap(letter: "ㄱ")
                        timer = Timer.publish(every: state.repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: vPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    text: "ㄴ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangeulKeypadTap(letter: "ㄴ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangeulKeypadTap(letter: "ㄴ")
                        timer = Timer.publish(every: state.repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    text: "ㅏㅓ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangeulKeypadTap(letter: "ㅏ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangeulKeypadTap(letter: "ㅏ")
                        timer = Timer.publish(every: state.repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    systemName: "delete.left", primary: false,
                    onPress: {
                        Feedback.shared.playDeleteSound()
                        Feedback.shared.playHaptic(style: .light)
                        let _ = state.delegate?.removeKeypadTap(isLongPress: false)
                    },
                    onLongPress: {
                        timer = Timer.publish(every: state.repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                if let isDeleted = state.delegate?.removeKeypadTap(isLongPress: true) {
                                    if isDeleted {
                                        Feedback.shared.playDeleteSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    }
                                }
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                .contentShape(Rectangle())
            }
            
            // MARK: - ㄹ, ㅁ, ㅗㅜ, 􁁺
            
            HStack(spacing: 0) {
                KeyboardButton(
                    text: "ㄹ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangeulKeypadTap(letter: "ㄹ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangeulKeypadTap(letter: "ㄹ")
                        timer = Timer.publish(every: state.repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    text: "ㅁ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangeulKeypadTap(letter: "ㅁ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangeulKeypadTap(letter: "ㅁ")
                        timer = Timer.publish(every: state.repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    text: "ㅗㅜ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangeulKeypadTap(letter: "ㅗ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangeulKeypadTap(letter: "ㅗ")
                        timer = Timer.publish(every: state.repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    systemName: "space", primary: true,
                    onPress: {
                        Feedback.shared.playModifierSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.spaceKeypadTap()
                    },
                    onLongPress: {
                        Feedback.shared.playModifierSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.spaceKeypadTap()
                        timer = Timer.publish(every: state.repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.spaceKeypadTap()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                .contentShape(Rectangle())
            }
            
            // MARK: - ㅅ, ㅇ, ㅣ, 􁂆
            
            HStack(spacing: 0) {
                KeyboardButton(
                    text: "ㅅ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangeulKeypadTap(letter: "ㅅ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangeulKeypadTap(letter: "ㅅ")
                        timer = Timer.publish(every: state.repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    text: "ㅇ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangeulKeypadTap(letter: "ㅇ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangeulKeypadTap(letter: "ㅇ")
                        timer = Timer.publish(every: state.repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    text: "ㅣ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangeulKeypadTap(letter: "ㅣ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangeulKeypadTap(letter: "ㅣ")
                        timer = Timer.publish(every: state.repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                if state.currentUIKeyboardType == .twitter {
                    HStack(spacing: 0) {
                        KeyboardButton(
                            text: "@_twitter", primary: true,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onRelease: {
                                state.delegate?.otherKeypadTap(letter: "@")
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                        
                        KeyboardButton(
                            text: "#_twitter", primary: true,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onRelease: {
                                state.delegate?.otherKeypadTap(letter: "#")
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                        .contentShape(Rectangle())
                    }
                } else {
                    KeyboardButton(
                        systemName: "return.left", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.enterKeypadTap()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
            }
            
            // MARK: - 획, ㅡ, 쌍, (!#1, 􀆪)
            
            HStack(spacing: 0) {
                KeyboardButton(
                    text: "획", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hoegKeypadTap()
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hoegKeypadTap()
                        if state.isHoegSsangAvailable {
                            timer = Timer.publish(every: state.repeatTimerInterval, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastHangeul()
                                }
                        }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    text: "ㅡ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangeulKeypadTap(letter: "ㅡ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangeulKeypadTap(letter: "ㅡ")
                        timer = Timer.publish(every: state.repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    text: "쌍", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.ssangKeypadTap()
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.ssangKeypadTap()
                        if state.isHoegSsangAvailable {
                            timer = Timer.publish(every: state.repeatTimerInterval, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastHangeul()
                                }
                        }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                if state.needsInputModeSwitchKey {
                    HStack(spacing: 0) {
                        KeyboardButton(
                            text: "!#1", primary: false,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onRelease: {
                                state.currentKeyboard = .symbol
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                        
                        NextKeyboardButton(
                            systemName: "globe",
                            action: state.nextKeyboardAction
                        )
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                        .contentShape(Rectangle())
                    }
                } else {
                    KeyboardButton(
                        text: "!#1", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.currentKeyboard = .symbol
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(width: state.currentOneHandedKeyboard == .center ? nil : state.oneHandedKeyboardWidth, height: state.keyboardHeight)
        .background(Color.white.opacity(0.001))
    }
}
