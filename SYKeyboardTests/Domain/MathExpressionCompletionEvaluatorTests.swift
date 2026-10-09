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

    @Test("수식으로 볼 수 없거나 계산할 수 없는 입력은 후보를 만들지 않음",
          arguments: [
            // (reason, expression)
            ("소수점 사이 공백은 거부", "1 . 2+3="),
            ("천 단위 쉼표 뒤 공백은 거부", "1, 000+2="),
            ("문자 문맥 뒤 숫자 사이 공백은 거부", "memo 2 3+1="),
            ("곱셈 별칭 x 뒤 숫자 사이 공백은 거부", "x 1 2+3="),
            ("연산자 뒤 숫자 사이 공백은 거부", "1 + 2 3+4="),
            ("숫자 구성 문자 사이 탭은 거부", "1\t2+3="),
            ("숫자 구성 문자 사이 NBSP는 거부", "1\u{00A0}2+3="),
            ("잘못된 선행 소수점: 숫자 없는 소수점", ".+1="),
            ("잘못된 선행 소수점: 소수점 연속", "..5+1="),
            ("잘못된 선행 소수점: 정수부 뒤 소수점 연속", "1..5+1="),
            ("이전 등식 뒤 숫자 공백이 여러 번이면 더 짧은 수식을 오탐지하지 않음", "3+1=4 2 3+4="),
            ("잘못된 천 단위 쉼표: 두 자리 묶음", "10,00+1="),
            ("잘못된 천 단위 쉼표: 네 자리 선행 묶음", "1234,567+1="),
            ("소수부 쉼표는 거부", "1,000.0,1+1="),
            ("수식이 아닌 텍스트", "abc="),
            ("불완전한 수식: 숫자 하나뿐", "3="),
            ("불완전한 수식: 연산자 뒤 피연산자 없음", "3+="),
            ("불완전한 수식: 0으로 나눔", "3/0="),
            ("불완전한 수식: 등호 없음", "3-1"),
            ("마지막 등호 외에 등호가 남아 있음: 결과 뒤 등호", "3+1=4="),
            ("마지막 등호 외에 등호가 남아 있음: 앞쪽 등식", "1=2+3="),
            ("마지막 등호 외에 등호가 남아 있음: 등호 연속", "3+1=="),
            ("괄호 쌍이 맞지 않음: ( ]", "(3+2]="),
            ("괄호 쌍이 맞지 않음: [ )", "[3+2)="),
            ("괄호 쌍이 맞지 않음: 닫는 괄호 없음", "(3+2="),
            ("제한보다 긴 숫자(400자리)는 거부", "1/" + String(repeating: "9", count: 400) + "="),
            ("유한 숫자(308자리)라도 중간 결과가 넘치면 거부", "1/(" + String(repeating: "9", count: 308) + "*2)=")
          ])
    func test수식이아닌입력은_후보를만들지않음(reason: String, expression: String) {
        #expect(
            MathExpressionCompletionEvaluator.completion(for: expression) == nil,
            "\(reason)"
        )
    }

    @Test("소수점 연산과 곱셈 나눗셈 우선순위를 계산")
    func test소수점연산과_곱셈나눗셈우선순위를계산() {
        let completion = MathExpressionCompletionEvaluator.completion(for: "1.5+2*3=")

        #expect(completion?.displayText == "1.5+2*3=7.5")
        #expect(completion?.insertText == "7.5")
    }

    private static let depth16Group = String(repeating: "(", count: 16) + "1+1" + String(repeating: ")", count: 16)

    @Test("선행 소수점·음수 0·곱셈 나눗셈 기호·큰 결과 표기·깊은 괄호 그룹의 계산 결과 문자열",
          arguments: [
            // (label, expression, expectedInsertText)
            ("정수부를 생략한 소수를 0으로 시작하는 소수로 계산", ".5+1=", "1.5"),
            ("정수부를 생략한 음수 소수를 계산", "-.5+1=", "0.5"),
            ("반올림된 음수 0은 부호 없이 표시", "-0.0001+0=", "0"),
            ("곱셈 기호 ×", "6×2=", "12"),
            ("곱셈 기호 ⋅", "6⋅2=", "12"),
            ("곱셈 기호 *", "6*2=", "12"),
            ("곱셈 별칭 x", "6x2=", "12"),
            ("곱셈 별칭 X", "6X2=", "12"),
            ("나눗셈 기호 ÷", "6÷2=", "3"),
            ("나눗셈 기호 /", "6/2=", "3"),
            ("10의 10제곱 미만은 일반 표기", "9999999999+0=", "9,999,999,999"),
            ("10의 10제곱 이상은 유효숫자 네 자리 과학 표기", "10*1234567890=", "1.235×10¹⁰"),
            ("음수도 유효숫자 네 자리 과학 표기", "-10*1234567890=", "-1.235×10¹⁰"),
            ("가수가 정수면 소수 없이 과학 표기", "999999999999999999999+1=", "1×10²¹"),
            ("과학 표기 가수가 십으로 반올림되면 지수를 올림", "99996000000+0=", "1×10¹¹"),
            ("동일 깊이(16) 괄호 그룹을 연산자로 연결해 계산",
             MathExpressionCompletionEvaluatorTests.depth16Group + "+" + MathExpressionCompletionEvaluatorTests.depth16Group + "=",
             "4")
          ])
    func test계산결과문자열(label: String, expression: String, expectedInsertText: String) {
        #expect(
            MathExpressionCompletionEvaluator.completion(for: expression)?.insertText == expectedInsertText,
            "\(label)"
        )
    }

    @Test("앞쪽 문맥을 떼고 마지막 수식만 계산",
          arguments: [
            // (label, text, expectedExpressionText, expectedInsertText)
            ("이전 등식 결과 뒤 마지막 수식만 계산", "3+1=4 2+3=", "2+3=", "5"),
            ("단어 끝 곱셈 별칭(x)은 마지막 수식과 분리", "tax 2+3=", "2+3=", "5"),
            ("단어 끝 곱셈 별칭(X)은 마지막 수식과 분리", "BOX 2+3=", "2+3=", "5"),
            ("줄바꿈 뒤 마지막 수식을 독립 문맥으로 계산", "1\n2+3=", "2+3=", "5"),
            ("문자 문맥과 줄바꿈 뒤 마지막 수식을 독립 문맥으로 계산", "memo 1\n2+3=", "2+3=", "5")
          ])
    func test앞쪽문맥을떼고_마지막수식만계산(
        label: String,
        text: String,
        expectedExpressionText: String,
        expectedInsertText: String
    ) {
        let completion = MathExpressionCompletionEvaluator.completion(for: text)

        #expect(completion?.expressionText == expectedExpressionText, "\(label)")
        #expect(completion?.insertText == expectedInsertText, "\(label)")
    }

    @Test("올바른 천 단위 쉼표 숫자는 계산하고 입력 원문을 유지")
    func test올바른천단위쉼표숫자는_계산하고입력원문을유지() {
        let completion = MathExpressionCompletionEvaluator.completion(
            for: "1,000 / 4="
        )

        #expect(completion?.expressionText == "1,000 / 4=")
        #expect(completion?.displayText == "1,000 / 4=250")
    }

    @Test("소수점으로 끝난 숫자는 계산하고 숫자 없는 소수점은 거부")
    func test소수점으로끝난숫자는_계산하고숫자없는소수점은거부() {
        #expect(
            MathExpressionCompletionEvaluator.completion(for: "1.+2=")?.insertText == "3"
        )
        #expect(MathExpressionCompletionEvaluator.completion(for: ".+2=") == nil)
        #expect(MathExpressionCompletionEvaluator.completion(for: "1..0+2=") == nil)
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

    @Test("수식 입력은 256자까지 계산하고 초과 입력은 거부")
    func test수식입력길이경계() {
        let maximumLengthExpression = String(repeating: "1+", count: 127) + "1="
        #expect(maximumLengthExpression.count == 256)
        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: maximumLengthExpression
            )?.insertText == "128"
        )

        let oversizedExpression = " " + maximumLengthExpression
        #expect(oversizedExpression.count == 257)
        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: oversizedExpression
            ) == nil
        )
    }

    @Test("괄호 중첩은 16단계까지 계산하고 17단계부터 거부")
    func test괄호중첩깊이경계() {
        func expression(depth: Int) -> String {
            return String(repeating: "(", count: depth)
                + "1+1"
                + String(repeating: ")", count: depth)
                + "="
        }

        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: expression(depth: 16)
            )?.insertText == "2"
        )
        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: expression(depth: 17)
            ) == nil
        )
    }
}
