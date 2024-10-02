//
//  NumberView.swift
//  Naratgeul
//
//  Created by 서동환 on 9/17/24.
//

import SwiftUI
import Combine

struct NumberView: View {
    @EnvironmentObject var state: NaratgeulState
    @State var timer: AnyCancellable?
    
    let vPadding: CGFloat = 4
    let interItemVPadding: CGFloat = 2
    let hPadding: CGFloat = 4
    let interItemHPadding: CGFloat = 2.5
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // MARK: - 1, 2, 3, 􀆛
                HStack(spacing: 0) {
                    SYKeyboardButton(
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    SYKeyboardButton(
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    SYKeyboardButton(
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    SYKeyboardButton(
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
                
                
                // MARK: - 4, 5, 6, 􁁺
                HStack(spacing: 0) {
                    SYKeyboardButton(
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    SYKeyboardButton(
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    SYKeyboardButton(
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    SYKeyboardButton(
                        systemName: "space", primary: false,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
                
                // MARK: - 7, 8, 9, 􁂆
                HStack(spacing: 0) {
                    SYKeyboardButton(
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    SYKeyboardButton(
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    SYKeyboardButton(
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    SYKeyboardButton(
                        systemName: "return.left", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.enterKeypadTap()
                        },
                        onLongPressFinished: {
                            state.delegate?.enterKeypadTap()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
                
                // MARK: - "-", ",", 0, ".", "/", (한글, 􀆪)
                HStack(spacing: 0) {
                    HStack(spacing: 0) {
                        SYKeyboardButton(
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
                            onLongPressFinished: {
                                timer?.cancel()
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                        
                        SYKeyboardButton(
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
                            onLongPressFinished: {
                                timer?.cancel()
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                    }
                    
                    SYKeyboardButton(
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    HStack(spacing: 0) {
                        SYKeyboardButton(
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
                            onLongPressFinished: {
                                timer?.cancel()
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                        
                        SYKeyboardButton(
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
                            onLongPressFinished: {
                                timer?.cancel()
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                    }
                    
                    if state.needsInputModeSwitchKey {
                        HStack(spacing: 0) {
                            SYKeyboardButton(
                                text: "한글", primary: false,
                                onPress: {
                                    Feedback.shared.playModifierSound()
                                    Feedback.shared.playHaptic(style: .light)
                                },
                                onRelease: {
                                    state.currentInputType = .hangeul
                                },
                                onLongPressFinished: {
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
                        SYKeyboardButton(
                            text: "한글", primary: false,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onRelease: {
                                state.currentInputType = .hangeul
                            },
                            onLongPressFinished: {
                                state.currentInputType = .hangeul
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                        .contentShape(Rectangle())
                    }
                }
            }
        }
        .frame(height: state.keyboardHeight)
        .background(Color.white.opacity(0.001))
    }
}
