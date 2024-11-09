//
//  Swift6_HangeulView.swift
//  Naratgeul
//
//  Created by 서동환 on 9/23/24.
//

import SwiftUI
import Combine

struct Swift6_HangeulView: View {
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
                if isOneHandTypeEnabled && state.currentOneHandType == .right {
                    ChevronButton(isLeftHandMode: false, geometry: geometry)
                }
                GeometryReader { geometry in
                    ZStack(alignment: .trailing) {
                        VStack(spacing: 0) {
                            // MARK: - ㄱ, ㄴ, ㅏㅓ, 􀆛
                            HStack(spacing: 0) {
                                Swift6_NaratgeulButton(
                                    text: "ㄱ", primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.hangulKeypadTap(letter: "ㄱ")
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.hangulKeypadTap(letter: "ㄱ")
                                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                            .autoconnect()
                                            .sink { _ in
                                                Feedback.shared.playTypingSound()
                                                Feedback.shared.playHaptic(style: .light)
                                                state.delegate?.inputLastHangeul()
                                            }
                                    },
                                    onLongPressFinished: {
                                        timer?.cancel()
                                    })
                                .padding(EdgeInsets(top: vPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                                .contentShape(Rectangle())
                                
                                Swift6_NaratgeulButton(
                                    text: "ㄴ", primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.hangulKeypadTap(letter: "ㄴ")
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.hangulKeypadTap(letter: "ㄴ")
                                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                            .autoconnect()
                                            .sink { _ in
                                                Feedback.shared.playTypingSound()
                                                Feedback.shared.playHaptic(style: .light)
                                                state.delegate?.inputLastHangeul()
                                            }
                                    },
                                    onLongPressFinished: {
                                        timer?.cancel()
                                    })
                                .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                                .contentShape(Rectangle())
                                
                                Swift6_NaratgeulButton(
                                    text: "ㅏㅓ", primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.hangulKeypadTap(letter: "ㅏ")
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.hangulKeypadTap(letter: "ㅏ")
                                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                            .autoconnect()
                                            .sink { _ in
                                                Feedback.shared.playTypingSound()
                                                Feedback.shared.playHaptic(style: .light)
                                                state.delegate?.inputLastHangeul()
                                            }
                                    },
                                    onLongPressFinished: {
                                        timer?.cancel()
                                    })
                                .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                                .contentShape(Rectangle())
                                
                                Swift6_NaratgeulButton(
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
                                    onLongPressFinished: {
                                        timer?.cancel()
                                    })
                                .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                                .contentShape(Rectangle())
                            }
                            
                            // MARK: - ㄹ, ㅁ, ㅗㅜ, 􁁺
                            HStack(spacing: 0) {
                                Swift6_NaratgeulButton(
                                    text: "ㄹ", primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.hangulKeypadTap(letter: "ㄹ")
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.hangulKeypadTap(letter: "ㄹ")
                                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                            .autoconnect()
                                            .sink { _ in
                                                Feedback.shared.playTypingSound()
                                                Feedback.shared.playHaptic(style: .light)
                                                state.delegate?.inputLastHangeul()
                                            }
                                    },
                                    onLongPressFinished: {
                                        timer?.cancel()
                                    })
                                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                                .contentShape(Rectangle())
                                
                                Swift6_NaratgeulButton(
                                    text: "ㅁ", primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.hangulKeypadTap(letter: "ㅁ")
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.hangulKeypadTap(letter: "ㅁ")
                                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                            .autoconnect()
                                            .sink { _ in
                                                Feedback.shared.playTypingSound()
                                                Feedback.shared.playHaptic(style: .light)
                                                state.delegate?.inputLastHangeul()
                                            }
                                    },
                                    onLongPressFinished: {
                                        timer?.cancel()
                                    })
                                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                                .contentShape(Rectangle())
                                
                                Swift6_NaratgeulButton(
                                    text: "ㅗㅜ", primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.hangulKeypadTap(letter: "ㅗ")
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.hangulKeypadTap(letter: "ㅗ")
                                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                            .autoconnect()
                                            .sink { _ in
                                                Feedback.shared.playTypingSound()
                                                Feedback.shared.playHaptic(style: .light)
                                                state.delegate?.inputLastHangeul()
                                            }
                                    },
                                    onLongPressFinished: {
                                        timer?.cancel()
                                    })
                                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                                .contentShape(Rectangle())
                                
