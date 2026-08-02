//
//  SuggestionBarViewPreviewHighlightTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/30/26.
//

import UIKit
import Testing

import SYKeyboardAssets

@testable import SYKeyboardCore

@Suite("자동완성 바 preview 하이라이트 검증")
@MainActor
struct SuggestionBarViewPreviewHighlightTests {

    @Test("후보 라벨은 스크롤 없이 두 줄 자동 축소와 가운데 생략 사용")
    func test후보라벨은_스크롤없이_두줄자동축소와_가운데생략사용() {
        let bar = SuggestionBarView(keyboardHStackView: UIStackView())
        bar.updateSuggestions(
            currentWord: nil,
            suggestions: ["123456789012345678901234567890", "b", "c"]
        )

        let labels = suggestionLabels(in: bar)

        #expect(scrollViews(in: bar).isEmpty)
        #expect(labels.count == 3)
        #expect(labels.allSatisfy { $0.numberOfLines == 2 })
        #expect(labels.allSatisfy { $0.adjustsFontSizeToFitWidth })
        #expect(labels.allSatisfy { abs($0.minimumScaleFactor - 0.7) < 0.001 })
        #expect(labels.allSatisfy { $0.lineBreakMode == .byTruncatingMiddle })
    }

    @Test("긴 후보에서 시작한 드래그도 종료 위치 후보를 선택")
    func test긴후보에서시작한드래그도_종료위치후보를선택() {
        let keyboardHStackView = UIStackView()
        let bar = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        let delegate = SuggestionBarRollbackDelegateSpy()
        bar.suggestionDelegate = delegate
        bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        bar.updateSuggestions(
            currentWord: nil,
            suggestions: [
                "123456789012345678901234567890",
                "두번째",
                "세번째"
            ]
        )
        bar.layoutIfNeeded()

        let buttons = typedSuggestionButtonViews(in: bar)
        let startPoint = center(of: buttons[0], in: bar)
        let endPoint = center(of: buttons[2], in: bar)

        bar.beginTouchInteraction(at: startPoint)
        bar.moveTouchInteraction(to: endPoint)

        #expect(buttons[2].isHighlighted)

        bar.endTouchInteraction(at: endPoint, playsFeedback: false)

        #expect(delegate.selectedIndexes == [2])
        #expect(keyboardHStackView.isUserInteractionEnabled)
    }

    @Test("preview 하이라이트 인덱스는 해당 후보 버튼만 강조")
    func testPreview하이라이트인덱스는_해당후보버튼만강조() {
        let bar = SuggestionBarView(keyboardHStackView: UIStackView())
        bar.updateSuggestions(currentWord: nil, suggestions: ["a", "b", "c"])

        bar.updatePreviewHighlight(index: 1)

        let buttons = suggestionButtonViews(in: bar)
        #expect(buttons.count == 3)
        #expect(isSuggestionButtonHighlighted(buttons[0]) == false)
        #expect(isSuggestionButtonHighlighted(buttons[1]) == true)
        #expect(isSuggestionButtonHighlighted(buttons[2]) == false)
    }

    @Test("preview 하이라이트를 nil로 갱신하면 모든 후보 강조를 해제")
    func testPreview하이라이트를Nil로갱신하면_모든후보강조를해제() {
        let bar = SuggestionBarView(keyboardHStackView: UIStackView())
        bar.updateSuggestions(currentWord: nil, suggestions: ["a", "b", "c"])

        bar.updatePreviewHighlight(index: 1)
        bar.updatePreviewHighlight(index: nil)

        let buttons = suggestionButtonViews(in: bar)
        #expect(buttons.allSatisfy { isSuggestionButtonHighlighted($0) == false })
    }

    @Test("기본 자동완성 후보 라벨은 suggestionButtonLabel로 표시")
    func test기본자동완성후보라벨은_SuggestionButtonLabel로표시() {
        let bar = SuggestionBarView(keyboardHStackView: UIStackView())

        bar.updateSuggestions(currentWord: nil, suggestions: ["a", "b", "c"])

        let labels = suggestionLabels(in: bar)
        #expect(labels.count == 3)
        #expect(labels.allSatisfy { $0.textColor == .suggestionButtonLabel })
    }

    @Test("preview 하이라이트 후보 라벨은 label 색상으로 표시")
    func testPreview하이라이트후보라벨은_Label색상으로표시() {
        let bar = SuggestionBarView(keyboardHStackView: UIStackView())
        bar.updateSuggestions(currentWord: nil, suggestions: ["a", "b", "c"])

        bar.updatePreviewHighlight(index: 1)

        let labels = suggestionLabels(in: bar)
        #expect(labels.count == 3)
        #expect(labels[0].textColor == .suggestionButtonLabel)
        #expect(labels[1].textColor == .label)
        #expect(labels[2].textColor == .suggestionButtonLabel)
    }

    @Test("수식 후보도 하이라이트 여부만으로 라벨 색상을 결정")
    func test수식후보도_하이라이트여부만으로_라벨색상을결정() {
        let bar = SuggestionBarView(keyboardHStackView: UIStackView())
        bar.updateMathResultSuggestions(["1+2=", "1+2=3", "3"])

        var labels = suggestionLabels(in: bar)
        #expect(labels.count == 3)
        #expect(labels.allSatisfy { $0.textColor == .suggestionButtonLabel })

        bar.updatePreviewHighlight(index: 2)

        labels = suggestionLabels(in: bar)
        #expect(labels[0].textColor == .suggestionButtonLabel)
        #expect(labels[1].textColor == .suggestionButtonLabel)
        #expect(labels[2].textColor == .label)
    }

