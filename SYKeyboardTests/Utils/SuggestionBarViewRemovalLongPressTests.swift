//
//  SuggestionBarViewRemovalLongPressTests.swift
//  SYKeyboardTests
//

import UIKit
import Testing

@testable import SYKeyboardCore

@Suite("자동완성 바 삭제 길게 누르기 검증")
@MainActor
struct SuggestionBarViewRemovalLongPressTests {

    @Test("삭제를 수락하면 손을 떼도 후보를 선택하지 않음")
    func test삭제를수락하면_손을떼도_후보를선택하지않음() {
        let fixture = makeFixture(acceptsRemoval: true)
        let point = center(of: fixture.buttons[1], in: fixture.bar)

        fixture.bar.beginTouchInteraction(at: point)
        fixture.bar.handleRemovalLongPress()

        #expect(fixture.delegate.removalRequestIndexes == [1])
        #expect(fixture.buttons[1].isHighlighted == false)

        let otherPoint = center(of: fixture.buttons[2], in: fixture.bar)
        fixture.bar.moveTouchInteraction(to: otherPoint)
        #expect(fixture.buttons[2].isHighlighted == false)

        fixture.bar.endTouchInteraction(at: otherPoint, playsFeedback: false)

        #expect(fixture.delegate.selectedIndexes == [])
        #expect(fixture.keyboardHStackView.isUserInteractionEnabled)
    }

    @Test("삭제를 거절하면 손을 뗄 때 기존처럼 선택")
    func test삭제를거절하면_손을뗄때_기존처럼선택() {
        let fixture = makeFixture(acceptsRemoval: false)
        let point = center(of: fixture.buttons[1], in: fixture.bar)

        fixture.bar.beginTouchInteraction(at: point)
        fixture.bar.handleRemovalLongPress()
        fixture.bar.endTouchInteraction(at: point, playsFeedback: false)

        #expect(fixture.delegate.removalRequestIndexes == [1])
        #expect(fixture.delegate.selectedIndexes == [1])
    }

    @Test("누른 후보를 벗어나면 삭제를 요청하지 않고 드래그 선택 유지")
    func test누른후보를벗어나면_삭제를요청하지않고_드래그선택유지() {
        let fixture = makeFixture(acceptsRemoval: true)
        let startPoint = center(of: fixture.buttons[0], in: fixture.bar)
        let endPoint = center(of: fixture.buttons[2], in: fixture.bar)

        fixture.bar.beginTouchInteraction(at: startPoint)
        fixture.bar.moveTouchInteraction(to: endPoint)
        fixture.bar.handleRemovalLongPress()
        fixture.bar.endTouchInteraction(at: endPoint, playsFeedback: false)

        #expect(fixture.delegate.removalRequestIndexes == [])
        #expect(fixture.delegate.selectedIndexes == [2])
    }

    @Test("터치가 끝난 뒤 타이머가 늦게 불려도 삭제를 요청하지 않음")
    func test터치가끝난뒤_타이머가늦게불려도_삭제를요청하지않음() {
        let fixture = makeFixture(acceptsRemoval: true)
        let point = center(of: fixture.buttons[1], in: fixture.bar)

        fixture.bar.beginTouchInteraction(at: point)
        fixture.bar.endTouchInteraction(at: point, playsFeedback: false)
        fixture.bar.handleRemovalLongPress()

        #expect(fixture.delegate.selectedIndexes == [1])
        #expect(fixture.delegate.removalRequestIndexes == [])
    }

    @Test("후보 3개는 후보 영역이 스크롤되지 않음")
    func test후보3개는_후보영역이스크롤되지않음() {
        let fixture = makeFixture(acceptsRemoval: false)

        // 레이아웃이 돌지 않아 폭이 0이면 아래 단언이 공허하게 통과한다
        #expect(fixture.buttons[0].bounds.width > 0)
        #expect(fixture.bar.isSuggestionAreaScrollable == false)
    }

    @Test("후보 버튼은 등폭을 유지")
    func test후보버튼은_등폭을유지() {
        let fixture = makeFixture(acceptsRemoval: false)
        let widths = fixture.buttons.map { $0.bounds.width }

        #expect(widths.count == 3)
        for width in widths {
            #expect(width > 0)
            #expect(abs(width - widths[0]) < 0.5)
        }
    }

    @Test("터치 취소는 하이라이트와 삭제 타이머를 함께 취소")
    func test터치취소는_하이라이트와삭제타이머를_함께취소() {
        let fixture = makeFixture(acceptsRemoval: true)
        let point = center(of: fixture.buttons[1], in: fixture.bar)

        fixture.bar.beginTouchInteraction(at: point)
        #expect(fixture.buttons[1].isHighlighted)

        fixture.bar.cancelTouchInteraction()
        fixture.bar.handleRemovalLongPress()

        #expect(fixture.buttons[1].isHighlighted == false)
        #expect(fixture.delegate.removalRequestIndexes == [])
        #expect(fixture.delegate.selectedIndexes == [])
        #expect(fixture.keyboardHStackView.isUserInteractionEnabled)
    }

