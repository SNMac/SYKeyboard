//
//  Feedback.swift
//  Naratgeul
//
//  Created by Sunghyun Cho on 2023-01-21.
//  Edited by 서동환 on 8/7/24.
//  - Downloaded from https://github.com/anaclumos/sky-earth-human - Feedback.swift
//

import AVFoundation
import UIKit


final class Feedback {
    static let shared = Feedback()
    
    var defaults: UserDefaults?
    
    let generator = UIImpactFeedbackGenerator(style: .light)
    
    init() {
        defaults = UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")
    }
    
    var haptics: Bool {
        return defaults?.bool(forKey: "isHapticFeedbackEnabled") ?? true
    }
    
    var sounds: Bool {
        return defaults?.bool(forKey: "isSoundFeedbackEnabled") ?? true
    }
    
    func playHaptics() {
        if !haptics { return }
        generator.prepare()
        generator.impactOccurred()
    }
    
    func playTypeSound() {
        if !sounds { return }
        let systemSoundID: SystemSoundID = 1104
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    func playDeleteSound() {
        if !sounds { return }
        let systemSoundID: SystemSoundID = 1155
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    func playModifierSound() {
        if !sounds { return }
        let systemSoundID: SystemSoundID = 1156
        AudioServicesPlaySystemSound(systemSoundID)
    }
}