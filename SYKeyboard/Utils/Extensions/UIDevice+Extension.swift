//
//  UIDevice+Extension.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/22/25.
//

import SwiftUI

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) { ptr in
            return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }
        
        switch modelCode {
            // Simulator
        case "i386", "x86_64", "arm64": return "Simulator"
            
            // iPhone
        case "iPhone1,1" :              return "iPhone"
        case "iPhone1,2" :              return "iPhone 3G"
        case "iPhone2,1" :              return "iPhone 3GS"
        case "iPhone3,1" :              return "iPhone 4"
        case "iPhone3,2" :              return "iPhone 4 GSM Rev A"
        case "iPhone3,3" :              return "iPhone 4 CDMA"
        case "iPhone4,1" :              return "iPhone 4S"
        case "iPhone5,1" :              return "iPhone 5 (GSM)"
        case "iPhone5,2" :              return "iPhone 5 (GSM+CDMA)"
        case "iPhone5,3" :              return "iPhone 5C (GSM)"
        case "iPhone5,4" :              return "iPhone 5C (Global)"
        case "iPhone6,1" :              return "iPhone 5S (GSM)"
        case "iPhone6,2" :              return "iPhone 5S (Global)"
        case "iPhone7,1" :              return "iPhone 6 Plus"
        case "iPhone7,2" :              return "iPhone 6"
        case "iPhone8,1" :              return "iPhone 6s"
        case "iPhone8,2" :              return "iPhone 6s Plus"
        case "iPhone8,4" :              return "iPhone SE (GSM)"
        case "iPhone9,1" :              return "iPhone 7"
        case "iPhone9,2" :              return "iPhone 7 Plus"
        case "iPhone9,3" :              return "iPhone 7"
        case "iPhone9,4" :              return "iPhone 7 Plus"
        case "iPhone10,1" :             return "iPhone 8"
        case "iPhone10,2" :             return "iPhone 8 Plus"
        case "iPhone10,3" :             return "iPhone X Global"
        case "iPhone10,4" :             return "iPhone 8"
        case "iPhone10,5" :             return "iPhone 8 Plus"
        case "iPhone10,6" :             return "iPhone X GSM"
        case "iPhone11,2" :             return "iPhone XS"
        case "iPhone11,4" :             return "iPhone XS Max"
        case "iPhone11,6" :             return "iPhone XS Max Global"
        case "iPhone11,8" :             return "iPhone XR"
        case "iPhone12,1" :             return "iPhone 11"
        case "iPhone12,3" :             return "iPhone 11 Pro"
        case "iPhone12,5" :             return "iPhone 11 Pro Max"
        case "iPhone12,8" :             return "iPhone SE 2nd Gen"
        case "iPhone13,1" :             return "iPhone 12 Mini"
        case "iPhone13,2" :             return "iPhone 12"
        case "iPhone13,3" :             return "iPhone 12 Pro"
        case "iPhone13,4" :             return "iPhone 12 Pro Max"
        case "iPhone14,2" :             return "iPhone 13 Pro"
        case "iPhone14,3" :             return "iPhone 13 Pro Max"
        case "iPhone14,4" :             return "iPhone 13 Mini"
        case "iPhone14,5" :             return "iPhone 13"
        case "iPhone14,6" :             return "iPhone SE 3rd Gen"
        case "iPhone14,7" :             return "iPhone 14"
        case "iPhone14,8" :             return "iPhone 14 Plus"
        case "iPhone15,2" :             return "iPhone 14 Pro"
        case "iPhone15,3" :             return "iPhone 14 Pro Max"
        case "iPhone15,4" :             return "iPhone 15"
        case "iPhone15,5" :             return "iPhone 15 Plus"
        case "iPhone16,1" :             return "iPhone 15 Pro"
        case "iPhone16,2" :             return "iPhone 15 Pro Max"
        case "iPhone17,1" :             return "iPhone 16 Pro"
        case "iPhone17,2" :             return "iPhone 16 Pro Max"
        case "iPhone17,3" :             return "iPhone 16"
        case "iPhone17,4" :             return "iPhone 16 Plus"
        case "iPhone17,5" :             return "iPhone Air"
        case "iPhone18,2" :             return "iPhone 17 Pro Max"
            
            // Others
        default:                        return modelCode
        }
    }
}
