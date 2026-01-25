//
//  FeedbackManager.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/16/25.
//

import UIKit
import AVFoundation
import OSLog

/// 햅틱, 사운드 피드백을 관리하는 싱글톤 매니저
@MainActor
final class FeedbackManager {
    
    // MARK: - Singleton Initializer
    
    static let shared = FeedbackManager()
    private init() {}
    
    // MARK: - Properties
    
    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
    /// 햅틱 피드백 생성기
    private let lightFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    /// 키 입력 버튼 사운드
    private let keyTypingSoundID: SystemSoundID = 1104
    /// 삭제 버튼 사운드
    private let deleteSoundID: SystemSoundID = 1155
    /// 스페이스, 리턴, 키보드 변경 버튼 사운드
    private let modifierSoundID: SystemSoundID = 1156
    
    // MARK: - Haptic Feedback Methods
    
    /// 탭틱 엔진 준비
    func prepareHaptic() {
        lightFeedbackGenerator.prepare()
    }
    
    /// 햅틱 피드백 재생
    func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light, isForcing: Bool = false) {
        guard UserDefaultsManager.shared.isHapticFeedbackEnabled || isForcing else { return }
        if style != .light {
            let tempFeedbackGenerator = UIImpactFeedbackGenerator(style: style)
            tempFeedbackGenerator.impactOccurred()
            tempFeedbackGenerator.prepare()
            logger.debug("커스텀 햅틱 피드백 재생")
        } else {
            lightFeedbackGenerator.impactOccurred()
            lightFeedbackGenerator.prepare()
            logger.debug("light 햅틱 피드백 재생")
        }
    }
    
    // MARK: - Sound Feedback Methods
    
    /// 키 입력 사운드 재생
    func playKeyTypingSound() {
        playSound(keyTypingSoundID, description: "키 입력")
    }
    
    /// 삭제 사운드 재생
    func playDeleteSound() {
        playSound(deleteSoundID, description: "삭제")
    }
    
    /// 모디파이어 사운드 재생
    func playModifierSound() {
        playSound(modifierSoundID, description: "모디파이어")
    }
}

// MARK: - Private Methods

private extension FeedbackManager {
    func playSound(_ soundID: SystemSoundID, description: String) {
        guard UserDefaultsManager.shared.isSoundFeedbackEnabled else { return }
        AudioServicesPlaySystemSound(soundID)
        logger.debug("\(description) 사운드 재생")
    }
}
