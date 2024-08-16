//
//  String+Encoding.swift
//
//
//  Created by 孟超 on 2024/8/16.
//

import Foundation

extension String.Encoding {
    /**
     Current encoding localization summary

     This property can be displayed in the user interface to present the name of the encoding.
     */
    public var localizedDescription: String {
        return switch self {
            case .ascii: "ASCII"
            case .nextstep: "NextStep"
            case .japaneseEUC: "Japanese EUC"
            case .utf8: "UTF-8"
            case .isoLatin1: "ISO-Latin1"
            case .symbol: "Symbol"
            case .nonLossyASCII: "NonLossy ASCII"
            case .shiftJIS: "Shift JIS"
            case .isoLatin2: "ISO-Latin2"
            case .unicode: "Unicode"
            case .windowsCP1251: "Windows CP1251"
            case .windowsCP1252: "Windows CP1252"
            case .windowsCP1253: "Windows CP1253"
            case .windowsCP1254: "Windows CP1254"
            case .windowsCP1250: "Windows CP1250"
            case .iso2022JP: "ISO-2022-JP"
            case .macOSRoman: "MacRoman"
            case .utf16: "UTF-16"
            case .utf16BigEndian: "UTF-16(BE)"
            case .utf16LittleEndian: "UTF-16(LE)"
            case .utf32: "UTF-32"
            case .utf32BigEndian: "UTF-32(BE)"
            case .utf32LittleEndian: "UTF-32(LE)"
            default:
                "Unknown Encoding"
        }
    }
}
