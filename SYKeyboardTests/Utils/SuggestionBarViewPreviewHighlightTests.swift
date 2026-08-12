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
