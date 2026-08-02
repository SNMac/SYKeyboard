//
//  MathExpressionCompletionEvaluatorTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/30/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("수식 결과 자동완성 계산 검증")
struct MathExpressionCompletionEvaluatorTests {

    @Test("등호로 끝나는 사칙연산 수식은 원문과 결과를 반환")
    func test등호로끝나는사칙연산수식은_원문과결과를반환() {
        let completion = MathExpressionCompletionEvaluator.completion(for: "3-1=")

        #expect(completion?.displayText == "3-1=2")
        #expect(completion?.insertText == "2")
    }

    @Test("수식 안의 공백은 계산에서 무시하고 표시 원문은 유지")
    func test수식안의공백은_계산에서무시하고표시원문은유지() {
        let completion = MathExpressionCompletionEvaluator.completion(for: "3 - 1 =")

        #expect(completion?.displayText == "3 - 1 =2")
        #expect(completion?.insertText == "2")
        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: "( 3 + 2 ) * 2 ="
            )?.insertText == "10"
        )
    }

    @Test("앞쪽 숫자 문맥 뒤 마지막 수식만 계산")
    func test앞쪽숫자문맥뒤_마지막수식만계산() {
        let spacedCompletion = MathExpressionCompletionEvaluator.completion(
            for: "1 2 + 3 ="
        )
        #expect(spacedCompletion?.expressionText == "2 + 3 =")
        #expect(spacedCompletion?.displayText == "2 + 3 =5")
        #expect(spacedCompletion?.insertText == "5")

        let compactCompletion = MathExpressionCompletionEvaluator.completion(
            for: "1 2+3="
        )
        #expect(compactCompletion?.expressionText == "2+3=")
        #expect(compactCompletion?.displayText == "2+3=5")
        #expect(compactCompletion?.insertText == "5")
    }

    @Test("소수점 쉼표와 문자 문맥의 숫자 사이 공백은 거부")
    func test소수점쉼표와문자문맥의_숫자사이공백은거부() {
        for expression in [
            "1 . 2+3=",
            "1, 000+2=",
            "memo 2 3+1=",
            "x 1 2+3=",
            "1 + 2 3+4="
        ] {
            #expect(
                MathExpressionCompletionEvaluator.completion(
                    for: expression
                ) == nil
            )
        }
    }

    @Test("숫자 구성 문자 사이 탭과 NBSP도 거부")
    func test숫자구성문자사이탭과NBSP도거부() {
        for expression in ["1\t2+3=", "1\u{00A0}2+3="] {
            #expect(MathExpressionCompletionEvaluator.completion(for: expression) == nil)
        }
    }

    @Test("소수점 연산과 곱셈 나눗셈 우선순위를 계산")
    func test소수점연산과_곱셈나눗셈우선순위를계산() {
        let completion = MathExpressionCompletionEvaluator.completion(for: "1.5+2*3=")

        #expect(completion?.displayText == "1.5+2*3=7.5")
        #expect(completion?.insertText == "7.5")
    }

    @Test("올바른 천 단위 쉼표 숫자는 계산하고 입력 원문을 유지")
    func test올바른천단위쉼표숫자는_계산하고입력원문을유지() {
        let completion = MathExpressionCompletionEvaluator.completion(
            for: "1,000 / 4="
        )

        #expect(completion?.expressionText == "1,000 / 4=")
        #expect(completion?.displayText == "1,000 / 4=250")
    }

    @Test("잘못된 천 단위 쉼표와 소수부 쉼표는 후보를 만들지 않음")
    func test잘못된천단위쉼표와_소수부쉼표는후보를만들지않음() {
        #expect(MathExpressionCompletionEvaluator.completion(for: "10,00+1=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "1234,567+1=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "1,000.0,1+1=") == nil)
    }

    @Test("지원하는 곱셈과 나눗셈 기호를 동일한 연산으로 계산")
    func test지원하는곱셈과나눗셈기호를_동일한연산으로계산() {
        for multiplicationOperator in ["×", "⋅", "*", "x", "X"] {
            #expect(
                MathExpressionCompletionEvaluator.completion(
                    for: "6\(multiplicationOperator)2="
                )?.insertText == "12"
            )
        }

        for divisionOperator in ["÷", "/"] {
            #expect(
                MathExpressionCompletionEvaluator.completion(
                    for: "6\(divisionOperator)2="
                )?.insertText == "3"
            )
        }
    }

    @Test("소수점으로 끝난 숫자는 계산하고 숫자 없는 소수점은 거부")
    func test소수점으로끝난숫자는_계산하고숫자없는소수점은거부() {
        #expect(
            MathExpressionCompletionEvaluator.completion(for: "1.+2=")?.insertText == "3"
        )
        #expect(MathExpressionCompletionEvaluator.completion(for: ".+2=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "1..0+2=") == nil)
    }

    @Test("수식이 아닌 텍스트와 불완전한 수식은 후보를 만들지 않음")
    func test수식이아닌텍스트와_불완전한수식은후보를만들지않음() {
        #expect(MathExpressionCompletionEvaluator.completion(for: "abc=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "3=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "3+=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "3/0=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "3-1") == nil)
    }

    @Test("마지막 등호 외에 등호가 남아 있으면 후보를 만들지 않음")
    func test마지막등호외에_등호가남아있으면후보를만들지않음() {
        #expect(MathExpressionCompletionEvaluator.completion(for: "3+1=4=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "1=2+3=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "3+1==") == nil)
    }

    @Test("앞쪽 음수만 허용하고 중간 부호 연속은 수식 후보를 만들지 않음")
    func test앞쪽음수만허용하고_중간부호연속은수식후보를만들지않음() {
        let completion = MathExpressionCompletionEvaluator.completion(for: "-3+1=")

        #expect(completion?.displayText == "-3+1=-2")
        #expect(completion?.insertText == "-2")
        #expect(MathExpressionCompletionEvaluator.completion(for: "+3+1=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "--3+1=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "3++1=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "3+-1=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "3*-1=") == nil)
    }

    @Test("소중대괄호는 우선순위를 지켜 계산")
    func test소중대괄호는_우선순위를지켜계산() {
        #expect(MathExpressionCompletionEvaluator.completion(for: "(3+2)*2=")?.displayText == "(3+2)*2=10")
        #expect(MathExpressionCompletionEvaluator.completion(for: "[3+2]*2=")?.displayText == "[3+2]*2=10")
        #expect(MathExpressionCompletionEvaluator.completion(for: "{3+2}*2=")?.displayText == "{3+2}*2=10")
        #expect(MathExpressionCompletionEvaluator.completion(for: "{[3+2]*(4-1)}=")?.displayText == "{[3+2]*(4-1)}=15")
    }

    @Test("괄호 쌍이 맞지 않으면 수식 후보를 만들지 않음")
    func test괄호쌍이맞지않으면_수식후보를만들지않음() {
        #expect(MathExpressionCompletionEvaluator.completion(for: "(3+2]=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "[3+2)=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "(3+2=") == nil)
    }

    @Test("소수 결과는 최대 세 자리까지 반올림")
    func test소수결과는_최대세자리까지반올림() {
        #expect(MathExpressionCompletionEvaluator.completion(for: "2/3=")?.displayText == "2/3=0.667")
        #expect(MathExpressionCompletionEvaluator.completion(for: "1.2345+0=")?.displayText == "1.2345+0=1.235")
        #expect(MathExpressionCompletionEvaluator.completion(for: "1.2+0=")?.displayText == "1.2+0=1.2")
    }

    @Test("일반 결과는 천 단위 쉼표와 최대 소수 셋째 자리로 표시")
    func test일반결과는_천단위쉼표와최대소수셋째자리로표시() {
        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: "1,000 * 1,000="
            )?.displayText == "1,000 * 1,000=1,000,000"
        )
        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: "1234567.8912+0="
            )?.insertText == "1,234,567.891"
        )
    }

    @Test("10의 10제곱 미만은 일반 표기하고 이상은 유효숫자 네 자리 과학 표기")
    func test큰결과는_유효숫자네자리과학표기로표시() {
        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: "9999999999+0="
            )?.insertText == "9,999,999,999"
        )
        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: "10*1234567890="
            )?.insertText == "1.235×10¹⁰"
        )
        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: "-10*1234567890="
            )?.insertText == "-1.235×10¹⁰"
        )
        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: "999999999999999999999+1="
            )?.insertText == "1×10²¹"
        )
    }

    @Test("과학 표기 가수가 십으로 반올림되면 지수를 올림")
    func test과학표기가수가십으로반올림되면_지수를올림() {
        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: "99996000000+0="
            )?.insertText == "1×10¹¹"
        )
    }

    @Test("유한하지 않은 숫자 토큰은 외부 연산 결과가 유한해도 거부")
    func test유한하지않은숫자토큰은_외부연산결과가유한해도거부() {
        let overflowingNumber = String(repeating: "9", count: 400)

        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: "1/\(overflowingNumber)="
            ) == nil
        )
    }

    @Test("유한 피연산자의 중간 연산 overflow는 외부 연산 결과가 유한해도 거부")
    func test유한피연산자의중간연산Overflow는_외부연산결과가유한해도거부() {
        let largeFiniteNumber = String(repeating: "9", count: 308)
        let smallFiniteNumber = "0." + String(repeating: "0", count: 307) + "1"
        let expressions = [
            "1/(\(largeFiniteNumber)+\(largeFiniteNumber))=",
            "1/(\(largeFiniteNumber)-(0-\(largeFiniteNumber)))=",
            "1/(\(largeFiniteNumber)*2)=",
            "1/(2/\(smallFiniteNumber))="
        ]

        for expression in expressions {
            #expect(
                MathExpressionCompletionEvaluator.completion(
                    for: expression
                ) == nil
            )
        }
    }
}
