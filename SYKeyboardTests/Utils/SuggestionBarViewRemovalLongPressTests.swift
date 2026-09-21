//
//  SuggestionBarViewRemovalLongPressTests.swift
//  SYKeyboardTests
//

import UIKit
import Testing

import SYKeyboardAssets

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

    @Test("누른 후보를 벗어나면 삭제를 요청하지 않음")
    func test누른후보를벗어나면_삭제를요청하지않음() {
        let fixture = makeFixture(acceptsRemoval: true)
        let startPoint = center(of: fixture.buttons[0], in: fixture.bar)
        let endPoint = center(of: fixture.buttons[2], in: fixture.bar)

        fixture.bar.beginTouchInteraction(at: startPoint)
        fixture.bar.moveTouchInteraction(to: endPoint)
        fixture.bar.handleRemovalLongPress()

        #expect(fixture.delegate.removalRequestIndexes == [])
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
}

@Suite("자동완성 바 후보 표시·레이아웃 검증")
@MainActor
struct SuggestionBarViewLayoutTests {

    @Test("후보 3개는 후보 영역이 스크롤되지 않음")
    func test후보3개는_후보영역이스크롤되지않음() {
        let fixture = makeFixture(acceptsRemoval: false)

        // 레이아웃이 돌지 않아 폭이 0이면 아래 단언이 공허하게 통과한다
        #expect(fixture.buttons[0].bounds.width > 0)
        #expect(fixture.bar.isSuggestionAreaScrollable == false)
    }

