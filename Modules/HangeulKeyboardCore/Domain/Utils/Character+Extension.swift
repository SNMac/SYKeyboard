//
//  Character+Extension.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 12/14/25.
//

import Foundation

extension Character {
    /// 해당 문자가 한글(완성형 소리마디, 호환 자모, 아래아 포함)인지 확인합니다.
    var isHangeul: Bool {
        guard let scalar = self.unicodeScalars.first?.value else { return false }
        
        return (0xAC00...0xD7A3).contains(scalar) // 가 ~ 힣 (완성형)
        || (0x3130...0x318F).contains(scalar)    // ㄱ ~ ㅎ, ㅏ ~ ㅣ, ㆍ(318D), ᆢ(318E) 포함
    }
}
