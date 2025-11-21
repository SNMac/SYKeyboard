//
//  String+Extension.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/18/25.
//

extension String {
    /// 문자열의 마지막 '.' 이후에 공백(whitespace)과 개행(newline) 문자만 있는지 확인합니다.
    ///
    /// - Returns: '.'이 없거나, '.' 이후에 공백/개행이 아닌 문자가 있으면 `false`를 반환합니다.
    ///            '.'이 마지막 문자이거나, '.' 이후가 공백/개행으로만 이루어져 있으면 `true`를 반환합니다.
    func hasOnlyWhitespaceFromLastDot() -> Bool {
        guard let lastDotIndex = self.lastIndex(of: ".") else { return false }
        
        let substringFromDot = String(self[lastDotIndex...])
        return substringFromDot.trimmingCharacters(in: .whitespacesAndNewlines) == "."
    }
    
    /// 문자열이 공백(whitespace) 또는 개행(newline)으로 끝나는지 확인합니다.
    ///
    /// - Returns: 문자열의 마지막 문자가 공백/개행이면 `true`를, 그렇지 않거나 빈 문자열이면 `false`를 반환합니다.
    func endsWithWhitespace() -> Bool {
        return self.last?.isWhitespace == true
    }
}
