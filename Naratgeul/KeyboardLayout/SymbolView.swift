//
//  SymbolView.swift
//  Naratgeul
//
//  Created by 서동환 on 8/14/24.
//

import SwiftUI
import Combine

struct SymbolView: View {
    @EnvironmentObject var state: NaratgeulState
    @AppStorage("isAutoChangeToHangeulEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isAutoChangeToHangeulEnabled = true
    @AppStorage("isOneHandTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isOneHandTypeEnabled = true
    @AppStorage("currentOneHandType", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var currentOneHandType = 1
    @State var timer: AnyCancellable?
    @State var isSymbolInput: Bool = false
    
    let vPadding: CGFloat = 4
    let interItemVPadding: CGFloat = 4.5
    let hPadding: CGFloat = 4
    let interItemHPadding: CGFloat = 2.5
    
    let symbols = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "/", ":", ";", "(", ")", "₩", "&", "@", "“", ".", ",", "?", "!", "’"],
        ["[", "]", "{", "}", "#", "%", "^", "*", "+", "=", "_", "\\", "|", "~", "<", ">", "$", "£", "¥", "•", ".", ",", "?", "!", "’"]
    ]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                if isOneHandTypeEnabled && state.currentOneHandType == .right {
                    ChevronButton(isLeftHandMode: false, geometry: geometry)
                }
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        VStack(spacing: 0) {
                            // MARK: - 1st row of Symbol Keyboard
                            HStack(spacing: 0) {
                                SYKeyboardButton(
                                    text: symbols[state.nowSymbolPage][0], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][0])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][0])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][1], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][1])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][1])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][2], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][2])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][2])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][3], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][3])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][3])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][4], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][4])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][4])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][5], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][5])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][5])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][6], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][6])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][6])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][7], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][7])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][7])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][8], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][8])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][8])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][9], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][9])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][9])
                                        isSymbolInput = true
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
                                .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                                .contentShape(Rectangle())
                            }
                            
                            // MARK: - 2nd row of Symbol Keyboard
                            HStack(spacing: 0) {
                                SYKeyboardButton(
                                    text: symbols[state.nowSymbolPage][10], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][10])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][10])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][11], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][11])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][11])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][12], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][12])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][12])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][13], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][13])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][13])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][14], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][14])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][14])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][15], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][15])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][15])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][16], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][16])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][16])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][17], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][17])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][17])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][18], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][18])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][18])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][19], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][19])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][19])
                                        isSymbolInput = true
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
                                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                                .contentShape(Rectangle())
                            }
                            
                            // MARK: - 3rd row of Symbol Keyboard
                            HStack(spacing: 0) {
                                SYKeyboardButton(
                                    text: "\(state.nowSymbolPage + 1)/\(state.totalSymbolPage)", primary: false, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playModifierSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.nowSymbolPage = (state.nowSymbolPage + 1) % state.totalSymbolPage
                                    })
                                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                                .contentShape(Rectangle())
                                
                                SYKeyboardButton(
                                    text: symbols[state.nowSymbolPage][20], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][20])
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][20])
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
                                    text: symbols[state.nowSymbolPage][21], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][21])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][21])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][22], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][22])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][22])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][23], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][23])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][23])
                                        isSymbolInput = true
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
                                    text: symbols[state.nowSymbolPage][24], primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][24])
                                        isSymbolInput = true
                                    },
                                    onLongPress: {
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][24])
                                        isSymbolInput = true
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
                                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                                .contentShape(Rectangle())
                            }
                            
                            // MARK: - (한글, 􀆪), 􁁺, 􁂆
                            HStack(spacing: 0) {
                                if state.needsInputModeSwitchKey {
                                    HStack(spacing: 0) {
                                        SYKeyboardButton(
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
                                                }
                                            },
                                            onLongPressFinished: {
                                                if state.isSelectingOneHandType {
                                                    state.currentOneHandType = state.selectedOneHandType
                                                    currentOneHandType = state.selectedOneHandType.rawValue
                                                    state.isSelectingOneHandType = false
                                                } else {
                                                    state.currentInputType = .hangeul
                                                }
                                            })
                                        .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                                        .contentShape(Rectangle())
                                        
                                        NextKeyboardButton(
                                            systemName: "globe",
                                            action: state.nextKeyboardAction
                                        )
                                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                                        .contentShape(Rectangle())
                                    }
                                } else {
                                    SYKeyboardButton(
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
                                            }
                                        },
                                        onLongPressFinished: {
                                            if state.isSelectingOneHandType {
                                                state.currentOneHandType = state.selectedOneHandType
                                                currentOneHandType = state.selectedOneHandType.rawValue
                                                state.isSelectingOneHandType = false
                                            } else {
                                                state.currentInputType = .hangeul
                                            }
                                        })
                                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                                    .contentShape(Rectangle())
                                }
                                
                                SYKeyboardButton(
                                    systemName: "space", primary: true, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playModifierSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.spaceKeypadTap()
                                        if state.currentKeyboardType != .numbersAndPunctuation && isAutoChangeToHangeulEnabled && isSymbolInput {
                                            state.currentInputType = .hangeul
                                        }
                                    },
                                    onLongPress: {
                                        Feedback.shared.playModifierSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.spaceKeypadTap()
                                        if state.currentKeyboardType != .numbersAndPunctuation && isAutoChangeToHangeulEnabled && isSymbolInput {
                                            state.currentInputType = .hangeul
                                        } else {
                                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                                .autoconnect()
                                                .sink { _ in
                                                    Feedback.shared.playModifierSound()
                                                    Feedback.shared.playHaptic(style: .light)
                                                    state.delegate?.spaceKeypadTap()
                                                }
                                        }
                                    },
                                    onLongPressFinished: {
                                        timer?.cancel()
                                    })
                                .frame(width: geometry.size.width / 2)
                                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                                .contentShape(Rectangle())
                                
                                SYKeyboardButton(
                                    systemName: "return.left", primary: false, geometry: geometry,
                                    onPress: {
                                        Feedback.shared.playModifierSound()
                                        Feedback.shared.playHaptic(style: .light)
                                    },
                                    onRelease: {
                                        state.delegate?.enterKeypadTap()
                                        if state.currentKeyboardType != .numbersAndPunctuation && isAutoChangeToHangeulEnabled && isSymbolInput {
                                            state.currentInputType = .hangeul
                                        }
                                    },
                                    onLongPressFinished: {
                                        state.delegate?.enterKeypadTap()
                                        if state.currentKeyboardType != .numbersAndPunctuation && isAutoChangeToHangeulEnabled && isSymbolInput {
                                            state.currentInputType = .hangeul
                                        }
                                    })
                                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                                .contentShape(Rectangle())
                            }
                        }
                        
                        if state.isSelectingInputType {
                            InputTypeSelectOverlayView()
                                .offset(x: 1, y: state.keyboardHeight / 8)
                        }
                        
                        if state.isSelectingOneHandType {
                            OneHandSelectOverlayView()
                                .offset(x: 1, y: state.keyboardHeight / 8)
                        }
                    }
                }
                if isOneHandTypeEnabled && state.currentOneHandType == .left {
                    ChevronButton(isLeftHandMode: true, geometry: geometry)
                }
            }
        }.onAppear {
            state.nowSymbolPage = 0
            state.totalSymbolPage = symbols.count
        }
        .frame(height: state.keyboardHeight)
        .background(Color.white.opacity(0.001))
    }
}
