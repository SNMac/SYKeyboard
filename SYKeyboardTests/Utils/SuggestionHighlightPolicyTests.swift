import Testing

@testable import SYKeyboardCore

@Suite("자동완성 highlight 정책 검증")
struct SuggestionHighlightPolicyTests {

    @Test("preview는 해당 후보만 강조")
    func testPreviewSuggestion() {
        let state = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 1,
            touchedSuggestionIndex: nil,
            touchedActionIndex: nil,
            suggestionCount: 3,
            actionCount: 2
        )

        #expect(state.highlightedSuggestionIndex == 1)
        #expect(state.highlightedActionIndex == nil)
    }

    @Test("후보 touch는 preview를 일시 대체하고 touch 종료 시 preview가 복원")
    func testSuggestionTouchOverridesPreview() {
        let touched = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 1,
            touchedSuggestionIndex: 2,
            touchedActionIndex: nil,
            suggestionCount: 3,
            actionCount: 2
        )
        let restored = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 1,
            touchedSuggestionIndex: nil,
            touchedActionIndex: nil,
            suggestionCount: 3,
            actionCount: 2
        )

        #expect(touched.highlightedSuggestionIndex == 2)
        #expect(restored.highlightedSuggestionIndex == 1)
    }

    @Test("action touch는 preview를 가리고 action만 강조")
    func testActionTouchOverridesPreview() {
        let state = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 1,
            touchedSuggestionIndex: nil,
            touchedActionIndex: 0,
            suggestionCount: 3,
            actionCount: 2
        )

        #expect(state.highlightedSuggestionIndex == nil)
        #expect(state.highlightedActionIndex == 0)
    }

    @Test("nil과 범위 밖 index는 강조하지 않음")
    func testNilAndOutOfRangeIndexes() {
        let nilState = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: nil,
            touchedSuggestionIndex: nil,
            touchedActionIndex: nil,
            suggestionCount: 3,
            actionCount: 2
        )
        let invalidState = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 3,
            touchedSuggestionIndex: -1,
            touchedActionIndex: 2,
            suggestionCount: 3,
            actionCount: 2
        )

        #expect(nilState == .none)
        #expect(invalidState == .none)
    }
}