    @Test("후보 수가 10 → 3 → 10으로 바뀌어도 이전 후보가 남지 않음")
    func test후보수가10과3을오가도_이전후보가남지않음() {
        let fixture = makeFixture(acceptsRemoval: false)
        let tenWords = (1...10).map { "단어\($0)" }
        let threeWords = ["가", "나", "다"]

        fixture.bar.updateSuggestions(currentWord: nil, suggestions: tenWords)
        fixture.bar.layoutIfNeeded()
        #expect(visibleSuggestionTexts(in: fixture.bar) == tenWords)
        #expect(fixture.bar.isSuggestionAreaScrollable)

        fixture.bar.updateSuggestions(currentWord: nil, suggestions: threeWords)
        fixture.bar.layoutIfNeeded()
        #expect(visibleSuggestionTexts(in: fixture.bar) == threeWords)
        #expect(fixture.bar.isSuggestionAreaScrollable == false)

        fixture.bar.updateSuggestions(currentWord: nil, suggestions: tenWords)
        fixture.bar.layoutIfNeeded()
        #expect(visibleSuggestionTexts(in: fixture.bar) == tenWords)
    }

    @Test("입력 중에는 0번 칸이 현재 단어이고 나머지가 후보")
    func test입력중에는_0번칸이현재단어이고_나머지가후보() {
        let fixture = makeFixture(acceptsRemoval: false)

        fixture.bar.updateSuggestions(currentWord: "hel", suggestions: ["hello", "help"])
        fixture.bar.layoutIfNeeded()

        #expect(visibleSuggestionTexts(in: fixture.bar) == ["\"hel\"", "hello", "help"])
    }

    @Test("후보가 없으면 후보 칸이 하나도 남지 않음")
    func test후보가없으면_후보칸이하나도남지않음() {
        let fixture = makeFixture(acceptsRemoval: false)

        fixture.bar.updateSuggestions(currentWord: nil, suggestions: [])
        fixture.bar.layoutIfNeeded()

        #expect(visibleSuggestionTexts(in: fixture.bar) == [])
        #expect(fixture.bar.isSuggestionAreaScrollable == false)
    }

    private struct Fixture {
        let bar: SuggestionBarView
        let keyboardHStackView: UIStackView
        let delegate: RemovalDelegateSpy
        let buttons: [SuggestionButtonView]
    }

    private func makeFixture(acceptsRemoval: Bool) -> Fixture {
        let keyboardHStackView = UIStackView()
        let bar = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        let delegate = RemovalDelegateSpy(acceptsRemoval: acceptsRemoval)
        bar.suggestionDelegate = delegate
        bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        bar.updateSuggestions(currentWord: nil, suggestions: ["오늘", "날씨", "좋다"])
        bar.layoutIfNeeded()
        return Fixture(
            bar: bar,
            keyboardHStackView: keyboardHStackView,
            delegate: delegate,
            buttons: typedSuggestionButtonViews(in: bar)
        )
    }
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

private func visibleSuggestionTexts(in bar: UIView) -> [String] {
    return typedSuggestionButtonViews(in: bar)
        .filter { !$0.isHidden && $0.hasText }
        .compactMap { $0.text }
}

private func center(of button: UIView, in bar: UIView) -> CGPoint {
    let frame = button.convert(button.bounds, to: bar)
    return CGPoint(x: frame.midX, y: frame.midY)
}

@MainActor
private final class RemovalDelegateSpy: SuggestionBarDelegate {
    private let acceptsRemoval: Bool
    private(set) var removalRequestIndexes: [Int] = []
    private(set) var selectedIndexes: [Int] = []

    init(acceptsRemoval: Bool) {
        self.acceptsRemoval = acceptsRemoval
    }

    func suggestionBar(_ bar: SuggestionBarView, didSelectSuggestionAt index: Int) {
        selectedIndexes.append(index)
    }

    func suggestionBar(_ bar: SuggestionBarView, shouldBeginRemovalAt index: Int) -> Bool {
        removalRequestIndexes.append(index)
        return acceptsRemoval
    }

    func suggestionBarDidTapUndo(_ bar: SuggestionBarView) {}
    func suggestionBarDidTapRedo(_ bar: SuggestionBarView) {}
    func suggestionBarDidTapClipboard(_ bar: SuggestionBarView) {}
}
