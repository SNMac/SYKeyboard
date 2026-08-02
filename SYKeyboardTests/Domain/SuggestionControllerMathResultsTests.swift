//
//  SuggestionControllerMathResultsTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/30/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("자동완성 컨트롤러 수식 결과 후보 검증")
struct SuggestionControllerMathResultsTests {

    @Test("수식 결과 설정이 켜져 있으면 좌중우 후보에 원문과 결과를 표시")
    func test수식결과설정이켜져있으면_좌중우후보에원문과결과를표시() {
        let delegate = RecordingMathExpressionSuggestionDelegate()
        let controller = SuggestionController()
        controller.delegate = delegate
        controller.isPredictiveTextEnabled = true
        controller.isShowMathResultsEnabled = true

        controller.updateSuggestions(for: "3 - 1 =")

        #expect(controller.currentMode == .mathExpression)
        #expect(delegate.updates.last?.currentWord == nil)
        #expect(delegate.updates.last?.suggestions == ["\"3 - 1 =\"", "3 - 1 =2", "2"])
    }

    @Test("가운데 수식 결과 후보 선택은 결과값만 삽입")
    func test가운데수식결과후보선택은_결과값만삽입() {
        let controller = SuggestionController()
        controller.isPredictiveTextEnabled = true
        controller.isShowMathResultsEnabled = true

        controller.updateSuggestions(for: "3-1=")
        let result = controller.mathResultInsertText(at: 1)

        #expect(result == "2")
    }

    @Test("오른쪽 수식 결과 후보 선택은 수식 전체를 결과값으로 대치")
    func test오른쪽수식결과후보선택은_수식전체를결과값으로대치() {
        let controller = SuggestionController()
        controller.isPredictiveTextEnabled = true
        controller.isShowMathResultsEnabled = true

        controller.updateSuggestions(for: "1 + 2 =")
        let replacement = controller.mathResultReplacement(at: 2)

        #expect(replacement?.deleteCount == 7)
        #expect(replacement?.insertText == "3")
    }

    @Test("왼쪽 수식 원문 후보 선택은 입력을 변경하지 않음")
    func test왼쪽수식원문후보선택은_입력을변경하지않음() {
        let controller = SuggestionController()
        controller.isPredictiveTextEnabled = true
        controller.isShowMathResultsEnabled = true

        controller.updateSuggestions(for: "1 + 2 =")

        #expect(controller.isMathExpressionOriginal(at: 0))
        #expect(controller.isMathExpressionOriginal(at: 1) == false)
        #expect(controller.mathResultInsertText(at: 0) == nil)
        #expect(controller.mathResultReplacement(at: 0) == nil)
    }

    @Test("수식 결과 설정이 꺼져 있으면 수식 후보를 표시하지 않음")
    func test수식결과설정이꺼져있으면_수식후보를표시하지않음() {
        let delegate = RecordingMathExpressionSuggestionDelegate()
        let controller = SuggestionController()
        controller.delegate = delegate
        controller.isPredictiveTextEnabled = true
        controller.isShowMathResultsEnabled = false

        controller.updateSuggestions(for: "3-1=")

        #expect(controller.currentMode == .typing)
        #expect(delegate.updates.last?.suggestions != ["", "3-1=2", ""])
    }

    @Test("괄호 수식은 좌중우 후보에 원문과 결과를 표시")
    func test괄호수식은_좌중우후보에원문과결과를표시() {
        let delegate = RecordingMathExpressionSuggestionDelegate()
        let controller = SuggestionController()
        controller.delegate = delegate
        controller.isPredictiveTextEnabled = true
        controller.isShowMathResultsEnabled = true

        controller.updateSuggestions(for: "(3+2)*2=")

        #expect(controller.currentMode == .mathExpression)
        #expect(delegate.updates.last?.suggestions == ["\"(3+2)*2=\"", "(3+2)*2=10", "10"])
        #expect(controller.mathResultInsertText(at: 1) == "10")
        #expect(controller.mathResultReplacement(at: 2)?.deleteCount == 8)
        #expect(controller.mathResultReplacement(at: 2)?.insertText == "10")
    }

    @Test("부호가 연속된 수식은 수식 모드로 전환하지 않음")
    func test부호가연속된수식은_수식모드로전환하지않음() {
        let delegate = RecordingMathExpressionSuggestionDelegate()
        let controller = SuggestionController()
        controller.delegate = delegate
        controller.isPredictiveTextEnabled = true
        controller.isShowMathResultsEnabled = true

        controller.updateSuggestions(for: "3++1=")

        #expect(controller.currentMode == .typing)
        #expect(delegate.updates.last?.suggestions != ["\"3++1=\"", "3++1=4", "4"])
    }
}

private final class RecordingMathExpressionSuggestionDelegate: SuggestionControllerDelegate {
    struct Update: Equatable {
        let currentWord: String?
        let suggestions: [String]
    }

    private(set) var updates: [Update] = []

    func suggestionController(
        _ controller: SuggestionController,
        didUpdateCurrentWord currentWord: String?,
        suggestions: [String]
    ) {
        updates.append(Update(currentWord: currentWord, suggestions: suggestions))
    }
}
