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
        let fixture = makeSuggestionBarFixture(acceptsRemoval: true)
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
        let fixture = makeSuggestionBarFixture(acceptsRemoval: false)
        let point = center(of: fixture.buttons[1], in: fixture.bar)

        fixture.bar.beginTouchInteraction(at: point)
        fixture.bar.handleRemovalLongPress()
        fixture.bar.endTouchInteraction(at: point, playsFeedback: false)

        #expect(fixture.delegate.removalRequestIndexes == [1])
        #expect(fixture.delegate.selectedIndexes == [1])
    }

    @Test("누른 후보를 벗어나면 삭제를 요청하지 않음")
    func test누른후보를벗어나면_삭제를요청하지않음() {
        let fixture = makeSuggestionBarFixture(acceptsRemoval: true)
        let startPoint = center(of: fixture.buttons[0], in: fixture.bar)
        let endPoint = center(of: fixture.buttons[2], in: fixture.bar)

        fixture.bar.beginTouchInteraction(at: startPoint)
        fixture.bar.moveTouchInteraction(to: endPoint)
        fixture.bar.handleRemovalLongPress()

        #expect(fixture.delegate.removalRequestIndexes == [])
    }

    @Test("터치가 끝난 뒤 타이머가 늦게 불려도 삭제를 요청하지 않음")
    func test터치가끝난뒤_타이머가늦게불려도_삭제를요청하지않음() {
        let fixture = makeSuggestionBarFixture(acceptsRemoval: true)
        let point = center(of: fixture.buttons[1], in: fixture.bar)

        fixture.bar.beginTouchInteraction(at: point)
        fixture.bar.endTouchInteraction(at: point, playsFeedback: false)
        fixture.bar.handleRemovalLongPress()

        #expect(fixture.delegate.selectedIndexes == [1])
        #expect(fixture.delegate.removalRequestIndexes == [])
    }

    @Test("터치 취소는 하이라이트와 삭제 타이머를 함께 취소")
    func test터치취소는_하이라이트와삭제타이머를_함께취소() {
        let fixture = makeSuggestionBarFixture(acceptsRemoval: true)
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
}
