//
//  NSString+Encoding.swift
//  TeXKit
//
//  Created by 孟超 on 2024/8/15.
//

import Foundation

extension NSString {
    /// Open the file independently of its encoding.
    ///
    /// - Parameter url: The url of the file.
    /// - Parameter encoding: The encoding of the file.
    static func createFromURL(_ url: URL, encoding: inout String.Encoding?) throws -> Self {
        // Open the file independently of its encoding
        var dict: NSDictionary? = [:]
        let attrString = try NSAttributedString(
            url: url, documentAttributes: &dict
        )
        guard let dict else {
            throw CocoaError(.fileReadUnknownStringEncoding)
        }
        guard let encodingRawValue = dict.value(forKey: NSAttributedString.DocumentAttributeKey.characterEncoding.rawValue) as? UInt else {
            throw CocoaError(.fileReadUnknownStringEncoding)
        }
        encoding = String.Encoding(rawValue: encodingRawValue)
        return Self.init(string: attrString.string)
    }
    
    /// Open the file independently of its encoding.
    ///
    /// - Parameter url: The url of the file.
    static func createFromURL(_ url: URL) throws -> Self {
        var encoding: String.Encoding?
        return try Self.createFromURL(url, encoding: &encoding)
    }
    
    /// Open the data independently of its encoding.
    ///
    /// - Parameter data: The data of the file.
    /// - Parameter encoding: The encoding of the file.
    static func createFromData(_ data: Data, encoding: inout String.Encoding?) throws -> Self {
        // Open the file independently of its encoding
        var dict: NSDictionary? = [:]
        let attrString = try NSAttributedString(
            data: data, documentAttributes: &dict
        )
        guard let dict else {
            throw CocoaError(.fileReadUnknownStringEncoding)
        }
        guard let encodingRawValue = dict.value(forKey: NSAttributedString.DocumentAttributeKey.characterEncoding.rawValue) as? UInt else {
            throw CocoaError(.fileReadUnknownStringEncoding)
        }
        encoding = String.Encoding(rawValue: encodingRawValue)
        return Self.init(string: attrString.string)
    }
    
    /// Open the data independently of its encoding.
    ///
    /// - Parameter data: The data of the file.
    static func createFromData(_ data: Data) throws -> Self {
        var encoding: String.Encoding?
        return try Self.createFromData(data, encoding: &encoding)
    }
}
