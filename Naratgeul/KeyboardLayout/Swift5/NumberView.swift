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
    @AppStorage("isOneHandTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isOneHandTypeEnabled = true
    @AppStorage("currentOneHandType", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var currentOneHandType = 1
    @State var timer: AnyCancellable?
    
    let vPadding: CGFloat = 4
    let interItemVPadding: CGFloat = 2
    let hPadding: CGFloat = 4
    let interItemHPadding: CGFloat = 2.5
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                GeometryReader { geometry in
                    ZStack(alignment: .trailing) {
                        VStack(spacing: 0) {
                            // MARK: - 1, 2, 3, 􀆛
                            HStack(spacing: 0) {
                                NaratgeulButton(
                                    text: "1", primary: true, geometry: geometry,
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
                                
                                NaratgeulButton(
                                    text: "2", primary: true, geometry: geometry,
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
                                
                                NaratgeulButton(
                                    text: "3", primary: true, geometry: geometry,
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
                                
                                NaratgeulButton(
                                    systemName: "delete.left", primary: false, geometry: geometry,
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
                                NaratgeulButton(
                                    text: "4", primary: true, geometry: geometry,
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
                                
                                NaratgeulButton(
                                    text: "5", primary: true, geometry: geometry,
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
                                
                                NaratgeulButton(
                                    text: "6", primary: true, geometry: geometry,
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
                                
                                NaratgeulButton(
                                    systemName: "space", primary: true, geometry: geometry,
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
                                NaratgeulButton(
                                    text: "7", primary: true, geometry: geometry,
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
                                
                                NaratgeulButton(
                                    text: "8", primary: true, geometry: geometry,
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
                                
                                NaratgeulButton(
                                    text: "9", primary: true, geometry: geometry,
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
                                
                                NaratgeulButton(
                                    systemName: "return.left", primary: false, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playModifierSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.enterKeypadTap()
                                    },
                                    onLongPressRelease: {
                                        state.delegate?.enterKeypadTap()
                                    })
                                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                                .contentShape(Rectangle())
                            }
                            
                            // MARK: - "-", ",", 0, ".", "/", (한글, 􀆪)
                            HStack(spacing: 0) {
                                HStack(spacing: 0) {
                                    NaratgeulButton(
                                        text: "-", primary: true, geometry: geometry,
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
                                    
                                    NaratgeulButton(
                                        text: ",", primary: true, geometry: geometry,
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
                                
                                NaratgeulButton(
                                    text: "0", primary: true, geometry: geometry,
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
                                    NaratgeulButton(
                                        text: ".", primary: true, geometry: geometry,
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
                                    
                                    NaratgeulButton(
                                        text: "/", primary: true, geometry: geometry,
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
                                        NaratgeulButton(
                                            text: "한글", primary: false, geometry: geometry,
                                            onPress: {
                                                Feedback.shared.playModifierSound()
                                                Feedback.shared.playHaptic(style: .light)
                                            },
                                            onRelease: {
                                                state.currentInputType = .hangeul
                                            },
                                            onLongPress: {
                                                if isOneHandTypeEnabled {
                                                    state.selectedOneHandType = state.currentOneHandType
                                                    state.isSelectingOneHandType = true
                                                    Feedback.shared.playHaptic(style: .light)
                                                }
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
                                    NaratgeulButton(
                                        text: "한글", primary: false, geometry: geometry,
                                        onPress: {
                                            Feedback.shared.playModifierSound()
                                            Feedback.shared.playHaptic(style: .light)
                                        },
                                        onRelease: {
                                            state.currentInputType = .hangeul
                                        },
                                        onLongPress: {
                                            if isOneHandTypeEnabled {
                                                state.selectedOneHandType = state.currentOneHandType
                                                state.isSelectingOneHandType = true
                                                Feedback.shared.playHaptic(style: .light)
                                            }
                                        })
                                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                                    .contentShape(Rectangle())
                                }
                            }
                        }
                        
                        if state.isSelectingInputType {
                            InputTypeSelectOverlayView()
                                .offset(x: -interItemHPadding, y: state.keyboardHeight / 8)
                        }
                    }
                }
            }
        }
        .frame(height: state.keyboardHeight)
        .background(Color.white.opacity(0.001))
    }
}