    @Test("다른 후보를 누르는 동안 preview 하이라이트는 터치 후보로 대체")
    func test다른후보를누르는동안_Preview하이라이트는_터치후보로대체() {
        let bar = SuggestionBarView(keyboardHStackView: UIStackView())
        bar.updateSuggestions(currentWord: nil, suggestions: ["a", "b", "c"])
        bar.updatePreviewHighlight(index: 1)

        bar.updateTouchHighlightForTesting(index: 2)

        var buttons = suggestionButtonViews(in: bar)
        #expect(isSuggestionButtonHighlighted(buttons[0]) == false)
        #expect(isSuggestionButtonHighlighted(buttons[1]) == false)
        #expect(isSuggestionButtonHighlighted(buttons[2]) == true)

        bar.updateTouchHighlightForTesting(index: nil)

        buttons = suggestionButtonViews(in: bar)
        #expect(isSuggestionButtonHighlighted(buttons[0]) == false)
        #expect(isSuggestionButtonHighlighted(buttons[1]) == true)
        #expect(isSuggestionButtonHighlighted(buttons[2]) == false)
    }

    @Test("undo redo를 누르는 동안 preview 하이라이트는 액션 버튼으로 대체")
    func testUndoRedo를누르는동안_Preview하이라이트는_액션버튼으로대체() {
        let bar = SuggestionBarView(keyboardHStackView: UIStackView())
        bar.updateSuggestions(currentWord: nil, suggestions: ["a", "b", "c"])
        bar.updateUndoRedoControls(isVisible: true, canUndo: true, canRedo: true)
        bar.updatePreviewHighlight(index: 1)

        bar.updateUndoRedoTouchHighlightForTesting(index: 0)

        var suggestionButtons = suggestionButtonViews(in: bar)
        var actionButtons = suggestionActionButtonViews(in: bar)
        #expect(suggestionButtons.allSatisfy { isSuggestionButtonHighlighted($0) == false })
        #expect(isSuggestionActionButtonHighlighted(actionButtons[0]) == true)
        #expect(isSuggestionActionButtonHighlighted(actionButtons[1]) == false)

        bar.updateUndoRedoTouchHighlightForTesting(index: nil)

        suggestionButtons = suggestionButtonViews(in: bar)
        actionButtons = suggestionActionButtonViews(in: bar)
        #expect(isSuggestionButtonHighlighted(suggestionButtons[0]) == false)
        #expect(isSuggestionButtonHighlighted(suggestionButtons[1]) == true)
        #expect(isSuggestionButtonHighlighted(suggestionButtons[2]) == false)
        #expect(actionButtons.allSatisfy { isSuggestionActionButtonHighlighted($0) == false })
    }

    private func suggestionButtonViews(in view: UIView) -> [UIView] {
        var result: [UIView] = []

        for subview in view.subviews {
            if String(describing: type(of: subview)).contains("SuggestionButtonView") {
                result.append(subview)
            }
            result.append(contentsOf: suggestionButtonViews(in: subview))
        }

        return result
    }

    private func isSuggestionButtonHighlighted(_ view: UIView) -> Bool? {
        Mirror(reflecting: view).descendant("isHighlighted") as? Bool
    }

    private func suggestionActionButtonViews(in view: UIView) -> [UIView] {
        var result: [UIView] = []

        for subview in view.subviews {
            if String(describing: type(of: subview)).contains("SuggestionActionButtonView") {
                result.append(subview)
            }
            result.append(contentsOf: suggestionActionButtonViews(in: subview))
        }

        return result
    }

    private func isSuggestionActionButtonHighlighted(_ view: UIView) -> Bool? {
        Mirror(reflecting: view).descendant("isHighlighted") as? Bool
    }

    private func suggestionLabels(in view: UIView) -> [UILabel] {
        var result: [UILabel] = []

        for subview in view.subviews {
            if let label = subview as? UILabel {
                result.append(label)
            }
            result.append(contentsOf: suggestionLabels(in: subview))
        }

        return result
    }
}

private func scrollViews(in view: UIView) -> [UIScrollView] {
    var result: [UIScrollView] = []
    for subview in view.subviews {
        if let scrollView = subview as? UIScrollView {
            result.append(scrollView)
        }
        result.append(contentsOf: scrollViews(in: subview))
    }
    return result
}

private func typedSuggestionButtonViews(
    in view: UIView
) -> [SuggestionButtonView] {
    var result: [SuggestionButtonView] = []
    for subview in view.subviews {
        if let button = subview as? SuggestionButtonView {
            result.append(button)
        }
        result.append(contentsOf: typedSuggestionButtonViews(in: subview))
    }
    return result.sorted {
        $0.convert($0.bounds, to: view).minX
            < $1.convert($1.bounds, to: view).minX
    }
}

private func center(of button: UIView, in bar: UIView) -> CGPoint {
    let frame = button.convert(button.bounds, to: bar)
    return CGPoint(x: frame.midX, y: frame.midY)
}

@MainActor
private final class SuggestionBarRollbackDelegateSpy: SuggestionBarDelegate {
    private(set) var selectedIndexes: [Int] = []

    func suggestionBar(
        _ bar: SuggestionBarView,
        didSelectSuggestionAt index: Int
    ) {
        selectedIndexes.append(index)
    }

    func suggestionBarDidTapUndo(_ bar: SuggestionBarView) {}
    func suggestionBarDidTapRedo(_ bar: SuggestionBarView) {}
}