                                Swift6_NaratgeulButton(
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
                                    onLongPressFinished: {
                                        timer?.cancel()
                                    })
                                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                                .contentShape(Rectangle())
                            }
                            
                            // MARK: - ㅅ, ㅇ, ㅣ, 􁂆
                            HStack(spacing: 0) {
                                Swift6_NaratgeulButton(
                                    text: "ㅅ", primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.hangulKeypadTap(letter: "ㅅ")
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.hangulKeypadTap(letter: "ㅅ")
                                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                            .autoconnect()
                                            .sink { _ in
                                                Feedback.shared.playTypingSound()
                                                Feedback.shared.playHaptic(style: .light)
                                                state.delegate?.inputLastHangeul()
                                            }
                                    },
                                    onLongPressFinished: {
                                        timer?.cancel()
                                    })
                                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                                .contentShape(Rectangle())
                                
                                Swift6_NaratgeulButton(
                                    text: "ㅇ", primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.hangulKeypadTap(letter: "ㅇ")
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.hangulKeypadTap(letter: "ㅇ")
                                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                            .autoconnect()
                                            .sink { _ in
                                                Feedback.shared.playTypingSound()
                                                Feedback.shared.playHaptic(style: .light)
                                                state.delegate?.inputLastHangeul()
                                            }
                                    },
                                    onLongPressFinished: {
                                        timer?.cancel()
                                    })
                                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                                .contentShape(Rectangle())
                                
                                Swift6_NaratgeulButton(
                                    text: "ㅣ", primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.hangulKeypadTap(letter: "ㅣ")
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.hangulKeypadTap(letter: "ㅣ")
                                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                            .autoconnect()
                                            .sink { _ in
                                                Feedback.shared.playTypingSound()
                                                Feedback.shared.playHaptic(style: .light)
                                                state.delegate?.inputLastHangeul()
                                            }
                                    },
                                    onLongPressFinished: {
                                        timer?.cancel()
                                    })
                                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                                .contentShape(Rectangle())
                                
                                if state.currentKeyboardType == .twitter {
                                    HStack(spacing: 0) {
                                        Swift6_NaratgeulButton(
                                            text: "@_twitter", primary: false, geometry: geometry,
                                            onPress: {
                                                Feedback.shared.playModifierSound()
                                                Feedback.shared.playHaptic(style: .light)
                                            },
                                            onRelease: {
                                                state.delegate?.otherKeypadTap(letter: "@")
                                            },
                                            onLongPressFinished: {
                                                state.delegate?.otherKeypadTap(letter: "@")
                                            })
                                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                                        .contentShape(Rectangle())
                                        
                                        Swift6_NaratgeulButton(
                                            text: "#_twitter", primary: false, geometry: geometry,
                                            onPress: {
                                                Feedback.shared.playModifierSound()
                                                Feedback.shared.playHaptic(style: .light)
                                            },
                                            onRelease: {
                                                state.delegate?.otherKeypadTap(letter: "#")
                                            },
                                            onLongPressFinished: {
                                                state.delegate?.otherKeypadTap(letter: "#")
                                            })
                                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                                        .contentShape(Rectangle())
                                    }
                                } else {
                                    Swift6_NaratgeulButton(
                                        systemName: "return.left", primary: false, geometry: geometry,
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
                            }
                            
                            // MARK: - 획, ㅡ, 쌍, (!#1, 􀆪)
                            HStack(spacing: 0) {
                                Swift6_NaratgeulButton(
                                    text: "획", primary: true, geometry: geometry,
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
                                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                                .autoconnect()
                                                .sink { _ in
                                                    Feedback.shared.playTypingSound()
                                                    Feedback.shared.playHaptic(style: .light)
                                                    state.delegate?.inputLastHangeul()
                                                }
                                        }
                                    },
                                    onLongPressFinished: {
                                        timer?.cancel()
                                    })
                                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                                .contentShape(Rectangle())
                                
                                Swift6_NaratgeulButton(
                                    text: "ㅡ", primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.hangulKeypadTap(letter: "ㅡ")
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.hangulKeypadTap(letter: "ㅡ")
                                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                            .autoconnect()
                                            .sink { _ in
                                                Feedback.shared.playTypingSound()
                                                Feedback.shared.playHaptic(style: .light)
                                                state.delegate?.inputLastHangeul()
                                            }
                                    },
                                    onLongPressFinished: {
                                        timer?.cancel()
                                    })
                                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                                .contentShape(Rectangle())
                                
                                Swift6_NaratgeulButton(
                                    text: "쌍", primary: true, geometry: geometry,
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
                                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                                .autoconnect()
                                                .sink { _ in
                                                    Feedback.shared.playTypingSound()
                                                    Feedback.shared.playHaptic(style: .light)
                                                    state.delegate?.inputLastHangeul()
                                                }
                                        }
                                    },
                                    onLongPressFinished: {
                                        timer?.cancel()
                                    })
                                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                                .contentShape(Rectangle())
                                
                                if state.needsInputModeSwitchKey {
                                    HStack(spacing: 0) {
                                        Swift6_NaratgeulButton(
                                            text: "!#1", primary: false, geometry: geometry,
                                            onPress: {
                                                Feedback.shared.playModifierSound()
                                                Feedback.shared.playHaptic(style: .light)
                                            },
                                            onRelease: {
                                                state.currentInputType = .symbol
                                            },
                                            onLongPress: {
                                                if isOneHandTypeEnabled {
                                                    state.selectedOneHandType = state.currentOneHandType
                                                    state.isSelectingOneHandType = true
                                                }
                                            },
                                            onLongPressFinished: {
                                                if state.isSelectingOneHandType {
                                                    state.currentOneHandType = state.selectedOneHandType
                                                    currentOneHandType = state.selectedOneHandType.rawValue
                                                    state.isSelectingOneHandType = false
                                                } else {
                                                    state.currentInputType = .symbol
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
                                    Swift6_NaratgeulButton(
                                        text: "!#1", primary: false, geometry: geometry,
                                        onPress: {
                                            Feedback.shared.playModifierSound()
                                            Feedback.shared.playHaptic(style: .light)
                                        },
                                        onRelease: {
                                            state.currentInputType = .symbol
                                        },
                                        onLongPress: {
                                            if isOneHandTypeEnabled {
                                                state.selectedOneHandType = state.currentOneHandType
                                                state.isSelectingOneHandType = true
                                            }
                                        },
                                        onLongPressFinished: {
                                            if state.isSelectingOneHandType {
                                                state.currentOneHandType = state.selectedOneHandType
                                                currentOneHandType = state.selectedOneHandType.rawValue
                                                state.isSelectingOneHandType = false
                                            } else {
                                                state.currentInputType = .symbol
                                            }
                                        })
                                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                                    .contentShape(Rectangle())
                                }
                            }
                        }
                        
                        if state.isSelectingInputType {
                            InputTypeSelectOverlayView()
                                .offset(x: -geometry.size.width / 16, y: state.keyboardHeight / 8)
                        }
                        
                        if state.isSelectingOneHandType {
                            OneHandSelectOverlayView()
                                .offset(x: -geometry.size.width / 40, y: state.keyboardHeight / 8)
                        }
                    }
                }
                if isOneHandTypeEnabled && state.currentOneHandType == .left {
                    ChevronButton(isLeftHandMode: true, geometry: geometry)
                }
            }
            
        }
        .frame(height: state.keyboardHeight)
        .background(Color.white.opacity(0.001))
    }
}
