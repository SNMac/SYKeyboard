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

        // 후보 목록은 #141부터 가로로 스크롤된다. 버튼 '안'의 긴 텍스트가
        // 스크롤되지 않는다는 #98 롤백 계약만 그대로 지킨다
        let buttons = typedSuggestionButtonViews(in: bar)
        #expect(buttons.count == 3)
        #expect(buttons.allSatisfy { scrollViews(in: $0).isEmpty })
        #expect(labels.count == 3)
        #expect(labels.allSatisfy { $0.numberOfLines == 2 })
        #expect(labels.allSatisfy { $0.adjustsFontSizeToFitWidth })
        #expect(labels.allSatisfy { abs($0.minimumScaleFactor - 0.7) < 0.001 })
        #expect(labels.allSatisfy { $0.lineBreakMode == .byTruncatingMiddle })
    }

    @Test("터치 중에는 preview 하이라이트를 표시하지 않고 손을 떼면 되살림")
    func test터치중에는_preview하이라이트를표시하지않고_손을떼면되살림() {
        let keyboardHStackView = UIStackView()
        let bar = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        let delegate = SuggestionBarDelegateSpy()
        bar.suggestionDelegate = delegate
        bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        bar.updateSuggestions(currentWord: nil, suggestions: ["원문", "원문과결과", "결과"])
        bar.updatePreviewHighlight(index: 1)
        bar.layoutIfNeeded()

        let buttons = typedSuggestionButtonViews(in: bar)
        #expect(buttons[1].isHighlighted)

        let startPoint = center(of: buttons[0], in: bar)
        let endPoint = center(of: buttons[2], in: bar)

        bar.beginTouchInteraction(at: startPoint)
        #expect(buttons[0].isHighlighted)
        #expect(buttons[1].isHighlighted == false)

        // 시작한 후보를 벗어나면 눌린 하이라이트가 사라지는데, 이때 preview가 드러나면
        // 끌고 있는 동안 가운데 칸이 선택된 것처럼 보인다
        // 후보 3개는 스크롤할 수 없어 끌어서 고르기가 유지된다. 하이라이트는 손가락을 따라가고
        // preview는 터치가 끝날 때까지 숨는다
        bar.moveTouchInteraction(to: endPoint)
        #expect(buttons[2].isHighlighted)
        #expect(buttons[1].isHighlighted == false)

        bar.endTouchInteraction(at: endPoint, playsFeedback: false)

        #expect(delegate.selectedIndexes == [2])
        #expect(buttons[1].isHighlighted)
    }

    @Test("긴 후보를 탭하면 그 후보를 선택")
    func test긴후보를탭하면_그후보를선택() {
        let keyboardHStackView = UIStackView()
        let bar = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        let delegate = SuggestionBarDelegateSpy()
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
        let point = center(of: buttons[0], in: bar)

        bar.beginTouchInteraction(at: point)

        #expect(buttons[0].isHighlighted)

        bar.endTouchInteraction(at: point, playsFeedback: false)

        #expect(delegate.selectedIndexes == [0])
        #expect(keyboardHStackView.isUserInteractionEnabled)
    }

    @Test("후보가 3개면 끌어서 고르기가 유지됨")
    func test후보가3개면_끌어서고르기가유지됨() {
        let keyboardHStackView = UIStackView()
        let bar = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        let delegate = SuggestionBarDelegateSpy()
        bar.suggestionDelegate = delegate
        bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        bar.updateSuggestions(currentWord: nil, suggestions: ["가", "나", "다"])
        bar.layoutIfNeeded()

        let buttons = typedSuggestionButtonViews(in: bar)
        let startPoint = center(of: buttons[0], in: bar)
        let endPoint = center(of: buttons[2], in: bar)

        #expect(bar.isSuggestionAreaScrollable == false)

        bar.beginTouchInteraction(at: startPoint)
        bar.moveTouchInteraction(to: endPoint)

        #expect(buttons[2].isHighlighted)

        bar.endTouchInteraction(at: endPoint, playsFeedback: false)

        #expect(delegate.selectedIndexes == [2])
        #expect(keyboardHStackView.isUserInteractionEnabled)
    }

    @Test("후보가 넘치면 시작한 후보를 벗어나 떼어도 선택되지 않음")
    func test후보가넘치면_시작한후보를벗어나떼어도_선택되지않음() {
        let keyboardHStackView = UIStackView()
        let bar = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        let delegate = SuggestionBarDelegateSpy()
        bar.suggestionDelegate = delegate
        bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        bar.updateSuggestions(
            currentWord: nil,
            suggestions: (1...10).map { "단어\($0)" }
        )
        bar.layoutIfNeeded()

        let buttons = typedSuggestionButtonViews(in: bar)
        let startPoint = center(of: buttons[0], in: bar)
        let endPoint = center(of: buttons[2], in: bar)

        #expect(bar.isSuggestionAreaScrollable)

        bar.beginTouchInteraction(at: startPoint)
        bar.moveTouchInteraction(to: endPoint)

        // 끄는 동작이 스크롤이므로 끌어서 고르기를 막는다. 떼어도 선택되지 않으니 강조도 남기지 않는다
        #expect(buttons[2].isHighlighted == false)
        #expect(buttons[0].isHighlighted == false)

        bar.endTouchInteraction(at: endPoint, playsFeedback: false)

        #expect(delegate.selectedIndexes == [])
        #expect(keyboardHStackView.isUserInteractionEnabled)
    }

    @Test("터치 도중 후보가 늘어나도 시작할 때 정한 끌어서 고르기 규칙을 유지")
    func test터치도중_후보가늘어나도_시작할때정한규칙을유지() {
        let keyboardHStackView = UIStackView()
        let bar = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        let delegate = SuggestionBarDelegateSpy()
        bar.suggestionDelegate = delegate
        bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        bar.updateSuggestions(currentWord: nil, suggestions: ["가", "나", "다"])
        bar.layoutIfNeeded()

        #expect(bar.isSuggestionAreaScrollable == false)

        let startPoint = center(of: typedSuggestionButtonViews(in: bar)[0], in: bar)
        bar.beginTouchInteraction(at: startPoint)

        // TextChecker 결과가 늦게 도착해 같은 터치 도중 후보가 3개에서 10개로 늘어난 상황
        bar.updateSuggestions(currentWord: nil, suggestions: (1...10).map { "단어\($0)" })
        bar.layoutIfNeeded()

        #expect(bar.isSuggestionAreaScrollable)

        let buttons = typedSuggestionButtonViews(in: bar)
        let endPoint = center(of: buttons[2], in: bar)

        bar.moveTouchInteraction(to: endPoint)

        // 시작 시 규칙이 끌어서 고르기였으므로 하이라이트는 손가락을 따라가야 한다
        #expect(buttons[2].isHighlighted)

        bar.endTouchInteraction(at: endPoint, playsFeedback: false)

        #expect(delegate.selectedIndexes == [2])
        #expect(keyboardHStackView.isUserInteractionEnabled)
    }

    @Test("클립보드 버튼 탭은 delegate에 전달되고 후보 하이라이트를 만들지 않음")
    func test클립보드버튼탭은_delegate전달_후보하이라이트없음() {
        let keyboardHStackView = UIStackView()
        let bar = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        let delegate = SuggestionBarDelegateSpy()
        bar.suggestionDelegate = delegate
        bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        bar.updateSuggestions(currentWord: nil, suggestions: ["가", "나", "다"])
        bar.updateClipboardControl(isVisible: true, isPanelVisible: false)
        bar.layoutIfNeeded()

        let buttons = typedSuggestionButtonViews(in: bar)
        // 클립보드 버튼은 bar 왼쪽 끝 44pt 영역을 차지한다
        let point = CGPoint(x: KeyboardLayoutFigure.undoRedoButtonWidth / 2, y: 24)

        bar.beginTouchInteraction(at: point)

        #expect(buttons.allSatisfy { !$0.isHighlighted })

        bar.endTouchInteraction(at: point, playsFeedback: false)

        #expect(delegate.clipboardTapCount == 1)
        #expect(delegate.selectedIndexes.isEmpty)
        #expect(keyboardHStackView.isUserInteractionEnabled)
    }

    @Test("클립보드 버튼이 숨겨져 있으면 같은 위치 탭은 첫 후보를 선택")
    func test클립보드버튼숨김시_같은위치탭은_첫후보선택() {
        let bar = SuggestionBarView(keyboardHStackView: UIStackView())
        let delegate = SuggestionBarDelegateSpy()
        bar.suggestionDelegate = delegate
        bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        bar.updateSuggestions(currentWord: nil, suggestions: ["가", "나", "다"])
        bar.updateClipboardControl(isVisible: false, isPanelVisible: false)
        bar.layoutIfNeeded()

        let point = CGPoint(x: KeyboardLayoutFigure.undoRedoButtonWidth / 2, y: 24)
        bar.beginTouchInteraction(at: point)
        bar.endTouchInteraction(at: point, playsFeedback: false)

        #expect(delegate.clipboardTapCount == 0)
        #expect(delegate.selectedIndexes == [0])
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