    @Test("후보 3칸과 divider 2개가 후보 영역을 빈틈없이 채움")
    func test후보3칸과divider2개가_후보영역을빈틈없이채움() {
        let fixture = makeFixture(acceptsRemoval: false)
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

    @Test("후보가 3칸을 채워야 마지막 후보가 오른쪽 끝 구분선을 지움")
    func test후보가3칸을채워야_마지막후보가_오른쪽끝구분선을지움() {
        let fixture = makeFixture(acceptsRemoval: false)
        fixture.bar.updateUndoRedoControls(isVisible: true, canUndo: true, canRedo: true)
        // 스택이 undo/redo 자리를 잡아야 후보 뷰포트 폭이 확정된다. 한 번의 레이아웃으로는
        // 후보 버튼이 기능 버튼을 숨겼던 폭 그대로 남으므로 한 번 더 돌린다
        fixture.bar.layoutIfNeeded()
        fixture.bar.setNeedsLayout()
        fixture.bar.layoutIfNeeded()

        let divider = trailingSuggestionAreaDivider(in: fixture.bar)
        #expect(divider != nil)

        // 후보 3개: 마지막 후보가 오른쪽 끝 divider와 인접하므로 누르면 지운다
        let lastOfThree = typedSuggestionButtonViews(in: fixture.bar)[2]
        fixture.bar.beginTouchInteraction(at: center(of: lastOfThree, in: fixture.bar))
        #expect(lastOfThree.isHighlighted)
        #expect(divider?.backgroundColor == UIColor.clear)
        fixture.bar.cancelTouchInteraction()

        // 후보 1개: 그 후보는 0번 열이라 오른쪽 끝 divider와 인접하지 않는다
        fixture.bar.updateSuggestions(currentWord: nil, suggestions: ["안농"])
        fixture.bar.layoutIfNeeded()

        let onlyButton = typedSuggestionButtonViews(in: fixture.bar)[0]
        fixture.bar.beginTouchInteraction(at: center(of: onlyButton, in: fixture.bar))

        #expect(onlyButton.isHighlighted)
        #expect(divider?.backgroundColor == UIColor.suggestionDividerColor)
    }

    @Test("후보가 갱신되면 후보 사이 구분선 색도 함께 갱신됨")
    func test후보가갱신되면_후보사이구분선색도함께갱신됨() {
        let fixture = makeBoundaryFixture(suggestionCount: 3)
        let buttons = typedSuggestionButtonViews(in: fixture.bar)

        // 마지막 후보를 누르면 그 앞 divider가 지워진다
        fixture.bar.beginTouchInteraction(at: center(of: buttons[2], in: fixture.bar))
        #expect(buttons[2].isHighlighted)
        #expect(suggestionDividers(in: fixture.bar)[1].backgroundColor == UIColor.clear)

        // 후보가 1개로 줄면 눌린 인덱스가 범위를 벗어나 하이라이트가 사라진다.
        // 빈 칸에도 divider는 남으므로(3칸 격자) 색이 낡은 채로 보이면 안 된다
        fixture.bar.updateSuggestions(currentWord: nil, suggestions: ["안농"])

        let dividers = suggestionDividers(in: fixture.bar)
        #expect(dividers.count >= 2)
        #expect(dividers[1].isHidden == false)
        #expect(dividers[1].backgroundColor == UIColor.suggestionDividerColor)
    }

    @Test("후보가 없으면 후보 칸이 하나도 남지 않음")
    func test후보가없으면_후보칸이하나도남지않음() {
        let fixture = makeFixture(acceptsRemoval: false)

        fixture.bar.updateSuggestions(currentWord: nil, suggestions: [])
        fixture.bar.layoutIfNeeded()

        #expect(visibleSuggestionTexts(in: fixture.bar) == [])
        #expect(fixture.bar.isSuggestionAreaScrollable == false)
    }

    @Test("후보가 10개여도 화면 밖 후보가 undo 버튼 탭을 가로채지 않음")
    func test후보가10개여도_화면밖후보가_undo버튼탭을가로채지않음() {
        let fixture = makeFixture(acceptsRemoval: true)
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

@MainActor
private struct Fixture {
    let bar: SuggestionBarView
    let keyboardHStackView: UIStackView
    let delegate: SuggestionBarDelegateSpy
    let buttons: [SuggestionButtonView]
}

@MainActor
private func makeFixture(acceptsRemoval: Bool) -> Fixture {
    let keyboardHStackView = UIStackView()
    let bar = SuggestionBarView(keyboardHStackView: keyboardHStackView)
    let delegate = SuggestionBarDelegateSpy(acceptsRemoval: acceptsRemoval)
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

/// 후보 영역 오른쪽에 붙은 바 끝 divider. 후보 스크롤 뷰의 형제 중 스크롤 뷰보다 오른쪽에 있는
/// 가장 가까운 순수 `UIView`다. undo/redo 버튼은 별도 타입이라 걸러진다
private func trailingSuggestionAreaDivider(in bar: UIView) -> UIView? {
    var scrollView: UIScrollView?
    var stack: [UIView] = bar.subviews
    while let view = stack.popLast() {
        if let found = view as? UIScrollView {
            scrollView = found
            break
        }
        stack.append(contentsOf: view.subviews)
    }

    guard let scrollView, let container = scrollView.superview else { return nil }

    return container.subviews
        .filter {
            type(of: $0) == UIView.self
                && !$0.isHidden
                && $0.frame.minX >= scrollView.frame.maxX
        }
        .min { $0.frame.minX < $1.frame.minX }
}

private func visibleSuggestionTexts(in bar: UIView) -> [String] {
    return typedSuggestionButtonViews(in: bar)
        .filter { !$0.isHidden && $0.hasText }
        .compactMap { $0.text }
}

/// 후보 스크롤 뷰. 아래 divider 헬퍼들의 기준점이다.
///
/// 이 헬퍼들은 production의 private subview 구조에 의존한다. 구조가 바뀌어 여기서 nil이 나오면
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

/// 클립보드·undo·redo 버튼과 경계 divider가 모두 보이는 fixture
@MainActor
private func makeBoundaryFixture(suggestionCount: Int) -> Fixture {
    let fixture = makeFixture(acceptsRemoval: false)
    fixture.bar.updateSuggestions(
        currentWord: nil,
        suggestions: (1...suggestionCount).map { "단어\($0)" }
    )
    fixture.bar.updateClipboardControl(isVisible: true, isPanelVisible: false)
    fixture.bar.updateUndoRedoControls(isVisible: true, canUndo: true, canRedo: true)
    // 스택이 기능 버튼 자리를 잡아야 후보 뷰포트 폭이 확정된다. 한 번의 레이아웃으로는
    // 후보 버튼이 기능 버튼을 숨겼던 폭 그대로 남으므로 한 번 더 돌린다
    fixture.bar.layoutIfNeeded()
    fixture.bar.setNeedsLayout()
    fixture.bar.layoutIfNeeded()

    return Fixture(
        bar: fixture.bar,
        keyboardHStackView: fixture.keyboardHStackView,
        delegate: fixture.delegate,
        buttons: typedSuggestionButtonViews(in: fixture.bar)
    )
}

/// 후보 사이 divider. 스크롤 뷰 안의 순수 `UIView`를 왼쪽부터 돌려준다
private func suggestionDividers(in bar: UIView) -> [UIView] {
    guard let scrollView = suggestionScrollView(in: bar),
          let content = scrollView.subviews.first else { return [] }

    return content.subviews
        .filter { type(of: $0) == UIView.self }
        .sorted { $0.frame.minX < $1.frame.minX }
}
