//
//  CloudTextModel.swift
//
//
//  Created by 孟超 on 2024/8/16.
//

#if canImport(Foundation)

import Foundation

/// The model of a string in CloudDocument.
///
/// The current model has valuable semantics.
public final class CloudTextModel: CloudFileModel {
    public typealias Encoding = String.Encoding
    public typealias DataInfo = Encoding
    /// The string that the current object is managing.
    public let string: String
    
    
    private let firstLoadEncoding: Encoding
    
    /// Construct the current model using the specified string.
    init(string: String, encoding: Encoding) {
        self.string = string
        self.firstLoadEncoding = encoding
    }
    /// Construct the current model using the specified string.
    ///
    /// - Parameter string: String used for initializing the current class.
    /// - Note: Initialize the current model with this method, `self.firstLoadInfo` will always return `.utf8`.
    public init(string: String = .init()) {
        self.string = string
        self.firstLoadEncoding = .utf8
    }
    /// The encoding used for the file data corresponding to this string.
    ///
    /// - Note: This property will never return `nil`, so you can safely force unwrap this property.
    ///
    /// When constructing an instance of the current class using the .init method, this property will always return `.utf8`.
    public var dataInfo: Encoding? {
        self.firstLoadEncoding
    }
    
    /// Create an empty string.
    ///
    /// - Note: Create an empty model with this method, `self.firstLoadInfo` will always return `.utf8`.
    public static func createEmptyModel() -> CloudTextModel {
        CloudTextModel()
    }
    
    /// Create a string from the given data.
    ///
    /// - Parameter data: File data used to create a string.
    ///
    /// If the file data is invalid or the encoding cannot be parsed, this method will throw an error.
    public static func createModel(from data: Data) throws -> CloudTextModel {
        var encoding: String.Encoding? = nil
        let str = try NSString.createFromData(data, encoding: &encoding) as String
        return CloudTextModel(string: str, encoding: encoding ?? str.fastestEncoding)
    }
    
    /// Please return the data corresponding to this string as quickly as possible.
    ///
    /// This method tries to generate string file data using the encoding corresponding to `self.firstLoadInfo` and UTF-8 encoding in turn. If both attempts fail, an error will be thrown.
    public func accessModelData() throws -> Data {
        guard let data = self.string.data(using: self.firstLoadEncoding) ?? self.string.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return data
    }
}

#endif
