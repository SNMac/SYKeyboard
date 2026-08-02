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

    @Test("선택되지 않은 가운데 후보는 결과값 삽입 action")
    func test선택되지않은가운데후보는_결과값삽입Action() {
        let controller = makeMathController(expression: "3-1=")

        #expect(
            controller.mathResultAction(
                at: 1,
                selectedText: nil
            ) == .insertResult("2")
        )
    }

    @Test("선택되지 않은 오른쪽 후보는 수식 전체 대치 action")
    func test선택되지않은오른쪽후보는_수식전체대치Action() {
        let controller = makeMathController(expression: "1 + 2 =")

        #expect(
            controller.mathResultAction(
                at: 2,
                selectedText: nil
            ) == .replaceExpression(deleteCount: 7, insertText: "3")
        )
    }

    @Test("선택된 가운데 후보는 원문과 결과로 selection 교체")
    func test선택된가운데후보는_원문과결과로Selection교체() {
        let controller = makeMathController(expression: "3-1=")

        #expect(
            controller.mathResultAction(
                at: 1,
                selectedText: "3-1="
            ) == .replaceSelection("3-1=2")
        )
    }

    @Test("선택된 오른쪽 후보는 결과값으로 selection 교체")
    func test선택된오른쪽후보는_결과값으로Selection교체() {
        let controller = makeMathController(expression: "3-1=")

        #expect(
            controller.mathResultAction(
                at: 2,
                selectedText: "3-1="
            ) == .replaceSelection("2")
        )
    }

    @Test("수식 suffix 앞에 선택 prefix가 있으면 가운데 후보가 prefix를 보존")
    func test수식Suffix앞에선택Prefix가있으면_가운데후보가Prefix를보존() {
        let controller = makeMathController(expression: "memo3+1=")

        #expect(
            controller.mathResultAction(
                at: 1,
                selectedText: "memo3+1="
            ) == .replaceSelection("memo3+1=4")
        )
    }

    @Test("수식 suffix 앞에 선택 prefix가 있으면 오른쪽 후보가 prefix를 보존")
    func test수식Suffix앞에선택Prefix가있으면_오른쪽후보가Prefix를보존() {
        let controller = makeMathController(expression: "memo3+1=")

        #expect(
            controller.mathResultAction(
                at: 2,
                selectedText: "memo3+1="
            ) == .replaceSelection("memo4")
        )
    }

    @Test("왼쪽 후보는 정확한 수식과 prefix 선택에서 원문 확정")
    func test왼쪽후보는_정확한수식과Prefix선택에서원문확정() {
        let controller = makeMathController(expression: "3-1=")

        #expect(
            controller.mathResultAction(
                at: 0,
                selectedText: nil
            ) == .confirmOriginal
        )
        #expect(
            controller.mathResultAction(
                at: 0,
                selectedText: "3-1="
            ) == .confirmOriginal
        )

        let prefixedController = makeMathController(expression: "memo3+1=")
        #expect(
            prefixedController.mathResultAction(
                at: 0,
                selectedText: "memo3+1="
            ) == .confirmOriginal
        )
    }

    @Test("현재 수식 생성 기준과 선택 문자열이 다르면 action을 반환하지 않음")
    func test현재수식생성기준과선택문자열이다르면_Action을반환하지않음() {
        let controller = makeMathController(expression: "memo3+1=")

        #expect(
            controller.mathResultAction(
                at: 1,
                selectedText: "note3+1="
            ) == nil
        )
        #expect(
            controller.mathResultAction(
                at: 2,
                selectedText: "3+1="
            ) == nil
        )
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
        #expect(
            controller.mathResultAction(
                at: 1,
                selectedText: nil
            ) == .insertResult("10")
        )
        #expect(
            controller.mathResultAction(
                at: 2,
                selectedText: nil
            ) == .replaceExpression(deleteCount: 8, insertText: "10")
        )
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

private func makeMathController(expression: String) -> SuggestionController {
    let controller = SuggestionController()
    controller.isPredictiveTextEnabled = true
    controller.isShowMathResultsEnabled = true
    controller.updateSuggestions(for: expression)
    return controller
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
