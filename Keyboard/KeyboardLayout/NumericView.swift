//
//  NumericView.swift
//  Keyboard
//
//  Created by 서동환 on 9/17/24.
//

import SwiftUI
import Combine

struct NumericView: View {
    @EnvironmentObject private var state: KeyboardState
    @State private var timer: AnyCancellable?
    
    private let vPadding: CGFloat = 4
    private let interItemVPadding: CGFloat = 2
    private let hPadding: CGFloat = 4
    private let interItemHPadding: CGFloat = 2.5
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 1, 2, 3, 􀆛
            HStack(spacing: 0) {
                KeyboardButton(
                    text: "1", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.otherKeypadTap(letter: "1")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.otherKeypadTap(letter: "1")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastSymbol()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: vPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    text: "2", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.otherKeypadTap(letter: "2")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.otherKeypadTap(letter: "2")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastSymbol()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    text: "3", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.otherKeypadTap(letter: "3")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.otherKeypadTap(letter: "3")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastSymbol()
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
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
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
            
            
            // MARK: - 4, 5, 6, 􁁺
            HStack(spacing: 0) {
                KeyboardButton(
                    text: "4", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.otherKeypadTap(letter: "4")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.otherKeypadTap(letter: "4")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastSymbol()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    text: "5", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.otherKeypadTap(letter: "5")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.otherKeypadTap(letter: "5")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastSymbol()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    text: "6", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.otherKeypadTap(letter: "6")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.otherKeypadTap(letter: "6")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastSymbol()
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
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
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
            
            // MARK: - 7, 8, 9, 􁂆
            HStack(spacing: 0) {
                KeyboardButton(
                    text: "7", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.otherKeypadTap(letter: "7")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.otherKeypadTap(letter: "7")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastSymbol()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    text: "8", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.otherKeypadTap(letter: "8")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.otherKeypadTap(letter: "8")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastSymbol()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                KeyboardButton(
                    text: "9", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.otherKeypadTap(letter: "9")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.otherKeypadTap(letter: "9")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastSymbol()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
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
            
            // MARK: - "-", ",", 0, ".", "/", (한글, 􀆪)
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    KeyboardButton(
                        text: "-", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: "-")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: "-")
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    KeyboardButton(
                        text: ",", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: ",")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: ",")
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                }
                
                KeyboardButton(
                    text: "0", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.otherKeypadTap(letter: "0")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.otherKeypadTap(letter: "0")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastSymbol()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                HStack(spacing: 0) {
                    KeyboardButton(
                        text: ".", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: ".")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: ".")
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    KeyboardButton(
                        text: "/", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: "/")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: "/")
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                }
                
                if state.needsInputModeSwitchKey {
                    HStack(spacing: 0) {
                        KeyboardButton(
                            text: "한글", primary: false,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onRelease: {
                                state.currentInputType = .hangeul
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
                        text: "한글", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.currentInputType = .hangeul
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(width: state.currentOneHandMode == .center ? nil : state.oneHandWidth, height: state.keyboardHeight)
        .background(Color.white.opacity(0.001))
    }
}
