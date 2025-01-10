//
//  Feedback.swift
//  SYKeyboard, Naratgeul
//
//  Created by Sunghyun Cho on 1/21/23.
//  Edited by 서동환 on 8/7/24.
//  - Downloaded from https://github.com/anaclumos/sky-earth-human - Feedback.swift
//

import AVFoundation
import UIKit

final class Feedback {
    static let shared = Feedback()
    private init() {}
    
    var sounds: Bool {
        let defaults = UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")
        return defaults?.bool(forKey: "isSoundFeedbackEnabled") ?? true
    }
    
    var haptic: Bool {
        let defaults = UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")
        return defaults?.bool(forKey: "isHapticFeedbackEnabled") ?? true
    }
    
    func prepareHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
    }
        
    func playHapticByForce(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        generator.prepare()
    }
    
    func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        if !haptic { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        generator.prepare()
    }
    
    func playTypingSound() {
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
