//
//  HangeulKeyboardInputAdapter.swift
//  HangeulKeyboardCore
//
//  Created by Codex on 8/13/26.
//

import UIKit

import SYKeyboardCore

/// 한글 조합 상태와 선택된 입력기/UI 상태를 재사용 가능한 형태로 제공합니다.
public final class HangeulKeyboardInputAdapter {

    // MARK: - Properties

    private let selectedKeyboard: HangeulKeyboardType
    private var compositionState = HangeulCompositionState()
    private var is글자Input = false

    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    private lazy var naratgeulProcessor: HangeulProcessable = NaratgeulProcessor(automata: automata)
    private lazy var cheonjiinProcessor: HangeulProcessable = CheonjiinProcessor(automata: automata)
    private lazy var dubeolsikProcessor: HangeulProcessable = DubeolsikProcessor(automata: automata)

    private var processor: HangeulProcessable {
        switch selectedKeyboard {
        case .naratgeul:
            return naratgeulProcessor
        case .cheonjiin:
            return cheonjiinProcessor
        case .dubeolsik:
            return dubeolsikProcessor
        }
    }

    private lazy var naratgeulKeyboardView: HangeulKeyboardLayoutProvider = NaratgeulKeyboardView()
    private lazy var cheonjiinKeyboardView: HangeulKeyboardLayoutProvider = CheonjiinKeyboardView()
    private lazy var dubeolsikKeyboardView: HangeulKeyboardLayoutProvider = DubeolsikKeyboardView(
        getIsShiftedLetterInput: { [weak self] in self?.is글자Input ?? false },
        setIsShiftedLetterInput: { [weak self] in self?.is글자Input = $0 }
    )

    private var hangeulKeyboardView: HangeulKeyboardLayoutProvider {
        switch selectedKeyboard {
        case .naratgeul:
            return naratgeulKeyboardView
        case .cheonjiin:
            return cheonjiinKeyboardView
        case .dubeolsik:
            return dubeolsikKeyboardView
        }
    }

    public var primaryKeyboardViews: [PrimaryKeyboardRepresentable] {
        return [primaryKeyboardView]
    }

    public var primaryKeyboardView: PrimaryKeyboardRepresentable {
        return hangeulKeyboardView
    }

    public var shouldDeferUndoRedoCommit: Bool {
        return !compositionState.composingBuffer.isEmpty
    }

    public var isCompositionOngoing: Bool {
        return processor.is한글조합OnGoing
    }

    public var hasRepeatableInput: Bool {
        return compositionState.lastInputText != nil
    }

    // MARK: - Initializer

    public init(
        selectedKeyboard: HangeulKeyboardType,
        showsLanguageSwitchButton: Bool = false
    ) {
        self.selectedKeyboard = selectedKeyboard
        _ = showsLanguageSwitchButton
    }

    // MARK: - Public Methods

    public func input(_ text: String) -> HangeulCompositionTransition {
        return compositionState.input(text, using: processor)
    }

    public func repeatInput() -> HangeulCompositionTransition {
        return compositionState.repeatInsert(using: processor)
    }

    public func space() -> HangeulCompositionTransition {
        return compositionState.space(using: processor)
    }

    public func delete() -> HangeulCompositionTransition {
        return compositionState.delete(using: processor)
    }

    public func repeatDelete() -> HangeulCompositionTransition {
        return compositionState.repeatDelete(using: processor)
    }

    public func beginDeleteTouchDown() {
        compositionState.beginDeleteButtonTouchDown()
    }

    public func endDeleteTouchDown() {
        compositionState.endDeleteButtonTouchDown()
    }

    public func cancelDeleteTouchDown() {
        compositionState.cancelDeleteButtonTouchDown()
    }

    public func finishRepeatDelete() -> HangeulCompositionTransition {
        return compositionState.finishRepeatDelete(using: processor)
            ?? HangeulCompositionTransition(proxyEdit: .none)
    }

    public func beginDeletePan() -> HangeulDeletePanResult? {
        return compositionState.deleteButtonPanDelete(using: processor)
    }

    public func restoreDeletePan(_ character: Character) -> HangeulCompositionTransition {
        return compositionState.deleteButtonPanRestore(character, using: processor)
    }

    public func finishDeletePan() {
        compositionState.finishDeleteButtonPan()
    }

    public func clearForExternalTextChange() {
        compositionState.clearAllBuffers()
        processor.reset한글조합()
    }

    public func finishForLanguageChange() {
        compositionState.clearAllBuffers()
        processor.reset한글조합()
    }

    public func updateLayout(for keyboardType: UIKeyboardType?) {
        switch keyboardType {
        case .default, nil, .asciiCapable, .numbersAndPunctuation:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
        case .URL:
            hangeulKeyboardView.currentHangeulKeyboardMode = .URL
        case .emailAddress:
            hangeulKeyboardView.currentHangeulKeyboardMode = .emailAddress
        case .twitter:
            hangeulKeyboardView.currentHangeulKeyboardMode = .twitter
        case .webSearch:
            hangeulKeyboardView.currentHangeulKeyboardMode = .webSearch
        case .numberPad, .phonePad, .namePhonePad, .decimalPad, .asciiCapableNumberPad:
            break
        @unknown default:
            assertionFailure("구현이 필요한 case 입니다.")
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
        }
    }

    public func updateSpaceButtonImage() {
        primaryKeyboardView.updateSpaceButtonImage(
            systemName: isCompositionOngoing ? "arrow.right" : "space"
        )
    }

    public func resetShiftState() {
        primaryKeyboardView.updateShiftButton(to: false)
        is글자Input = false
    }

    // MARK: - Internal Methods

    func recordTextInteraction() {
        is글자Input = true
    }

    func clearLetterInputState() {
        is글자Input = false
    }
}
