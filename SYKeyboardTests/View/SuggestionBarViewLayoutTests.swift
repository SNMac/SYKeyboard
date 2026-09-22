//
//  SuggestionBarViewLayoutTests.swift
//  SYKeyboardTests
//

import UIKit
import Testing

import SYKeyboardAssets

@testable import SYKeyboardCore

@Suite("자동완성 바 후보 표시·레이아웃 검증")
@MainActor
struct SuggestionBarViewLayoutTests {

    @Test("후보 3개는 후보 영역이 스크롤되지 않음")
    func test후보3개는_후보영역이스크롤되지않음() {
        let fixture = makeSuggestionBarFixture(acceptsRemoval: false)

        // 레이아웃이 돌지 않아 폭이 0이면 아래 단언이 공허하게 통과한다
        #expect(fixture.buttons[0].bounds.width > 0)
        #expect(fixture.bar.isSuggestionAreaScrollable == false)
    }

    @Test("후보 3칸과 divider 2개가 후보 영역을 빈틈없이 채움")
    func test후보3칸과divider2개가_후보영역을빈틈없이채움() {
        let fixture = makeSuggestionBarFixture(acceptsRemoval: false)
        let widths = fixture.buttons.map { $0.bounds.width }

        #expect(widths.count == 3)
        for width in widths {
            #expect(width > 0)
            #expect(abs(width - widths[0]) < 0.5)
        }

        // 후보 3칸 + divider 2개가 후보 영역(뷰포트)을 정확히 채운다.
        // 등폭만 보면 각 칸이 뷰포트의 1/6이어도 통과하므로 1/3임을 함께 고정한다
        let frames = fixture.buttons.map { $0.convert($0.bounds, to: fixture.bar) }
        let span = frames[2].maxX - frames[0].minX
        let dividerTotal: CGFloat = 2
        #expect(abs(widths.reduce(0, +) + dividerTotal - span) < 0.5)

        // 기능 버튼이 모두 숨겨진 fixture라 뷰포트는 바 폭에서 스택 좌우 margin 1pt씩을 뺀 값이다
        #expect(abs(span - (fixture.bar.bounds.width - 2)) < 0.5)
    }

    @Test("후보 수가 10 → 3 → 10으로 바뀌어도 이전 후보가 남지 않음")
    func test후보수가10과3을오가도_이전후보가남지않음() {
        let fixture = makeSuggestionBarFixture(acceptsRemoval: false)
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
        let fixture = makeSuggestionBarFixture(acceptsRemoval: false)

        fixture.bar.updateSuggestions(currentWord: "hel", suggestions: ["hello", "help"])
        fixture.bar.layoutIfNeeded()

        #expect(visibleSuggestionTexts(in: fixture.bar) == ["\"hel\"", "hello", "help"])
    }

    @Test("후보가 없으면 후보 칸이 하나도 남지 않음")
    func test후보가없으면_후보칸이하나도남지않음() {
        let fixture = makeSuggestionBarFixture(acceptsRemoval: false)

        fixture.bar.updateSuggestions(currentWord: nil, suggestions: [])
        fixture.bar.layoutIfNeeded()

        #expect(visibleSuggestionTexts(in: fixture.bar) == [])
        #expect(fixture.bar.isSuggestionAreaScrollable == false)
    }

    @Test("후보가 10개여도 화면 밖 후보가 undo 버튼 탭을 가로채지 않음")
    func test후보가10개여도_화면밖후보가_undo버튼탭을가로채지않음() {
        let fixture = makeSuggestionBarFixture(acceptsRemoval: true)
        fixture.bar.updateSuggestions(
            currentWord: nil,
            suggestions: (1...10).map { "단어\($0)" }
        )
        fixture.bar.updateUndoRedoControls(isVisible: true, canUndo: true, canRedo: true)
        fixture.bar.layoutIfNeeded()

        // undo 버튼 중심. 스크롤 뷰 오른쪽 바깥이라 잘린 후보가 덮고 있던 자리다
        let undoCenter = CGPoint(
            x: fixture.bar.bounds.maxX - 1 - KeyboardLayoutFigure.undoRedoButtonWidth * 1.5 - 1,
            y: fixture.bar.bounds.midY
        )

        fixture.bar.beginTouchInteraction(at: undoCenter)
        fixture.bar.handleRemovalLongPress()
        fixture.bar.endTouchInteraction(at: undoCenter, playsFeedback: false)

        #expect(fixture.delegate.selectedIndexes == [])
        #expect(fixture.delegate.removalRequestIndexes == [])
        #expect(fixture.delegate.undoTapCount == 1)
    }

    @Test("첫 updateSuggestions 전에 레이아웃해도 divider 풀을 넘겨 읽지 않음")
    func test첫후보갱신전_레이아웃은_divider풀을넘겨읽지않음() throws {
        // 후보가 0개여도 후보 영역은 3칸으로 보여야 하므로 divider 격자는 2개를 요구한다.
        // 반면 풀은 updateSuggestions가 처음 불릴 때까지 비어 있다. layoutSuggestionContent()가
        // 격자 개수만 믿고 pooledDividers를 훑으면 여기서 인덱스 범위를 넘는다
        #expect(SuggestionDividerPolicy.dividerCount(forSuggestionCount: 0) == 2)

        let bar = SuggestionBarView(keyboardHStackView: UIStackView())
        bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)

        // updateSuggestions 없이 곧바로 레이아웃한다. UIKit이 첫 후보 갱신보다 먼저
        // layoutSubviews()를 부르는 경로를 그대로 재현한다
        bar.layoutIfNeeded()

        // 뷰포트 폭이 0이면 layoutSuggestionContent()가 divider 배치 전에 빠져나가
        // 범위 초과 경로를 밟지 않은 채 통과한다. 실제로 배치까지 갔는지 먼저 확인한다
        let scrollView = try #require(suggestionScrollView(in: bar))
        #expect(scrollView.bounds.width > 0)

        // 후보가 0개면 content가 뷰포트를 넘지 않아 스크롤도 생기지 않는다.
        // 뷰포트 폭은 bar 폭에서 divider 자리를 뺀 값이라 bar 폭과 같지 않다
        #expect(scrollView.contentSize.width == scrollView.bounds.width)
    }
}

private func visibleSuggestionTexts(in bar: UIView) -> [String] {
    return typedSuggestionButtonViews(in: bar)
        .filter { !$0.isHidden && $0.hasText }
        .compactMap { $0.text }
}

/// 후보 스크롤 뷰.
///
/// production의 private subview 구조에 의존한다. 구조가 바뀌어 여기서 nil이 나오면
/// 억지로 맞춰 고치지 말고 관련 테스트를 지우고 실기기 수동 확인으로 옮긴다
private func suggestionScrollView(in bar: UIView) -> UIScrollView? {
    var stack: [UIView] = bar.subviews
    while let view = stack.popLast() {
        if let found = view as? UIScrollView {
            return found
        }
        stack.append(contentsOf: view.subviews)
    }
    return nil
}
