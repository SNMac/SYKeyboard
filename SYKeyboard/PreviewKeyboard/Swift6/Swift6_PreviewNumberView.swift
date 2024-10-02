//
//  Swift6_PreviewNumberView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/23/24.
//

import SwiftUI
import Combine

struct Swift6_PreviewNumberView: View {
    @EnvironmentObject var state: PreviewNaratgeulState
    @AppStorage("repeatTimerSpeed", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var repeatTimerSpeed = 0.06
    @AppStorage("keyboardHeight", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var keyboardHeight = 240.0
    @AppStorage("needsInputModeSwitchKey", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var needsInputModeSwitchKey = false
    @Binding var tempKeyboardHeight: Double
    @State var timer: AnyCancellable?
    
    let vPadding: CGFloat = 4
    let interItemVPadding: CGFloat = 2
    let hPadding: CGFloat = 4
    let interItemHPadding: CGFloat = 2.5
    
    var body: some View {
        let repeatTimerCycle = 0.10 - repeatTimerSpeed
        
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // MARK: - 1, 2, 3, 􀆛
                HStack(spacing: 0) {
                    Swift6_PreviewNaratgeulButton(
                        text: "1", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: "2", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: "3", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        systemName: "delete.left", primary: false,
                        onPress: {
                            Feedback.shared.playDeleteSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onLongPress: {
                            timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playDeleteSound()
                                    Feedback.shared.playHaptic(style: .light)
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
                    Swift6_PreviewNaratgeulButton(
                        text: "4", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: "5", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: "6", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        systemName: "space", primary: true,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onLongPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                            timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playModifierSound()
                                    Feedback.shared.playHaptic(style: .light)
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
                    Swift6_PreviewNaratgeulButton(
                        text: "7", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: "8", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: "9", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        systemName: "return.left", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
                
                // MARK: - "-", ",", 0, ".", "/", (한글, 􀆪)
                HStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Swift6_PreviewNaratgeulButton(
                            text: "-", primary: true,
                            onPress: {
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onLongPress: {
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                    .autoconnect()
                                    .sink { _ in
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    }
                            },
                            onLongPressFinished: {
                                timer?.cancel()
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                        
                        Swift6_PreviewNaratgeulButton(
                            text: ",", primary: true,
                            onPress: {
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onLongPress: {
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                    .autoconnect()
                                    .sink { _ in
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    }
                            },
                            onLongPressFinished: {
                                timer?.cancel()
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                    }
                    
                    Swift6_PreviewNaratgeulButton(
                        text: "0", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    HStack(spacing: 0) {
                        Swift6_PreviewNaratgeulButton(
                            text: ".", primary: true,
                            onPress: {
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onLongPress: {
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                    .autoconnect()
                                    .sink { _ in
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    }
                            },
                            onLongPressFinished: {
                                timer?.cancel()
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                        
                        Swift6_PreviewNaratgeulButton(
                            text: "/", primary: true,
                            onPress: {
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onLongPress: {
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                                    .autoconnect()
                                    .sink { _ in
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    }
                            },
                            onLongPressFinished: {
                                timer?.cancel()
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                    }
                    
                    if needsInputModeSwitchKey {
                        HStack(spacing: 0) {
                            Swift6_PreviewNaratgeulButton(
                                text: "한글", primary: false,
                                onPress: {
                                    Feedback.shared.playModifierSound()
                                    Feedback.shared.playHaptic(style: .light)
                                },
                                onRelease: {
                                    state.current = .hangeul
                                },
                                onLongPressFinished: {
                                    state.current = .hangeul
                                })
                            .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                            .contentShape(Rectangle())
                            
                            Swift6_PreviewNaratgeulButton(
                                systemName: "globe", primary: false,
                                onPress: {
                                    Feedback.shared.playModifierSound()
                                    Feedback.shared.playHaptic(style: .light)
                                }
                            )
                            .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                            .contentShape(Rectangle())
                        }
                    } else {
                        Swift6_PreviewNaratgeulButton(
                            text: "한글", primary: false,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onRelease: {
                                state.current = .hangeul
                            },
                            onLongPressFinished: {
                                state.current = .hangeul
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                        .contentShape(Rectangle())
                    }
                }
            }
        }
        .frame(height: tempKeyboardHeight)
        .background(Color("KeyboardBackground"))
        .padding(EdgeInsets(top: 0, leading: 0, bottom: (needsInputModeSwitchKey ? 0 : 40), trailing: 0))
    }
}
