//
//  HangeulCompletionMatchScenarioTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Testing

@testable import HangeulKeyboardCore
@testable import SYKeyboardCore

/// 조합 중 화면 텍스트에 NGram 완성 접두어 규칙을 적용한 결과를 자판별로 고정한다.
/// 마지막 상태는 입력이 목표와 같아 완성이 아니다(0번 칸이 보여준다)
@Suite("자판별 조합 중 NGram 완성 접두어 판정 시나리오")
struct HangeulCompletionMatchScenarioTests {

    // MARK: - Properties

    private let automata: HangeulAutomataProtocol = HangeulAutomata()

    // MARK: - Tests

    @Test("두벌식은 받침·겹받침이 다음 글자 초성이 되는 동안에도 목표를 완성 후보로 봄")
    func test두벌식은_받침과겹받침이_다음글자초성이되는동안에도_목표를완성후보로봄() {
        #expect(steps(DubeolsikProcessor(automata: automata), keys: ["ㅋ", "ㅣ", "ㅂ", "ㅗ", "ㄷ", "ㅡ"], target: "키보드") == [
            Step("ㅋ", true), Step("키", true), Step("킵", true), Step("키보", true), Step("키볻", true), Step("키보드", false)
        ])
        #expect(steps(DubeolsikProcessor(automata: automata), keys: ["ㄷ", "ㅏ", "ㄹ", "ㄱ", "ㅑ", "ㄹ"], target: "달걀") == [
            Step("ㄷ", true), Step("다", true), Step("달", true), Step("닭", true), Step("달갸", true), Step("달걀", false)
        ])
        #expect(steps(DubeolsikProcessor(automata: automata), keys: ["ㅇ", "ㅏ", "ㄴ", "ㅈ", "ㅜ"], target: "안주") == [
            Step("ㅇ", true), Step("아", true), Step("안", true), Step("앉", true), Step("안주", false)
        ])
    }

    @Test("나랏글은 받침·겹받침은 유지하고 획추가 전 상태에서만 한 타 빠짐")
    func test나랏글은_받침과겹받침은유지하고_획추가전상태에서만_한타빠짐() {
        #expect(steps(NaratgeulProcessor(automata: automata), keys: ["ㄱ", "획", "ㅣ", "ㅁ", "획", "ㅗ", "ㄴ", "획", "ㅡ"], target: "키보드") == [
            Step("ㄱ", false), Step("ㅋ", true), Step("키", true), Step("킴", false), Step("킵", true),
            Step("키보", true), Step("키본", false), Step("키볻", true), Step("키보드", false)
        ])
        #expect(steps(NaratgeulProcessor(automata: automata), keys: ["ㄴ", "획", "ㅏ", "ㄹ", "ㄱ", "ㅏ", "획", "ㄹ"], target: "달걀") == [
            Step("ㄴ", false), Step("ㄷ", true), Step("다", true), Step("달", true), Step("닭", true),
            Step("달가", false), Step("달갸", true), Step("달걀", false)
        ])
        #expect(steps(NaratgeulProcessor(automata: automata), keys: ["ㅇ", "ㅏ", "ㄴ", "ㅅ", "획", "ㅜ"], target: "안주") == [
            Step("ㅇ", true), Step("아", true), Step("안", true), Step("안ㅅ", false), Step("앉", true), Step("안주", false)
        ])
    }

    @Test("천지인은 받침·겹받침·조합 중 ㆍ는 유지하고 모음 조합과 자음 순환 전 상태에서만 한 타 빠짐")
    func test천지인은_받침과겹받침과조합중ㆍ는유지하고_모음조합과자음순환전상태에서만_한타빠짐() {
        #expect(steps(CheonjiinProcessor(automata: automata), keys: ["ㄱ", "ㄱ", "ㅣ", "ㅂ", "ㆍ", "ㅡ", "ㄷ", "ㅡ"], target: "키보드") == [
            Step("ㄱ", false), Step("ㅋ", true), Step("키", true), Step("킵", true), Step("킵ㆍ", true),
            Step("키보", true), Step("키볻", true), Step("키보드", false)
        ])
        #expect(steps(CheonjiinProcessor(automata: automata), keys: ["ㄷ", "ㅣ", "ㆍ", "ㄴ", "ㄴ", "ㄱ", "ㅣ", "ㆍ", "ㆍ", "ㄴ", "ㄴ"], target: "달걀") == [
            Step("ㄷ", true), Step("디", false), Step("다", true), Step("단", false), Step("달", true), Step("닭", true),
            Step("달기", false), Step("달가", false), Step("달갸", true), Step("달갼", false), Step("달걀", false)
        ])
        #expect(steps(CheonjiinProcessor(automata: automata), keys: ["ㅇ", "ㅣ", "ㆍ", "ㄴ", "ㅈ", "ㅡ", "ㆍ"], target: "안주") == [
            Step("ㅇ", true), Step("이", false), Step("아", true), Step("안", true), Step("앉", true),
            Step("안즈", false), Step("안주", false)
        ])
    }

    // MARK: - Helpers

    private struct Step: Equatable, CustomStringConvertible {
        let text: String
        let isCompletion: Bool

        init(_ text: String, _ isCompletion: Bool) {
            self.text = text
            self.isCompletion = isCompletion
        }

        var description: String { "\(text):\(isCompletion ? "T" : "F")" }
    }

    /// 키를 하나씩 넣으며 화면 텍스트와 목표 단어 완성 판정을 모은다
    private func steps(_ processor: HangeulProcessable, keys: [String], target: String) -> [Step] {
        let harness = HangeulCompositionTestHarness(processor: processor)
        return keys.map { key in
            harness.input(key)
            let isCompletion = PredictiveTextCompletionMatchPolicy(typedWord: harness.text)?.isCompletion(target) == true
            return Step(harness.text, isCompletion)
        }
    }
}
