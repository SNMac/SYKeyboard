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
