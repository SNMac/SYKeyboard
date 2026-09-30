//
//  HangeulEnglishKeyboardModeCoordinator.swift
//  SYKeyboardCore
//
//  Created by Codex on 8/13/26.
//

/// 한영 통합 키보드의 focus별 언어 mode를 관리합니다.
public final class HangeulEnglishKeyboardModeCoordinator {

    // MARK: - Properties

    public private(set) var currentMode: HangeulEnglishLanguageMode
    private var currentTextInputIdentifier: ObjectIdentifier?

    // MARK: - Initializer

    public init(initialMode: HangeulEnglishLanguageMode) {
        currentMode = initialMode
    }

    // MARK: - Public Methods

    public func modeForTextInputChange(
        identifier: ObjectIdentifier?,
        requiresLatinInput: Bool,
        lastMode: HangeulEnglishLanguageMode?,
        preferredLanguages: [String]
    ) -> HangeulEnglishLanguageMode {
        guard let identifier else { return currentMode }
        guard identifier != currentTextInputIdentifier else { return currentMode }

        currentTextInputIdentifier = identifier
        return KeyboardLanguageModePolicy.initialMode(
            requiresLatinInput: requiresLatinInput,
            lastMode: lastMode,
            preferredLanguages: preferredLanguages
        )
    }

    /// 입력 trait이 바뀌었을 때 쓸 언어를 다시 정한다.
    /// 필드 객체를 알 수 없는 환경에서 `modeForTextInputChange` 대신 쓴다
    public func modeForInputTraitsChange(
        requiresLatinInput: Bool,
        lastMode: HangeulEnglishLanguageMode?,
        preferredLanguages: [String]
    ) -> HangeulEnglishLanguageMode {
        KeyboardLanguageModePolicy.initialMode(
            requiresLatinInput: requiresLatinInput,
            lastMode: lastMode,
            preferredLanguages: preferredLanguages
        )
    }

    public func selectModeManually(_ mode: HangeulEnglishLanguageMode) {
        currentMode = mode
    }
}
