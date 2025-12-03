//
//  String+Extension.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 12/4/25.
//

extension String {
    /// 해당 문자열이 한글(자음, 모음, 완성형 포함)인지 확인합니다.
    /// - Returns: 한글 범주에 포함되면 `true`, 아니면 `false`
    public func isHangeul() -> Bool {
        guard let scalar = self.unicodeScalars.first else { return false }
        let value = scalar.value
        
        // 한글 자모 (0x1100-0x11FF)
        // 한글 호환 자모 (0x3130-0x318F)
        // 한글 완성형 (0xAC00-0xD7AF)
        // 천지인 아래아(ㆍ: 0x318D) 포함
        return (0x1100...0x11FF).contains(value) || (0x3130...0x318F).contains(value)
        || (0xAC00...0xD7AF).contains(value)
    }
}
