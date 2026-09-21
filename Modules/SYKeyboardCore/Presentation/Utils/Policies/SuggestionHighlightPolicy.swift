import CoreFoundation

enum SuggestionHighlightPolicy {

    struct State: Equatable {
        let highlightedSuggestionIndex: Int?
        let highlightedActionIndex: Int?

        static let none = State(
            highlightedSuggestionIndex: nil,
            highlightedActionIndex: nil
        )
    }

    static func resolve(
        previewSuggestionIndex: Int?,
        touchedSuggestionIndex: Int?,
        touchedActionIndex: Int?,
        suggestionCount: Int,
        actionCount: Int
    ) -> State {
        if let touchedSuggestionIndex,
           (0..<suggestionCount).contains(touchedSuggestionIndex) {
            return State(
                highlightedSuggestionIndex: touchedSuggestionIndex,
                highlightedActionIndex: nil
            )
        }

        if let touchedActionIndex,
           (0..<actionCount).contains(touchedActionIndex) {
            return State(
                highlightedSuggestionIndex: nil,
                highlightedActionIndex: touchedActionIndex
            )
        }

        if let previewSuggestionIndex,
           (0..<suggestionCount).contains(previewSuggestionIndex) {
            return State(
                highlightedSuggestionIndex: previewSuggestionIndex,
                highlightedActionIndex: nil
            )
        }

        return .none
    }
}

// MARK: - SuggestionScrollFadePolicy

/// 후보 가로 스크롤의 가장자리 페이드 표시 여부를 정하는 정책
enum SuggestionScrollFadePolicy {

    /// 부동소수 오차로 1pt도 안 되는 차이에 페이드가 켜지는 것을 막는 허용 오차
    static let edgeTolerance: CGFloat = 0.5

    struct State: Equatable {
        let showsLeadingFade: Bool
        let showsTrailingFade: Bool

        static let none = State(showsLeadingFade: false, showsTrailingFade: false)
    }

    /// - Parameters:
    ///   - contentOffsetX: 스크롤 뷰의 가로 오프셋
    ///   - viewportWidth: 스크롤 뷰 `bounds`의 너비
    ///   - contentWidth: 스크롤 뷰 `contentSize`의 너비
    /// - Returns: 남은 내용이 있는 방향만 `true`인 상태
    static func resolve(
        contentOffsetX: CGFloat,
        viewportWidth: CGFloat,
        contentWidth: CGFloat
    ) -> State {
        guard viewportWidth > 0,
              contentWidth > viewportWidth + edgeTolerance else { return .none }

        return State(
            showsLeadingFade: contentOffsetX > edgeTolerance,
            showsTrailingFade: contentOffsetX + viewportWidth < contentWidth - edgeTolerance
        )
    }
}
